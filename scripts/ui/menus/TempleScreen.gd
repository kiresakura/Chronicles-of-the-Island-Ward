# 鎮島錄 Q2-D — 修廟畫面（DELEGATION §5 Q2「修廟 UI + 建築解鎖實套」）。
#
# 香火（meta 貨幣，玩出來的）修復六棟建築 → 結構型解鎖即刻生效
# （虎爺殿→破煞法器進池、夜市香鋪→商店加成）；內容型（正殿/籤詩亭/鐘鼓樓）
# 誠實標注「Q3 內容關開放」— 不掰未存在的效果。戲台為純氛圍建築。
# 後端走 RitualTemple（資料 external/data/meta_buildings/，數值在 JSON — 鐵律 1）。
# 修復即存檔（FileLoader.save_profile）。佈局以 safe rect 重排（mobile-first）。
extends Control
class_name TempleScreen

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

## 建築 glyph 徽章 + 內容型標注（系統存在性以 Q2 現況誠實對映）
const BUILDING_GLYPH: Dictionary = {
	"building_main_hall": "殿", "building_tiger_shrine": "虎", "building_fortune_pavilion": "籤",
	"building_night_market": "市", "building_stage": "台", "building_bell_tower": "鐘",
}
const BUILDING_BADGE_COLOR: Dictionary = {
	"building_main_hall": Color(0.72, 0.20, 0.14), "building_tiger_shrine": Color(0.85, 0.55, 0.18),
	"building_fortune_pavilion": Color(0.36, 0.62, 0.74), "building_night_market": Color(0.93, 0.72, 0.30),
	"building_stage": Color(0.60, 0.36, 0.62), "building_bell_tower": Color(0.45, 0.58, 0.38),
}
## Q3 才有承載系統的解鎖鍵 → 卡上標注，避免「修了沒感」的誠信缺口
const CONTENT_PENDING_NOTE: Dictionary = {
	"building_main_hall": "神明位擴充於 Q3 內容關開放",
	"building_fortune_pavilion": "開局籤詩於 Q3 內容關開放",
	"building_bell_tower": "開局被動於 Q3 內容關開放",
}

signal temple_changed	# 修復成功（MainMenu 接這個刷新香火列）

var GOLD: Color = Color(0.95, 0.82, 0.45)
var PANEL_BG: Color = Color(0.14, 0.05, 0.04, 0.93)

var _incense_lbl: Label
var _grid: GridContainer
var _back_btn: Button
var _cards: Dictionary = {}	# building_id -> {panel, lv, cost, btn, note}

func _ready() -> void:
	GOLD = COTIW_UI_THEME.get_color("incense_gold", GOLD)
	PANEL_BG = COTIW_UI_THEME.get_color("panel_bg", PANEL_BG)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP	# modal：擋下層主選單
	_build()
	visible = false
	var resp: Node = get_node_or_null("/root/Responsive")
	if resp != null and resp.has_signal("changed"):
		resp.changed.connect(_relayout)

func open() -> void:
	refresh()
	_relayout()
	visible = true

func close() -> void:
	visible = false

func _build() -> void:
	# 全幅暗底（modal 遮罩 + 氛圍）
	var dim := ColorRect.new()
	dim.name = "TempleDim"
	dim.color = Color(0.06, 0.03, 0.03, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_to_group("fullbleed_mask")
	add_child(dim)

	var title := Label.new()
	title.name = "TempleTitle"
	title.text = "修復鎮島廟"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "TempleSubtitle"
	subtitle.text = "一磚一瓦，香火重光 — 廟越完整，出巡的選項越多"
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.78, 0.66))
	add_child(subtitle)

	_incense_lbl = Label.new()
	_incense_lbl.name = "IncenseBadge"
	_incense_lbl.add_theme_font_size_override("font_size", 22)
	_incense_lbl.add_theme_color_override("font_color", GOLD)
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = Color(0.20, 0.08, 0.06, 0.95)
	badge_sb.border_color = GOLD
	badge_sb.set_border_width_all(2)
	badge_sb.set_corner_radius_all(10)
	badge_sb.set_content_margin_all(10)
	_incense_lbl.add_theme_stylebox_override("normal", badge_sb)
	add_child(_incense_lbl)

	_back_btn = Button.new()
	_back_btn.name = "TempleBackButton"
	_back_btn.text = "返回正殿"
	_back_btn.custom_minimum_size = Vector2(200, 80)
	_back_btn.focus_mode = Control.FOCUS_NONE
	COTIW_UI_THEME.apply_primary_button_style(_back_btn)
	_back_btn.button_up.connect(close)
	add_child(_back_btn)

	_grid = GridContainer.new()
	_grid.name = "BuildingGrid"
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	add_child(_grid)

	# 敘事排序：核心 → 玩法 → 氛圍（檔名字母序會打亂長線目標的視覺權重）
	var display_order: Array[String] = [
		"building_main_hall", "building_tiger_shrine", "building_fortune_pavilion",
		"building_night_market", "building_bell_tower", "building_stage",
	]
	for bid: String in RitualTemple.list_building_ids():
		if not display_order.has(bid):
			display_order.append(bid)	# 未列入者掛尾（資料驅動：新建築 JSON 自動出現）
	for bid: String in display_order:
		if not RitualTemple.load_building(bid).is_empty():
			_grid.add_child(_make_building_card(bid))

func _make_building_card(bid: String) -> PanelContainer:
	var props: Dictionary = RitualTemple.load_building(bid)
	var card := PanelContainer.new()
	card.name = "Card_" + bid
	card.custom_minimum_size = Vector2(296, 218)
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = COTIW_UI_THEME.get_color("old_gold", Color(0.62, 0.49, 0.24))
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	# 首行：glyph 徽章 + 名稱 + 等級
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	vb.add_child(head)
	var badge := Label.new()
	badge.text = str(BUILDING_GLYPH.get(bid, "廟"))
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.custom_minimum_size = Vector2(44, 44)
	badge.add_theme_font_size_override("font_size", 24)
	badge.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = BUILDING_BADGE_COLOR.get(bid, Color(0.4, 0.3, 0.3))
	badge_sb.set_corner_radius_all(22)
	badge_sb.border_color = Color(0.12, 0.05, 0.04)
	badge_sb.set_border_width_all(2)
	badge.add_theme_stylebox_override("normal", badge_sb)
	head.add_child(badge)
	var name_lbl := Label.new()
	name_lbl.text = str(props.get("building_name", bid))
	name_lbl.add_theme_font_size_override("font_size", 21)
	name_lbl.add_theme_color_override("font_color", GOLD)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_lbl)
	var lv_lbl := Label.new()
	lv_lbl.name = "LvLabel"
	lv_lbl.add_theme_font_size_override("font_size", 17)
	lv_lbl.add_theme_color_override("font_color", Color(0.9, 0.84, 0.7))
	head.add_child(lv_lbl)

	# 效果摘要（對玩家說「修了得到什麼」）
	var effect := Label.new()
	effect.text = str(props.get("building_effect_summary", ""))
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.add_theme_font_size_override("font_size", 15)
	effect.add_theme_color_override("font_color", Color(0.93, 0.89, 0.80))
	effect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(effect)

	# 誠實標注：內容型解鎖的開放時程／純氛圍
	var note := Label.new()
	note.name = "NoteLabel"
	if CONTENT_PENDING_NOTE.has(bid):
		note.text = "※ " + str(CONTENT_PENDING_NOTE[bid])
	elif bool(props.get("is_cosmetic_only", false)):
		note.text = "※ 純氛圍建築（外觀／劇情／音樂）"
	else:
		note.text = "※ 修復後即刻生效"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.66, 0.58, 0.48))
	vb.add_child(note)

	# 尾行：成本 + 修復鈕
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	vb.add_child(foot)
	var cost_lbl := Label.new()
	cost_lbl.name = "CostLabel"
	cost_lbl.add_theme_font_size_override("font_size", 17)
	cost_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(cost_lbl)
	var btn := Button.new()
	btn.name = "RepairButton"
	btn.custom_minimum_size = Vector2(132, 64)
	btn.focus_mode = Control.FOCUS_NONE
	COTIW_UI_THEME.apply_primary_button_style(btn)
	btn.button_up.connect(_on_repair_pressed.bind(bid))
	foot.add_child(btn)

	_cards[bid] = {"panel": card, "lv": lv_lbl, "cost": cost_lbl, "btn": btn}
	return card

func refresh() -> void:
	var profile: ProfileData = Global.profile_data
	if _incense_lbl != null:
		_incense_lbl.text = "香火  %d" % (profile.profile_incense_balance if profile != null else 0)
	for bid: String in _cards.keys():
		var props: Dictionary = RitualTemple.load_building(bid)
		var entry: Dictionary = _cards[bid]
		var lvl: int = profile.get_building_level(bid) if profile != null else 0
		var max_lvl: int = int(props.get("max_level", 1))
		(entry["lv"] as Label).text = "Lv %d/%d" % [lvl, max_lvl]
		var btn: Button = entry["btn"] as Button
		var cost_lbl: Label = entry["cost"] as Label
		if lvl >= max_lvl:
			cost_lbl.text = "圓滿"
			cost_lbl.add_theme_color_override("font_color", GOLD)
			btn.text = "已圓滿"
			btn.disabled = true
		else:
			var cost: int = RitualTemple.repair_cost(props, lvl)
			cost_lbl.text = "香火 %d" % cost
			var affordable: bool = RitualTemple.can_repair(profile, bid)
			cost_lbl.add_theme_color_override("font_color",
				Color(0.93, 0.86, 0.66) if affordable else Color(0.85, 0.42, 0.36))
			btn.text = "修復" if lvl == 0 else "升級"
			btn.disabled = not affordable

func _on_repair_pressed(bid: String) -> void:
	if not RitualTemple.repair(Global.profile_data, bid):
		return
	FileLoader.save_profile()	# 修復即存檔（meta 進度不可丟）
	AudioManager.play_sfx("invoke")
	refresh()
	temple_changed.emit()
	# 修復鼓點：卡片金光一拍
	var entry: Dictionary = _cards.get(bid, {})
	var panel: Control = entry.get("panel", null) as Control
	if panel != null:
		var tw := panel.create_tween()
		tw.tween_property(panel, "modulate", Color(1.35, 1.22, 0.9), 0.12)
		tw.tween_property(panel, "modulate", Color.WHITE, 0.4)

## safe-rect 重排（mobile-first；4:3 直接受益於垂直置中）
func _relayout() -> void:
	var safe: Rect2 = COTIW_UI_THEME.get_safe_content_rect(get_viewport())
	var title: Control = get_node_or_null("TempleTitle") as Control
	var subtitle: Control = get_node_or_null("TempleSubtitle") as Control
	if title != null:
		title.position = safe.position + Vector2(232, 10)
	if subtitle != null:
		subtitle.position = safe.position + Vector2(234, 56)
	if _back_btn != null:
		_back_btn.position = safe.position + Vector2(16, 10)
	if _incense_lbl != null:
		_incense_lbl.size = Vector2.ZERO
		_incense_lbl.position = Vector2(safe.position.x + safe.size.x - 190.0, safe.position.y + 14.0)
	if _grid != null:
		var grid_w: float = 296.0 * 3.0 + 16.0 * 2.0
		var grid_h: float = 218.0 * 2.0 + 16.0
		var top: float = safe.position.y + 100.0
		_grid.position = Vector2(safe.position.x + (safe.size.x - grid_w) * 0.5,
			top + maxf(0.0, (safe.position.y + safe.size.y - top - grid_h) * 0.35))
