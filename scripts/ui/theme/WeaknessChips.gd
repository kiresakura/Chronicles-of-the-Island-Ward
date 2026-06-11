# 鎮島錄 Q1-E — 六道儀法弱點璽印章（DELEGATION §5 Q1「弱點 icon 化」）。
# 程序化「印章」語彙：暗紅圓璽 + 金邊 + 反白儀法單字（拳/符/火/鈴/陣/咒）。
# 零外部素材依賴 → 線寬/亮度/底框天生一致（QA 第 5 優先）；24px 視覺、行動端可辨。
# 純靜態建構器：Enemy 煞盾 UI 與任何需要儀法標示處共用。
class_name WeaknessChips
extends Object

const CHIP_SIZE := 26.0
const CHIP_BG := Color(0.38, 0.08, 0.07, 0.95)
const CHIP_BORDER := Color(0.95, 0.78, 0.32, 0.95)
const CHIP_TEXT := Color(1.0, 0.93, 0.78)

## 由儀法標籤陣列建一排璽印章（HBoxContainer）。未知標籤自動略過。
static func make(tags: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "WeaknessChips"
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for t: Variant in tags:
		var glyph: String = str(RitualTags.DISPLAY.get(str(t), ""))
		if glyph == "":
			continue
		row.add_child(_make_chip(glyph))
	return row

static func _make_chip(glyph: String) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(CHIP_SIZE, CHIP_SIZE)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = CHIP_BG
	sb.border_color = CHIP_BORDER
	sb.set_border_width_all(2)
	var r: int = int(CHIP_SIZE * 0.5)
	sb.corner_radius_top_left = r
	sb.corner_radius_top_right = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	chip.add_theme_stylebox_override("panel", sb)
	var label := Label.new()
	label.text = glyph
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", CHIP_TEXT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)
	return chip
