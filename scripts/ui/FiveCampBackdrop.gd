extends Control
class_name FiveCampBackdrop

# 鎮島錄 v0.3 — 五營戰鬥程序化背景（零素材依賴，純 _draw）。
# 畫「五營羅盤」：母壇為心的同心金環 + 四方煞道輻條 + 八卦對角細線。
# 目的（UIUX §C ruler 7/9）：① 補足文化母題（羅盤/八卦）② 用空間把「煞順道而下 →
# 該營當道攔截 → 護住母壇」畫出來，讓新手 5 秒讀懂十字盤面。
# 掛在 _stage 最底（節點之下）；座標為 1200×700 設計座標，隨 _stage 一起 fit 縮放。

const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

var altar_center: Vector2 = Vector2(490.0, 318.0)	# 母壇中心（設計座標）
var lane_reach: float = 300.0						# 輻條長度（母壇 → 煞道）

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var gold: Color = THEME.get_color("incense_gold", Color(0.93, 0.78, 0.42))
	var c: Vector2 = altar_center
	# 八卦對角細線（最弱，墊底氛圍）
	for d: Vector2 in [Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)]:
		draw_line(c, c + d.normalized() * (lane_reach - 40.0), Color(gold.r, gold.g, gold.b, 0.045), 1.0, true)
	# 同心金環（由內而外漸淡）
	for i: int in range(1, 5):
		var r: float = 64.0 + float(i) * 50.0
		draw_arc(c, r, 0.0, TAU, 72, Color(gold.r, gold.g, gold.b, 0.10 - float(i) * 0.017), 2.0, true)
	# 四方煞道輻條（母壇 → 北/南/西/東）：盤面骨架，明於對角線
	for d: Vector2 in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
		draw_line(c, c + d * lane_reach, Color(gold.r, gold.g, gold.b, 0.13), 2.0, true)
	# 母壇內芯小環（聖域感）
	draw_arc(c, 42.0, 0.0, TAU, 48, Color(gold.r, gold.g, gold.b, 0.16), 2.0, true)
