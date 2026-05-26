# 鎮島錄 — 看板娘 (mascot) 面板
# 主畫面偏左側顯示玩家選定角色的 PixelLab 去背全身 pixel 動畫條（idle 4 幀循環）。
# 像素全身像 + 透明背景 + idle 動畫，點擊開 MascotSelector 切換角色。
extends Control
class_name MascotPanel

# PixelLab anim 條目錄
const ANIM_DIR: String = "res://assets/generated/pixellab/anim/"
const ANIM_FRAME_COUNT: int = 4
const ANIM_IDLE_FPS: float = 4.0

# 細微 idle 動畫參數（疊在 frame cycling 之上的呼吸 / bobbing）
const BREATH_FREQ: float = 1.2          # Hz
const BREATH_AMP: float = 0.02          # ±2% scale 振幅
const BOB_FREQ: float = 0.6             # Hz
const BOB_AMP_PX: float = 8.0           # 上下浮動振幅（pixel）

signal mascot_tapped()

var _texture_rect: TextureRect
var _name_label: Label
var _button: Button

var _anim_frames: Array[Texture2D] = []
var _anim_frame_idx: int = 0
var _anim_time: float = 0.0  # frame cycling 累計
var _idle_time: float = 0.0  # 呼吸 / bob 累計

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 像素 sprite — 維持原始像素風（不要 LANCZOS 模糊化）
	_texture_rect = TextureRect.new()
	_texture_rect.name = "MascotSprite"
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 保留像素感
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texture_rect)

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
	_name_label.add_theme_font_size_override("font_size", 28)
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
	# 同步 child 給 parent size
	if _texture_rect != null:
		_texture_rect.size = size
		_texture_rect.pivot_offset = size * 0.5
	if _button != null:
		_button.size = size
	if _name_label != null:
		var lh: float = 36.0
		_name_label.size = Vector2(size.x, lh)
		_name_label.position = Vector2(0, size.y - lh - 4)

	# 細微 idle 動畫（疊在 anim cycling 之上）
	_idle_time += delta
	var breath: float = 1.0 + sin(_idle_time * BREATH_FREQ * TAU) * BREATH_AMP
	var bob: float = sin(_idle_time * BOB_FREQ * TAU) * BOB_AMP_PX
	if _texture_rect != null:
		_texture_rect.scale = Vector2(breath, breath)
		_texture_rect.position = Vector2(0, bob)

	# PixelLab anim frame cycling
	if _anim_frames.is_empty():
		return
	_anim_time += delta
	var step: float = 1.0 / ANIM_IDLE_FPS
	if _anim_time < step:
		return
	_anim_time -= step
	_anim_frame_idx = (_anim_frame_idx + 1) % _anim_frames.size()
	_texture_rect.texture = _anim_frames[_anim_frame_idx]

func refresh_mascot() -> void:
	var id: String = Global.get_mascot_character_id()
	_load_anim_for_id(id)
	_name_label.text = _display_name_for_id(id)

func _on_mascot_changed(_character_id: String) -> void:
	refresh_mascot()

func _on_button_up() -> void:
	mascot_tapped.emit()

func _load_anim_for_id(actor_id: String) -> void:
	_anim_frames.clear()
	_anim_frame_idx = 0
	_anim_time = 0.0
	var sheet_path: String = ANIM_DIR + actor_id + "/idle.png"
	if not ResourceLoader.exists(sheet_path):
		_texture_rect.texture = null
		push_warning("[MascotPanel] anim sheet not found: " + sheet_path)
		return
	var sheet: Texture2D = load(sheet_path)
	if sheet == null:
		return
	var frame_w: int = int(sheet.get_width() / ANIM_FRAME_COUNT)
	var frame_h: int = sheet.get_height()
	for i in ANIM_FRAME_COUNT:
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		_anim_frames.append(at)
	_texture_rect.texture = _anim_frames[0]

func _display_name_for_id(actor_id: String) -> String:
	var character_data = Global.get_character_data(actor_id) if Global.has_method("get_character_data") else null
	if character_data != null and "character_name" in character_data:
		return character_data.character_name
	const FALLBACK := {
		"character_tongji": "乩童",
		"character_luannu": "鸞女",
	}
	return FALLBACK.get(actor_id, actor_id)
