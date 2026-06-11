extends Button
class_name RestActionButton

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

var rest_action_object_id: String = ""
var excluded: bool = false # excluded buttons are disabled

@onready var panel_background: TextureRect = $PanelBackground if has_node("PanelBackground") else null

signal rest_action_button_up(button: RestActionButton)

func _ready():
	button_up.connect(_on_button_up)
	_apply_visual_style()

## UIQA P2-3：歇腳行動 icon（Recraft 民俗 SVG）；無對應 id 時不顯示（純加法）
const REST_ICON_BY_ID: Dictionary = {
	"rest_action_rest": "res://assets/generated/icons_v2/rest/icon_rest_rest.png",
	"rest_action_upgrade_card": "res://assets/generated/icons_v2/rest/icon_rest_upgrade_card.png",
	"rest_action_remove_cards": "res://assets/generated/icons_v2/rest/icon_rest_remove_cards.png",
	"rest_action_add_random_consumable": "res://assets/generated/icons_v2/rest/icon_rest_add_random_consumable.png",
	"rest_action_increase_attack_on_rest": "res://assets/generated/icons_v2/rest/icon_rest_increase_attack_on_rest.png",
}

func init(_rest_action_object_id: String) -> void:
	rest_action_object_id = _rest_action_object_id
	var rest_action_data: RestActionData = Global.get_rest_action_data(rest_action_object_id)
	text = rest_action_data.rest_action_name
	_ensure_action_icon(_rest_action_object_id)
	_apply_visual_style()

func _apply_visual_style() -> void:
	flat = true
	custom_minimum_size = Vector2(240, 180)
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	clip_text = true
	add_theme_font_size_override("font_size", 24)
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	add_theme_color_override("font_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	add_theme_color_override("font_hover_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	add_theme_color_override("font_pressed_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	add_theme_color_override("font_disabled_color", COTIW_UI_THEME.get_color("smoke_gray", Color.GRAY))
	add_theme_color_override("font_shadow_color",
		COTIW_UI_THEME.get_color("text_shadow_soft", Color(0, 0, 0, 0.65)))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	if panel_background != null:
		COTIW_UI_THEME.apply_panel_texture(panel_background, "rest")
		panel_background.modulate = Color.WHITE if not disabled else \
			COTIW_UI_THEME.get_color("disabled_tint", Color(0.6, 0.6, 0.6, 0.85))

func _on_button_up():
	rest_action_button_up.emit(self)

func validate_rest_button() -> bool:
	# returns whether the validators pass for this rest action
	# used for checking if the button should be enabled/disabled
	# this does not factor in rest action exclusivity
	if excluded:
		return false
	
	var rest_action_data: RestActionData = Global.get_rest_action_data(rest_action_object_id)
	return Global.validate(rest_action_data.rest_action_validators, null, null)


func _ensure_action_icon(rest_action_object_id: String) -> void:
	if get_node_or_null("ActionIcon") != null:
		return
	var icon_path: String = str(REST_ICON_BY_ID.get(rest_action_object_id, ""))
	if icon_path == "" or not ResourceLoader.exists(icon_path):
		return
	var ic := TextureRect.new()
	ic.name = "ActionIcon"
	ic.texture = load(icon_path)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.anchor_left = 0.5
	ic.anchor_right = 0.5
	ic.offset_left = -32.0
	ic.offset_right = 32.0
	ic.offset_top = 8.0
	ic.offset_bottom = 72.0
	add_child(ic)
