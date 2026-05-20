# 鎮島錄 — 主畫面（全向量 + 螢幕自適應）
#
# 設計：用戶 V5 mockup（廟宇 lobby，橫向）。chrome 為程序化向量（StyleBox + 自繪背景），
# icon 為 SVG。所有座標**不寫死 1200×700**，改由 Responsive.safe_rect 即時計算，
# 邊緣 UI 一律落在裝置安全區內（避瀏海/動態島/home indicator）；背景全出血填滿螢幕。
# 既有 Root.tscn 節點（QiJiaButton / Btn* / VBoxContainer 邏輯鈕）保留以維持導航/存檔。
extends Control

const ICON_DIR := "res://assets/ui/icons/"
const BACKDROP_SCRIPT := preload("res://scripts/ui/menus/VectorTempleBackdrop.gd")
const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

# 廟會配色 —— 全部由 design_tokens.json 經 CotiwUiTheme 提供（_ready 賦值）
var GOLD: Color = Color(0.95, 0.82, 0.45)
var GOLD_DIM: Color = Color(0.62, 0.49, 0.24)
var PANEL_BG: Color = Color(0.20, 0.07, 0.06, 0.53)
var PANEL_BG_HOVER: Color = Color(0.34, 0.11, 0.09, 0.96)
var PANEL_BG_LOCK: Color = Color(0.13, 0.09, 0.09, 0.80)

# 底部 6 格：node, 中文, icon, 是否已開放（false → 即將推出 toast）
const SLOTS := [
	{"node": "BtnCharacter", "label": "角色", "icon": "icon_character", "ready": false},
	{"node": "BtnFormation", "label": "陣型", "icon": "icon_formation", "ready": false},
	{"node": "BtnBattle",    "label": "戰鬥", "icon": "icon_battle",    "ready": true,  "act": "run"},
	{"node": "BtnShop",      "label": "商店", "icon": "icon_shop",      "ready": false},
	{"node": "BtnRecruit",   "label": "招募", "icon": "icon_recruit",   "ready": false},
	{"node": "BtnInventory", "label": "收藏", "icon": "icon_codex",     "ready": true,  "act": "codex"},
]
const UTILS := [
	{"icon": "icon_settings", "name": "設定"},
	{"icon": "icon_mail",     "name": "信件"},
	{"icon": "icon_achieve",  "name": "成就"},
]

@onready var title_screen: Control = $%TitleScreen
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var forfeit_run_button: Button = $VBoxContainer/ForfeitRunButton
@onready var new_run_button: Button = $VBoxContainer/NewRunButton
@onready var codex_button: Button = $VBoxContainer/CodexButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var qi_jia_button: Button = $QiJiaButton if has_node("QiJiaButton") else null
@onready var btn_exit_x: Button = $BtnExit if has_node("BtnExit") else null

# 自適應重排用的節點參照
var _backdrop: Control
var _avatar_frame: Panel
var _avatar_lv: Label
var _res_rows: Array = []          # 每列 {icon,pill,label,fill}
var _slot_btns: Array[Button] = []
var _util_btns: Array[Button] = []
var _toast: Label
var _toast_tween: Tween
var _res_incense: Label
var _res_level: Label
var _res_yuanbao: Label
var _level_fill: ColorRect

func _ready() -> void:
	GOLD = COTIW_UI_THEME.get_color("incense_gold", GOLD)
	GOLD_DIM = COTIW_UI_THEME.get_color("old_gold", GOLD_DIM)
	PANEL_BG = COTIW_UI_THEME.get_color("panel_bg", PANEL_BG)
	PANEL_BG_HOVER = COTIW_UI_THEME.get_color("panel_bg_hover", PANEL_BG_HOVER)
	PANEL_BG_LOCK = COTIW_UI_THEME.get_color("panel_bg_lock", PANEL_BG_LOCK)
	_hide_legacy_nodes()
	_add_backdrop()
	_build_avatar()
	_build_resource_bars()
	_build_slots()
	_build_utilities()
	_build_primary()
	_build_toast()

	Signals.run_ended.connect(_on_run_ended)
	Responsive.changed.connect(_relayout)
	update_continue_button_visibility()
	_refresh_resources()
	# Responsive autoload 以 call_deferred 算 safe_rect；等一幀再首次排版
	await get_tree().process_frame
	_relayout()

# ---------- 清掉舊 V4 / 點陣節點 ----------

func _hide_legacy_nodes() -> void:
	for n in ["MainMenuBg", "PortraitBackdrop", "Vignette", "Shrine", "ShrineGold",
			"ShrineGoldBottom", "ShrineGoldLeft", "ShrineGoldRight", "CharacterPlaceholder",
			"CharacterLabel", "CharacterHP", "Label", "Subtitle", "SmokeParticles",
			"IncenseLabel", "IncenseProgressBar", "HUDMoneyLabel", "HUDIncenseLabel",
			"PortraitCodexButton", "PortraitEventButton", "PortraitExitButton"]:
		if has_node(n):
			get_node(n).visible = false

func _add_backdrop() -> void:
	_backdrop = Control.new()
	_backdrop.name = "VectorBackdrop"
	_backdrop.set_script(BACKDROP_SCRIPT)
	_backdrop.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(_backdrop)
	move_child(_backdrop, 0)

# ---------- StyleBox：委派全專案共用工廠 ----------

func _sb(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	return COTIW_UI_THEME.make_stylebox(bg, border, radius, bw)

# ---------- 建立節點（不寫死座標，座標交給 _relayout） ----------

func _build_avatar() -> void:
	_avatar_frame = Panel.new()
	_avatar_frame.name = "AvatarFrame"
	_avatar_frame.add_theme_stylebox_override("panel", _sb(PANEL_BG, GOLD, 3, 8))
	_avatar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_avatar_frame)

	var ic := TextureRect.new()
	ic.name = "Icon"
	ic.texture = _load_icon("icon_avatar_tongji")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic.offset_left = 8; ic.offset_top = 8; ic.offset_right = -8; ic.offset_bottom = -8
	ic.modulate = GOLD
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_frame.add_child(ic)

	_avatar_lv = Label.new()
	_avatar_lv.name = "AvatarLv"
	_avatar_lv.text = "Lv 1"
	_avatar_lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_font(_avatar_lv, 16)
	add_child(_avatar_lv)

func _build_resource_bars() -> void:
	_res_incense = _make_resource_row(0, "icon_incense", GOLD)
	_res_level = _make_resource_row(1, "icon_level", Color(0.96, 0.78, 0.40))
	_res_yuanbao = _make_resource_row(2, "icon_yuanbao", Color(0.55, 0.78, 0.95))

func _make_resource_row(idx: int, icon: String, tint: Color) -> Label:
	var ic := TextureRect.new()
	ic.texture = _load_icon(icon)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.modulate = tint
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ic)

	var pill := Panel.new()
	pill.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.03, 0.03, 0.78), GOLD_DIM, 2, 12))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pill)

	var fill: ColorRect = null
	if idx == 1:
		fill = ColorRect.new()
		fill.color = Color(0.96, 0.62, 0.24, 0.55)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fill)
		_level_fill = fill

	var lbl := Label.new()
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gold_font(lbl, 16)
	add_child(lbl)

	_res_rows.append({"icon": ic, "pill": pill, "label": lbl, "fill": fill})
	return lbl

func _build_slots() -> void:
	for i in SLOTS.size():
		var data: Dictionary = SLOTS[i]
		if not has_node(data["node"]):
			_slot_btns.append(null)
			continue
		var btn: Button = get_node(data["node"])
		btn.flat = false
		btn.focus_mode = Control.FOCUS_NONE
		btn.disabled = false
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_slot_style(btn, data["ready"])
		_set_slot_content(btn, data["icon"], data["label"], data["ready"])
		_hook_hover(btn)
		for c in btn.button_up.get_connections():
			btn.button_up.disconnect(c["callable"])
		if data["ready"]:
			var act: String = data.get("act", "")
			if act == "run":
				btn.button_up.connect(_on_new_run_button_up)
			elif act == "codex":
				btn.button_up.connect(_on_codex_button_up)
		else:
			btn.button_up.connect(_show_coming_soon.bind(data["label"]))
		_slot_btns.append(btn)

func _apply_slot_style(btn: Button, ready: bool) -> void:
	var bg := PANEL_BG if ready else PANEL_BG_LOCK
	var border := GOLD if ready else GOLD_DIM
	btn.add_theme_stylebox_override("normal", _sb(bg, border, 2, 10))
	btn.add_theme_stylebox_override("hover", _sb(PANEL_BG_HOVER if ready else PANEL_BG_LOCK, GOLD, 3, 10))
	btn.add_theme_stylebox_override("pressed", _sb(bg.darkened(0.15), GOLD, 2, 10))
	btn.add_theme_stylebox_override("disabled", _sb(PANEL_BG_LOCK, GOLD_DIM, 2, 10))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _set_slot_content(btn: Button, icon: String, label_text: String, ready: bool) -> void:
	btn.text = ""
	var tint := GOLD if ready else Color(0.6, 0.55, 0.45)
	var ic := btn.get_node_or_null("Icon") as TextureRect
	if ic == null:
		ic = TextureRect.new()
		ic.name = "Icon"
		btn.add_child(ic)
	ic.texture = _load_icon(icon)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.modulate = tint
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lbl := btn.get_node_or_null("Label") as Label
	if lbl == null:
		lbl = Label.new()
		lbl.name = "Label"
		btn.add_child(lbl)
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gold_font(lbl, 17)
	lbl.add_theme_color_override("font_color", tint)
	if not ready:
		_add_lock_badge(btn)

func _add_lock_badge(btn: Button) -> void:
	if btn.has_node("Lock"):
		return
	var lock := Label.new()
	lock.name = "Lock"
	lock.text = "鎖"
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gold_font(lock, 13)
	lock.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lock)

func _build_primary() -> void:
	if qi_jia_button == null:
		return
	var b := qi_jia_button
	b.flat = false
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	COTIW_UI_THEME.apply_primary_button_style(b)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", 52)
	b.add_theme_constant_override("shadow_offset_x", 2)
	b.add_theme_constant_override("shadow_offset_y", 2)
	b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))

	var ic := b.get_node_or_null("Icon") as TextureRect
	if ic == null:
		ic = TextureRect.new()
		ic.name = "Icon"
		b.add_child(ic)
	ic.texture = _load_icon("icon_qijia")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.modulate = GOLD
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for c in b.button_up.get_connections():
		b.button_up.disconnect(c["callable"])
	b.button_up.connect(_on_primary_pressed)
	_hook_hover(b)
	_start_qi_jia_pulse()

func _on_primary_pressed() -> void:
	if FileLoader.has_save_file():
		_on_continue_button_up()
	else:
		_on_new_run_button_up()

func _build_utilities() -> void:
	for i in UTILS.size():
		var u := Button.new()
		u.name = "Util%d" % i
		u.flat = false
		u.focus_mode = Control.FOCUS_NONE
		u.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		u.add_theme_stylebox_override("normal", _sb(PANEL_BG, GOLD_DIM, 2, 8))
		u.add_theme_stylebox_override("hover", _sb(PANEL_BG_HOVER, GOLD, 2, 8))
		u.add_theme_stylebox_override("pressed", _sb(PANEL_BG.darkened(0.15), GOLD, 2, 8))
		u.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		add_child(u)
		var ic := TextureRect.new()
		ic.name = "Icon"
		ic.texture = _load_icon(UTILS[i]["icon"])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = 9; ic.offset_top = 9; ic.offset_right = -9; ic.offset_bottom = -9
		ic.modulate = GOLD
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		u.add_child(ic)
		u.button_up.connect(_show_coming_soon.bind(UTILS[i]["name"]))
		_hook_hover(u)
		_util_btns.append(u)

	if btn_exit_x:
		btn_exit_x.flat = true
		btn_exit_x.focus_mode = Control.FOCUS_NONE
		btn_exit_x.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_gold_font(btn_exit_x, 28)
		btn_exit_x.add_theme_color_override("font_color", GOLD)
		btn_exit_x.add_theme_color_override("font_hover_color", Color(1, 0.6, 0.5))
		for c in btn_exit_x.button_up.get_connections():
			btn_exit_x.button_up.disconnect(c["callable"])
		btn_exit_x.button_up.connect(_on_exit_button_up)
		_hook_hover(btn_exit_x)

func _build_toast() -> void:
	_toast = Label.new()
	_toast.name = "Toast"
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast.add_theme_stylebox_override("normal", _sb(Color(0.10, 0.05, 0.05, 0.94), GOLD, 2, 10))
	_gold_font(_toast, 22)
	_toast.modulate = Color(1, 1, 1, 0)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)

# ---------- 自適應排版：所有座標由 Responsive.safe_rect 計算 ----------

func _relayout() -> void:
	var screen: Rect2 = Responsive.screen_rect
	var safe: Rect2 = Responsive.safe_rect
	var ts: float = 1.15 if Responsive.is_tablet() else 1.0   # 平板放大
	var pad: float = roundf(18.0 * ts)

	# 背景：全出血填滿整個螢幕（可延伸到瀏海下）
	if _backdrop:
		_backdrop.position = screen.position
		_backdrop.size = screen.size
		_backdrop.queue_redraw()

	# 左上：頭像 + 等級
	var av: float = roundf(64.0 * ts)
	var ax: float = safe.position.x + pad
	var ay: float = safe.position.y + pad
	if _avatar_frame:
		_avatar_frame.position = Vector2(ax, ay)
		_avatar_frame.size = Vector2(av, av)
	if _avatar_lv:
		_avatar_lv.position = Vector2(ax - 4, ay + av + 2)
		_avatar_lv.size = Vector2(av + 8, 20)

	# 左上：3 條資源列（在頭像右側）
	var rx: float = ax + av + roundf(12.0 * ts)
	var icon_sz: float = roundf(24.0 * ts)
	var row_h: float = roundf(24.0 * ts)
	var row_gap: float = roundf(10.0 * ts)
	var pill_w: float = clampf(safe.size.x * 0.18, 150.0, 230.0) * ts
	for i in _res_rows.size():
		var r: Dictionary = _res_rows[i]
		var ry: float = ay + i * (row_h + row_gap)
		r["icon"].position = Vector2(rx, ry)
		r["icon"].size = Vector2(icon_sz, icon_sz)
		var px: float = rx + icon_sz + roundf(6.0 * ts)
		r["pill"].position = Vector2(px, ry)
		r["pill"].size = Vector2(pill_w, row_h)
		if r["fill"] != null:
			r["fill"].position = Vector2(px + 3, ry + 3)
			r["fill"].size = Vector2(maxf(4.0, (pill_w - 6) * _level_ratio()), row_h - 6)
		r["label"].position = Vector2(px + 8, ry)
		r["label"].size = Vector2(pill_w - 12, row_h)

	# 右上：✕ + 3 工具鈕（貼安全區右上）
	var ex: float = roundf(34.0 * ts)
	var ux: float = roundf(44.0 * ts)
	var ugap: float = roundf(6.0 * ts)
	var right: float = safe.position.x + safe.size.x - pad
	if btn_exit_x:
		btn_exit_x.position = Vector2(right - ex, safe.position.y + pad)
		btn_exit_x.size = Vector2(ex, ex)
	var util_right: float = right - ex - roundf(10.0 * ts)
	for i in _util_btns.size():
		var u: Button = _util_btns[i]
		# 由右往左排：i=0(設定) 最靠近 ✕
		var uxp: float = util_right - ux - i * (ux + ugap)
		u.position = Vector2(uxp, safe.position.y + pad)
		u.size = Vector2(ux, ux)
		u.pivot_offset = u.size * 0.5

	# 底部：6 格 slot + 中央起駕（貼安全區下緣）
	var sw: float = roundf(86.0 * ts)
	var sh: float = roundf(84.0 * ts)
	var pw: float = roundf(284.0 * ts)
	var ph: float = roundf(96.0 * ts)
	var by: float = safe.position.y + safe.size.y - sh - pad
	var sgap: float = roundf(10.0 * ts)
	var cx: float = safe.position.x + safe.size.x * 0.5
	# 左 3：自安全區左緣起；右 3：對稱靠右緣
	var lx: float = safe.position.x + pad
	var rx2: float = safe.position.x + safe.size.x - pad - (3 * sw + 2 * sgap)
	for i in _slot_btns.size():
		var btn: Button = _slot_btns[i]
		if btn == null:
			continue
		var col: int = i if i < 3 else i - 3
		var gx: float = (lx if i < 3 else rx2) + col * (sw + sgap)
		btn.position = Vector2(gx, by)
		btn.size = Vector2(sw, sh)
		btn.pivot_offset = btn.size * 0.5
		_layout_slot_content(btn, sw, sh)

	if qi_jia_button:
		qi_jia_button.position = Vector2(cx - pw * 0.5, safe.position.y + safe.size.y - ph - pad)
		qi_jia_button.size = Vector2(pw, ph)
		qi_jia_button.pivot_offset = qi_jia_button.size * 0.5
		var qic := qi_jia_button.get_node_or_null("Icon") as TextureRect
		if qic:
			qic.position = Vector2(roundf(20 * ts), (ph - roundf(44 * ts)) * 0.5)
			qic.size = Vector2(roundf(44 * ts), roundf(44 * ts))

	# Toast 置中於安全區
	if _toast:
		var tw: float = clampf(safe.size.x * 0.34, 300.0, 460.0)
		_toast.size = Vector2(tw, roundf(52 * ts))
		_toast.position = Vector2(cx - tw * 0.5, safe.position.y + safe.size.y * 0.62)

func _layout_slot_content(btn: Button, sw: float, sh: float) -> void:
	var ic := btn.get_node_or_null("Icon") as TextureRect
	if ic:
		var isz: float = roundf(sh * 0.48)
		ic.position = Vector2((sw - isz) * 0.5, sh * 0.12)
		ic.size = Vector2(isz, isz)
	var lbl := btn.get_node_or_null("Label") as Label
	if lbl:
		lbl.position = Vector2(0, sh * 0.64)
		lbl.size = Vector2(sw, sh * 0.30)
	var lock := btn.get_node_or_null("Lock") as Label
	if lock:
		lock.position = Vector2(sw - 24, 4)
		lock.size = Vector2(22, 22)

func _level_ratio() -> float:
	var wins := _profile_int("profile_total_wins", 0)
	return float(wins % 3) / 3.0

# ---------- Toast ----------

func _show_coming_soon(feature_name: String) -> void:
	_toast.text = "「%s」即將推出" % feature_name
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	var base_y: float = _toast.position.y
	_toast.modulate = Color(1, 1, 1, 0)
	_toast_tween = create_tween()
	_toast_tween.set_trans(Tween.TRANS_SINE)
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.18)
	_toast_tween.parallel().tween_property(_toast, "position:y", base_y - 18.0, 0.18)
	_toast_tween.tween_interval(1.1)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func(): _toast.position.y = base_y)

# ---------- 互動回饋 ----------

func _hook_hover(c: Control) -> void:
	c.mouse_entered.connect(func(): _scale_to(c, 1.05))
	c.mouse_exited.connect(func(): _scale_to(c, 1.0))
	if c is BaseButton:
		c.button_down.connect(func(): _scale_to(c, 0.95))
		c.button_up.connect(func(): _scale_to(c, 1.05 if c.get_global_rect().has_point(get_global_mouse_position()) else 1.0))

func _scale_to(c: Control, s: float) -> void:
	if c == qi_jia_button:
		return
	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "scale", Vector2(s, s), 0.12)

func _start_qi_jia_pulse() -> void:
	if qi_jia_button == null:
		return
	var st := create_tween().set_loops()
	st.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	st.tween_property(qi_jia_button, "scale", Vector2(1.05, 1.05), 1.4)
	st.tween_property(qi_jia_button, "scale", Vector2(1.0, 1.0), 1.4)
	var mt := create_tween().set_loops()
	mt.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	mt.tween_property(qi_jia_button, "modulate", Color(1.15, 1.10, 0.92, 1), 0.95)
	mt.tween_property(qi_jia_button, "modulate", Color(0.96, 0.96, 0.96, 1), 0.95)

# ---------- 資源刷新 ----------

func _refresh_resources() -> void:
	var incense := _profile_int("profile_incense", 250)
	var yuanbao := _profile_int("profile_yuanbao", 0)
	var wins := _profile_int("profile_total_wins", 0)
	var level: int = 1 + int(wins / 3)
	var xp_in_level: int = wins % 3
	if _res_incense: _res_incense.text = "香火  %d" % incense
	if _res_yuanbao: _res_yuanbao.text = "元寶  %d" % yuanbao
	if _res_level: _res_level.text = "Lv %d   %d/3" % [level, xp_in_level]
	if _avatar_lv: _avatar_lv.text = "Lv %d" % level
	# 進度填充寬度交由 _relayout 依 _level_ratio() 重算
	_relayout()

func _profile_int(field: String, fallback: int) -> int:
	if Global.profile_data and field in Global.profile_data:
		var v := int(Global.profile_data.get(field))
		if v > 0:
			return v
	return fallback

# ---------- helper ----------

func _gold_font(c: Control, sz: int) -> void:
	c.add_theme_font_size_override("font_size", sz)
	c.add_theme_color_override("font_color", GOLD)
	c.add_theme_constant_override("shadow_offset_x", 2)
	c.add_theme_constant_override("shadow_offset_y", 2)
	c.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))

func _load_icon(name: String) -> Texture2D:
	var path := ICON_DIR + name + ".svg"
	if ResourceLoader.exists(path):
		return load(path)
	return null

# ---------- 既有導航邏輯（保留） ----------

func _on_continue_button_up() -> void:
	FileLoader.autoload()

func _on_forfeit_run_button_up() -> void:
	FileLoader.delete_save()
	update_continue_button_visibility()

func _on_new_run_button_up() -> void:
	title_screen.show_new_run_menu()

func _on_codex_button_up() -> void:
	title_screen.show_codex_menu()

func _on_exit_button_up() -> void:
	get_tree().quit()

func update_continue_button_visibility() -> void:
	var has_save: bool = FileLoader.has_save_file()
	if qi_jia_button:
		qi_jia_button.text = "繼　續" if has_save else "起　駕"
	if continue_button: continue_button.visible = has_save
	if forfeit_run_button: forfeit_run_button.visible = has_save
	if new_run_button: new_run_button.visible = not has_save

func _on_run_ended() -> void:
	var has_save: bool = FileLoader.has_save_file()
	visible = has_save
	update_continue_button_visibility()
