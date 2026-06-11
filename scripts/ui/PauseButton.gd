# UI element that pauses the game
extends TextureButton

@onready var map: Control = %Map
@onready var shop_overlay: Control = %ShopOverlay

const BACK_ICON_PATH := "res://assets/generated/icons/ui_v2/ui_back.svg"

func _ready() -> void:
	pressed.connect(_on_pause_button_pressed)

	Signals.game_paused.connect(_on_game_paused)
	Signals.game_unpaused.connect(_on_game_unpaused)

	# 用 ui_back 返回圖示取代 icon.svg placeholder，讓暫停/返回鍵清楚可見
	if ResourceLoader.exists(BACK_ICON_PATH):
		var back_icon: Texture2D = load(BACK_ICON_PATH)
		texture_normal = back_icon
		texture_hover = back_icon
		texture_pressed = back_icon
		texture_disabled = back_icon
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(80, 80)
	size = Vector2(80, 80)
	
func _on_pause_button_pressed() -> void:
	Global.pause_game()

func _on_game_paused() -> void:
	if _is_game_pausable():
		disabled = true

func _on_game_unpaused() -> void:
	disabled = false

# returns whether the pausing should be allowed to work
# NOTE: Override this to change pausing logic
func _is_game_pausable() -> bool:
	if not Global.is_run:
		return false
	if map.visible:
		return false
	return true
