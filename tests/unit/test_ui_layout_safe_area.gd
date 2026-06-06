# 鎮島錄 — UI layout / safe-area contract 測試（UIQA Phase 7）。
# 純函式（CotiwUiTheme helpers）；同步、無場景。對應 docs/design/UI_LAYOUT_SAFE_AREA_GUIDE.md。
extends "res://tests/test_case.gd"

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

# 多比例 landscape 邏輯畫布（含 tablet-ish 4:3）
const RATIO_SIZES: Dictionary = {
	"16:9": Vector2(1280, 720),
	"19.5:9": Vector2(1560, 720),
	"20:9": Vector2(1600, 720),
	"4:3": Vector2(1024, 768),
}

func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x - 0.5 \
		and inner.position.y >= outer.position.y - 0.5 \
		and inner.position.x + inner.size.x <= outer.position.x + outer.size.x + 0.5 \
		and inner.position.y + inner.size.y <= outer.position.y + outer.size.y + 0.5

# ---------- clamp 在所有比例下都把 rect 夾進 safe area ----------

func test_clamp_keeps_rect_inside_all_ratios() -> void:
	for ratio: String in RATIO_SIZES:
		var size: Vector2 = RATIO_SIZES[ratio]
		var safe: Rect2 = Rect2(Vector2(40, 24), size - Vector2(80, 48))	# 模擬瀏海/安全區內縮
		var probes: Array = [
			Rect2(Vector2(-300, -300), Vector2(900, 500)),	# 左上出界 + 過大
			Rect2(safe.position + safe.size, Vector2(600, 300)),	# 右下完全出界
			Rect2(Vector2.ZERO, size * 2.0),	# 比畫面還大
		]
		for r: Rect2 in probes:
			var c: Rect2 = COTIW_UI_THEME.clamp_rect_to_safe_area(r, safe)
			assert_true(_rect_inside(c, safe), "%s：clamp 後應落在 safe rect 內（%s）" % [ratio, str(r)])

func test_clamp_preserves_already_inside_rect() -> void:
	var safe: Rect2 = Rect2(Vector2(40, 24), Vector2(1200, 672))
	var r: Rect2 = Rect2(Vector2(100, 100), Vector2(300, 120))
	assert_eq(COTIW_UI_THEME.clamp_rect_to_safe_area(r, safe), r, "已在內的 rect 應不變")

# ---------- safe rect / stage size / typography / layer tokens ----------

func test_get_safe_content_rect_is_positive() -> void:
	var r: Rect2 = COTIW_UI_THEME.get_safe_content_rect(null)
	assert_true(r.size.x > 0.0 and r.size.y > 0.0, "safe rect 應有正尺寸（來自 Responsive autoload）")

func test_get_stage_size_is_positive() -> void:
	var s: Vector2 = COTIW_UI_THEME.get_stage_size()
	assert_true(s.x > 0.0 and s.y > 0.0, "stage size 應為正")

func test_layer_tokens_strictly_ordered() -> void:
	assert_true(COTIW_UI_THEME.LAYER_BACKGROUND < COTIW_UI_THEME.LAYER_HUD, "背景 < HUD")
	assert_true(COTIW_UI_THEME.LAYER_HUD < COTIW_UI_THEME.LAYER_OVERLAY, "HUD < overlay")
	assert_true(COTIW_UI_THEME.LAYER_OVERLAY < COTIW_UI_THEME.LAYER_TOAST, "overlay < toast")
	assert_true(COTIW_UI_THEME.LAYER_TOAST < COTIW_UI_THEME.LAYER_TOUCH_DETAIL, "toast < touch detail")

func test_typography_token_returns_positive_and_fallback() -> void:
	assert_true(COTIW_UI_THEME.get_typography_size("h1", 30) > 0, "字級 token 應為正")
	assert_eq(COTIW_UI_THEME.get_typography_size("___no_such_token___", 17), 17, "未知 token 回 fallback")
