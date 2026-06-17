# 鎮島錄 v0.3 — 封神榜（formation_progression_v0.3.md §2.2，FC-5c）。
#
# 玩家以香火敕封神將位階 將→帥→神→帝（CanonizationSystem 後端）。每階解鎖「選項」
# （grants：營位資格/+1符令draft/緣分）而非堆數值。仿 TempleScreen：modal、safe-rect 重排、
# 敕封即存檔。修廟與敕封共用香火池＝廣度vs深度抉擇（doc §2.2）。
# 🔴 變現紅線：只花香火，元寶不碰（CanonizationSystem 保證；test_canonization 驗）。
# 可敕封對象＝FormationUnitData 全體（資料驅動，新單位 JSON 自動出現）。
extends Control
class_name CanonizationScreen

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const CANON := preload("res://scripts/systems/ritual/CanonizationSystem.gd")

# 五行色（單位屬性徽章；與五營戰一致）
const ELEMENT_COLOR := {
	"wood": Color(0.35, 0.66, 0.40), "fire": Color(0.86, 0.30, 0.20),
	"earth": Color(0.80, 0.64, 0.28), "metal": Color(0.82, 0.80, 0.62), "water": Color(0.30, 0.55, 0.82),
}

signal canon_changed	# 敕封成功（呼叫者刷新香火列）

var GOLD: Color = Color(0.95, 0.82, 0.45)
var PANEL_BG: Color = Color(0.14, 0.05, 0.04, 0.93)

var _incense_lbl: Label
var _grid: GridContainer
var _back_btn: Button
var _cards: Dictionary = {}	# unit_id → {panel, rank, cost, grant, btn}

func _ready() -> void:
	GOLD = COTIW_UI_THEME.get_color("incense_gold", GOLD)
	PANEL_BG = COTIW_UI_THEME.get_color("panel_bg", PANEL_BG)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP	# modal
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
	var dim := ColorRect.new()
	dim.name = "CanonDim"
	dim.color = Color(0.06, 0.03, 0.03, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_to_group("fullbleed_mask")
	add_child(dim)

	var title := Label.new()
	title.name = "CanonTitle"
	title.text = tr("canon.title")
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "CanonSubtitle"
	subtitle.text = tr("canon.subtitle")
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
	_back_btn.name = "CanonBackButton"
	_back_btn.text = tr("temple.back")
	_back_btn.custom_minimum_size = Vector2(200, 80)
	_back_btn.focus_mode = Control.FOCUS_NONE
	COTIW_UI_THEME.apply_primary_button_style(_back_btn)
	_back_btn.button_up.connect(close)
	add_child(_back_btn)

	var scroll := ScrollContainer.new()
	scroll.name = "CanonScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_grid = GridContainer.new()
	_grid.name = "CanonGrid"
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 16)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	var units: Dictionary = Global._id_to_formation_unit_data if "_id_to_formation_unit_data" in Global else {}
	for uid: String in units:
		_grid.add_child(_make_unit_card(uid, units[uid]))

func _make_unit_card(uid: String, unit: FormationUnitData) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "Card_" + uid
	card.custom_minimum_size = Vector2(300, 168)
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

	# 首行：名稱（五行色）+ 位階
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	vb.add_child(head)
	var name_lbl := Label.new()
	name_lbl.text = unit.unit_name
	name_lbl.add_theme_font_size_override("font_size", 21)
	name_lbl.add_theme_color_override("font_color", ELEMENT_COLOR.get(unit.unit_element, GOLD))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_lbl)
	var rank_lbl := Label.new()
	rank_lbl.name = "RankLabel"
	rank_lbl.add_theme_font_size_override("font_size", 18)
	rank_lbl.add_theme_color_override("font_color", GOLD)
	head.add_child(rank_lbl)

	# 下一階解鎖摘要
	var grant_lbl := Label.new()
	grant_lbl.name = "GrantLabel"
	grant_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grant_lbl.add_theme_font_size_override("font_size", 14)
	grant_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.74))
	grant_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(grant_lbl)

	# 尾行：成本 + 敕封鈕
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 8)
	vb.add_child(foot)
	var cost_lbl := Label.new()
	cost_lbl.name = "CostLabel"
	cost_lbl.add_theme_font_size_override("font_size", 16)
	cost_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(cost_lbl)
	var btn := Button.new()
	btn.name = "CanonButton"
	btn.custom_minimum_size = Vector2(132, 64)
	btn.focus_mode = Control.FOCUS_NONE
	COTIW_UI_THEME.apply_primary_button_style(btn)
	btn.button_up.connect(_on_canonize_pressed.bind(uid))
	foot.add_child(btn)

	_cards[uid] = {"panel": card, "rank": rank_lbl, "cost": cost_lbl, "grant": grant_lbl, "btn": btn}
	return card

func refresh() -> void:
	var profile: ProfileData = Global.profile_data
	if _incense_lbl != null:
		_incense_lbl.text = tr("temple.incense_badge") % (profile.profile_incense_balance if profile != null else 0)
	for uid: String in _cards.keys():
		var entry: Dictionary = _cards[uid]
		var rank: int = CANON.rank_of(profile, uid)
		(entry["rank"] as Label).text = tr("canon.rank") % CANON.rank_name(rank)
		var btn: Button = entry["btn"] as Button
		var cost_lbl: Label = entry["cost"] as Label
		var grant_lbl: Label = entry["grant"] as Label
		var cost: int = CANON.cost_for_next(profile, uid)
		if cost < 0:
			cost_lbl.text = tr("canon.maxed_cost")
			cost_lbl.add_theme_color_override("font_color", GOLD)
			btn.text = tr("canon.maxed_btn")
			btn.disabled = true
			grant_lbl.text = ""
		else:
			cost_lbl.text = tr("canon.cost") % cost
			var affordable: bool = CANON.can_canonize(profile, uid)
			cost_lbl.add_theme_color_override("font_color",
				Color(0.93, 0.86, 0.66) if affordable else Color(0.85, 0.42, 0.36))
			btn.text = tr("canon.next") % CANON.rank_name(rank + 1)
			btn.disabled = not affordable
			grant_lbl.text = _next_grant_text(rank)

## 下一階解鎖選項的人話摘要（grant 鍵 → CSV）。
func _next_grant_text(current_rank: int) -> String:
	var tier: Dictionary = CANON._tier_for(current_rank + 1)
	var parts: Array[String] = []
	for g: Variant in tier.get("grants", []):
		parts.append(tr("canon.grant." + str(g)))
	return "\n".join(parts)

func _on_canonize_pressed(uid: String) -> void:
	var result: Dictionary = CANON.canonize(Global.profile_data, uid)
	if not bool(result.get("success", false)):
		return
	FileLoader.save_profile()	# 敕封即存檔（meta 進度不可丟）
	AudioManager.play_sfx("invoke")
	refresh()
	canon_changed.emit()
	# 敕封金光一拍
	var panel: Control = (_cards.get(uid, {}) as Dictionary).get("panel", null) as Control
	if panel != null:
		var tw := panel.create_tween()
		tw.tween_property(panel, "modulate", Color(1.35, 1.22, 0.9), 0.12)
		tw.tween_property(panel, "modulate", Color.WHITE, 0.4)

## safe-rect 重排（mobile-first）
func _relayout() -> void:
	var safe: Rect2 = COTIW_UI_THEME.get_safe_content_rect(get_viewport())
	var title: Control = get_node_or_null("CanonTitle") as Control
	var subtitle: Control = get_node_or_null("CanonSubtitle") as Control
	var scroll: Control = get_node_or_null("CanonScroll") as Control
	if title != null:
		title.position = safe.position + Vector2(24, 10)
	if subtitle != null:
		subtitle.position = safe.position + Vector2(24, 52)
	if _incense_lbl != null:
		_incense_lbl.position = safe.position + Vector2(safe.size.x - 240, 12)
	if _back_btn != null:
		_back_btn.position = safe.position + Vector2(safe.size.x - 220, safe.size.y - 96)
	if scroll != null:
		scroll.position = safe.position + Vector2(24, 84)
		scroll.size = Vector2(safe.size.x - 48, safe.size.y - 180)
