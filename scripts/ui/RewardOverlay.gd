# Overlay for acceptable rewards
extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const FC := preload("res://scripts/systems/ritual/FormationCombat.gd")	# FP-3 寶箱符令顯示
const GILDED_DEPTH := preload("res://scripts/ui/fx/GildedDepthLayer.gd")	# 設計忠實「貴層」

@onready var reward_container: VBoxContainer = $RewardContainer
@onready var continue_button: Button = $ContinueButton
@onready var backdrop: ColorRect = $Background
@onready var panel_fill: ColorRect = $Background2

@onready var map = $%Map

var _offering_table_panel: Panel
var _input_mask: ColorRect	# 全幅 STOP 遮罩（取代固定 1200 Background；隨 viewport 鋪滿、寬螢幕不露邊/不穿透）
var _victory_fx: Control	# 凱旋 juice（金光芒輪+凱旋大字+金箔雨）；戰勝現、寶箱不現

# reward values; These are sorted into mutually exclusive groups
# they can be added to via ActionGrantRewards to allow things to affect them
# call populate_rewards() to actually generate RewardButtons UI elements
var reward_data: Dictionary = {
	#0:
		#{
		#"reward_money": 0,
		#"reward_artifact_ids": [],
		#"reward_card_drafts": [],
		#"reward_custom_action_data": [],
		#}
}

func _ready():
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)
	_apply_reward_banner()	# Q2-E 儀式感頂帶
	
	Signals.map_location_selected.connect(_on_map_location_selected)
	Signals.chest_opened.connect(_on_chest_opened)
	
	Signals.reward_grant_requested.connect(_on_reward_grant_requested)
	Signals.reward_clear_requested.connect(_on_reward_clear_requested)
	
	continue_button.button_up.connect(_on_continue_button_up)
	COTIW_UI_THEME.apply_primary_button_style(continue_button)
	COTIW_UI_THEME.style_overlay_backdrop(backdrop, panel_fill)
	# 固定 1200×700 Background 在寬螢幕(expand)露邊 + 不全幅擋輸入 → 疊一層全幅 STOP 遮罩。
	# 依 viewport.get_visible_rect()（真實邏輯 viewport，含側帶）鋪滿；顯示/改尺寸時重套。
	# 保留原 Background（不隱藏）作後備 dim，避免任何情境下完全無遮罩（無回歸）。
	_ensure_input_mask()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_fit_input_mask):
		vp.size_changed.connect(_fit_input_mask)
	if not visibility_changed.is_connected(_fit_input_mask):
		visibility_changed.connect(_fit_input_mask)	# 不論誰把它設 visible 都重鋪滿
	_build_offering_table_chrome()
	_build_gilded_atmosphere()	# 設計忠實「貴層」：神光+香火餘燼（墊遮罩之上、供桌/獎勵之下）
	_build_victory_fx()	# 凱旋 juice（最後建＝最上層繪於遮罩/供桌之上）

## 設計忠實「貴層」：鎏金氛圍層墊於全幅遮罩之上、供桌/獎勵磚之下 —
## 神光自上灑下 + 香火餘燼飄升，深化結算的儀式縱深（加性光，不蓋獎勵可讀性）。
func _build_gilded_atmosphere() -> void:
	if get_node_or_null("GildedDepthLayer") != null:
		return
	var layer: Control = GILDED_DEPTH.attach(self, GILDED_DEPTH.ACCENT_GOLD, 1.0, 12)
	if layer == null:
		return
	var mask_idx: int = _input_mask.get_index() if _input_mask != null and is_instance_valid(_input_mask) else 0
	move_child(layer, mask_idx + 1)

## 全幅深色 STOP 遮罩（dim + 擋輸入），最底繪。
func _ensure_input_mask() -> void:
	if _input_mask != null and is_instance_valid(_input_mask):
		return
	_input_mask = ColorRect.new()
	_input_mask.name = "FullInputMask"
	_input_mask.color = Color(0.06, 0.035, 0.04, 0.82)
	_input_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_input_mask)
	move_child(_input_mask, 0)
	_fit_input_mask()

func _fit_input_mask() -> void:
	if _input_mask == null or not is_instance_valid(_input_mask):
		return
	var vp := get_viewport()
	if vp == null:
		return
	var r: Rect2 = vp.get_visible_rect()
	_input_mask.global_position = r.position
	_input_mask.size = r.size

# ── 凱旋 juice（設計稿 §陸：延遲→揭示→爆發；金光芒輪 + 凱旋大字 + 金箔雨）──
func _build_victory_fx() -> void:
	if _victory_fx != null and is_instance_valid(_victory_fx):
		return
	_victory_fx = Control.new()
	_victory_fx.name = "VictoryFX"
	_victory_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE	# 不擋領賞點擊
	_victory_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_victory_fx.visible = false
	add_child(_victory_fx)
	var rays := TextureRect.new()
	rays.name = "Rays"
	rays.texture = _make_gold_burst_texture()
	rays.stretch_mode = TextureRect.STRETCH_SCALE
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays.size = Vector2(560, 300)
	_victory_fx.add_child(rays)
	var banner := Label.new()
	banner.name = "TriumphLabel"
	banner.text = tr("reward.triumph")
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 68)
	banner.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.82, 0.42)))
	banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	banner.add_theme_constant_override("shadow_offset_y", 3)
	_victory_fx.add_child(banner)
	var sub := Label.new()
	sub.name = "TriumphSub"
	sub.text = tr("reward.triumph_sub")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("ash_beige", Color(0.84, 0.77, 0.65)))
	_victory_fx.add_child(sub)
	_layout_victory_fx()

func _layout_victory_fx() -> void:
	if _victory_fx == null or not is_instance_valid(_victory_fx):
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var rays := _victory_fx.get_node_or_null("Rays") as TextureRect
	var banner := _victory_fx.get_node_or_null("TriumphLabel") as Label
	var sub := _victory_fx.get_node_or_null("TriumphSub") as Label
	if rays != null:
		rays.position = Vector2(vp.x * 0.5 - 280.0, 2.0)
	if banner != null:
		banner.position = Vector2(0, 40.0)
		banner.size = Vector2(vp.x, 84.0)
	if sub != null:
		sub.position = Vector2(0, 122.0)
		sub.size = Vector2(vp.x, 26.0)

## 戰勝放演出：顯示芒輪+凱旋字 + 灑金箔雨（程序化落片，自我清理）。
func _play_victory_juice() -> void:
	_build_victory_fx()
	_layout_victory_fx()
	_victory_fx.visible = true
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var cols: Array = [
		COTIW_UI_THEME.get_color("incense_gold", Color(0.91, 0.77, 0.42)),
		COTIW_UI_THEME.get_color("festival_red", Color(0.85, 0.29, 0.17)),
		COTIW_UI_THEME.get_color("neon_cyan", Color(0.34, 0.78, 0.83)),
	]
	for i: int in range(18):
		var flake := ColorRect.new()
		flake.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flake.size = Vector2(8.0, 12.0)
		flake.color = cols[i % cols.size()]
		flake.position = Vector2(vp.x * (float(i) + 0.5) / 18.0, -20.0)
		flake.pivot_offset = flake.size * 0.5
		_victory_fx.add_child(flake)
		var dur: float = 4.4 + float(i % 5) * 0.5
		var tw := flake.create_tween()
		tw.tween_property(flake, "position:y", vp.y + 30.0, dur)
		tw.parallel().tween_property(flake, "rotation", TAU * (1.0 if i % 2 == 0 else -1.0), dur)
		tw.tween_callback(flake.queue_free)

## 金光芒輪紋理（徑向金光，墊凱旋字後）。
func _make_gold_burst_texture() -> Texture2D:
	var gold: Color = COTIW_UI_THEME.get_color("incense_gold", Color(0.91, 0.77, 0.42))
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([
		Color(gold.r, gold.g, gold.b, 0.34), Color(gold.r, gold.g, gold.b, 0.12), Color(gold.r, gold.g, gold.b, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t

static func make_offering_table_panel(panel_size: Vector2 = Vector2(640, 360)) -> Panel:
	var table := Panel.new()
	table.name = "OfferingTablePanel"
	table.size = panel_size
	table.custom_minimum_size = panel_size
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table.set_meta("reward_language", "offering_table")
	table.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
		Color(0.10, 0.04, 0.03, 0.92),
		COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.82, 0.45)),
		20,
		3,
		0.22
	))

	var cloth := ColorRect.new()
	cloth.name = "OfferingCloth"
	cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloth.position = Vector2(18.0, 62.0)
	cloth.size = Vector2(maxf(0.0, panel_size.x - 36.0), maxf(0.0, panel_size.y - 92.0))
	cloth.color = Color(0.46, 0.04, 0.03, 0.54)
	table.add_child(cloth)

	var title := Label.new()
	title.name = "OfferingTitle"
	title.text = TranslationServer.translate("reward.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(20.0, 14.0)
	title.size = Vector2(maxf(0.0, panel_size.x - 40.0), 28.0)
	title.add_theme_font_size_override("font_size", COTIW_UI_THEME.get_typography_size("h2", 28))
	title.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color.GOLD))
	title.add_theme_color_override("font_shadow_color", COTIW_UI_THEME.get_color("text_shadow_strong", Color(0, 0, 0, 0.9)))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 2)
	table.add_child(title)

	var rule := Label.new()
	rule.name = "ChoiceRuleLabel"
	rule.text = TranslationServer.translate("reward.hint")
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule.position = Vector2(20.0, 42.0)
	rule.size = Vector2(maxf(0.0, panel_size.x - 40.0), 22.0)
	rule.add_theme_font_size_override("font_size", COTIW_UI_THEME.get_typography_size("caption", 18))
	rule.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	table.add_child(rule)

	return table

func _build_offering_table_chrome() -> void:
	if _offering_table_panel != null:
		return
	_offering_table_panel = make_offering_table_panel(panel_fill.size if panel_fill != null and panel_fill.size.x > 0 else Vector2(640, 360))
	_offering_table_panel.z_index = -1
	add_child(_offering_table_panel)
	move_child(_offering_table_panel, max(0, reward_container.get_index()))
	_sync_offering_table_layout()
	if not resized.is_connected(_sync_offering_table_layout):
		resized.connect(_sync_offering_table_layout)
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_sync_offering_table_layout):
		viewport.size_changed.connect(_sync_offering_table_layout)

func _sync_offering_table_layout() -> void:
	if _offering_table_panel == null or reward_container == null:
		return
	var margin := Vector2(26.0, 68.0)	# UIQA P2-2：標題列需 68px 頭部空間（原 42 被獎勵列壓住）
	_offering_table_panel.position = reward_container.position - margin
	_offering_table_panel.size = reward_container.size + margin * 2.0
	var cloth := _offering_table_panel.get_node_or_null("OfferingCloth") as ColorRect
	if cloth != null:
		cloth.position = Vector2(18.0, 62.0)
		cloth.size = Vector2(maxf(0.0, _offering_table_panel.size.x - 36.0), maxf(0.0, _offering_table_panel.size.y - 92.0))
	var title := _offering_table_panel.get_node_or_null("OfferingTitle") as Label
	if title != null:
		title.size.x = maxf(0.0, _offering_table_panel.size.x - 40.0)
	var rule := _offering_table_panel.get_node_or_null("ChoiceRuleLabel") as Label
	if rule != null:
		rule.size.x = maxf(0.0, _offering_table_panel.size.x - 40.0)

#region Reward Display
func populate_reward_display() -> void:
	# generate reward buttons from reward data
	clear_reward_display()
	
	for reward_group: int in reward_data.keys():
		var reward_group_data: Dictionary = reward_data[reward_group]
		
		# money reward
		var money_reward_amount: int = reward_group_data.get("reward_money")
		if money_reward_amount > 0:
			var add_money_action_data: Array[Dictionary] = [
					{
					Scripts.ACTION_ADD_MONEY: {"money_amount": money_reward_amount}
					}
				]
			
			var add_money_action: BaseAction = ActionGenerator.create_actions(null, null, [], add_money_action_data, null)[0]
			
			var money_reward_button: BaseRewardButton = Scenes.MONEY_REWARD_BUTTON.instantiate()
			money_reward_button.init(add_money_action, reward_group)
			reward_container.add_child(money_reward_button)
			# make reward group mutually exclusive
			money_reward_button.button_up.connect(_on_reward_group_selected.bind(reward_group))
		
		# card draft rewards
		var card_draft_rewards: Array[Array] = []
		card_draft_rewards.assign(reward_group_data.get("reward_card_drafts", []))
		for card_draft in card_draft_rewards:
			var draft_card_action_data: Array[Dictionary] = [
				{
				Scripts.ACTION_PICK_CARDS: {
					"card_pick_type": ActionBasePickCards.CARD_PICK_TYPES.DRAFT,
					"pick_draft_cards": true,
					"draft_cards": card_draft,
					"action_data": [{Scripts.ACTION_ADD_CARDS_TO_DECK: {}}]
					}
				}
			]
			
			var draft_card_action: BaseAction = ActionGenerator.create_actions(null, null, [], draft_card_action_data, null)[0]
			
			var card_reward_button: BaseRewardButton = Scenes.CARD_REWARD_BUTTON.instantiate()
			card_reward_button.init(draft_card_action, reward_group)
			reward_container.add_child(card_reward_button)
			# make reward group mutually exclusive
			card_reward_button.button_up.connect(_on_reward_group_selected.bind(reward_group))
		
		# artifact rewards
		var artifact_reward_ids: Array[String] = []
		artifact_reward_ids.assign(reward_group_data.get("reward_artifact_ids", []))
		
		for artifact_id in artifact_reward_ids:
			var draft_artifact_action_data: Array[Dictionary] = [
				{
				Scripts.ACTION_ADD_ARTIFACT: {
					"artifact_id": artifact_id
					}
				}
			]
			
			var draft_artifact_action: BaseAction = ActionGenerator.create_actions(null, null, [], draft_artifact_action_data, null)[0]
			
			var artifact_reward_button: BaseRewardButton = Scenes.ARTIFACT_REWARD_BUTTON.instantiate()
			artifact_reward_button.init(draft_artifact_action, reward_group)
			reward_container.add_child(artifact_reward_button)
			# make reward group mutually exclusive
			artifact_reward_button.button_up.connect(_on_reward_group_selected.bind(reward_group))

		# fu rewards（FP-3 寶箱符令；已進牌庫，資訊磚顯示「獲得符令」，非互斥）
		var reward_fu_ids: Array = []
		reward_fu_ids.assign(reward_group_data.get("reward_fu_ids", []))
		for fu_id_v in reward_fu_ids:
			reward_container.add_child(_make_fu_reward_chip(str(fu_id_v)))

	# clear reward data
	clear_rewards()
	
## FP-3 寶箱符令資訊磚（已進牌庫，純顯示「獲得符令 X」+ 效果；不互斥、無領取動作）。
func _make_fu_reward_chip(fu_id: String) -> Control:
	var d: Dictionary = FC.fu_def(fu_id)
	var root := PanelContainer.new()
	root.custom_minimum_size = Vector2(300, 92)
	root.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
		Color(0.14, 0.09, 0.06, 0.96), COTIW_UI_THEME.get_color("incense_gold", Color(0.90, 0.74, 0.40)), 0, 3, 0.0))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	root.add_child(vbox)
	var t := Label.new()
	t.text = tr("reward.fu_gained") % str(d.get("name", fu_id))
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.82, 0.42)))
	vbox.add_child(t)
	var ds := Label.new()
	ds.text = str(d.get("desc", ""))
	ds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ds.add_theme_font_size_override("font_size", 14)
	ds.add_theme_color_override("font_color", Color(0.90, 0.85, 0.74))
	vbox.add_child(ds)
	return root

func clear_reward_display() -> void:
	for child in reward_container.get_children():
		child.queue_free()
		
func _on_reward_group_selected(reward_group: int):
	# rewards groups are mutually exclusive
	for reward_button: BaseRewardButton in reward_container.get_children():
		if reward_button.reward_group != reward_group:
			reward_button.queue_free()
	
#endregion

#region Reward Data
func add_location_rewards() -> void:
	# adds rewards from the location to the end of combat rewards
	var player: Player = Global.get_player()
	# v0.3 換骨：戰鬥獎勵不再發卡牌 draft（卡牌戰鬥已退場）；符令改由 Combat 戰勝時三選一
	# draft 直接加進 run_fu_deck。此處保留香火/法器（artifact）獎勵。
	# 注意：card_drafts 須為型別化空陣列（Array[Array]），否則下游型別賦值報錯。
	var no_card_drafts: Array[Array] = []
	var action_data: Array[Dictionary] = [{
	Scripts.ACTION_GRANT_REWARDS: {
		"reward_group": 0,
		"money_amount": Random.get_location_money_reward(),
		"card_drafts": no_card_drafts,
		"artifact_ids": Random.get_location_artifact_rewards(),
		}
	}]
	var grant_reward_action: BaseAction = ActionGenerator.create_actions(player, null, [player], action_data, null)[0]
	grant_reward_action.perform_action()

func add_rewards(reward_group: int, money_amount: int, card_drafts: Array[Array], artifact_ids: Array[String], custom_action_data: Array[Array], fu_ids: Array[String] = []):
	# adds rewards which can be populated into the display

	# get existing reward data generate new reward data
	var reward_group_data: Dictionary = {}
	if reward_data.has(reward_group):
		reward_group_data = reward_data[reward_group]
	else:
		reward_group_data = {
			"reward_money": 0,
			"reward_card_drafts": [],
			"reward_artifact_ids": [],
			"reward_fu_ids": [],
			"reward_custom_action_data": [],
			}
	
	# money
	reward_group_data["reward_money"] = reward_group_data["reward_money"] + money_amount
	
	# card drafts
	var reward_card_drafts: Array = reward_group_data["reward_card_drafts"]
	reward_card_drafts.assign(card_drafts)
	reward_group_data["reward_card_drafts"] = reward_card_drafts
	
	# artifacts
	var reward_artifact_ids: Array = reward_group_data["reward_artifact_ids"]
	reward_artifact_ids.assign(artifact_ids)
	reward_group_data["reward_artifact_ids"] = reward_artifact_ids

	# fu（FP-3 寶箱符令；已進牌庫，此處顯示「獲得符令」資訊磚）
	var reward_fu_ids: Array = reward_group_data.get("reward_fu_ids", [])
	reward_fu_ids.assign(fu_ids)
	reward_group_data["reward_fu_ids"] = reward_fu_ids

	# custom actions
	var reward_custom_action_data: Array = reward_group_data["reward_custom_action_data"]
	reward_custom_action_data.assign(custom_action_data)
	reward_group_data["reward_custom_action_data"] = reward_custom_action_data
	
	# negative reward groups will assign to a new group
	var assigned_reward_group: int = reward_group
	if reward_group < 0:
		assigned_reward_group = 1
		while reward_data.has(assigned_reward_group):
			assigned_reward_group += 1
		
	# assign the data to the group	
	reward_data[assigned_reward_group] = reward_group_data

func clear_rewards(reward_group: int = -1) -> void:
	if reward_group < 0:
		reward_data.clear()	# -1 means clear all rewards
	else:
		reward_data.erase(reward_group)	# clear a specific reward group

func _on_reward_grant_requested(reward_group: int, money_amount: int, card_drafts: Array[Array], artifact_ids: Array[String], custom_action_data: Array[Array], fu_ids: Array[String] = []):
	add_rewards(reward_group, money_amount, card_drafts, artifact_ids, custom_action_data, fu_ids)

func _on_reward_clear_requested(reward_group: int):
	clear_rewards(reward_group)

#endregion

func _on_combat_started(_event_id: String):
	visible = false
	add_location_rewards()

func _on_combat_ended():
	if not Global.is_end_of_run():
		visible = true
		populate_reward_display()
		_play_victory_juice()	# 設計稿§陸 凱旋一拍爽（戰勝才放）

func _on_chest_opened():
	visible = true
	if _victory_fx != null and is_instance_valid(_victory_fx):
		_victory_fx.visible = false	# 寶箱非凱旋，不放戰勝演出
	# rewards will have been populated elsewhere, display them
	populate_reward_display()

func _on_continue_button_up():
	# increment the act and potentially generate a new one
	if Global.is_end_of_act():
		if not Global.is_end_of_run():
			ActionGenerator.generate_next_act()
	
	if not Global.is_end_of_run():
		map.show_map()
	else:
		visible = false
		Signals.run_victory.emit()

func _on_map_location_selected(_location_data: LocationData):
	visible = false

## Q2-E：獎勵畫面頂部紅綢金光 banner（儀式感錨點）。缺檔靜默跳過。
func _apply_reward_banner() -> void:
	const BANNER := "res://assets/generated/scenes_v2/reward_banner_v1.png"
	if get_node_or_null("RewardBannerArt") != null or not ResourceLoader.exists(BANNER):
		return
	var art := TextureRect.new()
	art.name = "RewardBannerArt"
	art.texture = load(BANNER)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.clip_contents = true
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate = Color(1, 1, 1, 0.92)
	art.set_anchors_preset(Control.PRESET_TOP_WIDE)
	art.offset_top = 0
	art.offset_bottom = 118
	add_child(art)
	var bg2_index: int = (get_node_or_null("Background2").get_index() + 1) if get_node_or_null("Background2") != null else 0
	move_child(art, bg2_index)	# 暗底之上、獎勵列/標題之下
