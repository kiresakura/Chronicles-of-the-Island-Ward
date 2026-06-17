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
const AffinityCls := preload("res://scripts/systems/ritual/AffinitySystem.gd")
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const BackdropCls := preload("res://scripts/ui/FiveCampBackdrop.gd")

# 五行色（UI 呈現層；只當「元素小章」一抹色，不再染整框 → 避免火營紅框被誤讀成敵方）
const ELEMENT_COLOR := {
	"wood": Color(0.35, 0.66, 0.40), "fire": Color(0.86, 0.30, 0.20),
	"earth": Color(0.80, 0.64, 0.28), "metal": Color(0.82, 0.80, 0.62), "water": Color(0.30, 0.55, 0.82),
}
# 敵我語言（UIUX §C：一眼分敵我）。我營一律燙金/玉青，來煞一律硃砂。
const FRIEND_GOLD := Color(0.93, 0.78, 0.42)		# 我營常態框（燙金）
const FRIEND_JADE := Color(0.42, 0.80, 0.60)		# 得位加持（玉青）
const FOE_RED := Color(0.90, 0.32, 0.24)			# 來煞/告急（硃砂）
const CAMP_BG := Color(0.10, 0.06, 0.05, 0.96)		# 我營暗漆底（高對比墊燙金框）
const ALTAR_BG := Color(0.17, 0.09, 0.05, 0.97)		# 母壇暖漆底（聖域）
# 營位/煞道座標（1200×700 基準，緊湊十字佈局；底部留符令手牌列）
const CAMP_SIZE := Vector2(150, 96)
const LANE_SIZE := Vector2(120, 50)
const CAMP_POS := {
	"north": Vector2(415, 150), "south": Vector2(415, 390),
	"west": Vector2(215, 270), "east": Vector2(615, 270), "": Vector2(215, 390),
}
const LANE_POS := {
	"north": Vector2(430, 92), "south": Vector2(430, 510),
	"west": Vector2(70, 290), "east": Vector2(790, 290),
}
const ALTAR_POS := Vector2(415, 270)
const ALTAR_SIZE := Vector2(150, 96)
const PANEL_X := 920.0
const FU_HAND_Y := 584.0			# 底部符令手牌列
const FU_BTN_SIZE := Vector2(150, 96)
const FU_SLOTS := 5					# 手牌顯示槽位數（= hand_max）
const DESIGN_SIZE := Vector2(1200, 700)		# 設計畫布；依裝置安全區置中+fit縮放（避免截斷/偏移）

var embedded: bool = false		# true＝由 Combat 接縫嵌入（_ready 不自動跑示範戰，等外部 start）
var _core: FormationCombat
var _selected_unit: String = ""
var _started: bool = false
var _resolved: bool = false		# 勝負訊號只發一次

# UI 參照
var _camp_tiles: Dictionary = {}	# camp_id → {btn,name,occ,mark}
var _lane_markers: Dictionary = {}	# lane → Panel(含 Txt 子)
var _altar_bar: ProgressBar
var _altar_label: Label
var _altar_panel: Panel
var _turn_label: Label
var _action_label: Label
var _jiao_button: Button
var _deity_button: Button
var _end_turn_button: Button
var _log_label: Label
var _banner: Label
var _affinity_strip: Label		# 緣分合祀提示帶（FC-6c）
var _stage: Control				# 1200×700 設計畫布（內容掛此；依安全區置中+fit縮放）
# 符令手牌（FP-2）
var _fu_slots: Array = []		# 底部手牌槽（Button），idx 對 core.fu_hand[idx]
var _fu_prompt: Label			# 提示/選方位
var _pending_fu: String = ""	# needs_target 符令選取中，等點方位營
# 顯示名快取（由核心資料建，避免散落字面值）
var _lane_to_name: Dictionary = {}
var _camp_to_name: Dictionary = {}
var _camp_to_lane: Dictionary = {}		# camp_id → lane（符令選方位用）

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_fit_stage()
	# 視窗/安全區變動時重新置中縮放（接 Responsive autoload；無則靠自身 resized）
	var resp: Node = get_node_or_null("/root/Responsive")
	if resp != null and resp.has_signal("changed") and not resp.changed.is_connected(_fit_stage):
		resp.changed.connect(_fit_stage)
	if not resized.is_connected(_fit_stage):
		resized.connect(_fit_stage)
	if not _started and not embedded:
		# 獨立執行（場景直跑/模擬器）：開一場示範戰，方便驗手感。嵌入接縫時由 Combat 呼叫 start。
		start([], {}, _demo_enemy_specs(), 20260616)

## 把 1200×700 設計畫布依裝置安全區置中 + fit 縮放（寬螢幕不偏移、瀏海不截斷；不放大保像素清晰）。
func _fit_stage() -> void:
	if _stage == null:
		return
	var safe: Rect2 = THEME.get_safe_content_rect()
	if safe.size.x <= 0.0 or safe.size.y <= 0.0:
		return
	var t: Dictionary = compute_stage_transform(safe, DESIGN_SIZE)
	_stage.scale = Vector2(t["scale"], t["scale"])
	_stage.position = t["position"]

## 純函式（可測）：算設計畫布在安全區內的「置中 + fit 縮放（不放大）」變換。
## 保證縮放後整塊落在安全區內（不溢出＝不截斷）。
static func compute_stage_transform(safe: Rect2, design: Vector2) -> Dictionary:
	var s: float = minf(minf(safe.size.x / design.x, safe.size.y / design.y), 1.0)
	return {"scale": s, "position": safe.position + (safe.size - design * s) * 0.5}

## 外部入口（接縫用）：開一場。open_camp_ids 空＝全五營；deploy 空＝自動佈陣。
## config 預設 {}（讀檔調參）；測試可注入（含 fu_config）求確定性。
func start(open_camp_ids: Array, deploy: Dictionary, enemy_specs: Array, seed: int, config: Dictionary = {}) -> void:
	_core = FormationCombatCls.new()
	_core.setup(open_camp_ids, deploy, enemy_specs, config, seed)
	_started = true
	_resolved = false
	_selected_unit = ""
	_pending_fu = ""
	_build_name_caches()
	if is_inside_tree():
		_refresh()

func _demo_enemy_specs() -> Array:
	return [{"id": "demo_a", "hp": 24}, {"id": "demo_b", "hp": 40}, {"id": "demo_c", "hp": 18}]

func _build_name_caches() -> void:
	_lane_to_name.clear()
	_camp_to_name.clear()
	_camp_to_lane.clear()
	for c: Dictionary in _core.camps:
		var cid: String = str(c.get("id"))
		_camp_to_name[cid] = str(c.get("name"))
		var lane: String = str(c.get("lane", ""))
		_camp_to_lane[cid] = lane
		if lane != "":
			_lane_to_name[lane] = str(c.get("name"))

# ---- 版面 ----
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = THEME.get_color("combat_bg", Color(0.06, 0.035, 0.035))
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)	# 背景填滿整個 viewport（letterbox 區也暗）

	# 暗角 vignette（全視窗徑向漸層；把焦點壓回盤面中央，零素材）
	var vig := TextureRect.new()
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.texture = _make_vignette_texture()
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(vig)

	# 設計畫布：所有內容掛此，依安全區置中+fit縮放
	_stage = Control.new()
	_stage.size = DESIGN_SIZE
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage)

	# 五營羅盤（程序化，墊 _stage 最底；母壇為心）
	var backdrop: Control = BackdropCls.new()
	backdrop.size = DESIGN_SIZE
	backdrop.altar_center = ALTAR_POS + ALTAR_SIZE * 0.5
	_stage.add_child(backdrop)

	# 硃砂帶標題（廟會 chrome：硃砂底 + 燙金字 + 硬邊）
	var title_band := Panel.new()
	title_band.position = Vector2(28, 12)
	title_band.size = Vector2(188, 44)
	title_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_band.add_theme_stylebox_override("panel", THEME.make_stylebox(
		THEME.get_color("festival_red", Color(0.56, 0.16, 0.11)), FRIEND_GOLD, 0, 3, 0.0))
	_stage.add_child(title_band)
	var title := Label.new()
	title.text = tr("combat.formation.title")
	title.position = Vector2(44, 16)
	title.add_theme_font_size_override("font_size", THEME.get_typography_size("title", 30))
	title.add_theme_color_override("font_color", FRIEND_GOLD)
	_stage.add_child(title)

	var hint := Label.new()
	hint.text = tr("combat.formation.hint")
	hint.position = Vector2(40, 60)
	hint.size = Vector2(820, 24)
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(0.90, 0.82, 0.70))
	_stage.add_child(hint)

	_build_legend()

	# 緣分合祀提示帶（FC-6c）：頂部、標題與控制面板之間；啟用合祀時亮金
	_affinity_strip = Label.new()
	_affinity_strip.position = Vector2(330, 22)
	_affinity_strip.size = Vector2(560, 28)
	_affinity_strip.add_theme_font_size_override("font_size", 17)
	_affinity_strip.add_theme_color_override("font_color", THEME.get_color("incense_gold", Color(0.96, 0.84, 0.45)))
	_stage.add_child(_affinity_strip)

	# lane 煞道標記（四方位）；營 tile 由核心提供的營在 _refresh 延遲建（依方位座標表定位）
	for lane: String in LANE_POS:
		_lane_markers[lane] = _make_lane_marker(LANE_POS[lane])
	_make_altar(ALTAR_POS)

	# 底部符令手牌列（FP-2）+ 選方位提示
	_build_fu_hand()

	# 右側控制面板
	_turn_label = _info_label(Vector2(PANEL_X, 86), 18, THEME.get_color("incense_gold", Color(0.96, 0.88, 0.62)))
	_action_label = _info_label(Vector2(PANEL_X, 118), 16, Color(0.92, 0.86, 0.70))

	_jiao_button = _make_action_button(Vector2(PANEL_X, 155), Color(0.36, 0.20, 0.46))
	_jiao_button.button_up.connect(_on_jiao)
	_deity_button = _make_action_button(Vector2(PANEL_X, 255), Color(0.20, 0.34, 0.46))
	_deity_button.button_up.connect(_on_deity)
	_end_turn_button = _make_action_button(Vector2(PANEL_X, 355), Color(0.74, 0.34, 0.14))
	_end_turn_button.button_up.connect(_on_end_turn)

	var log_head := _info_label(Vector2(PANEL_X, 458), 14, Color(0.80, 0.74, 0.64))
	log_head.text = tr("combat.formation.log_head")
	_log_label = Label.new()
	_log_label.position = Vector2(PANEL_X, 480)
	_log_label.size = Vector2(260, 200)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.add_theme_font_size_override("font_size", 13)
	_log_label.add_theme_color_override("font_color", Color(0.86, 0.80, 0.70))
	_log_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_stage.add_child(_log_label)

	_banner = Label.new()
	_banner.position = Vector2(300, 296)
	_banner.size = Vector2(520, 108)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 52)
	_banner.visible = false
	_stage.add_child(_banner)

## 常駐圖例（RichTextLabel，色塊配字；新手秒讀盤面語言）。文案全走 tr（i18n 清零）。
func _build_legend() -> void:
	var legend := RichTextLabel.new()
	legend.name = "Legend"
	legend.bbcode_enabled = true
	legend.fit_content = true
	legend.scroll_active = false
	legend.position = Vector2(916, 16)
	legend.size = Vector2(266, 56)
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	legend.add_theme_font_size_override("normal_font_size", 14)
	legend.text = "[color=#eec86a]◆[/color] %s   [color=#6ad29a]★[/color] %s\n[color=#e65240]▲[/color] %s   [color=#eec86a]▣[/color] %s" % [
		tr("combat.legend.ours"), tr("combat.formation.wei"),
		tr("combat.legend.sha"), tr("combat.legend.altar")]
	_stage.add_child(legend)

## 徑向漸層 vignette 紋理（中心透明 → 四角壓暗）。
func _make_vignette_texture() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.10), Color(0, 0, 0, 0.62)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t

## 母壇聖光暈紋理（金光中心 → 透明邊；低 alpha）。
func _make_altar_glow_texture() -> Texture2D:
	var gold: Color = THEME.get_color("incense_gold", FRIEND_GOLD)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([
		Color(gold.r, gold.g, gold.b, 0.22), Color(gold.r, gold.g, gold.b, 0.08), Color(gold.r, gold.g, gold.b, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	return t

func _make_camp_tile(camp_id: String, pos: Vector2, is_reserve: bool) -> void:
	var btn := Button.new()
	btn.name = "Camp_" + camp_id
	btn.position = pos
	btn.size = CAMP_SIZE	# ≥88 觸控
	btn.focus_mode = Control.FOCUS_NONE
	btn.button_up.connect(_on_camp_pressed.bind(camp_id))
	_stage.add_child(btn)
	var name_label := Label.new()
	name_label.position = Vector2(0, 6)
	name_label.size = Vector2(CAMP_SIZE.x, 22)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	btn.add_child(name_label)
	var occ_label := Label.new()
	occ_label.position = Vector2(0, 38)
	occ_label.size = Vector2(CAMP_SIZE.x, 32)
	occ_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	occ_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	occ_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	occ_label.add_theme_font_size_override("font_size", 15)
	btn.add_child(occ_label)
	var mark_label := Label.new()
	mark_label.position = Vector2(0, 73)
	mark_label.size = Vector2(CAMP_SIZE.x, 21)
	mark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark_label.add_theme_font_size_override("font_size", 13)
	btn.add_child(mark_label)
	# 元素小章（左上一抹色；元素資訊不再染整框 → 敵我語言不被五行色干擾）
	var chip := ColorRect.new()
	chip.name = "ElemChip"
	chip.position = Vector2(8, 8)
	chip.size = Vector2(13, 13)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(chip)
	_camp_tiles[camp_id] = {"btn": btn, "name": name_label, "occ": occ_label, "mark": mark_label, "chip": chip, "reserve": is_reserve}

func _make_lane_marker(pos: Vector2) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = LANE_SIZE
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(p)
	var l := Label.new()
	l.name = "Txt"
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)
	p.add_child(l)
	return p

func _make_altar(pos: Vector2) -> void:
	# 母壇＝盤面焦點：放大（182×122 vs 營 150×96）、雙金框聖域、置中於原設計座標。
	var center: Vector2 = pos + ALTAR_SIZE * 0.5
	var asize := Vector2(182, 122)
	# 母壇聖光暈（靜態一拍：母壇「在發光」的神聖能量；低 alpha 不洗白，墊於壇框之後）
	var glow := TextureRect.new()
	glow.texture = _make_altar_glow_texture()
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gsize := Vector2(304, 244)
	glow.position = center - gsize * 0.5
	glow.size = gsize
	_stage.add_child(glow)
	_altar_panel = Panel.new()
	_altar_panel.name = "Altar"
	_altar_panel.position = center - asize * 0.5
	_altar_panel.size = asize
	_altar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_altar_panel.add_theme_stylebox_override("panel", THEME.make_stylebox(ALTAR_BG, FRIEND_GOLD, 0, 4, 0.0))
	_stage.add_child(_altar_panel)
	# 內金線（雙框聖域感）
	var inner := Panel.new()
	inner.position = Vector2(6, 6)
	inner.size = asize - Vector2(12, 12)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_stylebox_override("panel", THEME.make_stylebox(
		Color(0, 0, 0, 0), Color(FRIEND_GOLD.r, FRIEND_GOLD.g, FRIEND_GOLD.b, 0.5), 0, 1, 0.0))
	_altar_panel.add_child(inner)
	_altar_label = Label.new()
	_altar_label.position = Vector2(0, 16)
	_altar_label.size = Vector2(asize.x, 28)
	_altar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_altar_label.add_theme_font_size_override("font_size", 18)
	_altar_label.add_theme_color_override("font_color", FRIEND_GOLD)
	_altar_panel.add_child(_altar_label)
	_altar_bar = ProgressBar.new()
	_altar_bar.position = Vector2(16, 66)
	_altar_bar.size = Vector2(asize.x - 32, 34)
	_altar_bar.show_percentage = false
	_altar_bar.add_theme_stylebox_override("background", THEME.make_stylebox(Color(0.08, 0.05, 0.04, 1.0), Color(0.40, 0.30, 0.18), 0, 1, 0.0))
	_altar_bar.add_theme_stylebox_override("fill", THEME.make_stylebox(THEME.get_color("incense_gold", FRIEND_GOLD), FRIEND_GOLD, 0, 0, 0.0))
	_altar_panel.add_child(_altar_bar)

func _info_label(pos: Vector2, fsize: int, col: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(280, 28)
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	_stage.add_child(l)
	return l

func _make_action_button(pos: Vector2, col: Color) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(270, 88)	# ≥88 觸控
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color(0.98, 0.94, 0.84))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.88))
	b.add_theme_color_override("font_pressed_color", Color(0.96, 0.90, 0.80))
	b.add_theme_color_override("font_disabled_color", Color(0.58, 0.54, 0.48))
	var gold: Color = THEME.get_color("incense_gold", FRIEND_GOLD)
	b.add_theme_stylebox_override("normal", THEME.make_stylebox(col, gold, 0, 2, 0.0))
	b.add_theme_stylebox_override("hover", THEME.make_stylebox(col.lightened(0.08), gold, 0, 2, 0.0))
	b.add_theme_stylebox_override("pressed", THEME.make_stylebox(col.darkened(0.10), gold, 0, 2, 0.0))
	b.add_theme_stylebox_override("disabled", THEME.make_stylebox(Color(0.16, 0.12, 0.10, 0.9), Color(0.40, 0.36, 0.30), 0, 2, 0.0))
	_stage.add_child(b)
	return b

## 底部符令手牌列（FU_SLOTS 個槽，_refresh 綁到 core.fu_hand[idx]）+ 選方位提示。
func _build_fu_hand() -> void:
	_fu_prompt = Label.new()
	_fu_prompt.position = Vector2(40, FU_HAND_Y - 26)
	_fu_prompt.size = Vector2(820, 22)
	_fu_prompt.add_theme_font_size_override("font_size", 15)
	_fu_prompt.add_theme_color_override("font_color", THEME.get_color("incense_gold", Color(0.96, 0.84, 0.45)))
	_stage.add_child(_fu_prompt)
	_fu_slots.clear()
	for i: int in range(FU_SLOTS):
		var b := Button.new()
		b.position = Vector2(40 + i * (FU_BTN_SIZE.x + 12), FU_HAND_Y)
		b.size = FU_BTN_SIZE
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 15)
		b.visible = false
		b.button_up.connect(_on_fu_slot_pressed.bind(i))
		_stage.add_child(b)
		_fu_slots.append(b)

# ---- 互動 ----
## 符令槽點擊：無目標即打；需目標者進「選方位」狀態，等點方位營。
func _on_fu_slot_pressed(idx: int) -> void:
	if _core == null or _core.state != FormationCombatCls.STATE_PLAYING:
		return
	if idx >= _core.fu_hand.size() or _core.fu_plays_left <= 0:
		return
	var fu_id: String = str(_core.fu_hand[idx])
	var def: Dictionary = _core.fu_defs.get(fu_id, {})
	_selected_unit = ""	# 取消選將
	if bool(def.get("needs_target", false)):
		_pending_fu = fu_id	# 等點方位營指定 lane
	else:
		_core.play_fu(fu_id)
		_pending_fu = ""
	_refresh()

func _on_camp_pressed(camp_id: String) -> void:
	if _core == null or _core.state != FormationCombatCls.STATE_PLAYING:
		return
	# 符令選方位中：點營＝對該營的 lane 放符令（中營無 lane 則取消）
	if _pending_fu != "":
		var lane: String = str(_camp_to_lane.get(camp_id, ""))
		if lane != "":
			_core.play_fu(_pending_fu, lane)
		_pending_fu = ""
		_refresh()
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
	_pending_fu = ""
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
	_update_altar_danger()
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
	# 符令手牌
	_refresh_fu_hand()
	# 緣分合祀提示
	_refresh_affinity_strip()
	# 戰況
	_log_label.text = _build_log_text()
	# 勝負
	_update_banner()

## 母壇告急：整備度 ≤34% → 框與血條轉硃砂、壇名轉紅（一眼看出快被破）。
func _update_altar_danger() -> void:
	if _altar_panel == null:
		return
	var ratio: float = float(_core.altar_integrity) / maxf(1.0, float(_core.altar_max))
	var low: bool = ratio <= 0.34
	var rim: Color = FOE_RED if low else FRIEND_GOLD
	_altar_panel.add_theme_stylebox_override("panel", THEME.make_stylebox(ALTAR_BG, rim, 0, 4, 0.0))
	var fill_col: Color = FOE_RED if low else THEME.get_color("incense_gold", FRIEND_GOLD)
	_altar_bar.add_theme_stylebox_override("fill", THEME.make_stylebox(fill_col, fill_col, 0, 0, 0.0))
	_altar_label.add_theme_color_override("font_color", rim)

## 緣分合祀提示帶：顯示目前佈陣啟用的合祀（名稱；效果在戰況+數值生效）。
func _refresh_affinity_strip() -> void:
	var active: Array = AffinityCls.active_affinities(_core.unit_location, _core.camps)
	if active.is_empty():
		_affinity_strip.text = ""
		return
	var names: Array[String] = []
	for a: Dictionary in active:
		names.append(str(a.get("affinity_name", "")))
	_affinity_strip.text = tr("combat.formation.affinity_active") % " · ".join(names)

func _refresh_fu_hand() -> void:
	var playable: bool = _core.state == FormationCombatCls.STATE_PLAYING and _core.fu_plays_left > 0
	for i: int in range(_fu_slots.size()):
		var b: Button = _fu_slots[i]
		if i >= _core.fu_hand.size():
			b.visible = false
			continue
		var fu_id: String = str(_core.fu_hand[i])
		var def: Dictionary = _core.fu_defs.get(fu_id, {})
		b.visible = true
		b.text = str(def.get("name", "")) + "\n" + str(def.get("desc", ""))
		b.disabled = not playable
		var sel: bool = fu_id == _pending_fu
		# 符令＝符紙暖底 + 燙金框（硬邊）；選取中加粗金框
		var sb := THEME.make_stylebox(
			Color(0.20, 0.14, 0.10, 0.96),
			THEME.get_color("incense_gold", FRIEND_GOLD) if sel else Color(0.56, 0.46, 0.32),
			0, 4 if sel else 2, 0.0)
		b.add_theme_color_override("font_color", Color(0.97, 0.92, 0.80))
		b.add_theme_color_override("font_disabled_color", Color(0.70, 0.64, 0.54))
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_stylebox_override("disabled", sb)
	# 選方位提示
	if _pending_fu != "":
		var d: Dictionary = _core.fu_defs.get(_pending_fu, {})
		_fu_prompt.text = tr("combat.formation.fu_pick_lane") % str(d.get("name", ""))
	else:
		_fu_prompt.text = ""

func _refresh_camp_tile(c: Dictionary) -> void:
	var cid: String = str(c.get("id"))
	var t: Dictionary = _camp_tiles[cid]
	var element: String = str(c.get("element"))
	var el_col: Color = ELEMENT_COLOR.get(element, Color(0.6, 0.6, 0.6))
	(t["chip"] as ColorRect).color = el_col		# 元素僅一抹小章，不染整框
	var name_lbl := t["name"] as Label
	name_lbl.text = str(c.get("name"))
	name_lbl.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
	var occ_uid: String = _core._unit_in_camp(cid)
	var occ_label := t["occ"] as Label
	var mark_label := t["mark"] as Label
	var wei: bool = false
	if occ_uid != "":
		var uname: String = str(_core.units[occ_uid].get("name"))
		occ_label.text = uname
		occ_label.add_theme_color_override("font_color", Color(0.98, 0.94, 0.84))
		wei = _core.is_wei_position(occ_uid, cid)
		if wei:
			mark_label.text = "★ " + tr("combat.formation.wei")
			mark_label.add_theme_color_override("font_color", FRIEND_JADE)
		else:
			mark_label.text = ""
	else:
		occ_label.text = tr("combat.formation.reserve") if bool(t.get("reserve")) else ""
		occ_label.add_theme_color_override("font_color", Color(0.6, 0.56, 0.5))
		mark_label.text = ""
	# 統一敵我語言：我營一律暗漆底 + 燙金框；得位→玉青；選中→粗金；
	# 空營且該方位來煞→硃砂告急框（新手一眼看出破口）。硬邊（像素鐵則）。
	var btn := t["btn"] as Button
	var selected: bool = occ_uid != "" and occ_uid == _selected_unit
	var lane: String = str(_camp_to_lane.get(cid, ""))
	var threatened: bool = occ_uid == "" and lane != "" and _core.lanes.has(lane) and _core.lanes[lane].get("sha") != null
	var border: Color = FRIEND_GOLD
	var width: int = 2
	if selected:
		width = 5
	elif threatened:
		border = FOE_RED
		width = 4
	elif wei:
		border = FRIEND_JADE
		width = 3
	var sb := THEME.make_stylebox(CAMP_BG, border, 0, width, 0.0)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

func _refresh_lane_marker(lane: String) -> void:
	var p: Panel = _lane_markers[lane]
	var txt := p.get_node("Txt") as Label
	var sha: Variant = _core.lanes[lane]["sha"] if _core.lanes.has(lane) else null
	if sha == null:
		# 清：壓暗收斂，不搶焦點（取代裸「—」）
		txt.text = tr("combat.formation.lane_clear")
		txt.add_theme_color_override("font_color", Color(0.46, 0.50, 0.46))
		p.add_theme_stylebox_override("panel", THEME.make_stylebox(
			Color(0.10, 0.11, 0.10, 0.5), Color(0.26, 0.30, 0.26, 0.7), 0, 1, 0.0))
	else:
		# 來煞：硃砂 + ▲ 警示符（敵我語言一致）
		txt.text = "▲ " + (tr("combat.formation.sha_marker") % [int(sha["strength"]), int(sha["steps"])])
		txt.add_theme_color_override("font_color", Color(1.0, 0.90, 0.78))
		p.add_theme_stylebox_override("panel", THEME.make_stylebox(
			Color(0.50, 0.10, 0.08, 0.92), FOE_RED, 0, 3, 0.0))

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
		FormationCombatCls.EV_FU:
			var fu_id: String = str(ev.get("fu"))
			var fu_name: String = str(_core.fu_defs.get(fu_id, {}).get("name", fu_id)) if _core != null else fu_id
			return tr("combat.log.fu") % fu_name
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
