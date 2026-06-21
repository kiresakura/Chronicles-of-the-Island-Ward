extends Control
## 圖鑑 / 收編錄 — 佈局契約版（移植自 codex_baseline.html）。
##
## 佈局契約（嚴守）：
##   1. 只用自動佈局容器（VBox/HBox/Grid/Margin/Scroll/Panel + size flags + anchor 比例），
##      零硬座標。唯一的「數字」是 token 化的 min-size 與 safe 邊距（皆來自 Responsive/THEME）。
##   2. 一開始就響應式：欄數由可用寬度推導（手機16:9 / 手機19.5:9 / 平板4:3 自動不同），
##      側欄依寬比收放，bg 全出血、內容 MarginContainer 內縮進 safe-area。
##   3. 鍵盤/手把：tab、卡位、篩選、搜尋、關閉皆 FOCUS_ALL；幾何自動鄰接 → D-pad 可巡。
##
## 四態：grid（成功網格）/ loading（骨架）/ error（重試）/ empty（引導）。
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const CELL_TARGET := 210  # 目標卡位寬 → 欄數 = 可用寬 / 此值（夾 3..6）

const CATS := [
	{"name": "卡圖收藏", "owned": 124, "total": 210},
	{"name": "符令", "owned": 38, "total": 52},
	{"name": "家將", "owned": 9, "total": 16},
	{"name": "神明", "owned": 4, "total": 12},
	{"name": "敵煞", "owned": 22, "total": 40},
	{"name": "遺物", "owned": 15, "total": 30},
	{"name": "消耗品", "owned": 12, "total": 18},
]
const SAMPLE := [
	{"name": "破煞符", "type": "符", "rar": "common", "cost": 1, "desc": "對單一目標造成 6 點破煞，並使其煞盾 −2。基礎中的基礎，整場遶境的起手式。", "got": "序章 · 城隍廟"},
	{"name": "護身符", "type": "技", "rar": "common", "cost": 1, "desc": "獲得 5 點煞盾。", "got": "序章 · 城隍廟"},
	{"name": "驅邪光", "type": "攻", "rar": "uncommon", "cost": 2, "desc": "造成 9 點破煞；若目標帶『陰』，額外 +4。", "got": "第一章 · 夜市"},
	{"name": "速描符", "type": "技", "rar": "common", "cost": 1, "desc": "抽 2 張牌。", "got": "序章 · 城隍廟"},
	{"name": "五雷正法", "type": "符", "rar": "rare", "cost": 3, "desc": "對全體敵人降下天雷，各造成 12 點破煞並清除其增益。", "got": "第二章 · 雷部"},
	{"name": "重擊", "type": "攻", "rar": "common", "cost": 2, "desc": "造成 14 點破煞。", "got": "序章 · 城隍廟"},
	{"name": "敕令·天兵", "type": "符", "rar": "epic", "cost": 4, "desc": "請下天兵天將，召喚三尊家將協戰，回合結束時各補一次破煞。", "got": "大醮 Boss · 首勝"},
	{"name": "安神香", "type": "技", "rar": "uncommon", "cost": 1, "desc": "回復 3 點神力並淨化一個負面狀態。", "got": "第一章 · 休息"},
	{"name": "鎮煞印", "type": "技", "rar": "rare", "cost": 2, "desc": "獲得 10 點煞盾，並反彈下一次受到的破煞。", "got": "第二章 · 廟祝"},
	{"name": "遶境鼓", "type": "符", "rar": "uncommon", "cost": 1, "desc": "本回合每打出一張牌，造成 2 點破煞。", "got": "第一章 · 陣頭"},
]

@export var demo_state: String = "grid"  # grid / loading / error / empty
@export var demo_cat: int = 0

var _safe: MarginContainer
var _sidebar: VBoxContainer
var _sidebar_box: ScrollContainer
var _tabs: Array[CdxCategoryTab] = []
var _cat_title: Label
var _cat_progress: Label
var _state_host: MarginContainer
var _grid: GridContainer
var _detail: CdxDetailSheet
var _filter := "all"  # all / owned / locked
var _search := ""
var _first_focus: Control = null
var _chips: Array[Button] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_build()
	_render_state()
	_apply_safe()
	var resp: Node = get_node_or_null("/root/Responsive")
	if resp != null and resp.has_signal("changed") and not resp.changed.is_connected(_apply_safe):
		resp.changed.connect(_apply_safe)
	if _first_focus != null:
		_first_focus.grab_focus.call_deferred()
	if demo_state == "detail":
		call_deferred("_open_demo_sheet")

func _open_demo_sheet() -> void:
	_detail.open(SAMPLE[6])  # 敕令·天兵（epic，示範稀有度配色）

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = THEME.get_color("night_ink")
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	_safe = MarginContainer.new()
	_safe.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_safe)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", THEME.get_spacing("lg", 24))
	_safe.add_child(main)

	main.add_child(_build_topbar())

	var body := HBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", THEME.get_spacing("lg", 24))
	main.add_child(body)

	# ── 側欄：分類分頁（可捲動）──
	_sidebar_box = ScrollContainer.new()
	_sidebar_box.custom_minimum_size = Vector2(248, 0)
	_sidebar_box.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sidebar = VBoxContainer.new()
	_sidebar.size_flags_horizontal = SIZE_EXPAND_FILL
	_sidebar.add_theme_constant_override("separation", THEME.get_spacing("xs", 8))
	for i in CATS.size():
		var t := CdxCategoryTab.new().setup(i, CATS[i]["name"], CATS[i]["owned"], CATS[i]["total"])
		t.tab_selected.connect(_on_tab)
		_sidebar.add_child(t)
		_tabs.append(t)
	_sidebar_box.add_child(_sidebar)
	body.add_child(_sidebar_box)

	# ── 內容欄 ──
	var content := VBoxContainer.new()
	content.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", THEME.get_spacing("md", 16))
	body.add_child(content)
	content.add_child(_build_header())

	_state_host = MarginContainer.new()
	_state_host.size_flags_vertical = SIZE_EXPAND_FILL
	content.add_child(_state_host)

	_detail = CdxDetailSheet.new()
	add_child(_detail)

	_tabs[clampi(demo_cat, 0, _tabs.size() - 1)].set_selected(true)

func _build_topbar() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", THEME.get_spacing("md", 16))
	var back := Button.new()
	back.text = "‹ 返回"
	back.custom_minimum_size = Vector2(0, THEME._get_touch_target_value("minimum", 88) * 0.62)
	THEME.apply_secondary_button_style(back)
	back.focus_mode = FOCUS_ALL
	bar.add_child(back)
	_first_focus = back
	var title := Label.new()
	title.text = "收編錄"
	title.add_theme_font_size_override("font_size", THEME.get_typography_size("h1", 36))
	title.add_theme_color_override("font_color", THEME.get_color("hot_gold"))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(title)
	var sp := Control.new(); sp.size_flags_horizontal = SIZE_EXPAND_FILL; bar.add_child(sp)
	# 總進度（全分類加總）
	var owned := 0; var total := 0
	for c in CATS: owned += int(c["owned"]); total += int(c["total"])
	var prog := VBoxContainer.new()
	prog.custom_minimum_size = Vector2(260, 0)
	prog.alignment = BoxContainer.ALIGNMENT_CENTER
	var pl := Label.new()
	pl.text = "總收編　%d / %d　·　%d%%" % [owned, total, int(round(100.0 * owned / total))]
	pl.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
	pl.add_theme_color_override("font_color", THEME.get_color("ash_beige"))
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prog.add_child(pl)
	prog.add_child(_thin_bar(float(owned) / total, "spirit_jade"))
	bar.add_child(prog)
	return bar

func _build_header() -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", THEME.get_spacing("md", 16))
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = SIZE_EXPAND_FILL
	_cat_title = Label.new()
	_cat_title.add_theme_font_size_override("font_size", THEME.get_typography_size("h2", 28))
	_cat_title.add_theme_color_override("font_color", THEME.get_color("paper_warm"))
	titles.add_child(_cat_title)
	_cat_progress = Label.new()
	_cat_progress.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
	_cat_progress.add_theme_color_override("font_color", THEME.get_color("ash_beige"))
	titles.add_child(_cat_progress)
	head.add_child(titles)
	# 篩選 chips
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", THEME.get_spacing("xs", 8))
	chips.size_flags_vertical = SIZE_SHRINK_CENTER
	for spec in [["all", "全部"], ["owned", "已收"], ["locked", "未收"]]:
		var key: String = spec[0]
		var chip := Button.new()
		chip.text = spec[1]
		chip.toggle_mode = true
		chip.focus_mode = FOCUS_ALL
		chip.set_meta("filter_key", key)
		chip.button_pressed = (key == _filter)
		_style_chip(chip)
		chip.pressed.connect(func() -> void: _on_filter(key))
		chips.add_child(chip)
		_chips.append(chip)
	head.add_child(chips)
	# 搜尋
	var search := LineEdit.new()
	search.placeholder_text = "搜尋…"
	search.custom_minimum_size = Vector2(220, THEME._get_touch_target_value("minimum", 88) * 0.56)
	search.size_flags_vertical = SIZE_SHRINK_CENTER
	search.add_theme_stylebox_override("normal",
		THEME.make_stylebox(THEME.get_color("lacquer_black"), THEME.get_color("old_gold"), 0, 2, 0.0))
	search.add_theme_stylebox_override("focus",
		THEME.make_stylebox(THEME.get_color("lacquer_black"), THEME.get_color("hot_gold"), 0, 2, 0.0))
	search.text_changed.connect(func(t: String) -> void: _search = t; _render_state())
	head.add_child(search)
	return head

# ── 狀態渲染 ──
func _render_state() -> void:
	for c in _state_host.get_children(): c.queue_free()
	var cat: Dictionary = CATS[clampi(demo_cat, 0, CATS.size() - 1)]
	_cat_title.text = str(cat["name"])
	_cat_progress.text = "已收編 %d / %d　·　%d%%" % [int(cat["owned"]), int(cat["total"]), int(round(100.0 * int(cat["owned"]) / int(cat["total"])))]
	match demo_state:
		"loading": _state_host.add_child(_make_skeleton())
		"error": _state_host.add_child(_make_error())
		"empty": _state_host.add_child(_make_empty())
		_: _state_host.add_child(_make_grid())

func _make_grid() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", THEME.get_spacing("md", 16))
	_grid.add_theme_constant_override("v_separation", THEME.get_spacing("md", 16))
	scroll.add_child(_grid)
	_populate_grid()
	_recompute_columns()
	return scroll

func _populate_grid() -> void:
	for c in _grid.get_children(): c.queue_free()
	var any := false
	# 已收編（樣本）
	if _filter != "locked":
		for d in SAMPLE:
			if _search != "" and not str(d["name"]).to_lower().contains(_search.to_lower()):
				continue
			var slot := CdxCardSlot.new().setup_collected(d)
			slot.slot_activated.connect(func(data: Dictionary) -> void: _detail.open(data))
			_grid.add_child(slot)
			any = true
	# 未收編（鎖定占位）— 只有無搜尋字或顯示「未收/全部」時補
	if _filter != "owned" and _search == "":
		for _i in range(8):
			_grid.add_child(CdxCardSlot.new().setup_locked())
			any = true
	if not any:
		# 篩選/搜尋後空集合 → 即時換成 empty
		_grid.add_child(_inline_hint("查無符合「%s」的項目" % _search))

func _make_skeleton() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid = GridContainer.new()
	_grid.size_flags_horizontal = SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", THEME.get_spacing("md", 16))
	_grid.add_theme_constant_override("v_separation", THEME.get_spacing("md", 16))
	for _i in range(12):
		_grid.add_child(CdxCardSlot.new().setup_skeleton())
	scroll.add_child(_grid)
	_recompute_columns()
	return scroll

func _make_error() -> Control:
	return _center_state("⚠", "載入收編錄失敗", "資料讀取時發生問題。請檢查存檔或稍後再試。", "重試", "festival_red")

func _make_empty() -> Control:
	return _center_state("⛩", "尚未收編任何項目", "踏上遶境、降伏邪煞，收編的符令與家將會在此一一現身。", "前往遶境", "spirit_jade")

func _center_state(glyph: String, title: String, body: String, cta: String, accent: String) -> Control:
	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	center.size_flags_vertical = SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", THEME.get_spacing("md", 16))
	v.custom_minimum_size = Vector2(440, 0)
	var g := Label.new(); g.text = glyph
	g.add_theme_font_size_override("font_size", THEME.get_typography_size("display", 48) * 2)
	g.add_theme_color_override("font_color", THEME.get_color(accent))
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(g)
	var t := Label.new(); t.text = title
	t.add_theme_font_size_override("font_size", THEME.get_typography_size("h2", 28))
	t.add_theme_color_override("font_color", THEME.get_color("paper_warm"))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var b := Label.new(); b.text = body
	b.add_theme_font_size_override("font_size", THEME.get_typography_size("body", 22))
	b.add_theme_color_override("font_color", THEME.get_color("ash_beige"))
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(b)
	var btn := Button.new(); btn.text = cta
	btn.custom_minimum_size = Vector2(0, THEME._get_touch_target_value("minimum", 88) * 0.7)
	THEME.apply_primary_button_style(btn)
	btn.focus_mode = FOCUS_ALL
	v.add_child(btn)
	center.add_child(v)
	return center

func _inline_hint(text: String) -> Control:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", THEME.get_typography_size("body", 22))
	l.add_theme_color_override("font_color", THEME.get_color("smoke_gray"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

# ── 互動 ──
func _on_tab(idx: int) -> void:
	demo_cat = idx
	for i in _tabs.size(): _tabs[i].set_selected(i == idx)
	_render_state()

func _on_filter(f: String) -> void:
	_filter = f
	for chip in _chips:
		chip.button_pressed = (str(chip.get_meta("filter_key", "")) == f)
	if demo_state == "grid" and is_instance_valid(_grid):
		_populate_grid()
		_recompute_columns()

func _style_chip(chip: Button) -> void:
	var on := THEME.make_stylebox(THEME.get_color("panel_bg_hover"), THEME.get_color("hot_gold"), 0, 2, 0.0)
	var off := THEME.make_stylebox(Color(0.10, 0.06, 0.05, 0.5), THEME.get_color("wood_brown"), 0, 1, 0.0)
	chip.add_theme_stylebox_override("normal", off)
	chip.add_theme_stylebox_override("hover", on)
	chip.add_theme_stylebox_override("pressed", on)
	chip.add_theme_stylebox_override("focus", THEME.make_focus_stylebox(THEME.get_color("hot_gold"), 0))
	chip.add_theme_color_override("font_color", THEME.get_color("paper_warm"))
	chip.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))

# ── helpers ──
func _thin_bar(ratio: float, color_token: String) -> Control:
	var track := Control.new()
	track.custom_minimum_size = Vector2(0, 8)
	var bg := ColorRect.new(); bg.color = Color(0.165, 0.078, 0.063)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT); track.add_child(bg)
	var fill := ColorRect.new(); fill.color = THEME.get_color(color_token)
	fill.anchor_left = 0; fill.anchor_top = 0; fill.anchor_bottom = 1
	fill.anchor_right = clampf(ratio, 0.0, 1.0)
	track.add_child(fill)
	return track

func _apply_safe() -> void:
	var vp := get_viewport().get_visible_rect().size
	var safe := THEME.get_safe_content_rect(get_viewport())
	var base := THEME.get_spacing("lg", 24)
	_safe.add_theme_constant_override("margin_left", base + maxi(0, int(safe.position.x)))
	_safe.add_theme_constant_override("margin_top", base + maxi(0, int(safe.position.y)))
	_safe.add_theme_constant_override("margin_right", base + maxi(0, int(vp.x - safe.end.x)))
	_safe.add_theme_constant_override("margin_bottom", base + maxi(0, int(vp.y - safe.end.y)))
	# 響應式側欄：窄寬比（平板 4:3）→ 收窄，把寬讓給網格
	var ar := vp.x / maxf(vp.y, 1.0)
	if _sidebar_box != null:
		_sidebar_box.custom_minimum_size.x = 200.0 if ar < 1.6 else 248.0
	_recompute_columns()
	if _detail != null and _detail.visible:
		_detail._apply_safe()

func _recompute_columns() -> void:
	if _grid == null or not is_instance_valid(_grid):
		return
	# 欄數由『網格可用寬』推導：viewport − 兩側(base+safe) − 側欄 − body 間距
	var vp := get_viewport().get_visible_rect().size
	var safe := THEME.get_safe_content_rect(get_viewport())
	var base := THEME.get_spacing("lg", 24)
	var side := _sidebar_box.custom_minimum_size.x if _sidebar_box != null else 248.0
	var h_margins := (base + maxi(0, int(safe.position.x))) + (base + maxi(0, int(vp.x - safe.end.x)))
	var avail := vp.x - h_margins - side - THEME.get_spacing("lg", 24)
	_grid.columns = clampi(int(avail / CELL_TARGET), 3, 6)
