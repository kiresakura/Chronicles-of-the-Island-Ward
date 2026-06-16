# 鎮島錄 v0.3 — 五營戰鬥畫面（FC-2b.1a）。
#
# 程序化 UI（不依賴 .tscn，避免動巨型 Root.tscn），由 FC-2a FormationCombat 核心驅動。
# 換骨後的戰鬥畫面：玩家是壇主，把神將擺進五營攔截來煞，別讓煞破營直擊母壇。
# 十字佈局：母壇居中，東南西北四營各守一條 lane，中營為調度 reserve（左下）。
# 顯示文案全走 CSV key（tr）；戰況讀核心的結構化事件 log_events 再渲染（邏輯/顯示分離）。
# 觸控區 ≥88（鐵律 2 行動裝置優先）；無 hover 依賴。
#
# 接縫（FC-2b.1b 用）：外部呼叫 start(...) 開一場；勝→formation_won、敗→formation_lost。
extends Control

signal formation_won
signal formation_lost

const FormationCombatCls := preload("res://scripts/systems/ritual/FormationCombat.gd")
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

# 五行色（UI 呈現層；與得位星標一起讓玩家秒讀營位屬性）
const ELEMENT_COLOR := {
	"wood": Color(0.35, 0.66, 0.40), "fire": Color(0.86, 0.30, 0.20),
	"earth": Color(0.80, 0.64, 0.28), "metal": Color(0.82, 0.80, 0.62), "water": Color(0.30, 0.55, 0.82),
}
# 營位/煞道座標（1200×700 基準，十字佈局）
const CAMP_SIZE := Vector2(160, 104)
const LANE_SIZE := Vector2(130, 60)
const CAMP_POS := {
	"north": Vector2(370, 180), "south": Vector2(370, 470),
	"west": Vector2(150, 300), "east": Vector2(590, 300), "": Vector2(150, 470),
}
const LANE_POS := {
	"north": Vector2(385, 82), "south": Vector2(385, 608),
	"west": Vector2(12, 318), "east": Vector2(762, 318),
}
const PANEL_X := 910.0

var _core: FormationCombat
var _selected_unit: String = ""
var _started: bool = false
var _resolved: bool = false		# 勝負訊號只發一次

# UI 參照
var _camp_tiles: Dictionary = {}	# camp_id → {btn,name,occ,mark}
var _lane_markers: Dictionary = {}	# lane → Panel(含 Txt 子)
var _altar_bar: ProgressBar
var _altar_label: Label
var _turn_label: Label
var _action_label: Label
var _jiao_button: Button
var _deity_button: Button
var _end_turn_button: Button
var _log_label: Label
var _banner: Label
# 顯示名快取（由核心資料建，避免散落字面值）
var _lane_to_name: Dictionary = {}
var _camp_to_name: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	if not _started:
		# 獨立執行（場景直跑/模擬器）：開一場示範戰，方便驗手感
		start([], {}, _demo_enemy_specs(), 20260616)

## 外部入口（接縫用）：開一場。open_camp_ids 空＝全五營；deploy 空＝自動佈陣。
func start(open_camp_ids: Array, deploy: Dictionary, enemy_specs: Array, seed: int) -> void:
	_core = FormationCombatCls.new()
	_core.setup(open_camp_ids, deploy, enemy_specs, {}, seed)
	_started = true
	_resolved = false
	_selected_unit = ""
	_build_name_caches()
	if is_inside_tree():
		_refresh()

func _demo_enemy_specs() -> Array:
	return [{"id": "demo_a", "hp": 24}, {"id": "demo_b", "hp": 40}, {"id": "demo_c", "hp": 18}]

func _build_name_caches() -> void:
	_lane_to_name.clear()
	_camp_to_name.clear()
	for c: Dictionary in _core.camps:
		_camp_to_name[str(c.get("id"))] = str(c.get("name"))
		var lane: String = str(c.get("lane", ""))
		if lane != "":
			_lane_to_name[lane] = str(c.get("name"))

# ---- 版面 ----
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = THEME.get_color("combat_bg", Color(0.07, 0.04, 0.04))
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var title := Label.new()
	title.text = tr("combat.formation.title")
	title.position = Vector2(40, 18)
	title.add_theme_font_size_override("font_size", THEME.get_typography_size("title", 30))
	title.add_theme_color_override("font_color", THEME.get_color("incense_gold", Color(0.96, 0.84, 0.45)))
	add_child(title)

	var hint := Label.new()
	hint.text = tr("combat.formation.hint")
	hint.position = Vector2(40, 56)
	hint.size = Vector2(820, 24)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.90, 0.82, 0.70))
	add_child(hint)

	# lane 煞道標記（四方位）；營 tile 由核心提供的營在 _refresh 延遲建（依方位座標表定位）
	for lane: String in LANE_POS:
		_lane_markers[lane] = _make_lane_marker(LANE_POS[lane])
	_make_altar(Vector2(350, 300))

	# 右側控制面板
	_turn_label = _info_label(Vector2(PANEL_X, 86), 18, THEME.get_color("incense_gold", Color(0.96, 0.88, 0.62)))
	_action_label = _info_label(Vector2(PANEL_X, 120), 16, Color(0.92, 0.86, 0.70))

	_jiao_button = _make_action_button(Vector2(PANEL_X, 158), Color(0.36, 0.20, 0.46))
	_jiao_button.button_up.connect(_on_jiao)
	_deity_button = _make_action_button(Vector2(PANEL_X, 254), Color(0.20, 0.34, 0.46))
	_deity_button.button_up.connect(_on_deity)
	_end_turn_button = _make_action_button(Vector2(PANEL_X, 350), Color(0.74, 0.34, 0.14))
	_end_turn_button.button_up.connect(_on_end_turn)

	var log_head := _info_label(Vector2(PANEL_X, 452), 14, Color(0.80, 0.74, 0.64))
	log_head.text = tr("combat.formation.log_head")
	_log_label = Label.new()
	_log_label.position = Vector2(PANEL_X, 478)
	_log_label.size = Vector2(280, 210)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 13)
	_log_label.add_theme_color_override("font_color", Color(0.86, 0.80, 0.70))
	_log_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(_log_label)

	_banner = Label.new()
	_banner.position = Vector2(300, 296)
	_banner.size = Vector2(520, 108)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 52)
	_banner.visible = false
	add_child(_banner)

func _make_camp_tile(camp_id: String, pos: Vector2, is_reserve: bool) -> void:
	var btn := Button.new()
	btn.name = "Camp_" + camp_id
	btn.position = pos
	btn.size = CAMP_SIZE	# ≥88 觸控
	btn.focus_mode = Control.FOCUS_NONE
	btn.button_up.connect(_on_camp_pressed.bind(camp_id))
	add_child(btn)
	var name_label := Label.new()
	name_label.position = Vector2(0, 6)
	name_label.size = Vector2(CAMP_SIZE.x, 22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	btn.add_child(name_label)
	var occ_label := Label.new()
	occ_label.position = Vector2(0, 40)
	occ_label.size = Vector2(CAMP_SIZE.x, 40)
	occ_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	occ_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	occ_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	occ_label.add_theme_font_size_override("font_size", 15)
	btn.add_child(occ_label)
	var mark_label := Label.new()
	mark_label.position = Vector2(0, 82)
	mark_label.size = Vector2(CAMP_SIZE.x, 20)
	mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark_label.add_theme_font_size_override("font_size", 13)
	btn.add_child(mark_label)
	_camp_tiles[camp_id] = {"btn": btn, "name": name_label, "occ": occ_label, "mark": mark_label, "reserve": is_reserve}

func _make_lane_marker(pos: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = LANE_SIZE
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	var l := Label.new()
	l.name = "Txt"
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)
	p.add_child(l)
	return p

func _make_altar(pos: Vector2) -> void:
	var panel := Panel.new()
	panel.name = "Altar"
	panel.position = pos
	panel.size = Vector2(200, 96)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.08, 0.05, 0.95)
	sb.border_color = THEME.get_color("incense_gold", Color(0.95, 0.82, 0.45))
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	_altar_label = Label.new()
	_altar_label.position = Vector2(0, 8)
	_altar_label.size = Vector2(200, 24)
	_altar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_altar_label.add_theme_font_size_override("font_size", 18)
	_altar_label.add_theme_color_override("font_color", THEME.get_color("incense_gold", Color(0.96, 0.84, 0.45)))
	panel.add_child(_altar_label)
	_altar_bar = ProgressBar.new()
	_altar_bar.position = Vector2(14, 44)
	_altar_bar.size = Vector2(172, 32)
	_altar_bar.show_percentage = false
	panel.add_child(_altar_bar)

func _info_label(pos: Vector2, fsize: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(280, 28)
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	add_child(l)
	return l

func _make_action_button(pos: Vector2, col: Color) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(270, 88)	# ≥88 觸控
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = THEME.get_color("incense_gold", Color(0.95, 0.84, 0.50))
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	add_child(b)
	return b

# ---- 互動 ----
func _on_camp_pressed(camp_id: String) -> void:
	if _core == null or _core.state != FormationCombatCls.STATE_PLAYING:
		return
	if _selected_unit == "":
		var uid: String = _core._unit_in_camp(camp_id)
		if uid != "":
			_selected_unit = uid
	else:
		_core.move_unit(_selected_unit, camp_id)
		_selected_unit = ""
	_refresh()

func _on_jiao() -> void:
	if _core == null:
		return
	_core.roll_jiao()
	_refresh()

func _on_deity() -> void:
	if _core == null:
		return
	_core.invoke_deity()
	_refresh()

func _on_end_turn() -> void:
	if _core == null:
		return
	_selected_unit = ""
	_core.end_turn()
	_refresh()

# ---- 重繪 ----
func _refresh() -> void:
	if _core == null:
		return
	# 營位（依核心提供的營，首次延遲建 tile）
	for c: Dictionary in _core.camps:
		var cid: String = str(c.get("id"))
		if not _camp_tiles.has(cid):
			var lane: String = str(c.get("lane", ""))
			var pos: Vector2 = CAMP_POS.get(lane, CAMP_POS[""])
			_make_camp_tile(cid, pos, lane == "")
		_refresh_camp_tile(c)
	# lane 煞標記
	for lane: String in _lane_markers:
		_refresh_lane_marker(lane)
	# 母壇
	_altar_bar.max_value = _core.altar_max
	_altar_bar.value = _core.altar_integrity
	_altar_label.text = tr("combat.formation.altar_hp") % [_core.altar_integrity, _core.altar_max]
	# 控制面板
	_turn_label.text = tr("combat.formation.turn") % _core.turn
	var jiao_state: String = tr("combat.formation.jiao_done") if _core.jiao_rolled_this_turn else tr("combat.formation.jiao_ready")
	_action_label.text = (tr("combat.formation.actions") % _core.actions_remaining) + "  " + jiao_state
	_jiao_button.text = tr("combat.formation.jiao_btn")
	_jiao_button.disabled = _core.jiao_rolled_this_turn or _core.state != FormationCombatCls.STATE_PLAYING
	var deity_ready: bool = _core.deity_charge >= _core.deity_charge_max
	_deity_button.text = tr("combat.formation.deity_btn") if deity_ready else (tr("combat.formation.deity_charging") % [_core.deity_charge, _core.deity_charge_max])
	_deity_button.disabled = not deity_ready or _core.state != FormationCombatCls.STATE_PLAYING
	_end_turn_button.text = tr("combat.formation.end_turn")
	_end_turn_button.disabled = _core.state != FormationCombatCls.STATE_PLAYING
	# 戰況
	_log_label.text = _build_log_text()
	# 勝負
	_update_banner()

func _refresh_camp_tile(c: Dictionary) -> void:
	var cid: String = str(c.get("id"))
	var t: Dictionary = _camp_tiles[cid]
	var element: String = str(c.get("element"))
	var el_col: Color = ELEMENT_COLOR.get(element, Color(0.6, 0.6, 0.6))
	(t["name"] as Label).text = str(c.get("name"))
	(t["name"] as Label).add_theme_color_override("font_color", el_col)
	var occ_uid: String = _core._unit_in_camp(cid)
	var occ_label := t["occ"] as Label
	var mark_label := t["mark"] as Label
	if occ_uid != "":
		var uname: String = str(_core.units[occ_uid].get("name"))
		occ_label.text = uname
		occ_label.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82))
		if _core.is_wei_position(occ_uid, cid):
			mark_label.text = "★ " + tr("combat.formation.wei")
			mark_label.add_theme_color_override("font_color", THEME.get_color("incense_gold", Color(0.96, 0.84, 0.45)))
		else:
			mark_label.text = ""
	else:
		occ_label.text = tr("combat.formation.reserve") if bool(t.get("reserve")) else ""
		occ_label.add_theme_color_override("font_color", Color(0.6, 0.56, 0.5))
		mark_label.text = ""
	# 邊框：選起該營占用者時高亮
	var btn := t["btn"] as Button
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.10, 0.09, 0.92)
	sb.set_corner_radius_all(8)
	var selected: bool = occ_uid != "" and occ_uid == _selected_unit
	sb.border_color = THEME.get_color("incense_gold", Color(0.96, 0.84, 0.45)) if selected else el_col
	sb.set_border_width_all(4 if selected else 2)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

func _refresh_lane_marker(lane: String) -> void:
	var p: Panel = _lane_markers[lane]
	var txt := p.get_node("Txt") as Label
	var sha: Variant = _core.lanes[lane]["sha"] if _core.lanes.has(lane) else null
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	if sha == null:
		txt.text = tr("combat.formation.lane_clear")
		txt.add_theme_color_override("font_color", Color(0.5, 0.48, 0.44))
		sb.bg_color = Color(0.12, 0.12, 0.10, 0.6)
		sb.border_color = Color(0.3, 0.3, 0.28)
	else:
		txt.text = tr("combat.formation.sha_marker") % [int(sha["strength"]), int(sha["steps"])]
		txt.add_theme_color_override("font_color", Color(0.98, 0.86, 0.7))
		sb.bg_color = Color(0.42, 0.10, 0.10, 0.85)
		sb.border_color = Color(0.9, 0.4, 0.3)
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)

func _build_log_text() -> String:
	var lines: Array[String] = []
	var events: Array = _core.log_events
	var start_idx: int = maxi(0, events.size() - 10)
	for i: int in range(start_idx, events.size()):
		var line: String = _render_log_event(events[i])
		if line != "":
			lines.append(line)
	return "\n".join(lines)

func _render_log_event(ev: Dictionary) -> String:
	match str(ev.get("t", "")):
		FormationCombatCls.EV_SHA_SPAWN:
			return tr("combat.log.sha_spawn") % [_lane_disp(str(ev.get("lane"))), int(ev.get("strength"))]
		FormationCombatCls.EV_INTERCEPT:
			return tr("combat.log.intercept") % [_unit_disp(str(ev.get("unit"))), int(ev.get("dmg"))]
		FormationCombatCls.EV_SHA_BREAK:
			return tr("combat.log.sha_break") % _lane_disp(str(ev.get("lane")))
		FormationCombatCls.EV_EMPTY_CAMP:
			return tr("combat.log.empty_camp") % _camp_disp(str(ev.get("camp")))
		FormationCombatCls.EV_ALTAR_HIT:
			return tr("combat.log.altar_hit") % int(ev.get("amount"))
		FormationCombatCls.EV_JIAO:
			match str(ev.get("result")):
				FormationCombatCls.JIAO_SHENG:
					return tr("combat.log.jiao_sheng") % int(ev.get("bonus", 0))
				FormationCombatCls.JIAO_XIAO:
					return tr("combat.log.jiao_xiao")
				FormationCombatCls.JIAO_YIN:
					return tr("combat.log.jiao_yin")
		FormationCombatCls.EV_YIN_SURGE:
			return tr("combat.log.yin_surge") % [_lane_disp(str(ev.get("lane"))), int(ev.get("amount"))]
		FormationCombatCls.EV_DEITY:
			return tr("combat.log.deity") % int(ev.get("hit"))
	return ""

func _update_banner() -> void:
	if _core.state == FormationCombatCls.STATE_PLAYING:
		_banner.visible = false
		return
	_banner.visible = true
	if _core.state == FormationCombatCls.STATE_WON:
		_banner.text = tr("combat.formation.win")
		_banner.add_theme_color_override("font_color", Color(0.55, 0.92, 0.55))
		if not _resolved:
			_resolved = true
			formation_won.emit()
	else:
		_banner.text = tr("combat.formation.lose")
		_banner.add_theme_color_override("font_color", Color(0.95, 0.45, 0.40))
		if not _resolved:
			_resolved = true
			formation_lost.emit()

# ---- 顯示名（由核心資料；非字面值）----
func _lane_disp(lane: String) -> String:
	return str(_lane_to_name.get(lane, lane))

func _camp_disp(camp_id: String) -> String:
	return str(_camp_to_name.get(camp_id, camp_id))

func _unit_disp(uid: String) -> String:
	if _core.units.has(uid):
		return str(_core.units[uid].get("name"))
	return uid
