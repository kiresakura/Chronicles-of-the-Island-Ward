# 鎮島錄 — 鎏金氛圍層（設計忠實「貴層」）。
#
# 神光自上灑下（天井/匾額而下）+ 香火餘燼飄升 + 壇底暖暈三件套，
# 純程序化 GradientTexture2D + tween，不依任何素材、不依 shader。
# 「加性混色（BLEND_MODE_ADD）只添光、不模糊底」→ gl_compatibility 安全、
# 不傷像素字可讀性（底圖照常清晰繪製，本層僅在其上疊加光暈）。
# 設計動機：WorldEnvironment glow 在 gl_compatibility 2D 無效，且切渲染器會危及
# iOS build；故以渲染器安全的程序化光層交付同一視覺目標（premium 縱深輝光）。
#
# 用法：GildedDepthLayer.attach(host_control, accent_color, intensity, embers)
# 全程 mouse 穿透；建議掛在背景之上、UI 之下（餘燼飄在面板後，不擋字）。
extends Control

const ACCENT_GOLD := Color(0.91, 0.77, 0.42)	# 燙金（incense_gold 對齊值）

var _accent: Color = ACCENT_GOLD
var _intensity: float = 1.0
var _ember_count: int = 10
var _rng := RandomNumberGenerator.new()
var _add_mat: CanvasItemMaterial

## 建層並掛上 host（回傳該層；冪等由呼叫端以節點名把關）。
static func attach(host: Control, accent: Color = ACCENT_GOLD, intensity: float = 1.0, embers: int = 10) -> Control:
	if host == null:
		return null
	var layer: Control = (load("res://scripts/ui/fx/GildedDepthLayer.gd") as GDScript).new()
	layer.name = "GildedDepthLayer"
	layer.set("_accent", accent)
	layer.set("_intensity", clampf(intensity, 0.0, 2.0))
	layer.set("_ember_count", maxi(0, embers))
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(layer)
	return layer

func _ready() -> void:
	_rng.randomize()
	_add_mat = CanvasItemMaterial.new()
	_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_top_light()
	_build_bottom_haze()
	for i in _ember_count:
		_spawn_ember(i)

## 視口尺寸（本層未排版完成前以視口為退路；resized 後 redraw 修正）。
func _vp() -> Vector2:
	return size if size.x > 1.0 else get_viewport_rect().size

## 徑向金暈紋理（中心亮 → 透明邊）。core_a＝中心 alpha。
func _radial_tex(core_a: float) -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([
		Color(_accent.r, _accent.g, _accent.b, core_a),
		Color(_accent.r, _accent.g, _accent.b, core_a * 0.35),
		Color(_accent.r, _accent.g, _accent.b, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t

## 神光：上緣中央寬橢圓金暈（光自天井/匾額而下），緩慢呼吸。
func _build_top_light() -> void:
	var light := TextureRect.new()
	light.name = "TopLight"
	light.texture = _radial_tex(0.5)
	light.material = _add_mat
	light.stretch_mode = TextureRect.STRETCH_SCALE
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(light)
	var redraw := func() -> void:
		var vp: Vector2 = _vp()
		var w: float = vp.x * 1.10
		var h: float = vp.y * 0.70
		light.size = Vector2(w, h)
		light.position = Vector2((vp.x - w) * 0.5, -h * 0.42)
	redraw.call()
	resized.connect(redraw)
	light.modulate = Color(1, 1, 1, 0.14 * _intensity)
	var tw := create_tween().set_loops()
	tw.tween_property(light, "modulate:a", 0.20 * _intensity, 2.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(light, "modulate:a", 0.12 * _intensity, 2.6).set_trans(Tween.TRANS_SINE)

## 壇底暖暈：底部偏暖橙的縱向漸層（母壇/香爐餘溫上浮）。
func _build_bottom_haze() -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 1.0])
	g.colors = PackedColorArray([
		Color(_accent.r, _accent.g, _accent.b, 0.0),
		Color(_accent.r * 0.95, _accent.g * 0.62, _accent.b * 0.42, 0.10 * _intensity)])	# 暖橙
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_LINEAR
	t.fill_from = Vector2(0.5, 0.0)
	t.fill_to = Vector2(0.5, 1.0)
	t.width = 8
	t.height = 64
	var haze := TextureRect.new()
	haze.name = "BottomHaze"
	haze.texture = t
	haze.material = _add_mat
	haze.stretch_mode = TextureRect.STRETCH_SCALE
	haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(haze)
	var redraw := func() -> void:
		var vp: Vector2 = _vp()
		haze.size = Vector2(vp.x, vp.y * 0.28)
		haze.position = Vector2(0, vp.y * 0.72)
	redraw.call()
	resized.connect(redraw)

## 香火餘燼：小金點自下緣飄升、左右輕擺、淡入淡出 → 抵頂自我重生（永動氛圍）。
func _spawn_ember(idx: int) -> void:
	var e := TextureRect.new()
	e.name = "Ember%d" % idx
	e.texture = _radial_tex(0.7)
	e.material = _add_mat
	e.stretch_mode = TextureRect.STRETCH_SCALE
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sz: float = _rng.randf_range(5.0, 12.0)
	e.size = Vector2(sz, sz)
	e.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
	e.modulate = Color(1, 1, 1, 0.0)
	add_child(e)
	_animate_ember(e)

func _animate_ember(e: TextureRect) -> void:
	if not is_instance_valid(e):
		return
	var vp: Vector2 = _vp()
	var x0: float = _rng.randf_range(vp.x * 0.06, vp.x * 0.94)
	var y0: float = vp.y * 0.96 + _rng.randf_range(0.0, vp.y * 0.12)
	var rise: float = _rng.randf_range(vp.y * 0.45, vp.y * 0.80)
	var dur: float = _rng.randf_range(5.5, 9.5)
	var sway: float = _rng.randf_range(-28.0, 28.0)
	var peak_a: float = _rng.randf_range(0.35, 0.70) * _intensity
	e.position = Vector2(x0, y0)
	e.modulate = Color(1, 1, 1, 0.0)
	var mv := create_tween()
	mv.set_parallel(true)
	mv.tween_property(e, "position:y", y0 - rise, dur).set_trans(Tween.TRANS_SINE)
	mv.tween_property(e, "position:x", x0 + sway, dur).set_trans(Tween.TRANS_SINE)
	var fade := create_tween()
	fade.tween_property(e, "modulate:a", peak_a, dur * 0.30)
	fade.tween_interval(dur * 0.30)
	fade.tween_property(e, "modulate:a", 0.0, dur * 0.40)
	fade.tween_callback(func() -> void: _animate_ember(e))
