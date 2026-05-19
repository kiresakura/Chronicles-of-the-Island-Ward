extends TextureButton
class_name MapLocation

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

var location_data: LocationData = null
var is_reachable: bool = false
var is_current: bool = false
var is_travel_mode: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var map_label: Label = $MapLabel
@onready var state_glow: ColorRect = $StateGlow

signal map_location_button_up(map_location: MapLocation)

func _ready():
	button_up.connect(_on_button_up)

func init(_location_data: LocationData, _is_reachable: bool = false, _is_current: bool = false, _is_travel_mode: bool = false):
	location_data = _location_data
	is_reachable = _is_reachable
	is_current = _is_current
	is_travel_mode = _is_travel_mode
	position = location_data.location_position
	texture_normal = load(COTIW_UI_THEME.get_map_node_path(location_data.location_type))
	texture_hover = texture_normal
	texture_pressed = texture_normal
	texture_disabled = texture_normal
	ignore_texture_size = false
	disabled = is_travel_mode and not is_reachable
	
	if location_data.location_obfuscated and not location_data.location_visited:
		map_label.text = "???"
	else:
		map_label.text = COTIW_UI_THEME.get_location_short_label(location_data.location_type)
	
	_apply_visual_state()

func flash_location() -> void:
	animation_player.play("flash_map_location")

func _apply_visual_state() -> void:
	var gold: Color = COTIW_UI_THEME.get_color("incense_gold", Color.GOLD)
	var cyan: Color = COTIW_UI_THEME.get_color("neon_cyan", Color.DEEP_SKY_BLUE)
	var paper: Color = COTIW_UI_THEME.get_color("paper_warm", Color.WHITE)
	var smoke: Color = COTIW_UI_THEME.get_color("smoke_gray", Color.GRAY)
	
	state_glow.visible = false
	state_glow.color = Color.TRANSPARENT
	scale = Vector2.ONE
	self_modulate = Color.WHITE
	map_label.add_theme_color_override("font_color", paper)
	
	if is_current:
		state_glow.visible = true
		state_glow.color = gold
		scale = Vector2.ONE * 1.08
		map_label.add_theme_color_override("font_color", gold)
	elif is_reachable:
		state_glow.visible = true
		state_glow.color = cyan
		scale = Vector2.ONE * 1.03
		map_label.add_theme_color_override("font_color", cyan.lightened(0.1))
	elif location_data.location_visited:
		self_modulate = Color(0.92, 0.88, 0.8, 1.0)
		map_label.add_theme_color_override("font_color", paper)
	elif is_travel_mode:
		self_modulate = Color(0.48, 0.48, 0.48, 0.82)
		map_label.add_theme_color_override("font_color", smoke)

func _on_button_up():
	location_data.location_visited = true
	map_location_button_up.emit(self)
