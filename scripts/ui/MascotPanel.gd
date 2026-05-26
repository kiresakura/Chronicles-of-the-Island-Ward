# 鎮島錄 — 看板娘 (mascot) v3
# 全螢幕半身像：bust 由螢幕高度撐滿，底部接觸畫面下緣（不被 slot bar
# 阻斷），無內建背景（PIL 已去白底成透明）。主畫面廟宇 + 既有天空 bg
# 在 mascot 後方自然透出。
extends Control
class_name MascotPanel

## v5：改用 Recraft SVG vector 動漫立繪（無解析度上限 + 真透明）
## 取代 v4 pixel art bust。SVG 由 Godot 自動 import 為 Texture2D。
const BUST_DIR: String = "res://assets/generated/characters_svg/"
const ACTOR_TO_BUST: Dictionary = {
	"character_tongji": "tongji_v3.svg",
	"character_luannu": "luannu_v3.svg",
}
# 舊 pixel bust fallback（萬一 SVG 載失敗）
const PIXEL_BUST_DIR: String = "res://assets/generated/pixellab/"
const PIXEL_BUST_FALLBACK: Dictionary = {
	"character_tongji": "mascot_tongji_bust_v2.png",
	"character_luannu": "mascot_luannu_bust_v2.png",
}

# 極微 idle 呼吸（不過動）
const BREATH_FREQ: float = 0.4
const BREATH_AMP: float = 0.008

# 半身像在 MascotPanel 內水平位移百分比（負值往左、正值往右）
# 0.0 = 正中，-0.20 = 偏左 20%
const HORIZONTAL_BIAS: float = -0.18
# 垂直高度倍率：放大角色讓下半身超出螢幕底（user spec）
# 1.0 = 全身剛好；1.4 = 下半身約 40% 在螢幕外
const HEIGHT_OVERSCAN: float = 1.4
# Y 偏移：正值往下，讓頭頂留更多上方空間
const VERTICAL_BIAS: float = 0.08

signal mascot_tapped()
signal mascot_change_requested()  # 長按或專屬切換 button 才開 selector

var _bust_rect: TextureRect
var _button: Button
var _dialog_label: Label
var _dialog_panel: Panel
var _idle_time: float = 0.0
var _bounce_tween: Tween = null
var _dialog_tween: Tween = null

# 隨機台詞（依角色不同）— v6 改用 i18n keys → tr() 解析
# 對應 assets/translations/cotiw_main.csv 中 mascot.<id>.qN
const QUOTE_KEYS: Dictionary = {
	"character_tongji": [
		"mascot.tongji.q1", "mascot.tongji.q2", "mascot.tongji.q3",
		"mascot.tongji.q4", "mascot.tongji.q5",
	],
	"character_luannu": [
		"mascot.luannu.q1", "mascot.luannu.q2", "mascot.luannu.q3",
		"mascot.luannu.q4", "mascot.luannu.q5",
	],
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # 容器透明擋

	# 半身像 — 由 _process 動態定位，這裡只設模式
	_bust_rect = TextureRect.new()
	_bust_rect.name = "MascotBust"
	_bust_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bust_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# SVG vector 用 LINEAR 平滑，PNG pixel 用 NEAREST。SVG 自動高品質渲染
	_bust_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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

	# 對話泡（_dialog_panel 含背景 + _dialog_label 文字），預設隱藏
	_build_dialog_bubble()

	refresh_mascot()
	_apply_ambient_tint()
	if Global.has_signal("mascot_changed") and not Global.mascot_changed.is_connected(_on_mascot_changed):
		Global.mascot_changed.connect(_on_mascot_changed)

func _process(delta: float) -> void:
	if _bust_rect == null or _bust_rect.texture == null:
		return

	# 半身像由高度 ×HEIGHT_OVERSCAN 撐起，底邊對齊 MascotPanel 底邊，
	# 超出部分延伸到螢幕外（避免「腰斬」感）。
	# bust 圖已 PIL auto-crop 過，character 100% 填滿圖；fit-by-height 後角色
	# 底剛好碰螢幕底；再加 overscan 讓角色身體繼續延伸超出底邊。
	var tex_size: Vector2 = _bust_rect.texture.get_size()
	if tex_size.y <= 0:
		return
	var aspect: float = tex_size.x / tex_size.y
	var dst_h: float = size.y * HEIGHT_OVERSCAN
	var dst_w: float = dst_h * aspect
	# 水平：以 HORIZONTAL_BIAS 偏移
	var center_x: float = size.x * 0.5 + size.x * HORIZONTAL_BIAS
	var dst_x: float = center_x - dst_w * 0.5
	# 垂直：底邊對齊 MascotPanel 底邊 + VERTICAL_BIAS 往下推
	# 結果：character 上半身置中偏下、下半身超出螢幕底（user spec：下半身遮住）
	var dst_y: float = size.y - dst_h + size.y * VERTICAL_BIAS
	_bust_rect.position = Vector2(dst_x, dst_y)
	_bust_rect.size = Vector2(dst_w, dst_h)
	_bust_rect.pivot_offset = Vector2(dst_w * 0.5, dst_h)   # 以底中為支點

	# Button hit-area 跟 bust 同步
	if _button != null:
		_button.position = _bust_rect.position
		_button.size = _bust_rect.size

	# 極微呼吸（在 bounce tween 進行時不疊加，避免衝突）
	_idle_time += delta
	if _bounce_tween == null or not _bounce_tween.is_running():
		var breath: float = 1.0 + sin(_idle_time * BREATH_FREQ * TAU) * BREATH_AMP
		_bust_rect.scale = Vector2(breath, breath)

	# 對話泡：浮在 character 頭頂附近右側
	if _dialog_panel != null and _dialog_panel.visible:
		var bubble_w: float = clamp(size.x * 0.30, 280.0, 460.0)
		var bubble_h: float = 76.0
		# 位置：bust 上半部右側，避免擋臉
		var bx: float = dst_x + dst_w * 0.55
		var by: float = dst_y + dst_h * 0.10
		_dialog_panel.position = Vector2(bx, by)
		_dialog_panel.size = Vector2(bubble_w, bubble_h)
		if _dialog_label != null:
			_dialog_label.size = _dialog_panel.size
			_dialog_label.position = Vector2.ZERO

## 依系統時間給 mascot 加 ambient tint（光照融合）
func _apply_ambient_tint() -> void:
	if _bust_rect == null:
		return
	var hour: int = Time.get_time_dict_from_system().get("hour", 12)
	var tint: Color
	if hour >= 5 and hour < 17:
		tint = Color(1.0, 1.0, 1.0)              # day：自然白
	elif hour >= 17 and hour < 19:
		tint = Color(1.08, 0.92, 0.78)           # dusk：暖橘黃
	else:
		tint = Color(0.78, 0.85, 1.05)           # night：冷藍
	_bust_rect.modulate = tint

func refresh_mascot() -> void:
	var id: String = Global.get_mascot_character_id()
	var svg_name: String = ACTOR_TO_BUST.get(id, "")
	# 優先 SVG vector
	if not svg_name.is_empty():
		var svg_path: String = BUST_DIR + svg_name
		if ResourceLoader.exists(svg_path):
			_bust_rect.texture = load(svg_path)
			return
	# fallback pixel bust
	var pixel_name: String = PIXEL_BUST_FALLBACK.get(id, "")
	if not pixel_name.is_empty():
		var pixel_path: String = PIXEL_BUST_DIR + pixel_name
		if ResourceLoader.exists(pixel_path):
			_bust_rect.texture = load(pixel_path)
			push_warning("[MascotPanel] using pixel fallback for " + id)
			return
	_bust_rect.texture = null
	push_warning("[MascotPanel] no bust for " + id)

func _on_mascot_changed(_character_id: String) -> void:
	refresh_mascot()

func _on_button_up() -> void:
	mascot_tapped.emit()
	_play_tap_reaction()

## tap 反應：彈跳 tween + 對話泡（隨機台詞）
func _play_tap_reaction() -> void:
	_bounce_bust()
	_show_random_dialog()

## 彈跳：scale up 1.1× → 回 1.0
func _bounce_bust() -> void:
	if _bust_rect == null:
		return
	if _bounce_tween != null and _bounce_tween.is_valid():
		_bounce_tween.kill()
	_bounce_tween = create_tween()
	_bounce_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bounce_tween.tween_property(_bust_rect, "scale", Vector2(1.06, 1.06), 0.15)
	_bounce_tween.tween_property(_bust_rect, "scale", Vector2(1.0, 1.0), 0.25)

## 對話泡 fade-in / hold / fade-out
func _show_random_dialog() -> void:
	if _dialog_panel == null or _dialog_label == null:
		return
	var id: String = Global.get_mascot_character_id()
	var keys: Array = QUOTE_KEYS.get(id, [])
	if keys.is_empty():
		_dialog_label.text = "..."
	else:
		var k: String = keys[randi() % keys.size()]
		_dialog_label.text = tr(k)   # i18n: 自動依 locale 解析
	if _dialog_tween != null and _dialog_tween.is_valid():
		_dialog_tween.kill()
	_dialog_panel.modulate = Color(1, 1, 1, 0)
	_dialog_panel.visible = true
	_dialog_tween = create_tween()
	_dialog_tween.tween_property(_dialog_panel, "modulate:a", 1.0, 0.2)
	_dialog_tween.tween_interval(2.2)
	_dialog_tween.tween_property(_dialog_panel, "modulate:a", 0.0, 0.5)
	_dialog_tween.tween_callback(func(): _dialog_panel.visible = false)

func _build_dialog_bubble() -> void:
	_dialog_panel = Panel.new()
	_dialog_panel.name = "DialogPanel"
	_dialog_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialog_panel.visible = false
	# StyleBox：金邊紙底
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.05, 0.04, 0.92)
	sb.border_color = Color(0.95, 0.82, 0.45)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 6
	_dialog_panel.add_theme_stylebox_override("panel", sb)
	add_child(_dialog_panel)

	_dialog_label = Label.new()
	_dialog_label.name = "DialogLabel"
	_dialog_label.add_theme_font_size_override("font_size", 22)
	_dialog_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.62))
	_dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialog_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialog_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialog_panel.add_child(_dialog_label)
