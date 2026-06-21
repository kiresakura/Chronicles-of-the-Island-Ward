class_name CdxCategoryTab
extends Button
## 圖鑑側欄分頁 kit。名 + 計數 + mini 進度 + 選中態。Button → focusable（鍵盤/手把）。
## padding 走 MarginContainer（自動佈局，零硬座標）；mini bar 走 anchor 比例。
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
signal tab_selected(index: int)

var index := 0
var _name_lbl: Label
var _fill: ColorRect

func setup(idx: int, cat_name: String, owned: int, total: int) -> CdxCategoryTab:
	index = idx
	custom_minimum_size = Vector2(0, 68)
	size_flags_horizontal = SIZE_EXPAND_FILL
	flat = true
	focus_mode = FOCUS_ALL
	toggle_mode = true
	var pad := MarginContainer.new()
	pad.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	pad.mouse_filter = MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", THEME.get_spacing("md", 16))
	pad.add_theme_constant_override("margin_right", THEME.get_spacing("sm", 12))
	pad.add_theme_constant_override("margin_top", THEME.get_spacing("sm", 12))
	pad.add_theme_constant_override("margin_bottom", THEME.get_spacing("sm", 12))
	add_child(pad)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", THEME.get_spacing("xs", 8))
	v.mouse_filter = MOUSE_FILTER_IGNORE
	pad.add_child(v)
	var head := HBoxContainer.new(); head.mouse_filter = MOUSE_FILTER_IGNORE
	_name_lbl = Label.new(); _name_lbl.text = cat_name
	_name_lbl.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
	_name_lbl.mouse_filter = MOUSE_FILTER_IGNORE
	head.add_child(_name_lbl)
	var sp := Control.new(); sp.size_flags_horizontal = SIZE_EXPAND_FILL; sp.mouse_filter = MOUSE_FILTER_IGNORE; head.add_child(sp)
	var cnt := Label.new(); cnt.text = "%d/%d" % [owned, total]
	cnt.add_theme_font_size_override("font_size", THEME.get_typography_size("micro", 16))
	cnt.add_theme_color_override("font_color", THEME.get_color("ash_beige"))
	cnt.mouse_filter = MOUSE_FILTER_IGNORE
	head.add_child(cnt)
	v.add_child(head)
	var track := Control.new()
	track.custom_minimum_size = Vector2(0, 6)
	track.mouse_filter = MOUSE_FILTER_IGNORE
	var bg := ColorRect.new(); bg.color = Color(0.165, 0.078, 0.063)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT); bg.mouse_filter = MOUSE_FILTER_IGNORE; track.add_child(bg)
	_fill = ColorRect.new(); _fill.mouse_filter = MOUSE_FILTER_IGNORE
	_fill.anchor_left = 0; _fill.anchor_top = 0; _fill.anchor_bottom = 1
	_fill.anchor_right = clampf(float(owned) / maxf(total, 1.0), 0.0, 1.0)
	track.add_child(_fill)
	v.add_child(track)
	pressed.connect(func() -> void: tab_selected.emit(index))
	set_selected(false)
	return self

func set_selected(sel: bool) -> void:
	button_pressed = sel
	var sb := StyleBoxFlat.new()
	sb.bg_color = THEME.get_color("panel_bg_hover") if sel else Color(0.10, 0.06, 0.05, 0.4)
	sb.border_width_left = 5
	sb.border_color = THEME.get_color("festival_red") if sel else Color(0, 0, 0, 0)
	for s in ["normal", "hover", "pressed"]:
		add_theme_stylebox_override(s, sb)
	add_theme_stylebox_override("focus", THEME.make_focus_stylebox(THEME.get_color("hot_gold"), 0))
	_name_lbl.add_theme_color_override("font_color", THEME.get_color("hot_gold") if sel else THEME.get_color("paper_warm"))
	_fill.color = THEME.get_color("spirit_jade") if sel else THEME.get_color("old_gold")
