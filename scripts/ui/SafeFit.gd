# 鎮島錄 — SafeFit：把固定 base 版面等比置中塞進安全區
#
# 用途：戰鬥/地圖/商店/選單等「以固定 1200×700 設計、不便逐一重排」的畫面，
# 整體等比縮放並置中到 Responsive.safe_rect，避開瀏海/底部手勢區，
# 且不破壞其內部相對版面（鐵律 3 友善：不動 STR scene 內部結構）。
#
# 周圍露出的區域由各畫面的全螢幕底色（如 TitleScreen/Background）填滿。
extends RefCounted
class_name SafeFit

const DESIGN := Vector2(1200, 700)

## 立即把 target 依安全區置中縮放一次
static func fit(target: Control, base: Vector2 = DESIGN) -> void:
	if not is_instance_valid(target):
		return
	var f: float = Responsive.fit_scale(base)
	var sr: Rect2 = Responsive.safe_rect
	target.pivot_offset = Vector2.ZERO
	target.scale = Vector2(f, f)
	target.position = sr.position + (sr.size - base * f) * 0.5

## fit 一次並訂閱 Responsive.changed 自動重算（給長生命週期畫面）
static func bind(target: Control, base: Vector2 = DESIGN) -> void:
	if not is_instance_valid(target):
		return
	fit(target, base)
	var cb := func() -> void:
		if is_instance_valid(target):
			fit(target, base)
	if not Responsive.changed.is_connected(cb):
		Responsive.changed.connect(cb)
