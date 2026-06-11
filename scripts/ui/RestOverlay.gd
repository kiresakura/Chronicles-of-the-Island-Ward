# Overlay for actions at a rest site
extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

@onready var rest_action_container: GridContainer = $ScrollContainer/MarginContainer/RestActionContainer
@onready var continue_button: Button = $ContinueButton
@onready var backdrop: ColorRect = $Background

@onready var map = $%Map

func _ready():
	Signals.combat_started.connect(_on_combat_started)
	_apply_scene_chrome()	# Q2-E 場景錨點

	Signals.map_location_selected.connect(_on_map_location_selected)
	continue_button.button_up.connect(_on_continue_button_up)
	COTIW_UI_THEME.apply_primary_button_style(continue_button)
	COTIW_UI_THEME.style_overlay_backdrop(backdrop)

func _on_map_location_selected(_location_data: LocationData):
	if _location_data.location_type == LocationData.LOCATION_TYPES.REST_SITE:
		visible = true
		populate_rest_actions()
	else:
		visible = false
		clear_rest_actions()

func populate_rest_actions() -> void:
	clear_rest_actions()
	_ensure_rest_title()
	
	# get the rest actions the player can perform
	var player_rest_action_object_ids: Array[String] = Global.player_data.player_available_rest_action_object_ids
	for rest_action_object_id in player_rest_action_object_ids:
		var rest_action_data: RestActionData = Global.get_rest_action_data(rest_action_object_id)
		if rest_action_data != null:
			var rest_action_button: RestActionButton = Scenes.REST_ACTION_BUTTON.instantiate()
			rest_action_container.add_child(rest_action_button)
			rest_action_button.init(rest_action_object_id)
			rest_action_button.rest_action_button_up.connect(_on_rest_action_button_up)
			rest_action_button.disabled = not rest_action_button.validate_rest_button()

func _on_rest_action_button_up(rest_action_button: RestActionButton):
	# perform actions
	var rest_action_data: RestActionData = Global.get_rest_action_data(rest_action_button.rest_action_object_id)
	if rest_action_data != null:
		var action_data: Array[Dictionary] = rest_action_data.rest_actions
		var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(null, null, [], action_data, null)
		ActionHandler.add_actions(generated_actions, false)
	
		# disable buttons based on pressed button's exclusivity
		var rest_action_cost_type: int = rest_action_data.rest_action_cost_type
		
		if rest_action_cost_type == RestActionData.REST_ACTION_COST_TYPES.INCLUSIVE:
			# disable non repeatable free buttons after single use
			rest_action_button.excluded = true
		if rest_action_cost_type == RestActionData.REST_ACTION_COST_TYPES.EXCLUSIVE:
			# disable all exclusive buttons if action taken exclusive
			for other_button: RestActionButton in rest_action_container.get_children():
				var other_button_rest_action_data: RestActionData = Global.get_rest_action_data(other_button.rest_action_object_id)
				if other_button_rest_action_data.rest_action_cost_type == RestActionData.REST_ACTION_COST_TYPES.EXCLUSIVE:
					other_button.excluded = true
	
	# re-validate all rest buttons
	for button: RestActionButton in rest_action_container.get_children():
		button.disabled = not button.validate_rest_button()

func clear_rest_actions():
	for child in rest_action_container.get_children():
		child.queue_free()

func _on_combat_started(_event_id: String):
	visible = false
	clear_rest_actions()

func _on_continue_button_up():
	if not Global.is_end_of_run():
		map.can_travel = true
		map.show_map()
	else:
		visible = false
		Signals.run_victory.emit()


## UIQA P3：歇腳畫面補標題（與其他 overlay 標題慣例一致）
func _ensure_rest_title() -> void:
	if get_node_or_null("RestTitle") != null:
		return
	var title := Label.new()
	title.name = "RestTitle"
	title.text = tr("run.rest_action")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(300.0, 36.0)
	title.size = Vector2(600.0, 44.0)
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.93, 0.62))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

## Q2-E 美術密度：場景錨點底圖（入廟安神）。COVERED 全出血、置於遮罩上內容下；
## 缺檔靜默跳過（佔位回退）。暗角壓字保可讀。
func _apply_scene_chrome() -> void:
	const SCENE_BG := "res://assets/generated/scenes_v2/rest_hall_bg_v1.png"
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
	vignette.color = Color(0.05, 0.03, 0.03, 0.38)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.add_to_group("fullbleed_mask")
	add_child(vignette)
	move_child(vignette, bg_index + 1)
