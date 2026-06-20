class_name CmbCardView
extends PanelContainer
## 手牌卡 kit 元件。cost 寶石＋tag＋圖占位＋名。
## 狀態：default / hover / selected / playable(可打發光) / disabled。Phase A 圖用占位。
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const _W := 132
const _H := 178

var _frame: StyleBoxFlat
var _state := "default"

func setup(card_name: String, cost: int, tag: String) -> CmbCardView:
	custom_minimum_size = Vector2(_W, _H)
	size_flags_vertical = SIZE_SHRINK_CENTER
	_frame = THEME.make_stylebox(THEME.get_color("paper_cream"), THEME.get_color("old_gold"),
		THEME.get_radius("md", 0), 3, 0.30)
	add_theme_stylebox_override("panel", _frame)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", maxi(2, THEME.get_spacing("xs", 8) / 2))
	add_child(v)
	var head := HBoxContainer.new()
	head.add_child(_lbl(str(cost), "h2", "hot_gold"))
	var sp := Control.new(); sp.size_flags_horizontal = SIZE_EXPAND_FILL; head.add_child(sp)
	head.add_child(_lbl(tag, "micro", "smoke_gray"))
	v.add_child(head)
	var art := ColorRect.new()  # Phase B 換卡圖
	art.color = Color(0.12, 0.08, 0.07, 0.9)
	art.size_flags_vertical = SIZE_EXPAND_FILL
	art.custom_minimum_size = Vector2(0, 92)
	v.add_child(art)
	var nm := _lbl(card_name, "caption", "lacquer_black")
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nm)
	set_state("default")
	return self

func set_state(s: String) -> void:
	_state = s
	match s:
		"hover":
			_frame.border_color = THEME.get_color("hot_gold"); _frame.set_border_width_all(3)
			modulate = Color(1.08, 1.08, 1.08)
		"selected":
			_frame.border_color = THEME.get_color("festival_red"); _frame.set_border_width_all(4)
			modulate = Color.WHITE
		"playable":
			_frame.border_color = THEME.get_color("hot_gold"); _frame.set_border_width_all(3)
			modulate = Color(1.0, 0.97, 0.88)
		"disabled":
			_frame.border_color = THEME.get_color("smoke_gray"); modulate = Color(0.55, 0.55, 0.55)
		_:
			_frame.border_color = THEME.get_color("old_gold"); _frame.set_border_width_all(3)
			modulate = Color.WHITE

func _lbl(text: String, token: String, color: String) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", THEME.get_typography_size(token, 18))
	l.add_theme_color_override("font_color", THEME.get_color(color))
	l.text = text
	return l
