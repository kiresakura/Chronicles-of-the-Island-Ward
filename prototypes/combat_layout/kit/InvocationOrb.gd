class_name CmbInvocationOrb
extends VBoxContainer
## 請神寶珠（方向 A）：側欄神明 gauge。Phase A 用占位方塊代圓形立繪（圓珠 art 留 Phase B）。
## 滿槽時珠子發金光 → 提示可降乩（C 立繪 cut-in 由外部觸發）。
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

var _orb_box: StyleBoxFlat
var _gauge: CmbResourceBar

func setup(deity: String, cur: float, mx: float) -> CmbInvocationOrb:
	add_theme_constant_override("separation", THEME.get_spacing("sm", 12))
	alignment = BoxContainer.ALIGNMENT_CENTER
	# 寶珠占位（Phase B 換圓形神明立繪）
	var orb := Panel.new()
	orb.custom_minimum_size = Vector2(108, 108)
	orb.size_flags_horizontal = SIZE_SHRINK_CENTER
	_orb_box = THEME.make_stylebox(THEME.get_color("lacquer_black"), THEME.get_color("hot_gold"), 0, 3, 0.0)
	orb.add_theme_stylebox_override("panel", _orb_box)
	var ol := Label.new()
	ol.text = "寶珠"
	ol.add_theme_color_override("font_color", THEME.get_color("smoke_gray"))
	ol.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
	ol.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	orb.add_child(ol)
	add_child(orb)
	# 神明名
	var nm := Label.new()
	nm.text = deity
	nm.add_theme_font_size_override("font_size", THEME.get_typography_size("h2", 28))
	nm.add_theme_color_override("font_color", THEME.get_color("hot_gold"))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(nm)
	# 請神 gauge
	_gauge = CmbResourceBar.new().setup("請神", "invoke", cur, mx)
	_gauge.custom_minimum_size = Vector2(140, 0)
	add_child(_gauge)
	_refresh_full(cur >= mx)
	return self

func _refresh_full(is_full: bool) -> void:
	# 滿槽：珠子金邊加粗發光，提示降乩
	_orb_box.border_color = THEME.get_color("hot_gold") if is_full else THEME.get_color("old_gold")
	_orb_box.set_border_width_all(5 if is_full else 3)
