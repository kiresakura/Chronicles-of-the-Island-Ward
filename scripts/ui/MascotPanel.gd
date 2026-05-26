# 鎮島錄 — 看板娘 (mascot) v3
# 全螢幕半身像：bust 由螢幕高度撐滿，底部接觸畫面下緣（不被 slot bar
# 阻斷），無內建背景（PIL 已去白底成透明）。主畫面廟宇 + 既有天空 bg
# 在 mascot 後方自然透出。
extends Control
class_name MascotPanel

const BUST_DIR: String = "res://assets/generated/pixellab/"
const ACTOR_TO_BUST: Dictionary = {
	"character_tongji": "mascot_tongji_bust_v2.png",
	"character_luannu": "mascot_luannu_bust_v2.png",
}

# 極微 idle 呼吸（不過動）
const BREATH_FREQ: float = 0.4
const BREATH_AMP: float = 0.008

# 半身像在 MascotPanel 內水平位移百分比（負值往左、正值往右）
# 0.0 = 正中，-0.20 = 偏左 20%
const HORIZONTAL_BIAS: float = -0.18

signal mascot_tapped()

var _bust_rect: TextureRect
var _button: Button
var _idle_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # 容器透明擋

	# 半身像 — 由 _process 動態定位，這裡只設模式
	_bust_rect = TextureRect.new()
	_bust_rect.name = "MascotBust"
	_bust_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bust_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bust_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bust_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bust_rect)

	# 透明 Button 蓋在 bust 上接點擊（不擋下層 UI，因為僅覆蓋 bust 範圍）
	_button = Button.new()
	_button.name = "MascotButton"
	_button.flat = true
	_button.focus_mode = Control.FOCUS_NONE
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.self_modulate = Color(1, 1, 1, 0)
	_button.button_up.connect(_on_button_up)
	add_child(_button)

	refresh_mascot()
	if Global.has_signal("mascot_changed") and not Global.mascot_changed.is_connected(_on_mascot_changed):
		Global.mascot_changed.connect(_on_mascot_changed)

func _process(delta: float) -> void:
	if _bust_rect == null or _bust_rect.texture == null:
		return

	# 半身像由高度撐滿（aspect 2:3），底邊對齊 MascotPanel 底邊
	var tex_size: Vector2 = _bust_rect.texture.get_size()
	if tex_size.y <= 0:
		return
	var aspect: float = tex_size.x / tex_size.y
	var dst_h: float = size.y
	var dst_w: float = dst_h * aspect
	# 水平：以 HORIZONTAL_BIAS 偏移
	var center_x: float = size.x * 0.5 + size.x * HORIZONTAL_BIAS
	var dst_x: float = center_x - dst_w * 0.5
	# 垂直：底邊對齊 MascotPanel 底邊（character 站到畫面底）
	var dst_y: float = size.y - dst_h
	_bust_rect.position = Vector2(dst_x, dst_y)
	_bust_rect.size = Vector2(dst_w, dst_h)
	_bust_rect.pivot_offset = Vector2(dst_w * 0.5, dst_h)   # 以底中為支點

	# Button hit-area 跟 bust 同步
	if _button != null:
		_button.position = _bust_rect.position
		_button.size = _bust_rect.size

	# 極微呼吸
	_idle_time += delta
	var breath: float = 1.0 + sin(_idle_time * BREATH_FREQ * TAU) * BREATH_AMP
	_bust_rect.scale = Vector2(breath, breath)

func refresh_mascot() -> void:
	var id: String = Global.get_mascot_character_id()
	var filename: String = ACTOR_TO_BUST.get(id, "")
	if filename.is_empty():
		_bust_rect.texture = null
		return
	var p: String = BUST_DIR + filename
	if not ResourceLoader.exists(p):
		_bust_rect.texture = null
		push_warning("[MascotPanel] bust missing: " + p)
		return
	_bust_rect.texture = load(p)

func _on_mascot_changed(_character_id: String) -> void:
	refresh_mascot()

func _on_button_up() -> void:
	mascot_tapped.emit()
