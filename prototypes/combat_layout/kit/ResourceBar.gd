class_name CmbResourceBar
extends VBoxContainer
## 戰鬥資源條 kit 元件。名稱＋數值＋條（track + fill）。
## 純 token 驅動；fill 寬用 anchor 比例（自動佈局，零硬 px）。
## kind: hp(元神/紅) · ward(煞盾/金) · invoke(請神/玉) · mana(神力/青)
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const _FILL := {"hp": "hp_red", "ward": "armor_gold", "invoke": "spirit_jade", "mana": "energy_cyan"}
const _TRACK := {"hp": Color(0.231, 0.086, 0.086), "ward": Color(0.255, 0.2, 0.102),
	"invoke": Color(0.09, 0.21, 0.18), "mana": Color(0.09, 0.21, 0.235)}
const _BAR_H := 16

var _name_lbl: Label
var _num_lbl: Label
var _fill: ColorRect
var _kind := "hp"

func setup(label_text: String, kind: String, cur: float, mx: float) -> CmbResourceBar:
	_kind = kind
	_build()
	_name_lbl.text = label_text
	set_values(cur, mx)
	return self

func _build() -> void:
	add_theme_constant_override("separation", maxi(2, THEME.get_spacing("xs", 8) / 2))
	var head := HBoxContainer.new()
	_name_lbl = _label("caption", "paper_warm")
	head.add_child(_name_lbl)
	var sp := Control.new(); sp.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(sp)
	_num_lbl = _label("caption", "hot_gold")
	head.add_child(_num_lbl)
	add_child(head)

	var track := Control.new()
	track.custom_minimum_size = Vector2(0, _BAR_H)
	track.size_flags_horizontal = SIZE_EXPAND_FILL
	var bg := ColorRect.new()
	bg.color = _TRACK.get(_kind, Color(0.2, 0.15, 0.12))
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(bg)
	_fill = ColorRect.new()
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_fill)
	add_child(track)

func set_values(cur: float, mx: float) -> void:
	var ratio := clampf(cur / maxf(mx, 1.0), 0.0, 1.0)
	_fill.anchor_left = 0.0; _fill.anchor_top = 0.0
	_fill.anchor_bottom = 1.0; _fill.anchor_right = ratio
	_fill.offset_left = 0; _fill.offset_top = 0; _fill.offset_right = 0; _fill.offset_bottom = 0
	_num_lbl.text = "%d / %d" % [int(round(cur)), int(round(mx))]
	# 狀態：請神滿槽 → 轉金光；元神 < 30% → 危險暗紅；其餘原色
	if _kind == "invoke" and ratio >= 1.0:
		_fill.color = THEME.get_color("hot_gold")
	elif _kind == "hp" and ratio < 0.3:
		_fill.color = THEME.get_color("danger_crimson")
	else:
		_fill.color = THEME.get_color(_FILL.get(_kind, "hp_red"))

func _label(token: String, color_token: String) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", THEME.get_typography_size(token, 18))
	l.add_theme_color_override("font_color", THEME.get_color(color_token))
	return l
