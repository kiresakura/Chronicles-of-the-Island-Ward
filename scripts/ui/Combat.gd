# maintains combat UI
extends Control

# COTIW 全向量視覺層（additive，不改動以下既有戰鬥邏輯）
const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const COMBAT_BACKDROP := preload("res://scripts/ui/VectorCombatBackdrop.gd")
const _FLAT_DECALS := [
	"Background", "CombatBackdrop", "CombatVignette",
	"CombatTopBarBg", "CombatTopBarGold", "CombatBottomBarBg", "CombatBottomBarGold",
]

const HUD_FOCUS := preload("res://scripts/ui/theme/HudFocus.gd")
const WARD_BREAK_FX := preload("res://scripts/ui/fx/WardBreakFX.gd")
const DEITY_CUTIN_FX := preload("res://scripts/ui/fx/DeityCutInFX.gd")

# 鎮島錄 v0.3 換骨：五營戰鬥畫面（取代卡牌戰鬥；執行期 instance，不動巨型 Root.tscn）
const FORMATION_VIEW_SCENE := preload("res://scenes/ui/FormationCombatView.tscn")
const FORMATION_COMBAT := preload("res://scripts/systems/ritual/FormationCombat.gd")
const FU_DRAFT_VIEW_SCENE := preload("res://scenes/ui/FuDraftView.tscn")

@onready var money_label: Label = $%MoneyLabel
@onready var health_label: Label = $%HealthLabel

@onready var energy_count: Label = $Energy/EnergyCount
@onready var energy: TextureButton = $Energy
@onready var draw_count: Label = $DrawPile/DrawCount
@onready var discard_count: Label = $DiscardPile/DiscardCount
@onready var exhaust_count: Label = $ExhaustPile/ExhaustCount

@onready var deck_button: TextureButton = $DeckButton
@onready var draw_pile_button: TextureButton = $DrawPile
@onready var discard_pile_button: TextureButton = $DiscardPile
@onready var exhaust_pile_button: TextureButton = $ExhaustPile

@onready var card_selection_overlay = $%CardSelectionOverlay

@onready var combat_animation_player: AnimationPlayer = $CombatAnimation
@onready var enemy_container = $EnemyContainer

@onready var player = $Player
@onready var hand = $Hand
@onready var chest = $Chest
@onready var shop = $Shop

@onready var background_button: TextureButton = %BackgroundButton

@onready var end_turn_button: Button = $EndTurnButton

## 鎮島錄 — 請神（Phase 1D）：虎爺請神槽控制器 + 降乩按鈕（程序化建立，不動 Combat.tscn）
var _deity_controller: DeityChargeController = null
var _invoke_button: Button = null
var _invoke_fill: ColorRect = null	# Q1-E：請神槽充能條
var _invoke_glow_tween: Tween = null	# Q1-E：滿槽金光脈動
var end_turn_object: CombatEndTurn = null

# 鎮島錄 v0.3 換骨：五營戰鬥畫面 + 符令 draft 獎勵 + 每場戰鬥編號（擲筊/draft RNG 種子，可重現）
var _formation_view: Control = null
var _fu_draft_view: Control = null
var _combat_index: int = 0

# ── P0 戰鬥狀態提示 + 不可出牌 toast（additive；不改既有 signal flow） ──
const COMBAT_STATUS_PLAYER: String = "combat.my_turn"	# i18n key（const 內不可 tr，顯示點翻）
const COMBAT_STATUS_TARGETING: String = "combat.pick_target"
const COMBAT_STATUS_PROCESSING: String = "combat.processing"
const COMBAT_STATUS_ENEMY: String = "combat.enemy_turn"
var _combat_status_label: Label = null
var _combat_status_base_text: String = ""	# 記住非選敵時的回合狀態，選敵取消後還原
var _combat_toast: Label = null
var _combat_toast_tween: Tween = null

func _ready():
	Signals.player_money_changed.connect(_on_player_money_changed)
	Signals.player_health_changed.connect(_on_player_health_changed)
	
	Signals.enemy_killed.connect(_on_enemy_killed)
	Signals.enemy_death_animation_finished.connect(_on_enemy_death_animation_finished)
	
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)
	
	Signals.player_turn_started.connect(_on_player_turn_started)
	Signals.player_turn_ended.connect(_on_player_turn_ended)
	Signals.enemy_turn_ended.connect(_on_enemy_turn_ended)
	Signals.enemy_turn_started.connect(_on_enemy_turn_started)
	
	Signals.end_turn_requested.connect(_on_end_turn_requested)
	
	end_turn_button.button_up.connect(_on_end_turn_button_up)
	
	update_combat_display()
	player.update_player_display(Global.player_data)
	
	# Q2-F：tablet（4:3）戰場帶 — 下沉 + 腳底錨點放大，把多出的縱向給「舞台」
	_apply_tablet_stage()
	var resp_node: Node = get_node_or_null("/root/Responsive")
	if resp_node != null and resp_node.has_signal("changed"):
		resp_node.changed.connect(_apply_tablet_stage)
	
	# pile buttons
	deck_button.button_up.connect(_on_deck_button_up)
	draw_pile_button.button_up.connect(_on_draw_pile_button_up)
	discard_pile_button.button_up.connect(_on_discard_pile_button_up)
	exhaust_pile_button.button_up.connect(_on_exhaust_pile_button_up)

	# 戰鬥上排 3 鈕 icon（返回鍵 PauseButton 自帶 ui_back）：牌組 / 地圖
	_apply_top_button_icon(deck_button, "res://assets/generated/icons/ui_v2/ui_deck.svg")
	_apply_top_button_icon(get_node_or_null("MapButton") as TextureButton, "res://assets/generated/icons/ui_v2/ui_map.svg")
	# 牌堆 / 能量 / 商店 HUD 鈕：接線既有主題 SVG，取代預設 res://icon.svg placeholder
	_apply_top_button_icon(draw_pile_button, "res://assets/generated/icons/ui_v2/ui_draw.svg")
	_apply_top_button_icon(discard_pile_button, "res://assets/generated/icons/ui_v2/ui_discard.svg")
	_apply_top_button_icon(exhaust_pile_button, "res://assets/generated/icons/ui_v2/ui_burn_jin.svg")  # 焚化 = 消耗堆
	_apply_top_button_icon(energy, "res://assets/generated/icons_v2/status/energy_taiji.svg")
	_apply_top_button_icon(get_node_or_null("Shop") as TextureButton, "res://assets/generated/icons_v2/icon_shop.svg")
	_apply_top_button_icon(chest as TextureButton, "res://assets/generated/icons_v2/icon_chest.svg")  # 寶箱（treasure 節點）
	
	# updating pile counts when cards do things
	Signals.card_played.connect(_on_card_played)	# player is playing card
	Signals.card_drawn.connect(_on_card_drawn)
	Signals.card_deck_shuffled.connect(_on_card_deck_shuffled)
	Signals.card_discarded.connect(_on_card_discarded)
	Signals.card_exhausted.connect(_on_card_exhausted)
	
	Signals.energy_added.connect(_on_energy_added)
	Signals.card_queue_refunded.connect(_on_card_queue_refunded)
	
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	
	Signals.map_location_selected.connect(_on_map_location_selected)

	_apply_vector_skin()
	# v4 Recraft pixel_art 背景 + PixelFX 動畫（火星漫天 + 緊張呼吸 + Ken Burns）
	const PixelSkinCls = preload("res://scripts/ui/theme/PixelSkin.gd")
	const PixelFXCls   = preload("res://scripts/ui/fx/PixelFX.gd")
	var _combat_layer = PixelSkinCls.apply_background(self, "combat_bg_ch1.png")  # 第一章專屬戰鬥 BG（山門廟埕）
	if _combat_layer:
		PixelFXCls.apply(_combat_layer, PixelFXCls.Preset.EMBERS)
	# v2 HUD overlay：3 神明 affinity badges + 八卦 energy ring
	const CombatHudOverlayCls = preload("res://scripts/ui/theme/CombatHudOverlay.gd")
	CombatHudOverlayCls.apply(self)
	# v3 FX overlay：技能特效（damage/block/heal）自動連 Signals
	const CombatFxOverlayCls = preload("res://scripts/ui/theme/CombatFxOverlay.gd")
	CombatFxOverlayCls.apply(self)

	# P0：頂部回合狀態提示 Label + 不可出牌短訊 toast（additive）
	_build_combat_status_label()
	_build_combat_toast()
	# 鎮島錄 — 請神槽 + 降乩按鈕（Phase 1D）
	_build_deity_invocation()
	# Q1-A：HUD 三層閱讀秩序 — 低頻資訊 idle 降權（變化時打一拍）
	_apply_hud_focus_layers()
	# Q1-B：破煞演出 — 演出層只訂閱事件，數值留在 WardBreakSystem（鐵律 1）
	if not Signals.enemy_broken.is_connected(_on_enemy_broken_fx):
		Signals.enemy_broken.connect(_on_enemy_broken_fx)

	# 鎮島錄 v0.3 換骨：建五營戰鬥畫面（隱藏待命，combat_started 時開戰）
	_build_formation_view()


## 套用戰鬥上排 TextureButton 的 icon（取代 icon.svg placeholder）
func _apply_top_button_icon(btn: TextureButton, icon_path: String) -> void:
	if btn == null or not ResourceLoader.exists(icon_path):
		return
	var tex: Texture2D = load(icon_path)
	btn.texture_normal = tex
	btn.texture_hover = tex
	btn.texture_pressed = tex
	btn.texture_disabled = tex


func _on_map_location_selected(location_data: LocationData):
	# determine what to do when the player visits a new location
	var location_type: int = location_data.location_type
	
	chest.visible = false
	shop.visible = false

	set_combat_display_visibility(false)
	# 換骨：離開戰鬥到寶箱/商店等節點時收起五營畫面（戰鬥節點會在 _on_combat_started 重開）
	if _formation_view != null:
		_formation_view.visible = false

	match location_type:
		LocationData.LOCATION_TYPES.COMBAT, LocationData.LOCATION_TYPES.MINIBOSS, LocationData.LOCATION_TYPES.BOSS:
			ActionGenerator.generate_combat_start("") # emit empty event to get location's combat event
		LocationData.LOCATION_TYPES.TREASURE:
			chest.visible = true
		LocationData.LOCATION_TYPES.SHOP:
			shop.visible = true
	
	_update_background()

func update_combat_display():
	energy_count.text = str(Global.player_data.player_energy) + "/" + str(Global.player_data.player_energy_max)
	_set_count_with_pulse(draw_count, draw_pile_button, str(len(Global.player_data.player_draw)))
	_set_count_with_pulse(discard_count, discard_pile_button, str(len(Global.player_data.player_discard)))
	_set_count_with_pulse(exhaust_count, exhaust_pile_button, str(len(Global.player_data.player_exhaust)))
	_on_player_health_changed()
	_on_player_money_changed()

func _update_background() -> void:
	# set the background if possible
	var background_texture_path: String = ""
	
	var act_id: String = Global.player_data.player_act_id
	var act_data: ActData = Global.get_act_data(act_id)
	var location_data: LocationData = Global.get_player_location_data()
	
	# act background
	if act_data.act_background_texture_path != "":
		background_texture_path = act_data.act_background_texture_path
	# location background
	if location_data.location_background_texture_path != "":
		background_texture_path = location_data.location_background_texture_path
	# event background
	var location_event_object_id: String = location_data.get_location_event_object_id()
	if location_event_object_id != "":
		var event_data: EventData = Global.get_event_data(location_event_object_id)
		if event_data.event_background_texture_path != "":
			background_texture_path = event_data.event_background_texture_path
	
	if background_texture_path != "":
		background_button.texture_normal = FileLoader.load_texture(background_texture_path)
	

func set_combat_display_visibility(display_visibility: bool) -> void:
	energy.visible = display_visibility
	draw_pile_button.visible = display_visibility
	discard_pile_button.visible = display_visibility
	exhaust_pile_button.visible = display_visibility
	end_turn_button.visible = display_visibility

func _on_card_played(_card_play_request: CardPlayRequest):
	update_combat_display()

func _on_card_drawn(_card_data: CardData):
	update_combat_display()

func _on_card_deck_shuffled(_is_reshuffle: bool):
	update_combat_display()

func _on_card_discarded(_card_data: CardData, _is_manual_discard: bool):
	update_combat_display()

func _on_card_exhausted(_card_data: CardData):
	update_combat_display()

func _on_energy_added(_energy_amount: int):
	update_combat_display()

func _on_card_queue_refunded():
	update_combat_display()

func _on_player_money_changed():
	var _money_text: String = tr("reward.money") % Global.player_data.player_money
	if money_label.text != _money_text:
		money_label.text = _money_text
		HUD_FOCUS.pulse(money_label)

func _on_player_health_changed():
	health_label.text = "%s / %s" % [Global.player_data.player_health, Global.player_data.player_health_max]

### Deck Buttons

func _on_deck_button_up():
	card_selection_overlay.view_deck()
func _on_draw_pile_button_up():
	card_selection_overlay.view_draw_pile()
func _on_discard_pile_button_up():
	card_selection_overlay.view_discard()
func _on_exhaust_pile_button_up():
	card_selection_overlay.view_exhaust()

### Turn Handling

func _on_enemy_killed(enemy: Enemy):
	var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(enemy, null, [], enemy.enemy_data.enemy_actions_on_death, null)
	ActionHandler.add_actions(generated_actions)
	
	
func _on_enemy_death_animation_finished(_enemy: Enemy):
	# determine if all non minion enemies killed and end combat
	var enemies: Array[Enemy] = []
	enemies.assign(get_tree().get_nodes_in_group("enemies"))
	
	var non_minion_enemies_remain: bool = true
	for enemy in enemies:
		if not enemy.enemy_data.enemy_is_minion:
			non_minion_enemies_remain = false
	
	if non_minion_enemies_remain:
		# wait for actions to finish and end combat
		if ActionHandler.actions_being_performed:
			await ActionHandler.actions_ended
		Signals.combat_ended.emit()

func _on_combat_started(event_id: String):
	# 鎮島錄 v0.3 換骨（FC-2b.1b）：卡牌戰鬥 → 五營戰鬥。仍從 location/event 解析敵人，
	# 翻成煞波餵進五營戰；勝→combat_ended（既有獎勵流程不動）、敗→end_run(LOSS)。
	var current_event: EventData = null
	if event_id == "":
		# if no event is provided, it will be derived from the location
		var current_location: LocationData = Global.get_player_location_data()
		current_event = Global.get_player_event_data()
		if current_location != null:
			current_location.location_visited = true
	else:
		current_event = Global.get_event_data(event_id)

	# 收起卡牌戰鬥 HUD（汰換中：卡牌死碼於 FC-2b.2 移除）
	set_combat_display_visibility(false)
	_hide_card_combat_nodes()
	# 開五營戰：敵人事件→煞波（FC-2a 翻譯），全五營、自動佈陣；符令用本局持久牌庫
	_combat_index += 1
	if _formation_view != null:
		_formation_view.visible = true
		var cfg: Dictionary = FORMATION_COMBAT.load_config()
		cfg["fu_config"] = FORMATION_COMBAT.build_fu_config(Global.run_fu_deck)
		_formation_view.start([], {}, _resolve_enemy_specs(current_event), _combat_index, cfg)
		_raise_top_controls()	# 保留暫停/回地圖鈕在五營畫面之上

func _on_combat_ended():
	set_combat_display_visibility(false)
	if _formation_view != null:
		_formation_view.visible = false


# ── 鎮島錄 v0.3 換骨接縫（FC-2b.1b） ──────────────────────────────────────────

## 建五營戰鬥畫面（隱藏待命）：embedded＝不自動跑示範戰；勝/敗轉接 run 流程。
func _build_formation_view() -> void:
	if _formation_view != null:
		return
	_formation_view = FORMATION_VIEW_SCENE.instantiate()
	_formation_view.embedded = true
	_formation_view.visible = false
	add_child(_formation_view)
	_formation_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not _formation_view.formation_won.is_connected(_on_formation_won):
		_formation_view.formation_won.connect(_on_formation_won)
	if not _formation_view.formation_lost.is_connected(_on_formation_lost):
		_formation_view.formation_lost.connect(_on_formation_lost)
	# 符令 draft 獎勵覆層（戰勝三選一）
	_fu_draft_view = FU_DRAFT_VIEW_SCENE.instantiate()
	_fu_draft_view.visible = false
	add_child(_fu_draft_view)
	_fu_draft_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not _fu_draft_view.fu_picked.is_connected(_on_fu_picked):
		_fu_draft_view.fu_picked.connect(_on_fu_picked)

## 敵人事件 → 五營戰煞波 specs：每個 weighted slot 取最高權重敵，解析其 HP。
func _resolve_enemy_specs(event: EventData) -> Array:
	var specs: Array = []
	if event == null:
		return specs
	for slot: Dictionary in event.event_weighted_enemy_object_ids:
		var best_id: String = ""
		var best_w: float = -1.0
		for eid: Variant in slot:
			var w: float = float(slot[eid])
			if w > best_w:
				best_w = w
				best_id = str(eid)
		if best_id == "":
			continue
		var ed: EnemyData = Global.get_enemy_data_from_prototype(best_id)
		if ed == null:
			continue
		specs.append({"id": best_id, "hp": int(ed.enemy_health)})
	return specs

## 收起卡牌戰鬥節點（汰換中：死碼於 FC-2b.2 移除；先隱藏避免擋五營畫面與輸入）。
func _hide_card_combat_nodes() -> void:
	var card_nodes: Array = [
		hand, player, enemy_container, deck_button, draw_pile_button,
		discard_pile_button, exhaust_pile_button, energy, get_node_or_null("Consumables"),
	]
	for n: Variant in card_nodes:
		if n != null and is_instance_valid(n):
			(n as CanvasItem).visible = false
	if _invoke_button != null and is_instance_valid(_invoke_button):
		_invoke_button.visible = false
	if _combat_status_label != null and is_instance_valid(_combat_status_label):
		_combat_status_label.visible = false

## 把暫停/回地圖鈕移到五營畫面之上（仍可暫停與逃離）。
func _raise_top_controls() -> void:
	for path: String in ["PauseButton", "MapButton"]:
		var n: Node = get_node_or_null(path)
		if n != null:
			move_child(n, -1)

## 五營戰勝：破盡諸煞 → 三選一符令 draft（非 run 結束時）→ 選後發 combat_ended。
func _on_formation_won() -> void:
	if _formation_view != null:
		_formation_view.visible = false
	# run 結束（boss 終局）不發 draft，直接結算
	if _fu_draft_view != null and not Global.is_end_of_run():
		var rng := RandomNumberGenerator.new()
		rng.seed = _combat_index
		var fu_cfg: Dictionary = FORMATION_COMBAT.load_fu_config()
		var choices: Array = FORMATION_COMBAT.draft_fu_choices(int(fu_cfg.get("draft_choices", 3)), rng)
		if choices.is_empty():
			Signals.combat_ended.emit()
			return
		_fu_draft_view.offer(choices, fu_cfg.get("fu", {}))
		move_child(_fu_draft_view, -1)	# 置頂（模態）
	else:
		Signals.combat_ended.emit()

## 領取 draft 符令 → 加進本局持久符令牌庫 → 續發 combat_ended 接既有獎勵流程。
func _on_fu_picked(fu_id: String) -> void:
	Global.run_fu_deck.append(fu_id)
	if _fu_draft_view != null:
		_fu_draft_view.visible = false
	Signals.combat_ended.emit()

## 五營戰敗：母壇崩 → 結束 run（LOSS）。
func _on_formation_lost() -> void:
	if _formation_view != null:
		_formation_view.visible = false
	Global.end_run(Global.RUN_ENDS.LOSS)


func perform_enemy_turn():
	# generates enemy actions and performs them in order
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	if len(enemies) == 0:
		Signals.combat_ended.emit()
		return
	
	# Enemy Turn
	for e in enemies:
		# get enemy standard attack data
		var enemy: Enemy = e	# typecast iterator
		
		
		### perform enemy start of turn statuses
		if enemy.is_alive():
			enemy.perform_status_effect_actions(StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.ENEMY_START_TURN)
			if ActionHandler.actions_being_performed:
				await ActionHandler.actions_ended 
		
		### perform intent
		# NOTE: remember these go in reverse order on the stack
		if enemy.is_alive():
			# add custom actions
			var enemy_actions_data: Array[Dictionary] = []
			enemy_actions_data.assign(enemy.enemy_data.get_current_attack_custom_actions())
			
			# add attacks
			var enemy_attack: Array = enemy.enemy_data.get_current_attack_damages()
			if enemy_attack[1] > 0:
				enemy_actions_data.append(
				{
				Scripts.ACTION_ATTACK_GENERATOR: {"damage": enemy_attack[0], "number_of_attacks": enemy_attack[1], "time_delay": EnemyData.ENEMY_ATTACK_DELAY}
				}
				)
			
			# add block
			var enemy_block: int = enemy.enemy_data.get_current_attack_block()
			if enemy_block > 0:
				enemy_actions_data.append(
					{
					Scripts.ACTION_BLOCK: {
						"block": enemy_block,
						"target_override": BaseAction.TARGET_OVERRIDES.PARENT,
						"time_delay": 0.0,
						}
					}
			)
			
			# add reset block action
			enemy_actions_data.append(
			{
			Scripts.ACTION_RESET_BLOCK:  {
				"target_override": BaseAction.TARGET_OVERRIDES.PARENT,
				"time_delay": 0.0
				}
			}
			)
			
			# perform them and wait
			var enemy_attack_actions: Array = ActionGenerator.create_actions(enemy, null, [player], enemy_actions_data, null)
			ActionHandler.add_actions(enemy_attack_actions)
			if ActionHandler.actions_being_performed:
				await ActionHandler.actions_ended
		
		### Perform enemy end of turn statuses
		if enemy.is_alive():
			enemy.perform_status_effect_actions(StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.ENEMY_END_TURN)
			if ActionHandler.actions_being_performed:
				await ActionHandler.actions_ended 
		
		# if player is dead stop
		if Global.player_data.player_health <= 0:
			return
	
	# all enemies dead
	enemies = get_tree().get_nodes_in_group("enemies")
	if len(enemies) == 0:
		Signals.combat_ended.emit()
		return
	
	Signals.enemy_turn_ended.emit()

	
func _on_player_turn_started():
	# prevent player from playing cards manually
	hand.hand_disabled = true
	set_combat_status(COMBAT_STATUS_PROCESSING)	# P0：抽牌/開場結算中
	
	# first turn actions
	if Global.get_combat_stats().turn_count == 1:
		# location initial actions
		var location_data: LocationData = Global.get_player_location_data()
		assert(location_data != null)
		if location_data != null:
			var card_play_request: CardPlayRequest = CardPlayRequest.new()	# generate fake request
			card_play_request.card_data = null
			card_play_request.selected_target = null
			
			# perform location initial actions
			var location_initial_combat_actions: Array[BaseAction] = ActionGenerator.create_actions(player, card_play_request, [], location_data.location_initial_combat_actions, null)
			ActionHandler.add_actions(location_initial_combat_actions)
		
			# wait for first turn actions
			if ActionHandler.actions_being_performed:
				await ActionHandler.actions_ended
			
			# perform event initial actions
			var event_data: EventData = Global.get_player_event_data()
			var event_initial_combat_actions: Array[BaseAction] = ActionGenerator.create_actions(player, card_play_request, [], event_data.event_initial_combat_actions, null)
			ActionHandler.add_actions(event_initial_combat_actions)
			
			# wait for first turn actions
			if ActionHandler.actions_being_performed:
				await ActionHandler.actions_ended
			
		
		# combat start card actions
		for card_data: CardData in Global.player_data.player_draw:
			var card_play_request: CardPlayRequest = CardPlayRequest.new()	# generate fake request
			card_play_request.card_data = card_data
			card_play_request.selected_target = null
			
			# perform initial actions
			var card_play_actions: Array[BaseAction] = ActionGenerator.create_actions(player, card_play_request, [], card_data.card_initial_combat_actions, null)
			ActionHandler.add_actions(card_play_actions)
	
		# wait for first turn actions
		if ActionHandler.actions_being_performed:
			await ActionHandler.actions_ended
	
	# perform pre draw actions
	player.update_incoming_damage_amount(true)
	player.generate_reset_block_action()
	player.perform_status_effect_actions(StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.POST_DRAW_PLAYER_START_TURN)
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	
	# draw cards
	ActionGenerator.generate_start_of_turn_draw_actions()
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	
	# perform post draw actions
	player.perform_status_effect_actions(StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.PRE_DRAW_PLAYER_START_TURN)
	
	# unlock and update hand
	hand.hand_disabled = false
	hand.update_hand_card_display()
	set_combat_status(COMBAT_STATUS_PLAYER)	# P0：手牌就緒，輪到玩家

func _on_player_turn_ended():
	# prevent player from playing cards
	hand.hand_disabled = true
	set_combat_status(COMBAT_STATUS_PROCESSING)	# P0：回合結束結算中
	# discard non retained cards and perform card actions
	hand.perform_end_of_turn_hand_actions()
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	
	# perform all end of turn actions and await
	player.perform_status_effect_actions(StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.PLAYER_END_TURN)
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	

func _on_player_start_turn_animation_finished():
	# called from animation player
	start_turn()

func _on_player_end_turn_animation_finished():
	# called from animation player
	Signals.player_turn_ended.emit()
	
	# wait for all end of turn actions to process
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	
	# start enemy turn if they're alive
	if len(get_tree().get_nodes_in_group("enemies")) > 0:
		Signals.enemy_turn_started.emit()

func _on_enemy_turn_started():
	set_combat_status(COMBAT_STATUS_ENEMY)	# P0：敵方回合
	perform_enemy_turn()

func _on_enemy_turn_ended():
	set_combat_status(COMBAT_STATUS_PROCESSING)	# P0：敵方結束，準備換我方
	start_turn_animation()
	
func _on_end_turn_button_up():
	AudioManager.play_sfx("turn_end")	# Q1-F
	queue_end_turn(CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.WAIT_FOR_ALL_CARD_PLAYS)

func _on_end_turn_requested(immediacy: int):
	queue_end_turn(immediacy)

func queue_end_turn(immediacy: int = CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.WAIT_FOR_ALL_CARD_PLAYS):
	# queues up an end turn, using async objects with priority to determine how to handle it
	if end_turn_object == null:
		end_turn_object = CombatEndTurn.new(self, %Hand, immediacy)
		end_turn_object.wait()
		end_turn_button.disabled = true
	elif immediacy > end_turn_object.end_turn_queue_value:
		# higher priority end turn, replace the old with a newer one
		end_turn_object.disable()	# stop the old one working
		end_turn_object = CombatEndTurn.new(self, %Hand, immediacy)
		end_turn_object.wait()

func _reset_turn_end_queue() -> void:
	if end_turn_object != null:
		end_turn_object.disable()
		end_turn_object = null

func _on_run_started():
	visible = true
	_on_player_health_changed()
	_on_player_money_changed()
	
func _on_run_ended():
	visible = false
	_reset_turn_end_queue()

func start_combat() -> void:
	_reset_turn_end_queue()

func end_combat() -> void:
	_reset_turn_end_queue()

func end_turn():
	pass

func start_turn():
	# called from animation player
	_reset_turn_end_queue()
	Global.player_data.player_energy = Global.player_data.player_energy_max
	update_combat_display()
	Signals.player_turn_started.emit()

func end_turn_animation() -> void:
	_reset_turn_end_queue()
	combat_animation_player.play("end_turn")
	
func start_turn_animation() -> void:
	combat_animation_player.play("start_turn")

# ---------- COTIW 全向量視覺層（additive；不影響上方戰鬥邏輯） ----------
# 比照主選單：隱藏 Aida 扁平 ColorRect chrome，疊上程序化向量框/暈影/HUD 帶，
# HUD 文字/結束回合鈕走 CotiwUiTheme。保留場景圖（BackgroundButton）為底、
# 全部功能節點與信號不動。隨 RunScreen SafeFit 一起等比進安全區。

func _apply_vector_skin() -> void:
	# 1. 隱藏 Aida 扁平 ColorRect chrome
	for decal_name: String in _FLAT_DECALS:
		var d: Node = get_node_or_null(decal_name)
		if d != null:
			(d as CanvasItem).visible = false

	# 2. 疊上向量 chrome（在場景圖之上、HUD 之下）
	if not has_node("VectorCombatBackdrop"):
		var bg := Control.new()
		bg.name = "VectorCombatBackdrop"
		bg.set_script(COMBAT_BACKDROP)
		bg.anchor_left = 0.0
		bg.anchor_top = 0.0
		bg.anchor_right = 0.0
		bg.anchor_bottom = 0.0
		bg.offset_left = 0.0
		bg.offset_top = 0.0
		bg.offset_right = 1200.0
		bg.offset_bottom = 700.0
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		# 置於場景圖（BackgroundButton）之後 → 繪於其上、HUD 之下
		var anchor_idx: int = 1
		if is_instance_valid(background_button):
			anchor_idx = background_button.get_index() + 1
		move_child(bg, anchor_idx)

	# 3. HUD 文字接通語意色（design_tokens：金幣→incense_gold、血→hp_red、能量→energy_cyan，
	#    牌堆計數沿用 incense_gold —— 卡片相關無其他語意）
	_combat_label(money_label, "incense_gold")
	_combat_label(health_label, "hp_red")
	_combat_label(energy_count, "energy_cyan")
	_combat_label(draw_count, "incense_gold")
	_combat_label(discard_count, "incense_gold")
	_combat_label(exhaust_count, "incense_gold")
	if is_instance_valid(end_turn_button):
		COTIW_UI_THEME.apply_primary_button_style(end_turn_button)
		end_turn_button.add_theme_color_override("font_shadow_color",
			COTIW_UI_THEME.get_color("text_shadow_strong", Color(0, 0, 0, 0.9)))
		end_turn_button.add_theme_constant_override("shadow_offset_x", 2)
		end_turn_button.add_theme_constant_override("shadow_offset_y", 2)

# 給 HUD 文字套上 token 化的語意色 + 標準陰影
func _combat_label(c: Control, color_token: String) -> void:
	if not is_instance_valid(c):
		return
	c.add_theme_color_override("font_color", COTIW_UI_THEME.get_color(color_token, Color(0.95, 0.82, 0.45)))
	c.add_theme_constant_override("shadow_offset_x", 2)
	c.add_theme_constant_override("shadow_offset_y", 2)
	c.add_theme_color_override("font_shadow_color",
		COTIW_UI_THEME.get_color("text_shadow_strong", Color(0, 0, 0, 0.9)))

# ---------- P0 戰鬥狀態提示 + 不可出牌 toast（additive；不影響上方戰鬥邏輯） ----------

## 頂部中央小型回合狀態 Label（我方回合 / 選擇目標 / 行動處理中 / 敵方回合）
func _build_combat_status_label() -> void:
	if _combat_status_label != null:
		return
	_combat_status_label = Label.new()
	_combat_status_label.name = "CombatStatusLabel"
	_combat_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combat_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combat_status_label.position = Vector2(420.0, 8.0)
	_combat_status_label.size = Vector2(360.0, 34.0)
	_combat_status_label.add_theme_font_size_override("font_size", 24)
	_combat_status_label.add_theme_color_override("font_color",
		COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.82, 0.45)))
	_combat_status_label.add_theme_color_override("font_shadow_color",
		COTIW_UI_THEME.get_color("text_shadow_strong", Color(0, 0, 0, 0.9)))
	_combat_status_label.add_theme_constant_override("shadow_offset_x", 2)
	_combat_status_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_combat_status_label)

## 設定回合狀態文字，並記為 base（供選敵取消後還原）
func set_combat_status(text: String) -> void:
	_combat_status_base_text = tr(text)
	if is_instance_valid(_combat_status_label):
		_combat_status_label.text = tr(text)

## Hand 於進入/離開選敵時呼叫：顯示「選擇目標」，取消後還原回合狀態
func set_targeting_status(active: bool) -> void:
	if not is_instance_valid(_combat_status_label):
		return
	_combat_status_label.text = tr(COMBAT_STATUS_TARGETING) if active else _combat_status_base_text

## UIQA Phase3 — toast 佇列（逐則顯示，避免疊字 / 無限堆疊）
var _combat_toast_queue: Array[String] = []

## 戰鬥短訊 toast（預設透明，呼叫時 fade in → 停留 → fade out）
func _build_combat_toast() -> void:
	if _combat_toast != null:
		return
	_combat_toast = Label.new()
	_combat_toast.name = "CombatToast"
	_combat_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combat_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combat_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combat_toast.size = Vector2(440.0, 46.0)	# UIQA：尺寸/位置由 _position_combat_toast 依 safe-rect 設定
	_combat_toast.add_theme_font_size_override("font_size", COTIW_UI_THEME.get_typography_size("h1", 30))
	_combat_toast.add_theme_color_override("font_color",
		COTIW_UI_THEME.get_color("hp_red", Color(0.86, 0.30, 0.24)))
	_combat_toast.add_theme_color_override("font_shadow_color",
		COTIW_UI_THEME.get_color("text_shadow_strong", Color(0, 0, 0, 0.9)))
	_combat_toast.add_theme_constant_override("shadow_offset_x", 2)
	_combat_toast.add_theme_constant_override("shadow_offset_y", 2)
	_combat_toast.modulate = Color(1, 1, 1, 0)
	add_child(_combat_toast)

## 顯示一則短訊（例如「神力不足」「合符完成」）。由 Hand/戰鬥事件呼叫。
## UIQA Phase3：單一 toast 節點 + 佇列 → 不疊字、不無限堆疊；定位走 safe-rect toast lane。
func show_combat_toast(text: String) -> void:
	if _combat_toast == null:
		_build_combat_toast()
	# 若目前正在顯示，排入佇列逐則顯示（避免疊字）
	if _combat_toast.modulate.a > 0.0 and _combat_toast_tween != null and _combat_toast_tween.is_valid():
		if not _combat_toast_queue.has(text):
			_combat_toast_queue.append(text)
		return
	_show_toast_now(text)

func _show_toast_now(text: String) -> void:
	_position_combat_toast()
	_combat_toast.text = text
	if _combat_toast_tween != null and _combat_toast_tween.is_valid():
		_combat_toast_tween.kill()
	_combat_toast.modulate = Color(1, 1, 1, 1)
	_combat_toast_tween = create_tween()
	_combat_toast_tween.tween_interval(0.7)
	_combat_toast_tween.tween_property(_combat_toast, "modulate:a", 0.0, 0.4)
	_combat_toast_tween.tween_callback(_on_combat_toast_finished)

func _on_combat_toast_finished() -> void:
	if not _combat_toast_queue.is_empty():
		_show_toast_now(_combat_toast_queue.pop_front())

## UIQA — toast lane：safe-rect 頂部 HUD 下緣（不遮敵人 intent / 手牌 / 請神槽）。
func _position_combat_toast() -> void:
	if not is_instance_valid(_combat_toast):
		return
	var safe: Rect2 = COTIW_UI_THEME.get_safe_content_rect(get_viewport())
	var w: float = minf(440.0, safe.size.x * 0.66)
	_combat_toast.size = Vector2(w, 46.0)
	# 置中、頂部狀態 Label(y≈8-42)/請神鈕(y≈46-80) 下方
	var pos: Vector2 = Vector2(safe.position.x + (safe.size.x - w) * 0.5, safe.position.y + 100.0)
	_combat_toast.position = COTIW_UI_THEME.clamp_rect_to_safe_area(Rect2(pos, _combat_toast.size), safe).position


#region 鎮島錄 — 請神（Deity Invocation, Phase 1D）
const ACTIVE_DEITY_ID: String = "deity_tiger_god"	# MVP 固定虎爺（主祭/護壇/法器配置屬 Phase 2）
const TIGER_ROAR_DAMAGE: int = 12
const MERCIFUL_HEAL: int = 12		# 媽祖回元神
const MERCIFUL_BLOCK: int = 8		# 媽祖護身符
const LAND_DRAW: int = 2			# 土地公抽牌
const LAND_BLOCK: int = 4			# 土地公護身符

## 建立請神槽控制器 + 降乩按鈕（程序化）。按鈕兼作請神槽顯示（請神中→顯示進度且 disabled；滿槽→可點降乩）。
func _build_deity_invocation() -> void:
	if _deity_controller != null:
		return
	_deity_controller = DeityChargeController.new()
	_deity_controller.name = "DeityChargeController"
	add_child(_deity_controller)
	_deity_controller.charge_changed.connect(_on_deity_charge_changed)

	_invoke_button = Button.new()
	_invoke_button.name = "InvokeButton"
	_invoke_button.focus_mode = Control.FOCUS_NONE
	# 頂部置中，避開底部手牌與中央敵人
	_invoke_button.anchor_left = 0.5
	_invoke_button.anchor_right = 0.5
	_invoke_button.offset_left = -95.0
	_invoke_button.offset_right = 95.0
	# P2：置於頂部回合狀態 Label（y 8–42）下方，避免重疊；仍在敵人區（y>120）上方
	_invoke_button.offset_top = 46.0
	_invoke_button.offset_bottom = 80.0
	_invoke_button.add_theme_font_size_override("font_size", 16)
	_invoke_button.disabled = true
	_invoke_button.visible = false
	_invoke_button.pressed.connect(_on_invoke_button_pressed)
	add_child(_invoke_button)
	HUD_FOCUS.mark_low_freq(_invoke_button)	# Q1-A：請神進度屬層 3，滿槽才升層
	# Q1-E：鈕內底部充能細條（背景 + 金色填充）
	var fill_bg := ColorRect.new()
	fill_bg.color = Color(0.12, 0.06, 0.05, 0.9)
	fill_bg.position = Vector2(6.0, 27.0)
	fill_bg.size = Vector2(178.0, 4.0)
	fill_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_invoke_button.add_child(fill_bg)
	_invoke_fill = ColorRect.new()
	_invoke_fill.color = Color(0.95, 0.78, 0.32)
	_invoke_fill.position = Vector2(6.0, 27.0)
	_invoke_fill.size = Vector2(0.0, 4.0)
	_invoke_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_invoke_button.add_child(_invoke_fill)

func _on_deity_charge_changed(current: int, max_charge: int) -> void:
	if not is_instance_valid(_invoke_button):
		return
	var dname: String = tr("combat.deity")
	if _deity_controller != null and _deity_controller.deity != null:
		dname = _deity_controller.deity.deity_name
	_invoke_button.visible = max_charge > 0
	if _deity_controller != null and _deity_controller.is_ready():
		_invoke_button.text = tr("combat.invoked") % dname
		_invoke_button.disabled = false
		HUD_FOCUS.set_operational(_invoke_button, true)	# 滿槽=本回合可操作 → 恆亮
		if is_instance_valid(_invoke_fill):
			_invoke_fill.size.x = 178.0
		_start_invoke_glow()	# Q1-E：滿槽金光脈動
	else:
		var _prev_text: String = _invoke_button.text
		_invoke_button.text = tr("combat.charge") % [dname, current, max_charge]
		_invoke_button.disabled = true
		HUD_FOCUS.set_operational(_invoke_button, false)
		_stop_invoke_glow()
		if is_instance_valid(_invoke_fill) and max_charge > 0:
			_invoke_fill.size.x = 178.0 * clampf(float(current) / float(max_charge), 0.0, 1.0)
		if _prev_text != _invoke_button.text:
			HUD_FOCUS.pulse(_invoke_button)	# 充能進度變化打一拍

func _on_invoke_button_pressed() -> void:
	if _deity_controller == null or not _deity_controller.is_ready():
		return
	_execute_deity_invocation(_deity_controller.deity)
	_deity_controller.consume()
	# Q3-E 正殿備援神位：釋放後次位神接掌（重設請神盤；無備援則維持原神重充）
	var next_id: String = Global.advance_deity_queue()
	if next_id != "":
		_deity_controller.setup(DeityInvocationSystem.load_deity(next_id))
		show_combat_toast(tr("combat.backup_deity") % str(_deity_controller.deity.deity_name if _deity_controller.deity != null else next_id))

## 降乩效果分派（資料驅動鍵 → 效果）。MVP：虎爺 tiger_roar；其他神明屬 Phase 1D+。
func _execute_deity_invocation(deity: DeityData) -> void:
	if deity == null:
		return
	match deity.deity_invocation_effect:
		"tiger_roar":
			_invoke_tiger_roar()
		"judgment":
			_invoke_judgment()
		"merciful_tide":
			_invoke_merciful_tide()
		"land_blessing":
			_invoke_land_blessing()
		_:
			pass
	# Q1-D：cut-in 演出取代文字 toast（效果已即時結算，演出純 overlay 不拖慢操作）
	DEITY_CUTIN_FX.play(self, deity)
	AudioManager.play_sfx("invoke")	# Q1-F

## 虎爺咬煞：對全體存活敵人造成穿透傷害，並延長其破煞爆發窗口 1 回合。
## 直接走 Enemy.damage()（可靠、含破煞 ×1.5 與死亡處理）；action 化的演出時序屬後續打磨。
func _invoke_tiger_roar() -> void:
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and (e as Enemy).is_alive():
			var enemy_node: Enemy = e as Enemy
			enemy_node.damage(TIGER_ROAR_DAMAGE, true)
			var ed: EnemyData = enemy_node.enemy_data
			if ed != null and ed.enemy_is_broken:
				ed.enemy_broken_turns_remaining += 1

## 城隍夜審：全體存活敵人 驚嚇 +2、怯戰 +1（控場）。
func _invoke_judgment() -> void:
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if e is Enemy and (e as Enemy).is_alive():
			(e as Enemy).add_status_effect_charges("status_effect_vulnerable", 2)
			(e as Enemy).add_status_effect_charges("status_effect_weak", 1)

## 媽祖慈航普渡：回復元神 + 獲得護身符。
func _invoke_merciful_tide() -> void:
	var pd: PlayerData = Global.player_data
	pd.set_health(mini(pd.player_health + MERCIFUL_HEAL, pd.player_health_max))
	if is_instance_valid(player):
		player.add_block(MERCIFUL_BLOCK)

## 土地公福德降臨：抽牌 + 獲得護身符（資源/穩定）。
func _invoke_land_blessing() -> void:
	Signals.card_draw_requested.emit(LAND_DRAW, PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
	if is_instance_valid(player):
		player.add_block(LAND_BLOCK)
#endregion


## Q1-A：三層閱讀秩序接線 — 層 3 低頻元素清單（層 1/2 不經此系統，恆亮）
func _apply_hud_focus_layers() -> void:
	for low_freq: Variant in [
		money_label,
		deck_button, draw_pile_button, discard_pile_button, exhaust_pile_button,
		get_node_or_null("MapButton"), get_node_or_null("PauseButton"),
	]:
		if low_freq is CanvasItem:
			HUD_FOCUS.mark_low_freq(low_freq as CanvasItem)

## 計數文字變更才更新 + 對所屬按鈕打鼓點（值沒變不打 — 熱鬧要有鼓點）
func _set_count_with_pulse(count_label: Label, owner_button: CanvasItem, new_text: String) -> void:
	if count_label.text == new_text:
		return
	count_label.text = new_text
	HUD_FOCUS.pulse(owner_button)


## Q1-B：破煞情緒峰值 — 煞盾碎裂 + 畫面震 + 背景降亮（總長 0.72s，不阻塞輸入）
func _on_enemy_broken_fx(enemy: Enemy) -> void:
	if enemy == null or not is_instance_valid(enemy) or not visible:
		return
	var at: Vector2 = enemy.global_position + Vector2(0.0, -60.0)	# 煞盾環視覺位置（頭頂）
	WARD_BREAK_FX.play(self, at)
	AudioManager.play_sfx("ward_break")	# Q1-F


## Q1-E：滿槽金光脈動（呼吸式 self_modulate 暖金；非滿槽即停）
func _start_invoke_glow() -> void:
	if _invoke_glow_tween != null and _invoke_glow_tween.is_valid():
		return
	_invoke_glow_tween = _invoke_button.create_tween().set_loops()
	_invoke_glow_tween.tween_property(_invoke_button, "self_modulate", Color(1.35, 1.18, 0.85), 0.55).set_trans(Tween.TRANS_SINE)
	_invoke_glow_tween.tween_property(_invoke_button, "self_modulate", Color(1, 1, 1), 0.55).set_trans(Tween.TRANS_SINE)

func _stop_invoke_glow() -> void:
	if _invoke_glow_tween != null and _invoke_glow_tween.is_valid():
		_invoke_glow_tween.kill()
	_invoke_glow_tween = null
	if is_instance_valid(_invoke_button):
		_invoke_button.self_modulate = Color(1, 1, 1)


# ───────────────── Q2-F tablet（4:3）戰場帶 ─────────────────

## 4:3 多出的縱向高度若不處理，會變成「單位群與手牌之間的裂縫 + 頂上空帶」。
## 專屬排版：戰場成員（玩家/敵群）整帶下沉 + 以腳底為錨微放大 — 舞台感而非拉伸。
## 可逆（手機回 1.0/原位）；基準位置首次記在 meta（冪等）。
const TABLET_STAGE_SHIFT_Y := 92.0
const TABLET_STAGE_SCALE := 1.12

func _apply_tablet_stage() -> void:
	var resp: Node = get_node_or_null("/root/Responsive")
	var on_tablet: bool = resp != null and resp.has_method("is_tablet") and resp.is_tablet()
	for member: Control in [player as Control, enemy_container as Control]:
		if member == null:
			continue
		if not member.has_meta("tablet_base_y"):
			member.set_meta("tablet_base_y", member.position.y)
		var base_y: float = float(member.get_meta("tablet_base_y"))
		member.position.y = base_y + (TABLET_STAGE_SHIFT_Y if on_tablet else 0.0)
		member.pivot_offset = Vector2(member.size.x * 0.5, member.size.y)	# 腳底錨點
		member.scale = Vector2.ONE * (TABLET_STAGE_SCALE if on_tablet else 1.0)
