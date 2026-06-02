extends TextureButton
class_name MapLocation

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const TOUCH_FEEDBACK := preload("res://scripts/ui/theme/TouchFeedback.gd")

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
	button_down.connect(func(): TOUCH_FEEDBACK.apply_state(self, TOUCH_FEEDBACK.TouchState.PRESSED))

func init(_location_data: LocationData, _is_reachable: bool = false, _is_current: bool = false, _is_travel_mode: bool = false):
	location_data = _location_data
	is_reachable = _is_reachable
	is_current = _is_current
	is_travel_mode = _is_travel_mode
	position = location_data.location_position
	disabled = is_travel_mode and not is_reachable
	
	if location_data.location_obfuscated and not location_data.location_visited:
		map_label.text = "???"
	else:
		map_label.text = COTIW_UI_THEME.get_location_short_label(location_data.location_type)
	
	_apply_visual_state()
	TOUCH_FEEDBACK.install_long_press_detail(self, {
		"type": "map_location",
		"label": map_label.text,
		"reachable": is_reachable,
		"current": is_current,
		"travel_mode": is_travel_mode,
	})

func flash_location() -> void:
	animation_player.play("flash_map_location")

func get_anchor_position() -> Vector2:
	return position + size * 0.5

func _apply_visual_state() -> void:
	COTIW_UI_THEME.style_map_node(
		self,
		location_data.location_type,
		map_label,
		state_glow,
		is_reachable,
		is_current,
		is_travel_mode,
		location_data.location_visited
	)

	# icon 才是主角，文字只是輔助節奏提示；因此 label 故意退一階，不跟圖示搶戲。
	map_label.modulate = Color(1.0, 1.0, 1.0, 0.96 if is_current else (0.88 if is_reachable else 0.72))

	if is_current:
		TOUCH_FEEDBACK.apply_state(self, TOUCH_FEEDBACK.TouchState.SELECTED)
	elif is_reachable:
		TOUCH_FEEDBACK.apply_state(self, TOUCH_FEEDBACK.TouchState.SELECTED)
	elif is_travel_mode:
		TOUCH_FEEDBACK.apply_state(self, TOUCH_FEEDBACK.TouchState.DISABLED)

func _on_button_up():
	location_data.location_visited = true
	map_location_button_up.emit(self)
