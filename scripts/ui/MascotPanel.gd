# 鎮島錄 — 看板娘 (mascot) v2
# 主畫面偏左：sky 天空背景 + 角色高解析半身像 + 極微 idle 呼吸動畫。
# 不再 frame cycling（避免「過動」），讓畫面寧靜。
extends Control
class_name MascotPanel

# v2 高解析半身素材（256×384 PixFlux × 4 nearest upscale = 1024×1536）
const BUST_DIR: String = "res://assets/generated/pixellab/"
const SKY_PATH: String = "res://assets/generated/pixellab/mascot_sky_bg.png"

const ACTOR_TO_BUST: Dictionary = {
	"character_tongji": "mascot_tongji_bust_v2.png",
	"character_luannu": "mascot_luannu_bust_v2.png",
}

# 極微 idle 呼吸（不再 bobbing — 過動傾向）
const BREATH_FREQ: float = 0.4          # Hz，慢呼吸
const BREATH_AMP: float = 0.008         # ±0.8% scale，幾乎不察覺

signal mascot_tapped()

var _sky_rect: TextureRect              # 天空背景層
var _bust_rect: TextureRect             # 角色半身像
var _name_label: Label
var _button: Button

var _idle_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true   # 限制 sky 不擴出 MascotPanel 邊界

	# 天空：背後層
	_sky_rect = TextureRect.new()
	_sky_rect.name = "SkyBackdrop"
	_sky_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sky_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_sky_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(SKY_PATH):
		_sky_rect.texture = load(SKY_PATH)
	add_child(_sky_rect)

	# 角色半身像（前景）
	_bust_rect = TextureRect.new()
	_bust_rect.name = "MascotBust"
	_bust_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bust_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bust_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bust_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bust_rect)

	# 透明 Button 接點擊
	_button = Button.new()
	_button.name = "MascotButton"
	_button.flat = true
	_button.focus_mode = Control.FOCUS_NONE
	_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_button.self_modulate = Color(1, 1, 1, 0)
	_button.button_up.connect(_on_button_up)
	add_child(_button)

	# 名稱標籤
	_name_label = Label.new()
	_name_label.name = "MascotName"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 32)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.62))
	_name_label.add_theme_constant_override("shadow_offset_x", 2)
	_name_label.add_theme_constant_override("shadow_offset_y", 2)
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	refresh_mascot()
	if Global.has_signal("mascot_changed") and not Global.mascot_changed.is_connected(_on_mascot_changed):
		Global.mascot_changed.connect(_on_mascot_changed)

func _process(delta: float) -> void:
	# 同步 child layout 給 parent size
	if _sky_rect != null:
		_sky_rect.size = size
		_sky_rect.position = Vector2.ZERO
	if _bust_rect != null:
		_bust_rect.size = size
		_bust_rect.pivot_offset = size * 0.5
	if _button != null:
		_button.size = size
		_button.position = Vector2.ZERO
	if _name_label != null:
		var lh: float = 44.0
		_name_label.size = Vector2(size.x, lh)
		_name_label.position = Vector2(0, size.y - lh - 8)

	# 極微 idle 呼吸（只 scale，不 bobbing 不切幀）
	_idle_time += delta
	var breath: float = 1.0 + sin(_idle_time * BREATH_FREQ * TAU) * BREATH_AMP
	if _bust_rect != null:
		_bust_rect.scale = Vector2(breath, breath)

func refresh_mascot() -> void:
	var id: String = Global.get_mascot_character_id()
	_load_bust_for_id(id)
	_name_label.text = _display_name_for_id(id)

func _on_mascot_changed(_character_id: String) -> void:
	refresh_mascot()

func _on_button_up() -> void:
	mascot_tapped.emit()

func _load_bust_for_id(actor_id: String) -> void:
	var filename: String = ACTOR_TO_BUST.get(actor_id, "")
	if filename.is_empty():
		_bust_rect.texture = null
		push_warning("[MascotPanel] no bust for id " + actor_id)
		return
	var p: String = BUST_DIR + filename
	if not ResourceLoader.exists(p):
		_bust_rect.texture = null
		push_warning("[MascotPanel] bust file missing: " + p)
		return
	_bust_rect.texture = load(p)

func _display_name_for_id(actor_id: String) -> String:
	var character_data = Global.get_character_data(actor_id) if Global.has_method("get_character_data") else null
	if character_data != null and "character_name" in character_data:
		return character_data.character_name
	const FALLBACK := {
		"character_tongji": "乩童",
		"character_luannu": "鸞女",
	}
	return FALLBACK.get(actor_id, actor_id)
