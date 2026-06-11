extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const CHARACTER_GALLERY_SCENE := preload("res://scenes/ui/menus/CharacterGallery.tscn")

const CHARACTER_SHELF_PATH := "res://external/data/ui/new_run_character_shelf.json"
const PORTRAIT_DIR := "res://assets/generated/portraits_v3/"

@onready var title_screen: Control = $%TitleScreen

@onready var character_name_label: Label = $CharacterNameLabel
@onready var character_health_label: Label = $CharacterHealthLabel
@onready var character_money_label: Label = $CharacterMoneyLabel
@onready var character_description_label: Label = $CharacterDescriptionLabel

@onready var character_artifact_texture_rect: TextureRect = $CharacterArtifactTextureRect
@onready var character_artifact_name_label: Label = $CharacterArtifactNameLabel
@onready var character_artifact_description_label: Label = $CharacterArtifactDescriptionLabel

@onready var decrease_difficulty_button: Button = $DifficultySelect/DecreaseDifficultyButton
@onready var difficulty_label: Label = $DifficultySelect/DifficultyLabel
@onready var increase_difficulty_button: Button = $DifficultySelect/IncreaseDifficultyButton

@onready var custom_run_modifier_button_container: ScrollContainer = $CustomRunModifierButtonContainer
@onready var character_button_container: ScrollContainer = $CharacterButtonContainer

@onready var start_run_button: Button = $StartRunButton
@onready var seed_input: LineEdit = $SeedInput
@onready var back_button: Button = $BackButton

var selected_character_object_id: String = ""
var selected_difficulty_level: int = 0

## 鎮島錄 — 2B-UI 班底選擇器（護壇 / 法器；留空 → 角色預設班底，由 RitualLoadout 解析出戰神明）
var selected_guardian_id: String = ""
var selected_ritual_tool_id: String = ""
var _guardian_picker: OptionButton = null
var _tool_picker: OptionButton = null

var _character_gallery
var _character_info_panel: Panel
var _run_guide_panel: Panel
var _character_tags_flow: HFlowContainer
var _start_hint_label: Label
var _info_heading_label: Label
var _run_heading_label: Label
var _selection_bridge: Label
var _character_shelf: Array = []

## UIQA P1-2 重排：guide 面板內四列互不重疊（標題/提示/護壇法器/種子），
## 開始開壇 = 右側 80 高大 CTA；返回正殿改左上角（與角色面板「← 返回」同慣例，
## 原本排在 guide 下方 y=guide_y+guide_h+10 → 698 必出界）。
static func calculate_p1_bottom_control_layout(safe: Rect2) -> Dictionary:
	var left_x: float = safe.position.x + 36.0
	var left_w: float = clampf(safe.size.x * 0.25, 292.0, 320.0)
	var right_w: float = 344.0
	var right_x: float = safe.position.x + safe.size.x - right_w - 32.0
	var gallery_x: float = left_x + left_w + 24.0
	var gallery_w: float = maxf(280.0, right_x - gallery_x - 24.0)
	var guide_y: float = safe.position.y + safe.size.y - 164.0
	var guide_h: float = 152.0
	var guide_x: float = gallery_x + 12.0
	var guide_w: float = maxf(360.0, minf(428.0, gallery_w - 24.0))
	var inner_x: float = guide_x + 16.0
	var inner_w: float = guide_w - 32.0
	var cta_w: float = 168.0
	var left_zone_w: float = inner_w - cta_w - 16.0
	var picker_w: float = (left_zone_w - 12.0) / 2.0
	# v5（UIQA W1）：hint 移右欄「自訂修正」下空帶（autowrap，任何寬度零碰撞）；
	# picker 左欄疊雙行 48 高（寬列舒適線）；種子右欄上列、開壇 CTA 右下大鈕
	var hint_rect := Rect2(Vector2(right_x + 8.0, safe.position.y + safe.size.y - 252.0), Vector2(right_w - 24.0, 84.0))
	var seed_rect := Rect2(Vector2(guide_x + guide_w - cta_w - 16.0, guide_y + 26.0), Vector2(cta_w, 32.0))
	var guardian_rect := Rect2(Vector2(inner_x, guide_y + 40.0), Vector2(left_zone_w, 48.0))
	var tool_rect := Rect2(Vector2(inner_x, guide_y + 92.0), Vector2(left_zone_w, 48.0))
	var start_rect := Rect2(Vector2(guide_x + guide_w - cta_w - 16.0, guide_y + 62.0), Vector2(cta_w, 86.0))
	var back_rect := Rect2(Vector2(safe.position.x + 16.0, safe.position.y + 12.0), Vector2(188.0, 80.0))
	return {
		"guide": Rect2(Vector2(guide_x, guide_y), Vector2(guide_w, guide_h)),
		"hint": hint_rect,
		"guardian": guardian_rect,
		"tool": tool_rect,
		"seed": seed_rect,
		"start": start_rect,
		"back": back_rect,
	}

func _ready() -> void:
	_character_shelf = _load_character_shelf()
	start_run_button.button_up.connect(_on_start_run_button_up)
	back_button.button_up.connect(_on_back_button_up)
	decrease_difficulty_button.button_up.connect(_on_decrease_difficulty_button)
	increase_difficulty_button.button_up.connect(_on_increase_difficulty_button)
	seed_input.text_changed.connect(_on_seed_input_text_changed)
	Signals.character_selected.connect(_on_character_selected)
	Signals.run_ended.connect(_on_run_ended)
	if not resized.is_connected(_relayout_runtime_chrome):
		resized.connect(_relayout_runtime_chrome)
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_relayout_runtime_chrome):
		viewport.size_changed.connect(_relayout_runtime_chrome)
	if not Responsive.changed.is_connected(_relayout_runtime_chrome):
		Responsive.changed.connect(_relayout_runtime_chrome)

	const PixelSkinCls = preload("res://scripts/ui/theme/PixelSkin.gd")
	const PixelFXCls = preload("res://scripts/ui/fx/PixelFX.gd")
	var newrun_layer := PixelSkinCls.apply_background(self, "newrun_bg_v5.png")
	if newrun_layer:
		PixelFXCls.apply(newrun_layer, PixelFXCls.Preset.SMOKE)

	_style_static_controls()
	_build_runtime_chrome()
	_build_loadout_pickers()
	_build_character_gallery()
	populate_new_run_menu()
	await get_tree().process_frame
	_relayout_runtime_chrome()

func _style_static_controls() -> void:
	COTIW_UI_THEME.apply_primary_button_style(start_run_button)
	COTIW_UI_THEME.apply_secondary_button_style(back_button)
	COTIW_UI_THEME.apply_secondary_button_style(decrease_difficulty_button)
	COTIW_UI_THEME.apply_secondary_button_style(increase_difficulty_button)
	start_run_button.text = "開始開壇"
	back_button.text = "返回正殿"
	seed_input.placeholder_text = "留白則隨機起局"
	seed_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_button_container.visible = false
	_update_difficulty_label()
	_start_run_button_state(false)

func _build_runtime_chrome() -> void:
	if _character_info_panel == null:
		_character_info_panel = Panel.new()
		_character_info_panel.name = "CharacterInfoPanel"
		_character_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_character_info_panel.z_index = -1
		add_child(_character_info_panel)
		_character_info_panel.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
			Color(0.08, 0.03, 0.03, 0.90),
			Color(0.78, 0.58, 0.20, 0.72),
			18,
			2,
			0.18
		))
	if _run_guide_panel == null:
		_run_guide_panel = Panel.new()
		_run_guide_panel.name = "RunGuidePanel"
		_run_guide_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_run_guide_panel.z_index = -1
		add_child(_run_guide_panel)
		_run_guide_panel.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
			Color(0.10, 0.04, 0.03, 0.92),
			Color(0.86, 0.64, 0.24, 0.82),
			18,
			2,
			0.18
		))
	if _info_heading_label == null:
		_info_heading_label = Label.new()
		_info_heading_label.name = "InfoHeadingLabel"
		_info_heading_label.text = "選誰・得到什麼"
		_info_heading_label.add_theme_font_size_override("font_size", 16)
		_info_heading_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.82, 0.45)))
		add_child(_info_heading_label)
	if _run_heading_label == null:
		_run_heading_label = Label.new()
		_run_heading_label.name = "RunHeadingLabel"
		_run_heading_label.text = "如何開始"
		_run_heading_label.add_theme_font_size_override("font_size", 16)
		_run_heading_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.82, 0.45)))
		add_child(_run_heading_label)
	if _selection_bridge == null:
		_selection_bridge = Label.new()
		_selection_bridge.name = "SelectionBridgeLabel"
		_selection_bridge.text = "← 神壇燈光落在哪位，左側就寫誰的起手命格。"
		_selection_bridge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_selection_bridge.add_theme_font_size_override("font_size", 13)
		_selection_bridge.add_theme_color_override("font_color", Color(0.96, 0.88, 0.72, 0.82))
		_selection_bridge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_selection_bridge)
	if _character_tags_flow == null:
		_character_tags_flow = HFlowContainer.new()
		_character_tags_flow.name = "CharacterTagsFlow"
		_character_tags_flow.alignment = FlowContainer.ALIGNMENT_BEGIN
		_character_tags_flow.add_theme_constant_override("h_separation", 6)
		_character_tags_flow.add_theme_constant_override("v_separation", 6)
		add_child(_character_tags_flow)
	if _start_hint_label == null:
		_start_hint_label = Label.new()
		_start_hint_label.name = "StartHintLabel"
		_start_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_start_hint_label.add_theme_font_size_override("font_size", 14)
		_start_hint_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82, 0.92))
		_start_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_start_hint_label)

func _build_character_gallery() -> void:
	if _character_gallery != null:
		return
	_character_gallery = CHARACTER_GALLERY_SCENE.instantiate()
	if _character_gallery == null:
		return
	_character_gallery.name = "CharacterGallery"
	add_child(_character_gallery)
	_character_gallery.character_selected.connect(func(character_id: String): Signals.character_selected.emit(character_id))

func _relayout_runtime_chrome() -> void:
	var safe: Rect2 = Responsive.safe_rect if Responsive != null else Rect2(Vector2.ZERO, get_viewport_rect().size)
	# UIQA：safe 是螢幕座標；本面板掛在會被置中偏移的 TitleScreen 下（4:3 時 y+100）
	# → 轉成 parent-local，否則底排（開始開壇/班底 picker）雙重偏移出畫面
	safe.position -= global_position
	var left_x: float = safe.position.x + 36.0
	var left_w: float = clampf(safe.size.x * 0.25, 292.0, 320.0)
	var info_y: float = safe.position.y + 108.0
	var info_h: float = clampf(safe.size.y * 0.56, 360.0, 396.0)
	var right_w: float = 344.0
	var right_x: float = safe.position.x + safe.size.x - right_w - 32.0
	var gallery_x: float = left_x + left_w + 24.0
	var gallery_w: float = maxf(280.0, right_x - gallery_x - 24.0)
	var gallery_y: float = safe.position.y + 106.0
	var gallery_h: float = clampf(safe.size.y * 0.56, 350.0, 410.0)
	var bottom_layout := calculate_p1_bottom_control_layout(safe)
	var guide_rect: Rect2 = bottom_layout["guide"]
	var hint_rect: Rect2 = bottom_layout["hint"]
	var seed_rect: Rect2 = bottom_layout["seed"]
	var start_rect: Rect2 = bottom_layout["start"]
	var guide_x: float = guide_rect.position.x
	var guide_y: float = guide_rect.position.y
	var guide_w: float = guide_rect.size.x
	var guide_h: float = guide_rect.size.y

	if _character_gallery != null:
		_character_gallery.position = Vector2(gallery_x, gallery_y)
		_character_gallery.size = Vector2(gallery_w, gallery_h)
	if _character_info_panel != null:
		_character_info_panel.position = Vector2(left_x - 8.0, info_y - 10.0)
		_character_info_panel.size = Vector2(left_w + 16.0, info_h)
	if _run_guide_panel != null:
		_run_guide_panel.position = Vector2(guide_x, guide_y)
		_run_guide_panel.size = Vector2(guide_w, guide_h)
	if _info_heading_label != null:
		_info_heading_label.position = Vector2(left_x + 4.0, info_y - 6.0)
		_info_heading_label.size = Vector2(left_w - 8.0, 24.0)
	if _run_heading_label != null:
		_run_heading_label.position = Vector2(guide_x + 16.0, guide_y + 10.0)
		_run_heading_label.size = Vector2(160.0, 24.0)
	if _selection_bridge != null:
		_selection_bridge.position = Vector2(gallery_x - 12.0, gallery_y + gallery_h + 2.0)
		_selection_bridge.size = Vector2(gallery_w + 24.0, 20.0)
	if _character_tags_flow != null:
		_character_tags_flow.position = Vector2(left_x, info_y + 330.0)
		_character_tags_flow.size = Vector2(left_w - 16.0, 72.0)
	if _start_hint_label != null:
		_start_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_start_hint_label.position = hint_rect.position
		_start_hint_label.size = hint_rect.size
	if seed_input != null:
		seed_input.position = seed_rect.position
		seed_input.size = seed_rect.size
	if start_run_button != null:
		start_run_button.position = start_rect.position
		start_run_button.size = start_rect.size
	if back_button != null:
		# UIQA P1-2：返回改左上角（原 guide 下方必出界）
		var back_rect: Rect2 = bottom_layout["back"]
		back_button.position = back_rect.position
		back_button.size = back_rect.size
	# 班底選擇器：與種子/開始鈕同列系統，互不重疊（rect 由 layout 函式給）
	if _guardian_picker != null:
		var g_rect: Rect2 = bottom_layout["guardian"]
		_guardian_picker.position = g_rect.position
		_guardian_picker.size = g_rect.size
	if _tool_picker != null:
		var t_rect: Rect2 = bottom_layout["tool"]
		_tool_picker.position = t_rect.position
		_tool_picker.size = t_rect.size

func _on_seed_input_text_changed(new_text: String) -> void:
	var caret_column: int = seed_input.caret_column
	seed_input.text = str(new_text.to_int())
	seed_input.caret_column = min(caret_column, len(seed_input.text))

func _on_character_selected(character_object_id: String) -> void:
	selected_character_object_id = character_object_id
	populate_character_info(selected_character_object_id)
	if _character_gallery != null:
		_character_gallery.select_character(character_object_id)
	_start_run_button_state(not selected_character_object_id.is_empty())

func _on_decrease_difficulty_button() -> void:
	selected_difficulty_level = max(0, selected_difficulty_level - 1)
	_update_difficulty_label()

func _on_increase_difficulty_button() -> void:
	selected_difficulty_level = min(selected_difficulty_level + 1, len(PlayerData.DIFFICULTY_RUN_MODIFIER_OBJECT_IDS))
	_update_difficulty_label()

func _update_difficulty_label() -> void:
	difficulty_label.text = "難度 %d" % selected_difficulty_level

func populate_new_run_menu() -> void:
	custom_run_modifier_button_container.populate_custom_run_modifiers()
	_refresh_character_gallery()
	_select_default_character_if_needed()

func populate_character_info(character_object_id: String) -> void:
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data == null:
		character_name_label.text = "請先選角"
		character_health_label.text = "元神：—"
		character_money_label.text = "銀兩：—"
		character_description_label.text = "神壇還沒選定主位。"
		character_artifact_texture_rect.texture = null
		character_artifact_name_label.text = "起手護符：待定"
		character_artifact_description_label.text = "先選角色，再看祂帶來什麼。"
		_populate_character_tags([])
		_start_hint_label.text = "先從中央 gallery 點一位角色，再決定難度、種子；右側這欄會告訴你祂適合怎麼開局。"
		return

	character_name_label.text = character_data.character_name
	character_health_label.text = "元神：%d" % character_data.character_starting_health
	character_money_label.text = "銀兩：%d" % character_data.character_starting_money
	character_description_label.text = character_data.character_description
	_populate_character_tags(_tags_for_character(character_object_id))

	var starter_artifact_name: String = "無起手護符"
	var starter_artifact_description: String = ""
	character_artifact_texture_rect.texture = null
	if len(character_data.character_starting_artifact_ids) > 0:
		var artifact_data: ArtifactData = Global.get_artifact_data(character_data.character_starting_artifact_ids[0])
		if artifact_data != null:
			character_artifact_texture_rect.texture = CardArtRegistry.resolve_artifact_texture(artifact_data)
			starter_artifact_name = artifact_data.artifact_name
			starter_artifact_description = artifact_data.artifact_description
	character_artifact_name_label.text = starter_artifact_name
	character_artifact_description_label.text = starter_artifact_description if not starter_artifact_description.is_empty() else "此角色不帶額外起手遺物。"
	var build_hint: String = _build_hint_for_character(character_object_id)
	if build_hint.is_empty():
		_start_hint_label.text = "已選中【%s】。確認難度與種子後，按下〈開始開壇〉立刻進局。" % character_data.character_name
	else:
		_start_hint_label.text = "已選中【%s】。核心開局：%s\n確認難度與種子後，按下〈開始開壇〉立刻進局。" % [character_data.character_name, build_hint]

func _populate_character_tags(tags: Array) -> void:
	if _character_tags_flow == null:
		return
	for child in _character_tags_flow.get_children():
		child.queue_free()
	for raw_tag in tags:
		var tag_text: String = str(raw_tag)
		if tag_text.is_empty():
			continue
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(0, 24)
		panel.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
			Color(0.20, 0.08, 0.05, 0.94),
			Color(0.90, 0.68, 0.26, 0.84),
			12,
			1,
			0.12
		))
		var label := Label.new()
		label.text = tag_text
		label.position = Vector2(9, 2)
		label.size = Vector2(maxf(58.0, float(tag_text.length()) * 15.0), 20.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.82, 1.0))
		panel.custom_minimum_size.x = label.size.x + 18.0
		panel.add_child(label)
		_character_tags_flow.add_child(panel)

func _refresh_character_gallery() -> void:
	if _character_gallery == null:
		return
	_character_gallery.setup_entries(_build_gallery_entries())
	_character_gallery.select_character(selected_character_object_id)

func _build_gallery_entries() -> Array:
	var entries: Array = []
	for shelf_entry in _character_shelf:
		var entry: Dictionary = shelf_entry.duplicate(true)
		var character_id: String = str(entry.get("character_id", ""))
		var character_data: CharacterData = Global.get_character_data(character_id)
		var has_data: bool = character_data != null
		var unlocked: bool = has_data and Global.is_character_unlocked(character_id)
		var unlock_hint: String = Global.get_unlock_hint(character_id)
		if unlock_hint.is_empty():
			unlock_hint = str(entry.get("fallback_hint", ""))
		entry["locked"] = not unlocked
		entry["portrait_path"] = PORTRAIT_DIR + str(entry.get("portrait_file", ""))
		entry["unlock_hint"] = unlock_hint
		if has_data:
			entry["label"] = character_data.character_name
			entry["description"] = character_data.character_description
			if len(character_data.character_starting_artifact_ids) > 0:
				var artifact_data: ArtifactData = Global.get_artifact_data(character_data.character_starting_artifact_ids[0])
				if artifact_data != null:
					entry["starter_name"] = artifact_data.artifact_name
					entry["starter_description"] = artifact_data.artifact_description
		else:
			entry["description"] = str(entry.get("locked_copy", "神像尚未開眼。"))
		entries.append(entry)
	return entries

func _select_default_character_if_needed() -> void:
	if not selected_character_object_id.is_empty() and Global.get_character_data(selected_character_object_id) != null:
		return
	for entry in _build_gallery_entries():
		if not bool(entry.get("locked", true)):
			var character_id: String = str(entry.get("character_id", ""))
			if not character_id.is_empty():
				Signals.character_selected.emit(character_id)
				return
	_on_character_selected("")

func _tags_for_character(character_object_id: String) -> Array:
	for shelf_entry in _character_shelf:
		if str(shelf_entry.get("character_id", "")) == character_object_id:
			return shelf_entry.get("tags", [])
	return []

func _build_hint_for_character(character_object_id: String) -> String:
	for shelf_entry in _character_shelf:
		if str(shelf_entry.get("character_id", "")) == character_object_id:
			return str(shelf_entry.get("build_hint", ""))
	return ""

func _load_character_shelf() -> Array:
	if not FileAccess.file_exists(CHARACTER_SHELF_PATH):
		push_error("NewRunMenu: missing character shelf data: " + CHARACTER_SHELF_PATH)
		return _fallback_character_shelf_from_global()
	var file := FileAccess.open(CHARACTER_SHELF_PATH, FileAccess.READ)
	if file == null:
		push_error("NewRunMenu: cannot open character shelf data: " + CHARACTER_SHELF_PATH)
		return _fallback_character_shelf_from_global()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("NewRunMenu: character shelf JSON must be an array")
		return _fallback_character_shelf_from_global()
	var shelf: Array = []
	for item in parsed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = (item as Dictionary).duplicate(true)
		if not entry.has("tags") or typeof(entry["tags"]) != TYPE_ARRAY:
			entry["tags"] = []
		shelf.append(entry)
	if shelf.is_empty():
		return _fallback_character_shelf_from_global()
	return shelf

func _fallback_character_shelf_from_global() -> Array:
	var shelf: Array = []
	for character_id: String in Global._id_to_character_data.keys():
		var character_data: CharacterData = Global.get_character_data(character_id)
		if character_data == null:
			continue
		shelf.append({
			"character_id": character_id,
			"label": character_data.character_name,
			"portrait_file": "",
			"locked_copy": character_data.character_description,
			"tags": [],
			"build_hint": "",
		})
	return shelf

func _start_run_button_state(can_start: bool) -> void:
	start_run_button.disabled = not can_start

## 鎮島錄 — 2B-UI：建立護壇 / 法器選擇器（OptionButton，選項資料驅動；留空 = 角色預設班底）。
func _build_loadout_pickers() -> void:
	if _guardian_picker != null:
		return
	_guardian_picker = _make_loadout_picker(RitualLoadout.list_guardian_ids(), "護壇", true)
	_guardian_picker.item_selected.connect(_on_guardian_picked)
	add_child(_guardian_picker)
	_tool_picker = _make_loadout_picker(RitualLoadout.list_tool_ids(), "法器", false)
	_tool_picker.item_selected.connect(_on_tool_picked)
	add_child(_tool_picker)

func _make_loadout_picker(ids: Array, prefix: String, is_guardian: bool) -> OptionButton:
	var ob: OptionButton = OptionButton.new()
	ob.name = prefix + "Picker"
	ob.clip_text = true	# UIQA P1-2：min width 不得撐爆排版（曾壓到開始開壇）
	ob.fit_to_longest_item = false
	ob.add_item("%s：（角色預設）" % prefix)
	ob.set_item_metadata(0, "")
	for id: String in ids:
		var disp: String = id
		if is_guardian:
			var g: GuardianData = RitualLoadout.load_guardian(id)
			if g != null and g.guardian_name != "":
				disp = g.guardian_name
		else:
			var t: RitualToolData = RitualLoadout.load_tool(id)
			if t != null and t.tool_name != "":
				disp = t.tool_name
		ob.add_item("%s：%s" % [prefix, disp])
		ob.set_item_metadata(ob.item_count - 1, id)
	return ob

func _on_guardian_picked(idx: int) -> void:
	selected_guardian_id = str(_guardian_picker.get_item_metadata(idx))

func _on_tool_picked(idx: int) -> void:
	selected_ritual_tool_id = str(_tool_picker.get_item_metadata(idx))

func _on_start_run_button_up() -> void:
	if selected_character_object_id.is_empty():
		return
	var run_seed: int = seed_input.text.to_int()
	# 2B-UI：把玩家選的護壇 / 法器帶入 start_run（留空 → 角色預設班底）
	Global.start_run(selected_character_object_id, run_seed, selected_difficulty_level, custom_run_modifier_button_container.selected_custom_run_modififers, selected_guardian_id, selected_ritual_tool_id)

func _on_back_button_up() -> void:
	title_screen.show_main_menu()

func _on_run_ended() -> void:
	var has_save_file: bool = FileLoader.has_save_file()
	visible = not has_save_file
	selected_character_object_id = ""
	populate_new_run_menu()
