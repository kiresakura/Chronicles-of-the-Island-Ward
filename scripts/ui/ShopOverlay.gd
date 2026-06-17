# Overlay for a shop
extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

# NPC 報價台詞池 — 隨機挑一條顯示於頂部資訊欄
const _NPC_QUOTES: Array[String] = [
	"shop.slogan1",
	"shop.slogan2",
	"shop.slogan3",
	"shop.slogan4",
]

@onready var card_container: HBoxContainer = $CardContainer
@onready var artifact_container: VBoxContainer = $ArtifactContainer
@onready var consumable_container: VBoxContainer = $ConsumableContainer

@onready var continue_button: Button = $ContinueButton
@onready var backdrop: ColorRect = $Background
@onready var panel_fill: ColorRect = $Background2
@onready var npc_info_bar: Label = %NPCInfoBar

@onready var map = $%Map

func _ready():
	Signals.combat_started.connect(_on_combat_started)
	_apply_scene_chrome()	# Q2-E 場景錨點

	Signals.map_location_selected.connect(_on_map_location_selected)
	Signals.shop_opened.connect(_on_shop_opened)

	Signals.card_purchased.connect(_on_card_purchased)
	Signals.fu_purchased.connect(_on_fu_purchased)
	Signals.artifact_purchased.connect(_on_artifact_purchased)
	Signals.consumable_purchased.connect(_on_consumable_purchased)

	# 隨機 NPC 報價台詞
	npc_info_bar.text = tr(_NPC_QUOTES[randi() % _NPC_QUOTES.size()])

	continue_button.text = tr("ui.leave")
	continue_button.button_up.connect(_on_continue_button_up)
	COTIW_UI_THEME.apply_primary_button_style(continue_button)
	COTIW_UI_THEME.style_overlay_backdrop(backdrop, panel_fill)

func populate_shop() -> void:
	clear_shop()
	
	var shop_data: ShopData = Global.get_shop_at_player_location()
	if shop_data == null:
		shop_data = Global.generate_shop_at_player_location()

	if shop_data != null:
		shop_data.visit_shop()	# ensure the shop is populated
		
		### populate shop fu（FP-3 符令版商店：戰鬥已用符令，商店改賣符；卡牌只留 meta 圖鑑）
		for fu_id_v in shop_data.shop_fu:
			card_container.add_child(_make_fu_shop_button(shop_data, str(fu_id_v)))
		
		### populate shop artifacts
		var shop_artifacts: Array[ArtifactData] = shop_data.get_shop_artifact_options()
		for artifact_data in shop_artifacts:
			# create artifact button asset
			var artifact_shop_button: BaseShopButton = Scenes.ARTIFACT_SHOP_BUTTON.instantiate()
			artifact_container.add_child(artifact_shop_button)
			
			# generate action payload
			var artifact_id: String = artifact_data.object_id
			var artifact_price: int = shop_data.get_shop_artifact_price(artifact_id)
			
			var purchase_artifact_action_data: Array[Dictionary] = [
				{
				Scripts.ACTION_SHOP_PURCHASE_ITEMS: {
					"artifact_id": artifact_id,
					"money_amount": artifact_price,
					}
				}
			]
			
			var purchase_artifact_action: BaseAction = ActionGenerator.create_actions(null, null, [], purchase_artifact_action_data, null)[0]
			
			# initialize button with payload
			artifact_shop_button.init(purchase_artifact_action)
		
		### populate shop consumables
		for consumable_slot_index in shop_data.shop_consumable_slot_to_consumable_object_id.keys():
			# create consumable button asset
			var consumable_shop_button: BaseShopButton = Scenes.CONSUMABLE_SHOP_BUTTON.instantiate()
			consumable_container.add_child(consumable_shop_button)
			
			# generate action payload
			var consumable_object_id: String = shop_data.shop_consumable_slot_to_consumable_object_id[consumable_slot_index]
			var consumable_price: int = shop_data.get_shop_consumable_price(consumable_slot_index)
			
			var purchase_consumable_action_data: Array[Dictionary] = [
				{
				Scripts.ACTION_SHOP_PURCHASE_ITEMS: {
					"consumable_object_id": consumable_object_id,
					"consumable_slot_index": consumable_slot_index,
					"money_amount": consumable_price,
					}
				}
			]
			
			var purchase_consumable_action: BaseAction = ActionGenerator.create_actions(null, null, [], purchase_consumable_action_data, null)[0]
			
			# initialize button with payload
			consumable_shop_button.init(purchase_consumable_action)
		

func clear_shop():
	for child in card_container.get_children():
		child.queue_free()
	for child in artifact_container.get_children():
		child.queue_free()
	for child in consumable_container.get_children():
		child.queue_free()

func _on_combat_started(_event_id: String):
	visible = false
	clear_shop()

func _on_shop_opened():
	visible = true
	populate_shop()

func _on_card_purchased(_card_data: CardData):
	_repopulate_shop_after_actions_ended()

func _on_fu_purchased(_fu_id: String):
	_repopulate_shop_after_actions_ended()

## FP-3 符令商店磚（程序化；Button 根 + 全幅內容 vbox；名/稀有星/述/價；點擊走購買 action）。
func _make_fu_shop_button(shop_data: ShopData, fu_id: String) -> Control:
	var fc := preload("res://scripts/systems/ritual/FormationCombat.gd")
	var d: Dictionary = fc.fu_def(fu_id)
	var price: int = shop_data.get_shop_fu_price(fu_id)
	var affordable: bool = Global.player_data.player_money >= price
	var rarity: String = str(d.get("rarity", "common"))
	var col: Color = COTIW_UI_THEME.get_color("incense_gold", Color(0.85, 0.72, 0.42))
	if rarity == "rare":
		col = COTIW_UI_THEME.get_color("festival_red", Color(0.90, 0.40, 0.28))
	elif rarity == "uncommon":
		col = COTIW_UI_THEME.get_color("spirit_jade", Color(0.42, 0.80, 0.60))
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(176, 232)
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = not affordable
	btn.clip_text = true
	var rim: Color = col if affordable else Color(0.40, 0.36, 0.30)
	var sb := COTIW_UI_THEME.make_stylebox(Color(0.13, 0.08, 0.06, 0.96), rim, 0, 3, 0.0)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", COTIW_UI_THEME.make_stylebox(Color(0.17, 0.10, 0.07, 0.98), rim, 0, 3, 0.0))
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("disabled", COTIW_UI_THEME.make_stylebox(Color(0.10, 0.07, 0.06, 0.92), Color(0.40, 0.36, 0.30), 0, 2, 0.0))
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)
	vbox.add_child(_fu_shop_label(str(d.get("name", fu_id)), 19, col if affordable else Color(0.62, 0.58, 0.52)))
	vbox.add_child(_fu_shop_label("★".repeat(3 if rarity == "rare" else (2 if rarity == "uncommon" else 1)), 13, col))
	var desc := _fu_shop_label(str(d.get("desc", "")), 13, Color(0.90, 0.85, 0.74))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(150, 78)
	vbox.add_child(desc)
	var price_col: Color = COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.80, 0.42)) if affordable else COTIW_UI_THEME.get_color("warning_orange", Color(0.92, 0.52, 0.20))
	vbox.add_child(_fu_shop_label("%d %s" % [price, tr("currency.silver")], 16, price_col))
	btn.button_up.connect(func() -> void:
		var pd: Array[Dictionary] = [{Scripts.ACTION_SHOP_PURCHASE_ITEMS: {"fu_id": fu_id, "money_amount": price}}]
		ActionHandler.add_action(ActionGenerator.create_actions(null, null, [], pd, null)[0]))
	return btn

func _fu_shop_label(text_value: String, fsize: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text_value
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	return l

func _on_artifact_purchased(_artifact_data: ArtifactData):
	_repopulate_shop_after_actions_ended()

func _on_consumable_purchased(_consumable_object_id: String):
	_repopulate_shop_after_actions_ended()

func _repopulate_shop_after_actions_ended() -> void:
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	populate_shop()

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

## Q2-E 美術密度：場景錨點底圖（夜市香鋪）。COVERED 全出血、置於遮罩上內容下；
## 缺檔靜默跳過（佔位回退）。暗角壓字保可讀。
func _apply_scene_chrome() -> void:
	const SCENE_BG := "res://assets/generated/scenes_v2/shop_market_bg_v1.png"
	if get_node_or_null("SceneChromeBg") != null or not ResourceLoader.exists(SCENE_BG):
		return
	var bg := TextureRect.new()
	bg.name = "SceneChromeBg"
	bg.texture = load(SCENE_BG)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.add_to_group("fullbleed_mask")
	add_child(bg)
	var bg_index: int = 1 if get_node_or_null("Background") != null else 0
	move_child(bg, bg_index)	# 遮罩之上、內容之下
	var vignette := ColorRect.new()
	vignette.name = "SceneChromeVignette"
	vignette.color = Color(0.05, 0.03, 0.03, 0.42)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.add_to_group("fullbleed_mask")
	add_child(vignette)
	move_child(vignette, bg_index + 1)
