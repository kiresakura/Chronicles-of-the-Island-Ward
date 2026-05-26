# 鎮島錄 — 看板娘 (mascot) 面板
# 顯示玩家選定的角色 Recraft anime 立繪在 MainMenu 中央。
# 受眾為「二次元」玩家 → 用 characters_v2/<actor>_anim_idle.png 動漫立繪
# 而非 pixellab 像素小圖。加細微呼吸 + bobbing 動畫，靜態立繪也活起來。
# 點擊開 MascotSelector 切換角色。
extends Control
class_name MascotPanel

# Recraft anime 動漫立繪根目錄
const CHARS_V2_DIR: String = "res://assets/generated/characters_v2/"

# actor_id → characters_v2 檔名 base
const ACTOR_TO_FILE: Dictionary = {
	"character_tongji": "tongji",
	"character_luannu": "luannu",
}

# 細微 idle 動畫參數
const BREATH_FREQ: float = 1.2          # Hz，呼吸頻率
const BREATH_AMP: float = 0.015         # scale 振幅 (±1.5%)
const BOB_FREQ: float = 0.6             # Hz，上下浮動
const BOB_AMP_PX: float = 6.0           # 上下浮動振幅（pixel）

signal mascot_tapped()

var _texture_rect: TextureRect
var _name_label: Label
var _button: Button

var _time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # 容器本身不擋事件；交給內部 Button
	pivot_offset = size * 0.5  # 縮放以中心為支點

	# 立繪
	_texture_rect = TextureRect.new()
	_texture_rect.name = "MascotSprite"
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texture_rect)

	# 透明 Button 在貼圖之上接點擊
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
	_name_label.add_theme_font_size_override("font_size", 26)
	_name_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.62))
	_name_label.add_theme_constant_override("shadow_offset_x", 2)
	_name_label.add_theme_constant_override("shadow_offset_y", 2)
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	refresh_mascot()
	if Global.has_signal("mascot_changed") and not Global.mascot_changed.is_connected(_on_mascot_changed):
		Global.mascot_changed.connect(_on_mascot_changed)

func _process(delta: float) -> void:
	_time += delta
	# bobbing：垂直偏移 TextureRect（不動 MascotPanel.position，避開 parent layout 衝突）
	var bob: float = sin(_time * BOB_FREQ * TAU) * BOB_AMP_PX
	# 呼吸：scale TextureRect（pivot 設中心）
	var breath: float = 1.0 + sin(_time * BREATH_FREQ * TAU) * BREATH_AMP

	if _texture_rect != null:
		_texture_rect.size = size
		_texture_rect.pivot_offset = size * 0.5
		_texture_rect.scale = Vector2(breath, breath)
		_texture_rect.position = Vector2(0, bob)
	if _button != null:
		_button.size = size
		_button.position = Vector2.ZERO
	if _name_label != null:
		var lh: float = 36.0
		_name_label.size = Vector2(size.x, lh)
		_name_label.position = Vector2(0, size.y - lh - 4)

func refresh_mascot() -> void:
	var id: String = Global.get_mascot_character_id()
	var base_name: String = ACTOR_TO_FILE.get(id, "")
	if base_name.is_empty():
		_texture_rect.texture = null
		_name_label.text = ""
		print("[MascotPanel] no anime art for id ", id)
		return
	# 優先載 idle 立繪，沒有就用 card 後備
	var paths: Array[String] = [
		CHARS_V2_DIR + base_name + "_anim_idle.png",
		CHARS_V2_DIR + base_name + "_standee.png",
		CHARS_V2_DIR + base_name + "_card.png",
	]
	for p in paths:
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p)
			if tex != null:
				_texture_rect.texture = tex
				print("[MascotPanel] loaded ", p)
				break
	_name_label.text = _display_name_for_id(id)

func _on_mascot_changed(_character_id: String) -> void:
	refresh_mascot()

func _on_button_up() -> void:
	mascot_tapped.emit()

func _display_name_for_id(actor_id: String) -> String:
	var character_data = Global.get_character_data(actor_id) if Global.has_method("get_character_data") else null
	if character_data != null and "character_name" in character_data:
		return character_data.character_name
	const FALLBACK := {
		"character_tongji": "乩童",
		"character_luannu": "鸞女",
	}
	return FALLBACK.get(actor_id, actor_id)
