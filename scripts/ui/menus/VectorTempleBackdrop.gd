# 鎮島錄 — 全向量主畫面背景（程序化繪製，無 PNG 依賴）
#
# 用 _draw() 以多邊形 / 線 / 漸層純向量重現「廟宇 lobby」氛圍：
# 朱紅漸層牆、屋簷、雙朱柱（金龍紋線稿）、中央神龕（神像剪影 + 供桌 + 燭火 +
# 香爐）、垂吊燈籠（暖光呼吸）、右側龍雲線稿牆、石獅剪影。
# 設計座標固定 1200×700，靠 Godot stretch(canvas_items/keep) 自動縮放。
extends Control

const DESIGN_W: float = 1200.0
const DESIGN_H: float = 700.0

# 廟會配色
const C_WALL_TOP := Color(0.56, 0.10, 0.10)      # 朱紅（上）
const C_WALL_BOT := Color(0.10, 0.045, 0.05)     # 暗（下）
const C_GOLD := Color(0.85, 0.69, 0.36)
const C_GOLD_DIM := Color(0.55, 0.43, 0.20)
const C_PILLAR := Color(0.62, 0.13, 0.12)
const C_PILLAR_SHADE := Color(0.40, 0.08, 0.08)
const C_WOOD := Color(0.28, 0.13, 0.10)
const C_ALCOVE := Color(0.10, 0.06, 0.09)
const C_LANTERN := Color(1.0, 0.62, 0.26)
const C_LANTERN_CORE := Color(1.0, 0.86, 0.55)

var _glow: float = 0.0          # 燈籠呼吸 0..1
var _grad_tex: GradientTexture2D

func _ready() -> void:
	# size 由建立者（MainMenu._add_backdrop）以 offset 設為設計尺寸 1200×700
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grad_tex = GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, C_WALL_TOP)
	g.set_color(1, C_WALL_BOT)
	g.add_point(0.45, Color(0.34, 0.08, 0.09))
	_grad_tex.gradient = g
	_grad_tex.fill_from = Vector2(0.5, 0.0)
	_grad_tex.fill_to = Vector2(0.5, 1.0)
	_grad_tex.width = 16
	_grad_tex.height = 256

func _process(delta: float) -> void:
	_glow = wrapf(_glow + delta * 0.9, 0.0, TAU)
	queue_redraw()

# 將設計座標 (0..1200,0..700) 換成實際畫布座標
func _p(x: float, y: float) -> Vector2:
	return Vector2(x / DESIGN_W * size.x, y / DESIGN_H * size.y)

func _sx(v: float) -> float:
	return v / DESIGN_W * size.x

func _draw() -> void:
	# --- 背景漸層牆 ---
	draw_texture_rect(_grad_tex, Rect2(Vector2.ZERO, size), false)

	# --- 右側龍雲線稿牆（低 alpha 裝飾） ---
	_draw_filigree()

	# --- 屋簷 ---
	_draw_eave()

	# --- 中央神龕 ---
	_draw_shrine()

	# --- 雙朱柱 + 金龍 ---
	_draw_pillar(150.0)
	_draw_pillar(560.0)

	# --- 石獅 ---
	_draw_foo_lion(120.0)
	_draw_foo_lion(590.0)

	# --- 垂吊燈籠 ---
	var lantern_xs: Array[float] = [95.0, 250.0, 360.0, 470.0, 600.0, 690.0]
	var lantern_ys: Array[float] = [150.0, 110.0, 175.0, 120.0, 165.0, 130.0]
	for i in lantern_xs.size():
		_draw_lantern(lantern_xs[i], lantern_ys[i], 0.45 + 0.12 * sin(_glow + i))

	# --- 底部地板暗帶 ---
	draw_rect(Rect2(_p(0, 610), Vector2(size.x, _sx(90))), Color(0.07, 0.035, 0.04, 0.85))

func _draw_eave() -> void:
	var pts := PackedVector2Array([
		_p(40, 30), _p(680, 30), _p(620, 95), _p(100, 95)
	])
	draw_colored_polygon(pts, C_WOOD)
	draw_polyline(PackedVector2Array([_p(40, 30), _p(680, 30)]), C_GOLD, _sx(4.0))
	draw_polyline(PackedVector2Array([_p(100, 95), _p(620, 95)]), C_GOLD_DIM, _sx(2.5))
	# 簷下椽木
	for i in 11:
		var x := 130.0 + i * 44.0
		draw_line(_p(x, 95), _p(x + 8, 30), C_GOLD_DIM, _sx(2.0))
	# 中央寶珠
	var c := _p(360, 24)
	draw_circle(c, _sx(15.0), C_GOLD)
	draw_circle(c, _sx(9.0), Color(1, 0.85, 0.5))

func _draw_pillar(x: float) -> void:
	var top := 95.0
	var bot := 620.0
	var w := 46.0
	# 柱身
	draw_rect(Rect2(_p(x, top), Vector2(_sx(w), _sx(bot - top))), C_PILLAR)
	draw_rect(Rect2(_p(x + w * 0.62, top), Vector2(_sx(w * 0.38), _sx(bot - top))), C_PILLAR_SHADE)
	# 柱頭 / 柱礎
	draw_rect(Rect2(_p(x - 8, top), Vector2(_sx(w + 16), _sx(20))), C_GOLD_DIM)
	draw_rect(Rect2(_p(x - 10, bot - 26), Vector2(_sx(w + 20), _sx(26))), Color(0.32, 0.30, 0.30))
	# 盤龍金線（沿柱身的螺旋）
	var spiral := PackedVector2Array()
	var seg := 26
	for i in seg + 1:
		var t := float(i) / seg
		var yy := top + 40.0 + t * (bot - top - 80.0)
		var xx := x + w * 0.5 + sin(t * TAU * 3.0) * (w * 0.42)
		spiral.append(_p(xx, yy))
	draw_polyline(spiral, C_GOLD, _sx(3.0))

func _draw_shrine() -> void:
	# 神龕外金框
	var ox := 250.0
	var oy := 150.0
	var ow := 220.0
	var oh := 360.0
	draw_rect(Rect2(_p(ox - 14, oy - 14), Vector2(_sx(ow + 28), _sx(oh + 28))), C_GOLD_DIM)
	draw_rect(Rect2(_p(ox - 8, oy - 8), Vector2(_sx(ow + 16), _sx(oh + 16))), C_GOLD)
	draw_rect(Rect2(_p(ox, oy), Vector2(_sx(ow), _sx(oh))), C_ALCOVE)
	# 神像剪影（簡化幾何）
	var cx := ox + ow * 0.5
	draw_circle(_p(cx, oy + 70), _sx(34.0), Color(0.30, 0.20, 0.16))      # 頭/光輪
	draw_circle(_p(cx, oy + 70), _sx(26.0), Color(0.42, 0.28, 0.20))
	var body := PackedVector2Array([
		_p(cx - 60, oy + 250), _p(cx - 42, oy + 96),
		_p(cx + 42, oy + 96), _p(cx + 60, oy + 250)
	])
	draw_colored_polygon(body, Color(0.34, 0.18, 0.16))
	# 供桌
	draw_rect(Rect2(_p(ox + 8, oy + 250), Vector2(_sx(ow - 16), _sx(70))), Color(0.50, 0.11, 0.11))
	draw_rect(Rect2(_p(ox + 8, oy + 250), Vector2(_sx(ow - 16), _sx(10))), C_GOLD_DIM)
	# 香爐
	var bx := cx
	draw_rect(Rect2(_p(bx - 26, oy + 215), Vector2(_sx(52), _sx(34))), Color(0.40, 0.34, 0.22))
	draw_line(_p(bx - 30, oy + 215), _p(bx + 30, oy + 215), C_GOLD, _sx(3.0))
	# 三炷燭火 + 微光
	for dx: float in [-40.0, 0.0, 40.0]:
		var fx: float = cx + dx
		var fy: float = oy + 205.0
		var flame := PackedVector2Array([
			_p(fx - 5, fy), _p(fx, fy - 22), _p(fx + 5, fy)
		])
		draw_colored_polygon(flame, Color(1.0, 0.78, 0.40, 0.95))
		draw_circle(_p(fx, fy - 10), _sx(11.0), Color(1.0, 0.72, 0.35, 0.18 + 0.06 * sin(_glow * 2.0)))

func _draw_lantern(x: float, y: float, glow_a: float) -> void:
	var c := _p(x, y)
	var r := _sx(26.0)
	# 吊線
	draw_line(_p(x, y - 70), c - Vector2(0, r), C_GOLD_DIM, _sx(2.0))
	# 外暈
	draw_circle(c, r * 2.0, Color(C_LANTERN.r, C_LANTERN.g, C_LANTERN.b, glow_a * 0.35))
	draw_circle(c, r * 1.35, Color(C_LANTERN.r, C_LANTERN.g, C_LANTERN.b, glow_a * 0.5))
	# 燈體
	draw_circle(c, r, C_LANTERN)
	draw_circle(c, r * 0.62, C_LANTERN_CORE)
	# 上下蓋
	draw_rect(Rect2(c + Vector2(-r * 0.45, -r - _sx(7)), Vector2(r * 0.9, _sx(7))), C_GOLD_DIM)
	draw_rect(Rect2(c + Vector2(-r * 0.45, r), Vector2(r * 0.9, _sx(6))), C_GOLD_DIM)
	# 流蘇
	draw_line(c + Vector2(0, r + _sx(6)), c + Vector2(0, r + _sx(22)), Color(0.80, 0.20, 0.16), _sx(3.0))

func _draw_foo_lion(x: float) -> void:
	var base := 590.0
	var col := Color(0.46, 0.42, 0.34)
	var body := PackedVector2Array([
		_p(x, base), _p(x, base - 46), _p(x + 14, base - 60),
		_p(x + 34, base - 58), _p(x + 40, base - 30), _p(x + 40, base)
	])
	draw_colored_polygon(body, col)
	draw_circle(_p(x + 27, base - 62), _sx(11.0), col)
	draw_rect(Rect2(_p(x - 6, base), Vector2(_sx(52), _sx(12))), Color(0.34, 0.31, 0.26))

func _draw_filigree() -> void:
	# 右側龍雲線稿（低 alpha，純裝飾）
	var col := Color(C_GOLD.r, C_GOLD.g, C_GOLD.b, 0.16)
	for k in 3:
		var ox := 760.0 + k * 130.0
		var oy := 130.0 + k * 150.0
		var curve := PackedVector2Array()
		for i in 33:
			var t := float(i) / 32.0
			var xx := ox + sin(t * TAU * 1.5) * 70.0
			var yy := oy + t * 320.0
			curve.append(_p(xx, yy))
		draw_polyline(curve, col, _sx(2.5))
	# 雲渦
	for cloud: Array in [[900.0, 240.0], [1050.0, 430.0], [980.0, 600.0]]:
		var cx: float = cloud[0]
		var cy: float = cloud[1]
		var cc := PackedVector2Array()
		for i in 26:
			var a := float(i) / 25.0 * TAU
			var rr := 34.0 + 10.0 * sin(a * 3.0)
			cc.append(_p(cx + cos(a) * rr, cy + sin(a) * rr * 0.6))
		draw_polyline(cc, col, _sx(2.0))
