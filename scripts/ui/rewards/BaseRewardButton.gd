extends Button
class_name BaseRewardButton

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

var action_on_click: BaseAction = null
var reward_group: int = 0

@onready var panel_background: TextureRect = $PanelBackground if has_node("PanelBackground") else null

func _ready():
	button_up.connect(_on_button_up)
	_apply_visual_style()

func init(_action_on_click: BaseAction, _reward_group: int) -> void:
	action_on_click = _action_on_click
	reward_group = _reward_group
	_apply_visual_style()

func _apply_visual_style() -> void:
	flat = true
	custom_minimum_size = Vector2(320, 112)
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	clip_text = true
	expand_icon = true
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_font_size_override("font_size", 24)
	add_theme_constant_override("h_separation", 16)
	add_theme_constant_override("icon_max_width", 40)
	add_theme_color_override("font_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	add_theme_color_override("font_hover_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	add_theme_color_override("font_pressed_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	add_theme_color_override("font_disabled_color", COTIW_UI_THEME.get_color("smoke_gray", Color.GRAY))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	if panel_background != null:
		COTIW_UI_THEME.apply_panel_texture(panel_background, "reward")
		panel_background.modulate = Color.WHITE if not disabled else Color(0.6, 0.6, 0.6, 0.85)

func _on_button_up():
	if action_on_click != null:
		ActionHandler.add_action(action_on_click)
	queue_free()
