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
		
		### populate shop cards
		var shop_cards: Array[CardData] = shop_data.shop_cards
		for card_data in shop_cards:
			# create card button asset
			var card_shop_button: BaseShopButton = Scenes.CARD_SHOP_BUTTON.instantiate()
			card_container.add_child(card_shop_button)
			
			# generate action payload
			var card_price: int = shop_data.get_shop_card_price(card_data)
			
			var purchase_card_action_data: Array[Dictionary] = [
				{
				Scripts.ACTION_SHOP_PURCHASE_ITEMS: {
					"card_data": card_data,
					"money_amount": card_price,
					}
				}
			]
			
			var purchase_card_action: BaseAction = ActionGenerator.create_actions(null, null, [], purchase_card_action_data, null)[0]
			
			# initialize button with payload
			card_shop_button.init(purchase_card_action)
		
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
