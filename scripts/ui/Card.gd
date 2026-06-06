# UI element representing a CardData
extends Control
class_name Card

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const CARD_ART_REGISTRY := preload("res://scripts/ui/theme/CardArtRegistry.gd")
const TOUCH_FEEDBACK := preload("res://scripts/ui/theme/TouchFeedback.gd")

var card_data: CardData = null
var card_listeners: Array[BaseCardListener] = []

const CARDS_RERENDER_LAZILY: bool = true # throttles card display generation to next frame
var _card_is_rerendering: bool = false

const CARD_TEXT_IMAGE_SIZE: int = 16	# images in card descriptions will be set to this size
const ENERGY_ICON_KEYWORD: String = "[energy_icon]"	# tells description to display an energy icon in place

@onready var card_button: Button = %CardButton

@onready var pivot: Node2D = $Pivot

@onready var card_texture = %CardTexture
@onready var card_frame: TextureRect = %CardFrame
@onready var card_name: RichLabelAutoSizer = %CardName
@onready var card_type: Label = %CardType
@onready var card_description: RichLabelAutoSizer = %CardDescription
@onready var card_energy_cost: Label = %EnergyCost
@onready var card_color: ColorRect = %ColorBackground

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var card_glow: ColorRect = %CardGlow

@onready var keyword_container = $Pivot/KeywordContainer
@onready var keyword_timer = $KeywordTimer

const KEYWORD_HOVER_DELAY: float = 0.5

## Figma 規格：卡牌主色依 card_type 決定（鮮豔飽和，不再 lerp 到 paper_warm）
const CARD_TYPE_COLORS: Dictionary = {
	CardData.CARD_TYPES.ATTACK: Color(0.79, 0.13, 0.13),   # 攻擊 — 朱紅
	CardData.CARD_TYPES.SKILL:  Color(0.18, 0.56, 0.72),   # 技能 — 海青
	CardData.CARD_TYPES.POWER:  Color(0.16, 0.52, 0.28),   # 能力 — 翠綠
	CardData.CARD_TYPES.STATUS: Color(0.55, 0.38, 0.12),   # 狀態 — 琥珀
	CardData.CARD_TYPES.CURSE:  Color(0.40, 0.13, 0.52),   # 詛咒 — 深紫
}
## 中文卡牌類型標籤（Figma 頂右 pill badge 顯示）
const CARD_TYPE_LABELS: Dictionary = {
	CardData.CARD_TYPES.ATTACK: "攻擊",
	CardData.CARD_TYPES.SKILL:  "技能",
	CardData.CARD_TYPES.POWER:  "能力",
	CardData.CARD_TYPES.STATUS: "狀態",
	CardData.CARD_TYPES.CURSE:  "詛咒",
}

signal card_selected(Card)
signal card_right_clicked(Card)
signal card_hovered(Card)
signal card_unhovered(Card)

## 鎮島錄 — 手牌長按合符 handler（由 Hand 設定為 try_mobile_merge；回傳 true=已處理 → 不顯示詳情）。
## 非手牌卡（reward/shop）不設定此 handler → 長按維持顯示詳情。
var long_press_handler: Callable = Callable()

func init(_card_data: CardData, angular_offset: float, connect_combat_signals: bool = false, connect_ui_signals: bool = true):
	card_data = _card_data
	pivot.rotation_degrees = angular_offset
	
	# signals used for cards in player's hand
	if connect_combat_signals:
		Signals.card_discarded.connect(_on_card_discarded)
		Signals.card_play_started.connect(_on_card_play_started)
		Signals.card_exhausted.connect(_on_card_exhausted)
		Signals.card_banished.connect(_on_card_banished)
		Signals.card_drawn.connect(_on_card_drawn)
		Signals.card_added_to_draw.connect(_on_card_added_to_draw)
		Signals.card_properties_changed.connect(_on_card_properties_changed)
		Signals.card_turn_energy_changed.connect(_on_card_turn_energy_changed)
		Signals.card_upgraded.connect(_on_card_upgraded)
		Signals.card_transformed.connect(_on_card_transformed)
	# flag to disable cards so they're not interactable by player
	if connect_ui_signals:
		card_button.gui_input.connect(_on_button_gui_input)
		# button_up handles card selection on both desktop and mobile (touch)
		# gui_input's left_click is unreliable on Android (InputEventScreenTouch ≠ InputEventMouseButton)
		card_button.button_up.connect(_on_card_button_up)
		card_button.button_down.connect(func(): TOUCH_FEEDBACK.apply_state(card_button, TOUCH_FEEDBACK.TouchState.PRESSED))
		TOUCH_FEEDBACK.install_long_press_detail(card_button, _make_card_detail_payload(), _on_long_press_attempt)
		card_button.mouse_entered.connect(_on_mouse_entered)
		card_button.mouse_exited.connect(_on_mouse_exited)
		keyword_timer.timeout.connect(_on_keyword_timeout)
	
	update_card_display()
	
	# initialize card listeners if in hand
	if Global.player_data.player_hand.has(card_data):
		card_listeners = _generate_card_listeners(card_data.card_listeners)
	

func update_card_display(selected_enemy: Enemy = null) -> void:
	if _card_is_rerendering:
		return
	if CARDS_RERENDER_LAZILY:
		_card_is_rerendering = true
		await get_tree().process_frame
		_card_is_rerendering = false
	
	# update visuals - v3 NBP cards first, fallback to legacy path
	var v3_tex: Texture2D = CARD_ART_REGISTRY.get_card_art(card_data.object_id)
	if v3_tex != null:
		card_texture.texture = v3_tex
	else:
		var card_art_path: String = COTIW_UI_THEME.get_mobile_safe_card_art_path(card_data.card_texture_path)
		if card_art_path != "":
			# v3 NBP refined pixel art lives at res:// (packed in APK)；用 load() 直拿，跳過 FileLoader user:// prefix
			if card_art_path.begins_with("res://") and ResourceLoader.exists(card_art_path):
				card_texture.texture = load(card_art_path)
			else:
				card_texture.texture = FileLoader.load_texture(card_art_path)
	
	var frame_path: String = COTIW_UI_THEME.get_card_frame_path(card_data.card_rarity)
	if frame_path != "" and ResourceLoader.exists(frame_path):
		card_frame.texture = load(frame_path)
		card_frame.visible = true  # 啟用金框 SVG 疊圖

	# ── Figma 排版：卡名移至描述區，類型 pill 移至右上角 ─────────────────────────────
	# 卡名：在 CardTexture 座標系下 offset_top=102 = 卡片 y≈106，落在暗色描述區頂部
	card_name.offset_top    = 102.0
	card_name.offset_bottom = 118.0
	# 描述區背景延伸覆蓋 y=107 以下（原 y=122，補齊與色塊分界對齊）
	var desc_bg := $Pivot/CardVisual/DescriptionBg
	desc_bg.offset_top    = 107.0
	desc_bg.offset_bottom = 180.0
	desc_bg.color         = Color(0.08, 0.03, 0.03, 0.95)
	# 描述文字下移，避免與卡名重疊
	card_description.offset_top = 122.0
	# 類型 pill：移至右上角，套用暗底圓角 StyleBox
	card_type.offset_left  = 82.0
	card_type.offset_top   = 3.0
	card_type.offset_right = 140.0
	card_type.offset_bottom = 14.0
	var _pill := StyleBoxFlat.new()
	_pill.bg_color = Color(0.04, 0.01, 0.01, 0.86)
	_pill.set_corner_radius_all(4)
	_pill.content_margin_left   = 3.0
	_pill.content_margin_right  = 3.0
	_pill.content_margin_top    = 0.0
	_pill.content_margin_bottom = 0.0
	card_type.add_theme_stylebox_override("normal", _pill)

	# ── 文字內容 ─────────────────────────────────────────────────────────────────────
	card_name.set_bbcode("[center]" + card_data.get_card_name() + "[/center]")
	card_description.set_bbcode(get_card_description(selected_enemy))
	card_type.text = CARD_TYPE_LABELS.get(card_data.card_type, "？")
	card_name.add_theme_color_override("default_color", COTIW_UI_THEME.get_color("incense_gold", Color.GOLD))
	card_type.add_theme_color_override("font_color", Color(0.96, 0.90, 0.80, 1.0))
	card_description.add_theme_color_override("default_color", COTIW_UI_THEME.get_color("paper_warm", Color(0.96, 0.90, 0.80)))
	card_glow.color = COTIW_UI_THEME.get_color("neon_cyan", Color(0.909804, 0.901961, 0.992157, 0.392157))

	# ── 卡片主色：依類型飽和色，限縮至頂部美術區（高度 107 px）─────────────────────
	card_color.offset_top    = 0.0
	card_color.offset_left   = 0.0
	card_color.offset_right  = 144.0
	card_color.offset_bottom = 107.0
	# P0：卡類色彩統一走 design token 語意，不在 Card 內各自硬編孤立色。
	card_color.color = COTIW_UI_THEME.get_card_type_accent(card_data.card_type)
	
	$Pivot/CardVisual/EnergySprite.visible = card_data.card_is_playable
	
	if card_data.card_energy_cost_is_variable:
		card_energy_cost.text = "X"
		if card_data.card_energy_cost_variable_upper_bound >= 1:
			card_energy_cost.text = "X-" + str(card_data.card_energy_cost_variable_upper_bound)
	else:
		card_energy_cost.text = str(card_data.get_card_energy_cost())

func set_card_glow(_visible: bool) -> void:
	card_glow.visible = _visible

func toggle_card_glow() -> void:
	card_glow.visible = !card_glow.visible

func can_play_card() -> bool:
	if not card_data.card_is_playable:
		return false
	if Global.player_data.player_energy < card_data.get_card_energy_cost():
		return false
	
	if not _validate_card():
		return false
	
	return true

func get_card_description(selected_target: BaseCombatant = null) -> String:
	# generates a card description for a card
	var modified_description_bb_code: String = card_data.card_description
	

	# generate fake card request
	var card_play_request: CardPlayRequest = CardPlayRequest.new()	# generate fake request
	card_play_request.card_data = card_data
	card_play_request.selected_target = selected_target
	
	# figure out what actions/values to calculate for the preview
	var card_description_preview_data: Array[Array] = []
	if len(card_data.card_description_preview_overrides) == 0:
		# with no overrides, assume basic block and attack
		card_description_preview_data = [
		 ["damage", Scripts.ACTION_ATTACK],
		 ["block", Scripts.ACTION_BLOCK]
		]
	else:
		# use the card's preview overrides
		card_description_preview_data = card_data.card_description_preview_overrides
	
	var player: Player = Global.get_player()
	
	# iterate over the preview data to determine any differences in the card's values
	for preview_data in card_description_preview_data:
		if len(preview_data) >= 2:
			var key_name: String = preview_data[0]
			var action_script_path: String = preview_data[1]
			
			if card_data.card_description.contains("[" + key_name + "]"):
				var action_data: Array[Dictionary] = [{action_script_path: {}}]
				var generated_action: BaseAction = ActionGenerator.create_actions(player, card_play_request, [selected_target], action_data, null)[0]
				var action_interceptor_processor: ActionInterceptorProcessor = generated_action._intercept_action([selected_target], true)[0]
				
				var card_value: int = card_data.card_values.get(key_name, 0)
				var value_substring: String = str(card_value)
				
				if action_interceptor_processor.shadowed_action_values.has(key_name):
					var intercepted_value: int = action_interceptor_processor.get_shadowed_action_values(key_name, card_value)
					
					# compare the intercepted valus to the card's values
					if intercepted_value < card_value:
						value_substring = "[color=red]" + str(intercepted_value) + "[/color]" # worse: red
					if intercepted_value > card_value:
						value_substring = "[color=green]" + str(intercepted_value) + "[/color]" # better: green
				
				modified_description_bb_code = modified_description_bb_code.replace("["+key_name+"]", value_substring)
			
	# do a second pass for non intercepted values in card description
	for key_name in card_data.card_values.keys():
		var non_intercepted_value: Variant = card_data.card_values[key_name]
		if non_intercepted_value is float:
			non_intercepted_value = int(non_intercepted_value)
		modified_description_bb_code = modified_description_bb_code.replace("["+key_name+"]", str(non_intercepted_value))
	
	# replace energy icon with external image bbcode
	if card_data.card_description.contains(ENERGY_ICON_KEYWORD):
		var character_data: CharacterData = Global.get_character_data(Global.player_data.player_character_object_id)
		if character_data != null:
			var image_bb_code: String = "[img width={0}]{1}[/img]".format([CARD_TEXT_IMAGE_SIZE, character_data.character_text_energy_texture_path])
			modified_description_bb_code = modified_description_bb_code.replace(ENERGY_ICON_KEYWORD, image_bb_code)
	
	return modified_description_bb_code

func _make_card_detail_payload() -> Dictionary:
	if card_data == null:
		return {"type": "card", "label": "未知卡牌"}
	return {
		"type": "card",
		"id": card_data.object_id,
		"name": card_data.get_card_name(),
		"cost": card_data.get_card_energy_cost(),
		"description": get_card_description(),
	}

func _generate_card_listeners(listener_data: Array[Dictionary]) -> Array[BaseCardListener]:
	var generated_card_listeners: Array[BaseCardListener] = []
	for card_listener_data in listener_data:
		for card_listener_path in card_listener_data:
			var listener_asset = load(card_listener_path)
			var listener_values: Dictionary = card_listener_data[card_listener_path]
			var card_listener: BaseCardListener = listener_asset.new(self, listener_values)
			generated_card_listeners.append(card_listener)
	
	return generated_card_listeners

## Checks if card passes all validators to play it
func _validate_card() -> bool:
	return Global.validate(card_data.card_play_validators, card_data, null)

func _glow_validation() -> bool:
	# determines glow logic
	if len(card_data.card_glow_validators) == 0:
		if len(card_data.card_play_validators) > 0:
			return _validate_card() # if no glow validators use play validators
		else:
			return false
	else:
		# use glow validators
		return Global.validate(card_data.card_glow_validators, card_data, null)

func _is_card_in_hand() -> bool:
	return Global.player_data.player_hand.has(card_data)

func _attempt_hand_glow() -> void:
	# tests to see if cards in hand that require validation meet validation and glow
	if _is_card_in_hand():
		set_card_glow(_glow_validation())

func _on_card_button_up():
	# fires on both mouse-left-release (desktop) and touch-release (mobile)
	card_selected.emit(self)

func _on_button_gui_input(event: InputEvent):
	# left_click is handled by button_up (cross-platform)
	# keep gui_input only for right_click
	if event.is_action_pressed("right_click"):
		card_right_clicked.emit(self)

## 鎮島錄 — 長按攔截：委派 Hand 的合符入口（僅手牌卡有 handler）。
## 回傳 true=已合符/已攔截 → TouchFeedback 不顯示詳情 overlay。
func _on_long_press_attempt() -> bool:
	if long_press_handler.is_valid():
		return bool(long_press_handler.call(self))
	return false

func _on_mouse_entered():
	keyword_timer.start(KEYWORD_HOVER_DELAY)
	card_hovered.emit(self)
	
func _on_mouse_exited():
	keyword_timer.stop()
	keyword_container.clear_keywords()
	card_unhovered.emit(self)

func _on_keyword_timeout():
	keyword_container.populate_card_keywords(card_data)

func _on_card_properties_changed(_card_data: CardData):
	if card_data == _card_data:
		update_card_display()

func _on_card_turn_energy_changed(_card_data: CardData):
	if card_data == _card_data:
		update_card_display()

func _on_card_upgraded(_card_data: CardData):
	if card_data == _card_data:
		update_card_display()

func _on_card_transformed(_card_data: CardData):
	if card_data == _card_data:
		# # reset card listeners to newly transformed card and rerender if in hand
		if Global.player_data.player_hand.has(card_data):
			card_listeners = _generate_card_listeners(card_data.card_listeners)
			update_card_display()

func _on_card_discarded(_card_data: CardData, _is_manual_discard: bool):
	if card_data == _card_data:
		queue_free()
	else:
		_attempt_hand_glow()

func _on_card_play_started(card_play_request: CardPlayRequest):
	if card_data == card_play_request.card_data:
		queue_free()
	else:
		_attempt_hand_glow()

func _on_card_exhausted(_card_data: CardData):
	if card_data == _card_data:
		queue_free()
	else:
		_attempt_hand_glow()

func _on_card_banished(_card_data: CardData, _in_limbo: bool):
	if card_data == _card_data:
		queue_free()
	else:
		_attempt_hand_glow()

func _on_card_drawn(_card_data: CardData):
	_attempt_hand_glow()

func _on_card_added_to_draw(_card_data: CardData):
	if card_data == _card_data:
		queue_free()
	else:
		_attempt_hand_glow()

func disconnect_non_ui_signals() -> void:
	# disconnects everything except internal clicking signals
	pass
