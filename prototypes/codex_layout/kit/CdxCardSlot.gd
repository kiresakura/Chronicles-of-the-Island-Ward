class_name CdxCardSlot
extends Button
## 圖鑑卡位 kit。狀態：collected / locked / loading / error。
## extends Button → 天生可 focus（鍵盤/手把）+ 點擊；視覺用 mouse-ignore 子節點疊上。
## 純自動佈局：欄寬由 GridContainer 分配（size flags EXPAND），高固定比例。零硬座標（徽章用 anchor）。
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const RAR_COLOR := {"common": "old_gold", "uncommon": "spirit_jade", "rare": "neon_cyan", "epic": "hot_gold"}
const RAR_TXT := {"common": "常", "uncommon": "良", "rare": "稀", "epic": "神"}
const _H := 180

signal slot_activated(data: Dictionary)

var data: Dictionary = {}
var _pulse_target: CanvasItem = null

func _ready() -> void:
	# 骨架脈動（須在 tree 內才能建 tween；setup 在 add_child 前呼叫故延後到此）
	if _pulse_target != null:
		var tw := create_tween().set_loops()
		tw.tween_property(_pulse_target, "modulate:a", 0.4, 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_pulse_target, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)

func _base() -> void:
	custom_minimum_size = Vector2(0, _H)
	size_flags_horizontal = SIZE_EXPAND_FILL
	flat = true
	focus_mode = FOCUS_ALL
	clip_contents = true

func setup_collected(d: Dictionary) -> CdxCardSlot:
	data = d
	_base()
	var rc := THEME.get_color(RAR_COLOR.get(d.get("rar", "common"), "old_gold"))
	_frame(rc, THEME.get_color("hot_gold"))
	var v := _fill_vbox()
	# 立繪占位（暗廟殿色 + 稀有色暈 + 型別字 glyph + 角標）
	var art := Control.new()
	art.size_flags_vertical = SIZE_EXPAND_FILL
	art.mouse_filter = MOUSE_FILTER_IGNORE
	var artbg := ColorRect.new()
	artbg.color = Color(rc.r, rc.g, rc.b, 0.15)
	artbg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	artbg.mouse_filter = MOUSE_FILTER_IGNORE
	art.add_child(artbg)
	var glyph := Label.new()
	glyph.text = str(d.get("type", ""))
	glyph.add_theme_font_size_override("font_size", THEME.get_typography_size("display", 48))
	glyph.add_theme_color_override("font_color", Color(rc.r, rc.g, rc.b, 0.22))
	glyph.set_anchors_and_offsets_preset(PRESET_CENTER)
	glyph.mouse_filter = MOUSE_FILTER_IGNORE
	art.add_child(glyph)
	if int(d.get("cost", 0)) > 0:
		var cost := _badge(str(d.get("cost")), "hot_gold", PRESET_TOP_LEFT)
		art.add_child(cost)
	var rar := _badge(RAR_TXT.get(d.get("rar", "common"), "常"), RAR_COLOR.get(d.get("rar", "common"), "old_gold"), PRESET_TOP_RIGHT)
	art.add_child(rar)
	v.add_child(art)
	# 名條（夜底米白字，截斷）
	v.add_child(_name_strip(str(d.get("name", "")), rc))
	pressed.connect(func() -> void: slot_activated.emit(data))
	return self

func setup_locked() -> CdxCardSlot:
	_base()
	disabled = false  # 仍可 focus/點（顯示 tooltip），但不開 sheet
	_frame(THEME.get_color("wood_brown"), THEME.get_color("smoke_gray"))
	var v := _fill_vbox()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var lock := Label.new(); lock.text = "🔒"
	lock.add_theme_font_size_override("font_size", THEME.get_typography_size("h1", 36))
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(lock)
	var q := Label.new(); q.text = "？？？"
	q.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
	q.add_theme_color_override("font_color", THEME.get_color("ash_beige"))  # AA：ash 過 4.5:1
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(q)
	return self

func setup_skeleton() -> CdxCardSlot:
	_base()
	disabled = true
	focus_mode = FOCUS_NONE
	mouse_filter = MOUSE_FILTER_IGNORE
	var sb := THEME.make_stylebox(Color(0.16, 0.10, 0.08, 1), THEME.get_color("wood_brown"), 0, 2, 0.0)
	add_theme_stylebox_override("disabled", sb)
	add_theme_stylebox_override("normal", sb)
	# 內容形狀骨架：art 塊（撐高）＋名條塊；脈動暗示「載入中」
	var v := _fill_vbox()
	var art := ColorRect.new()
	art.color = Color(0.24, 0.16, 0.13, 1)
	art.size_flags_vertical = SIZE_EXPAND_FILL
	art.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(art)
	var namebar := ColorRect.new()
	namebar.color = Color(0.13, 0.08, 0.07, 1)
	namebar.custom_minimum_size = Vector2(0, THEME.get_spacing("xl", 32))
	namebar.mouse_filter = MOUSE_FILTER_IGNORE
	v.add_child(namebar)
	_pulse_target = art
	return self

# ── helpers ──
func _frame(border: Color, hover_border: Color) -> void:
	add_theme_stylebox_override("normal", THEME.make_stylebox(Color(0.086, 0.043, 0.039, 1), border, 0, 3, 0.0))
	add_theme_stylebox_override("hover", THEME.make_stylebox(Color(0.11, 0.06, 0.05, 1), hover_border, 0, 3, 0.0))
	add_theme_stylebox_override("pressed", THEME.make_stylebox(Color(0.11, 0.06, 0.05, 1), hover_border, 0, 3, 0.0))
	add_theme_stylebox_override("focus", THEME.make_focus_stylebox(hover_border, 0))

func _fill_vbox() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(v)
	return v

func _badge(text: String, color_token: String, anchor: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
	l.add_theme_color_override("font_color", THEME.get_color(color_token))
	l.mouse_filter = MOUSE_FILTER_IGNORE
	l.set_anchors_and_offsets_preset(anchor)
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.02, 0.8))
	return l

func _name_strip(text: String, rc: Color) -> Control:
	var strip := PanelContainer.new()
	strip.add_theme_stylebox_override("panel", THEME.make_stylebox(THEME.get_color("lacquer_black"), Color(rc.r, rc.g, rc.b, 0.4), 0, 1, 0.0))
	strip.mouse_filter = MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
	l.add_theme_color_override("font_color", THEME.get_color("paper_warm"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.mouse_filter = MOUSE_FILTER_IGNORE
	strip.add_child(l)
	return strip
