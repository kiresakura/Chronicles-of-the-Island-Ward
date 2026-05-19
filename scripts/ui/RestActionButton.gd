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

func init(_rest_action_object_id: String) -> void:
	rest_action_object_id = _rest_action_object_id
	var rest_action_data: RestActionData = Global.get_rest_action_data(rest_action_object_id)
	text = rest_action_data.rest_action_name
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
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	if panel_background != null:
		COTIW_UI_THEME.apply_panel_texture(panel_background, "rest")
		panel_background.modulate = Color.WHITE if not disabled else Color(0.6, 0.6, 0.6, 0.85)

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
