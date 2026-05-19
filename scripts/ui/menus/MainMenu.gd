# 鎮島錄 — 主畫面（全向量重build）
#
# 設計：用戶 V5 mockup（廟宇 lobby）。全部 chrome 為程序化向量（StyleBox + 自繪背景），
# icon 為 SVG（assets/ui/icons/*.svg，靠 modulate 上色 / 狀態變化）。
# 既有 Root.tscn 的節點（QiJiaButton / Btn* / VBoxContainer 邏輯鈕）保留以維持
# TitleScreen 導航與存檔邏輯；視覺層在此程式化重built，幾乎不動龐大的 .tscn。
extends Control

const ICON_DIR := "res://assets/ui/icons/"
const BACKDROP_SCRIPT := preload("res://scripts/ui/menus/VectorTempleBackdrop.gd")
const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

# 廟會配色 —— 品牌主色（金）由 design_tokens.json 透過 CotiwUiTheme 提供，
# 在 _ready() 賦值，確保與全遊戲一致、可隨 token 換膚。
# PANEL_* 為主畫面 chrome 專用表面色（設計系統未定義鎖態 token），保留為本地常數。
var GOLD: Color = Color(0.95, 0.82, 0.45)
var GOLD_DIM: Color = Color(0.62, 0.49, 0.24)
const PANEL_BG := Color(0.20, 0.07, 0.06, 0.92)
const PANEL_BG_HOVER := Color(0.34, 0.11, 0.09, 0.96)
const PANEL_BG_LOCK := Color(0.13, 0.09, 0.09, 0.80)

# 底部 7 格：id, 中文, icon, 是否已開放（false → 即將推出 toast）
const SLOTS := [
	{"node": "BtnCharacter", "label": "角色", "icon": "icon_character", "ready": false},
	{"node": "BtnFormation", "label": "陣型", "icon": "icon_formation", "ready": false},
	{"node": "BtnBattle",    "label": "戰鬥", "icon": "icon_battle",    "ready": true,  "act": "run"},
	{"node": "BtnShop",      "label": "商店", "icon": "icon_shop",      "ready": false},
	{"node": "BtnRecruit",   "label": "招募", "icon": "icon_recruit",   "ready": false},
	{"node": "BtnInventory", "label": "收藏", "icon": "icon_codex",     "ready": true,  "act": "codex"},
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

var _toast: Label
var _toast_tween: Tween
var _res_incense: Label
var _res_level: Label
var _res_yuanbao: Label
var _level_fill: ColorRect

func _ready() -> void:
	# 品牌金色取自 design_tokens.json（與全遊戲 CotiwUiTheme 一致）
	GOLD = COTIW_UI_THEME.get_color("incense_gold", GOLD)
	GOLD_DIM = COTIW_UI_THEME.get_color("old_gold", GOLD_DIM)
	_hide_legacy_nodes()
	_add_backdrop()
	_build_avatar()
	_build_resource_bars()
	_build_slots()
	_build_utilities()
	_build_primary()
	_build_toast()

	Signals.run_ended.connect(_on_run_ended)
	update_continue_button_visibility()
	_refresh_resources()

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
	var bg := Control.new()
	bg.name = "VectorBackdrop"
	bg.set_script(BACKDROP_SCRIPT)
	bg.anchor_left = 0.0
	bg.anchor_top = 0.0
	bg.anchor_right = 0.0
	bg.anchor_bottom = 0.0
	bg.offset_left = 0.0
	bg.offset_top = 0.0
	bg.offset_right = 1200.0
	bg.offset_bottom = 700.0
	add_child(bg)
	move_child(bg, 0)

# ---------- StyleBox：委派全專案共用工廠（CotiwUiTheme） ----------
# 保留本地 _sb() 簽名（bg, border, bw, radius）以維持呼叫端不變，
# 但實際建構統一走 CotiwUiTheme.make_stylebox，圓角/邊框/陰影語言全遊戲一致。

func _sb(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	return COTIW_UI_THEME.make_stylebox(bg, border, radius, bw)

# ---------- 左上角：玩家頭像框 ----------

func _build_avatar() -> void:
	var frame := Panel.new()
	frame.name = "AvatarFrame"
	frame.position = Vector2(20, 16)
	frame.size = Vector2(64, 64)
	frame.add_theme_stylebox_override("panel", _sb(PANEL_BG, GOLD, 3, 8))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	var ic := TextureRect.new()
	ic.texture = _load_icon("icon_avatar_tongji")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic.offset_left = 8; ic.offset_top = 8; ic.offset_right = -8; ic.offset_bottom = -8
	ic.modulate = GOLD
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(ic)

	var lv := Label.new()
	lv.name = "AvatarLv"
	lv.position = Vector2(20, 80)
	lv.size = Vector2(64, 20)
	lv.text = "Lv 1"
	lv.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_font(lv, 16)
	add_child(lv)

# ---------- 左上：3 條資源條（香火 / 等級 / 元寶） ----------

func _build_resource_bars() -> void:
	_res_incense = _make_resource_row(0, "icon_incense", GOLD)
	var lvl := _make_resource_row(1, "icon_level", Color(0.96, 0.78, 0.40))
	_res_level = lvl
	_res_yuanbao = _make_resource_row(2, "icon_yuanbao", Color(0.55, 0.78, 0.95))

func _make_resource_row(idx: int, icon: String, tint: Color) -> Label:
	var y := 20.0 + idx * 34.0
	var ic := TextureRect.new()
	ic.texture = _load_icon(icon)
	ic.position = Vector2(100, y)
	ic.size = Vector2(24, 24)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.modulate = tint
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ic)

	var pill := Panel.new()
	pill.position = Vector2(130, y)
	pill.size = Vector2(190, 24)
	pill.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.03, 0.03, 0.78), GOLD_DIM, 2, 12))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pill)

	if idx == 1:
		# 等級列：xp 進度填充
		_level_fill = ColorRect.new()
		_level_fill.position = Vector2(133, y + 3)
		_level_fill.size = Vector2(60, 18)
		_level_fill.color = Color(0.96, 0.62, 0.24, 0.55)
		_level_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_level_fill)

	var lbl := Label.new()
	lbl.position = Vector2(138, y)
	lbl.size = Vector2(178, 24)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gold_font(lbl, 16)
	add_child(lbl)
	return lbl

# ---------- 底部 7 格 slot ----------

func _build_slots() -> void:
	var small := Vector2(86, 84)
	# 左 3 / 右 3 對稱排列（中央留給起駕大鈕）
	var xs := [70.0, 166.0, 262.0, 762.0, 858.0, 954.0]
	for i in SLOTS.size():
		var data: Dictionary = SLOTS[i]
		if not has_node(data["node"]):
			continue
		var btn: Button = get_node(data["node"])
		btn.flat = false
		btn.position = Vector2(xs[i], 606)
		btn.size = small
		btn.pivot_offset = small * 0.5
		btn.focus_mode = Control.FOCUS_NONE
		btn.disabled = false
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_slot_style(btn, data["ready"])
		_set_slot_content(btn, data["icon"], data["label"], data["ready"])
		_hook_hover(btn)
		# 連線（先斷既有再連）
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
	ic.position = Vector2(23, 10)
	ic.size = Vector2(40, 40)
	ic.modulate = tint
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lbl := btn.get_node_or_null("Label") as Label
	if lbl == null:
		lbl = Label.new()
		lbl.name = "Label"
		btn.add_child(lbl)
	lbl.text = label_text
	lbl.position = Vector2(0, 54)
	lbl.size = Vector2(86, 24)
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
	lock.position = Vector2(60, 6)
	lock.size = Vector2(22, 22)
	lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_gold_font(lock, 13)
	lock.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lock)

# ---------- 中央：起駕 / 繼續 主鈕 ----------

func _build_primary() -> void:
	if qi_jia_button == null:
		return
	var b := qi_jia_button
	b.flat = false
	b.position = Vector2(458, 596)
	b.size = Vector2(284, 96)
	b.pivot_offset = b.size * 0.5
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# 起駕＝主 CTA：直接套用設計系統 primary 按鈕樣式（token 驅動，全遊戲一致）
	COTIW_UI_THEME.apply_primary_button_style(b)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	# 僅覆寫字級與陰影；字色沿用設計系統 primary 文字色（paper_warm）
	b.add_theme_font_size_override("font_size", 52)
	b.add_theme_constant_override("shadow_offset_x", 2)
	b.add_theme_constant_override("shadow_offset_y", 2)
	b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))

	var ic := TextureRect.new()
	ic.name = "Icon"
	ic.texture = _load_icon("icon_qijia")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = Vector2(20, 26)
	ic.size = Vector2(44, 44)
	ic.modulate = GOLD
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)

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

# ---------- 右上：3 工具鈕（設定 / 信件 / 成就）+ ✕ ----------

func _build_utilities() -> void:
	var defs := [
		{"icon": "icon_settings", "name": "設定"},
		{"icon": "icon_mail",     "name": "信件"},
		{"icon": "icon_achieve",  "name": "成就"},
	]
	for i in defs.size():
		var u := Button.new()
		u.name = "Util%d" % i
		u.position = Vector2(1006 + i * 50, 18)
		u.size = Vector2(44, 44)
		u.pivot_offset = Vector2(22, 22)
		u.flat = false
		u.focus_mode = Control.FOCUS_NONE
		u.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		u.add_theme_stylebox_override("normal", _sb(PANEL_BG, GOLD_DIM, 2, 8))
		u.add_theme_stylebox_override("hover", _sb(PANEL_BG_HOVER, GOLD, 2, 8))
		u.add_theme_stylebox_override("pressed", _sb(PANEL_BG.darkened(0.15), GOLD, 2, 8))
		u.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		add_child(u)
		var ic := TextureRect.new()
		ic.texture = _load_icon(defs[i]["icon"])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = 9; ic.offset_top = 9; ic.offset_right = -9; ic.offset_bottom = -9
		ic.modulate = GOLD
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		u.add_child(ic)
		u.button_up.connect(_show_coming_soon.bind(defs[i]["name"]))
		_hook_hover(u)

	# ✕ 離開（最右上角）
	if btn_exit_x:
		btn_exit_x.position = Vector2(1158, 16)
		btn_exit_x.size = Vector2(34, 34)
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

# ---------- Toast：即將推出 ----------

func _build_toast() -> void:
	_toast = Label.new()
	_toast.name = "Toast"
	_toast.position = Vector2(420, 470)
	_toast.size = Vector2(360, 52)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast.add_theme_stylebox_override("normal", _sb(Color(0.10, 0.05, 0.05, 0.94), GOLD, 2, 10))
	_gold_font(_toast, 22)
	_toast.modulate = Color(1, 1, 1, 0)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)

func _show_coming_soon(feature_name: String) -> void:
	_toast.text = "「%s」即將推出" % feature_name
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast.modulate = Color(1, 1, 1, 0)
	_toast.position.y = 470
	_toast_tween = create_tween()
	_toast_tween.set_trans(Tween.TRANS_SINE)
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.18)
	_toast_tween.parallel().tween_property(_toast, "position:y", 452.0, 0.18)
	_toast_tween.tween_interval(1.1)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)

# ---------- 互動回饋：hover/press 縮放微動 ----------

func _hook_hover(c: Control) -> void:
	c.mouse_entered.connect(func(): _scale_to(c, 1.05))
	c.mouse_exited.connect(func(): _scale_to(c, 1.0))
	if c is BaseButton:
		c.button_down.connect(func(): _scale_to(c, 0.95))
		c.button_up.connect(func(): _scale_to(c, 1.05 if c.get_global_rect().has_point(get_global_mouse_position()) else 1.0))

func _scale_to(c: Control, s: float) -> void:
	if c == qi_jia_button:
		return  # 起駕有自己的呼吸 tween，不覆寫
	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "scale", Vector2(s, s), 0.12)

# ---------- 起駕呼吸脈動 ----------

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

# ---------- 資源刷新（防禦式讀 profile，缺欄位用 fallback） ----------

func _refresh_resources() -> void:
	var incense := _profile_int("profile_incense", 250)
	var yuanbao := _profile_int("profile_yuanbao", 0)
	var wins := _profile_int("profile_total_wins", 0)
	var level: int = 1 + int(wins / 3)
	var xp_in_level: int = wins % 3
	if _res_incense: _res_incense.text = "香火  %d" % incense
	if _res_yuanbao: _res_yuanbao.text = "元寶  %d" % yuanbao
	if _res_level: _res_level.text = "Lv %d   %d/3" % [level, xp_in_level]
	if _level_fill: _level_fill.size.x = 4 + 182.0 * (float(xp_in_level) / 3.0)
	var av := get_node_or_null("AvatarLv") as Label
	if av: av.text = "Lv %d" % level

func _profile_int(field: String, fallback: int) -> int:
	if Global.profile_data and field in Global.profile_data:
		var v := int(Global.profile_data.get(field))
		if v > 0:
			return v
	return fallback

# ---------- 字型 helper ----------

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
	# 中央主鈕：有存檔 → 繼續；否則 → 起駕
	if qi_jia_button:
		qi_jia_button.text = "繼　續" if has_save else "起　駕"
	# 隱藏的 STR 邏輯鈕仍維持狀態（callbacks 用）
	if continue_button: continue_button.visible = has_save
	if forfeit_run_button: forfeit_run_button.visible = has_save
	if new_run_button: new_run_button.visible = not has_save

func _on_run_ended() -> void:
	var has_save: bool = FileLoader.has_save_file()
	visible = has_save
	update_continue_button_visibility()
