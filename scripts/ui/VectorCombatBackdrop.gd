# 鎮島錄 — 戰鬥畫面向量 chrome（疊在 BackgroundButton 場景圖之上）
#
# 比照主選單的全向量做法，但保留各章節 AI 場景圖當底（戰鬥情境需要），
# 在其上以純向量繪製 Temple Neon Pixel 框架：頂/底 HUD 漸層帶 + 金邊欞線
# + 四角暈影 + 微弱燈籠光暈。取代 Aida 的扁平 ColorRect chrome。
extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const DESIGN_W: float = 1200.0
const DESIGN_H: float = 700.0
const TOP_H := 78.0
const BOT_Y := 600.0

# 全部走 design_tokens（_ready 一次性快取；fallback 為 token 對應的近似值）
var C_GOLD: Color = Color(0.91, 0.77, 0.42)
var C_GOLD_DIM: Color = Color(0.64, 0.49, 0.16)
var C_INK: Color = Color(0.07, 0.04, 0.035)
var C_HUD_BG: Color = Color(0.11, 0.06, 0.05)        # lacquer_black
var C_LANTERN: Color = Color(1.0, 0.62, 0.26)        # warning_orange

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	C_GOLD = COTIW_UI_THEME.get_color("incense_gold", C_GOLD)
	C_GOLD_DIM = COTIW_UI_THEME.get_color("old_gold", C_GOLD_DIM)
	C_INK = COTIW_UI_THEME.get_color("night_ink", C_INK)
	C_HUD_BG = COTIW_UI_THEME.get_color("lacquer_black", C_HUD_BG)
	C_LANTERN = COTIW_UI_THEME.get_color("warning_orange", C_LANTERN)

func _p(x: float, y: float) -> Vector2:
	return Vector2(x / DESIGN_W * size.x, y / DESIGN_H * size.y)

func _sx(v: float) -> float:
	return v / DESIGN_W * size.x

func _draw() -> void:
	var w := size.x
	var h := size.y

	# --- 四角暈影（資訊聚焦中央，邊角壓暗） ---
	var vig := Color(C_INK.r, C_INK.g, C_INK.b, 0.0)
	for i in 5:
		var t := float(i) / 4.0
		var a := 0.42 * (1.0 - t)
		var inset := _sx(120.0) * t
		var col := Color(C_INK.r, C_INK.g, C_INK.b, a)
		# 上下左右各一條漸暗帶
		draw_rect(Rect2(0, 0, w, inset + _sx(10)), col)
		draw_rect(Rect2(0, h - inset - _sx(10), w, inset + _sx(10)), col)
		draw_rect(Rect2(0, 0, inset + _sx(10), h), col)
		draw_rect(Rect2(w - inset - _sx(10), 0, inset + _sx(10), h), col)

	# --- 頂部 HUD 帶（lacquer_black 漸層 + 金邊） ---
	var top_h := _sx(TOP_H)
	for i in 8:
		var tt := float(i) / 7.0
		draw_rect(Rect2(0, tt * top_h, w, top_h / 8.0 + 1.0),
			Color(C_HUD_BG.r, C_HUD_BG.g, C_HUD_BG.b, lerp(0.92, 0.30, tt)))
	draw_line(Vector2(0, top_h), Vector2(w, top_h), C_GOLD, maxf(2.0, _sx(3.0)))
	draw_line(Vector2(0, top_h + _sx(3)), Vector2(w, top_h + _sx(3)), C_GOLD_DIM, maxf(1.0, _sx(1.5)))

	# --- 底部 HUD 帶（手牌區，lacquer_black 漸層 + 金邊） ---
	var bot_y := _p(0, BOT_Y).y
	for i in 8:
		var bt := float(i) / 7.0
		draw_rect(Rect2(0, bot_y + bt * (h - bot_y), w, (h - bot_y) / 8.0 + 1.0),
			Color(C_HUD_BG.r, C_HUD_BG.g, C_HUD_BG.b, lerp(0.30, 0.95, bt)))
	draw_line(Vector2(0, bot_y), Vector2(w, bot_y), C_GOLD, maxf(2.0, _sx(3.0)))
	draw_line(Vector2(0, bot_y - _sx(3)), Vector2(w, bot_y - _sx(3)), C_GOLD_DIM, maxf(1.0, _sx(1.5)))

	# --- 戰場金邊欞框（頂帶與底帶之間） ---
	var frame := Rect2(_sx(22), top_h + _sx(14),
		w - _sx(44), bot_y - top_h - _sx(28))
	draw_rect(frame, C_GOLD_DIM, false, maxf(1.5, _sx(2.0)))
	# 四角短金線（廟門欞格意象）
	var cl := _sx(26.0)
	for c in [
		[frame.position, Vector2(1, 1)],
		[Vector2(frame.end.x, frame.position.y), Vector2(-1, 1)],
		[Vector2(frame.position.x, frame.end.y), Vector2(1, -1)],
		[frame.end, Vector2(-1, -1)],
	]:
		var o: Vector2 = c[0]
		var d: Vector2 = c[1]
		draw_line(o, o + Vector2(cl * d.x, 0), C_GOLD, maxf(1.5, _sx(2.5)))
		draw_line(o, o + Vector2(0, cl * d.y), C_GOLD, maxf(1.5, _sx(2.5)))

	# --- 頂部兩側微弱燈籠光暈（廟會氛圍，warning_orange 兩段透明度） ---
	var lantern_core := C_LANTERN.lerp(Color(1, 1, 1, 1), 0.25)
	for gx: float in [_sx(90.0), w - _sx(90.0)]:
		draw_circle(Vector2(gx, _sx(40.0)), _sx(46.0), Color(C_LANTERN.r, C_LANTERN.g, C_LANTERN.b, 0.10))
		draw_circle(Vector2(gx, _sx(40.0)), _sx(26.0), Color(lantern_core.r, lantern_core.g, lantern_core.b, 0.12))
