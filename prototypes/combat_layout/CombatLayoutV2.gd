extends Control
## Phase A — 戰鬥版面「結構」（方向 A 底 + 降乩 CTA 在拇指區）。
## 鐵律：純自動佈局 Container＋size flags，零硬座標；bg 全出血、內容 MarginContainer 內縮進 safe-area；
## 響應式（依 AR 調側欄）；互動元件可 focus（鍵盤/手把）。Phase B 才上美術。
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

var _safe: MarginContainer
var _sidebar: VBoxContainer
var _end_turn: Button
var _invoke_btn: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build()
	_apply_safe()
	var resp: Node = get_node_or_null("/root/Responsive")
	if resp != null and resp.has_signal("changed") and not resp.changed.is_connected(_apply_safe):
		resp.changed.connect(_apply_safe)

func _build() -> void:
	# 背景：廟殿暗底占位（全出血；Phase B 換場景圖）
	var bg := ColorRect.new()
	bg.color = THEME.get_color("night_ink")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_safe = MarginContainer.new()
	_safe.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_safe)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", THEME.get_spacing("lg", 24))
	_safe.add_child(main)

	# ── TopBar：地點麵包屑（左）＋ 敵人名牌（右）──
	var top := HBoxContainer.new()
	top.add_child(_breadcrumb("遶境·山路  ›  巡境遇煞"))
	var tsp := Control.new(); tsp.size_flags_horizontal = SIZE_EXPAND_FILL; top.add_child(tsp)
	var enemy := CmbUnitFrame.new().setup_enemy("椅仔姑", 38, 48, 7, 12, "施法 · 護身符")
	enemy.custom_minimum_size = Vector2(320, 0)
	top.add_child(enemy)
	main.add_child(top)

	# ── MidRow：戰鬥舞台（expand）＋ 請神寶珠側欄（方向 A）──
	var mid := HBoxContainer.new()
	mid.size_flags_vertical = SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", THEME.get_spacing("md", 16))
	var stage := PanelContainer.new()
	stage.size_flags_horizontal = SIZE_EXPAND_FILL
	stage.size_flags_vertical = SIZE_EXPAND_FILL
	stage.add_theme_stylebox_override("panel",
		THEME.make_stylebox(Color(0.10, 0.06, 0.05, 0.5), THEME.get_color("wood_brown"), 0, 2, 0.0))
	var sl := Label.new()
	sl.text = "（戰鬥舞台：乩童 ⟷ 椅仔姑）"
	sl.add_theme_color_override("font_color", THEME.get_color("smoke_gray"))
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage.add_child(sl)
	mid.add_child(stage)
	_sidebar = VBoxContainer.new()
	_sidebar.custom_minimum_size = Vector2(184, 0)
	_sidebar.add_child(CmbInvocationOrb.new().setup("虎爺", 62, 100))
	mid.add_child(_sidebar)
	main.add_child(mid)

	# ── BottomBar：神力（左）＋ 手牌（中,expand）＋ 降乩/結束回合（右,拇指區）──
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", THEME.get_spacing("md", 16))
	bottom.add_child(_mana_wheel("神力", 1, 3))
	var hand := HBoxContainer.new()
	hand.size_flags_horizontal = SIZE_EXPAND_FILL
	hand.alignment = BoxContainer.ALIGNMENT_CENTER
	hand.add_theme_constant_override("separation", THEME.get_spacing("sm", 12))
	var deck := [["破煞", "符", 1], ["護身符", "技", 1], ["驅邪光", "攻", 2], ["速描符", "技", 1], ["重擊", "攻", 2]]
	for i in deck.size():
		var c := CmbCardView.new().setup(deck[i][0], deck[i][2], deck[i][1])
		c.focus_mode = Control.FOCUS_ALL
		hand.add_child(c)
		if i == 2: c.set_state("playable")
		elif i == 4: c.set_state("disabled")
	bottom.add_child(hand)
	var rcol := VBoxContainer.new()
	rcol.add_theme_constant_override("separation", THEME.get_spacing("xs", 8))
	_invoke_btn = Button.new(); _invoke_btn.text = "降乩 ▶"
	THEME.apply_primary_button_style(_invoke_btn)
	_invoke_btn.focus_mode = Control.FOCUS_ALL
	rcol.add_child(_invoke_btn)
	_end_turn = Button.new(); _end_turn.text = "結束回合"
	THEME.apply_secondary_button_style(_end_turn)
	_end_turn.focus_mode = Control.FOCUS_ALL
	rcol.add_child(_end_turn)
	bottom.add_child(rcol)
	main.add_child(bottom)

	_end_turn.grab_focus.call_deferred()

func _breadcrumb(text: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel",
		THEME.make_stylebox(THEME.get_color("panel_bg"), THEME.get_color("old_gold"), 0, 2, 0.0))
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
	l.add_theme_color_override("font_color", THEME.get_color("paper_warm"))
	p.add_child(l)
	return p

func _mana_wheel(label: String, cur: int, mx: int) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(96, 96)
	p.size_flags_vertical = SIZE_SHRINK_CENTER
	p.add_theme_stylebox_override("panel",
		THEME.make_stylebox(THEME.get_color("lacquer_black"), THEME.get_color("energy_cyan"), 0, 3, 0.0))
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var n := Label.new(); n.text = "%d / %d" % [cur, mx]
	n.add_theme_font_size_override("font_size", THEME.get_typography_size("h1", 36))
	n.add_theme_color_override("font_color", THEME.get_color("energy_cyan"))
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(n)
	var c := Label.new(); c.text = label
	c.add_theme_font_size_override("font_size", THEME.get_typography_size("micro", 16))
	c.add_theme_color_override("font_color", THEME.get_color("smoke_gray"))
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(c)
	p.add_child(v)
	return p

func _apply_safe() -> void:
	# 用『實際視口』算 safe 邊距（get_stage_size 可能 stale），再加一圈基礎呼吸 margin
	# （即使無瀏海也留邊 → 內容不貼死螢幕緣、吸收設備差異；呼應 SAFE_AREA_GUIDE §9）
	var vp := get_viewport().get_visible_rect().size
	var safe := THEME.get_safe_content_rect(get_viewport())
	var base := THEME.get_spacing("lg", 24)
	_safe.add_theme_constant_override("margin_left", base + maxi(0, int(safe.position.x)))
	_safe.add_theme_constant_override("margin_top", base + maxi(0, int(safe.position.y)))
	_safe.add_theme_constant_override("margin_right", base + maxi(0, int(vp.x - safe.end.x)))
	_safe.add_theme_constant_override("margin_bottom", base + maxi(0, int(vp.y - safe.end.y)))
	# 響應式：平板/窄寬比（AR < 1.6）→ 側欄收窄，把寬讓給舞台
	var ar := vp.x / maxf(vp.y, 1.0)
	if _sidebar != null:
		_sidebar.custom_minimum_size.x = 150.0 if ar < 1.6 else 184.0
