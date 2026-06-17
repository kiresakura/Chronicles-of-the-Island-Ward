# Displays run start options
extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const JIAOBEI_FX := preload("res://scripts/ui/fx/JiaoBeiFX.gd")

var _option_type_to_option_ids: Dictionary = {}
const MIXED_OPTION_COUNT: int = 3	# number of options to populate that have both an upside and downside
const COMPLETE_OPTION_COUNT: int = 1	# number of unique options to populate

@onready var starting_option_container = $StartingOptionContainer
@onready var map = $%Map

## P0-1 神示供桌：供桌背景素材（取代 debug 紅黑底，建立「擲筊問神」舞台）
const OFFERING_BG_PATH := "res://assets/generated/scenes_v2/run_start_offering_bg_v2.png"	# Q2-E：v2 供桌（中央淨空給籤詩列）

## v0.3 籤運統一階梯（唯一一套，best→worst）：資料層 external/data/qian_grades.json
## （鐵律1：階梯不寫死於腳本；亦避免民俗籤運被 i18n 當程式中文）。
const QIAN_GRADES_PATH := "res://external/data/qian_grades.json"
const STRIP_SEPARATION: float = 16.0
var _qian_ladder: Array = []	# 籤運由好到壞；index 越小越吉

# Phase 2 籤運視覺階梯（tier 5=上上…1=下下；非籤運→預設中平 tier3）。色非中文，i18n 安全。
const TIER_BORDER: Dictionary = {
	5: Color(1.00, 0.86, 0.42), 4: Color(0.91, 0.77, 0.42), 3: Color(0.74, 0.64, 0.42),
	2: Color(0.58, 0.52, 0.46), 1: Color(0.46, 0.44, 0.44),
}
const TIER_HEAD_BG: Dictionary = {
	5: Color(0.66, 0.16, 0.10, 1.0), 4: Color(0.56, 0.14, 0.10, 1.0), 3: Color(0.46, 0.16, 0.12, 1.0),
	2: Color(0.38, 0.18, 0.16, 1.0), 1: Color(0.30, 0.28, 0.27, 1.0),	# 下下：灰燼
}
const TIER_PAPER: Dictionary = {	# 紙底：上上偏亮、下下偏灰，其餘 paper_warm
	5: Color(0.98, 0.94, 0.82, 0.97), 1: Color(0.74, 0.72, 0.70, 0.96),
}

## 讀籤運階梯（best→worst）。RSO 視覺階梯 + validator 共用。
static func load_qian_ladder() -> Array:
	if not FileAccess.file_exists(QIAN_GRADES_PATH):
		return []
	var f := FileAccess.open(QIAN_GRADES_PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	return (parsed as Dictionary).get("properties", {}).get("ladder", [])

## 籤運 → tier（上上=ladder長度…下下=1；不在階梯回 0）。
func _grade_tier(grade: String) -> int:
	var idx: int = _qian_ladder.find(grade)
	if idx < 0:
		return 0
	return _qian_ladder.size() - idx

## 籤運貼圖裝飾（素材存在才套；無則靠程序化階梯撐，§0.4 美術非阻塞）。
func _apply_tier_decals(option: Control, tier: int) -> void:
	var frame_path: String = "res://assets/generated/ui_v2/qian_frame_%d.png" % tier
	if ResourceLoader.exists(frame_path) and option.get_node_or_null("QianFrame") == null:
		var frame := TextureRect.new()
		frame.name = "QianFrame"
		frame.texture = load(frame_path)
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		option.add_child(frame)
	var seal_path: String = "res://assets/generated/ui_v2/qian_seal_%d.png" % tier
	if ResourceLoader.exists(seal_path) and option.get_node_or_null("QianSeal") == null:
		var seal := TextureRect.new()
		seal.name = "QianSeal"
		seal.texture = load(seal_path)
		seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		seal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.custom_minimum_size = Vector2(44, 44)
		seal.size = Vector2(44, 44)
		seal.position = Vector2(8, 8)	# 籤首左上角印章
		option.add_child(seal)
var _resolving: bool = false	# 擲筊演出中鎖重入

func _ready():
	_qian_ladder = load_qian_ladder()
	_aggregate_run_start_options()
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	Signals.map_location_selected.connect(_on_map_location_selected)
	_apply_offering_chrome()	# P0-1：神示供桌 chrome（additive，不動流程）

func _aggregate_run_start_options() -> void:
	# sorts the various options into boxes based on type
	for option_type in RunStartOptionData.RUN_START_OPTION_TYPES.values():
		_option_type_to_option_ids[option_type] = [] as Array[String]
	for run_start_option_data in Global._id_to_run_start_option_data.values() as Array[RunStartOptionData]:
		_option_type_to_option_ids[run_start_option_data.run_start_option_type].append(run_start_option_data.object_id)

func populate_run_start_options() -> void:
	# Presents a list of options to the player
	_resolving = false
	_relayout_offering_strips()	# Q2-B：容器轉橫排 + 依視口置中（四支籤詩並立）

	_update_fortune_banner()	# Q3-E：籤詩亭開局籤顯示（無籤自動隱藏）

	# get options based on type
	var upside_option_ids: Array[String] = _option_type_to_option_ids[RunStartOptionData.RUN_START_OPTION_TYPES.PARTIAL_UPSIDE]
	var complete_option_ids: Array[String] = _option_type_to_option_ids[RunStartOptionData.RUN_START_OPTION_TYPES.COMPLETE]
	var downside_option_ids: Array[String] = _option_type_to_option_ids[RunStartOptionData.RUN_START_OPTION_TYPES.PARTIAL_DOWNSIDE]
	
	# duplicate for later removal of items
	downside_option_ids = downside_option_ids.duplicate()
	upside_option_ids = upside_option_ids.duplicate()
	complete_option_ids = complete_option_ids.duplicate()
	
	# randomize presented options
	var rng_run_start_options: RandomNumberGenerator = Global.player_data.get_player_rng("rng_run_start_options")
	Random.shuffle_array(rng_run_start_options, downside_option_ids)
	Random.shuffle_array(rng_run_start_options, upside_option_ids)
	Random.shuffle_array(rng_run_start_options, downside_option_ids)
	
	# populate mixed options
	var mixed_option_count: int = min(MIXED_OPTION_COUNT, len(upside_option_ids), len(downside_option_ids))
	for i in mixed_option_count:
		var upside_option_id: String = upside_option_ids.pop_back()
		var downside_option_id: String = downside_option_ids.pop_back()
		
		DebugLogger.log_line("Run options: " + upside_option_id + " " + downside_option_id)
		
		var upside_run_start_option_data: RunStartOptionData = Global.get_run_start_option_data(upside_option_id)
		var downside_run_start_option_data: RunStartOptionData = Global.get_run_start_option_data(downside_option_id)
		
		var upside_actions: Array[Dictionary] = upside_run_start_option_data.run_start_option_actions.duplicate()
		var downside_actions: Array[Dictionary] = downside_run_start_option_data.run_start_option_actions.duplicate()

		# concatenate partial text and actions
		var option_bbcode: String = upside_run_start_option_data.run_start_option_bb_code + ", " + downside_run_start_option_data.run_start_option_bb_code
		var option_actions: Array[Dictionary] = downside_run_start_option_data.run_start_option_actions + upside_run_start_option_data.run_start_option_actions
		
		# create a dialogue button for the option
		var run_start_option_button: DialogueOption = Scenes.DIALOGUE_OPTION.instantiate()
		starting_option_container.add_child(run_start_option_button)
		run_start_option_button.init("", option_bbcode, option_bbcode, option_actions, [])
		COTIW_UI_THEME.apply_panel_style(run_start_option_button)
		# 混合卡：顯示 upside（boon）的籤；利忌走 bbcode
		_apply_offering_strip_style(run_start_option_button, i, option_bbcode,
			upside_run_start_option_data.option_qian_name,
			upside_run_start_option_data.option_qian_verse,
			upside_run_start_option_data.option_qian_grade)

		run_start_option_button.dialogue_option_clicked.connect(_on_dialogue_option_clicked)

	# populate complete options
	for i in min(COMPLETE_OPTION_COUNT, len(complete_option_ids)):
		# get option
		var complete_option_id: String = complete_option_ids.pop_back()
		var complete_run_start_option_data: RunStartOptionData = Global.get_run_start_option_data(complete_option_id)

		# get actions and bbcode
		var option_bbcode: String = complete_run_start_option_data.run_start_option_bb_code
		var option_actions: Array[Dictionary] = complete_run_start_option_data.run_start_option_actions

		# create a dialogue button for the option
		var run_start_option_button: DialogueOption = Scenes.DIALOGUE_OPTION.instantiate()
		starting_option_container.add_child(run_start_option_button)
		run_start_option_button.init("", option_bbcode, option_bbcode, option_actions, [])
		COTIW_UI_THEME.apply_panel_style(run_start_option_button)
		# 完整卡：顯示自身的籤（通常上上）
		_apply_offering_strip_style(run_start_option_button, MIXED_OPTION_COUNT + i, option_bbcode,
			complete_run_start_option_data.option_qian_name,
			complete_run_start_option_data.option_qian_verse,
			complete_run_start_option_data.option_qian_grade)

		run_start_option_button.dialogue_option_clicked.connect(_on_dialogue_option_clicked)

func clear_run_start_options() -> void:
	for child in starting_option_container.get_children():
		child.queue_free()
	
func _on_dialogue_option_clicked(dialogue_option: DialogueOption):
	# Q2-B 擲筊問神：效果即刻生效（演出鐵律 — 結算不等演出）；
	# 筊杯演出為 overlay 節拍（1.15s ≤ 1.5s），其間鎖選項防重入。
	if _resolving:
		return
	_resolving = true
	var player: Player = Global.get_player()
	var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(player, null, [player], dialogue_option.action_data, null)
	ActionHandler.add_actions(generated_actions)

	# 選中演出：本籤升起鍍金、其餘籤退場
	for child in starting_option_container.get_children():
		if child is DialogueOption:
			(child as DialogueOption).option_enabled = false
			var tw := (child as Control).create_tween()
			if child == dialogue_option:
				tw.set_parallel(true)
				tw.tween_property(child, "modulate", Color(1.18, 1.10, 0.86), 0.18)
				tw.tween_property(child, "position:y", (child as Control).position.y - 14.0, 0.22) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			else:
				tw.tween_property(child, "modulate:a", 0.22, 0.20)

	# 擲筊（供桌中央偏下）+ 落地木響
	var stage: Rect2 = Rect2(Vector2.ZERO, COTIW_UI_THEME.get_stage_size())
	var resp: Node = get_node_or_null("/root/Responsive")
	if resp != null:
		stage = resp.screen_rect
	JIAOBEI_FX.play(self, stage.position + stage.size * Vector2(0.5, 0.58))
	get_tree().create_timer(0.55).timeout.connect(func() -> void: AudioManager.play_sfx("turn_end"))

	# 演出節拍 + actions 收尾後進地圖
	await get_tree().create_timer(1.15).timeout
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended

	clear_run_start_options()
	visible = false
	_resolving = false
	map.can_travel = true
	map.show_map()
	
func _on_run_started():
	visible = false
	
func _on_run_ended():
	visible = false

func _on_map_location_selected(location_data: LocationData):
	# determine what to do when the player visits a new location
	var location_type: int = location_data.location_type

	visible = false
	match location_type:
		LocationData.LOCATION_TYPES.STARTING:
			populate_run_start_options()
			visible = true
			_play_offering_omen()	# P1：神示金光提示（擲筊問神得示）


# ───────────────── P0-1 神示供桌 chrome（additive；保留節點與流程） ─────────────────

## 以供桌背景 + 紅布暗角取代 debug 紅黑底，讓「擲筊問神」成為儀式舞台。
func _apply_offering_chrome() -> void:
	var backdrop: Node = get_node_or_null("RSOBackdrop")
	if backdrop is CanvasItem:
		(backdrop as CanvasItem).visible = false	# 隱藏 debug 紅黑底（保留節點，不刪）
	if not ResourceLoader.exists(OFFERING_BG_PATH):
		if backdrop is CanvasItem:
			(backdrop as CanvasItem).visible = true	# 找不到素材就回退原底
		return
	if get_node_or_null("RSOOfferingBg") == null:
		var bg := TextureRect.new()
		bg.name = "RSOOfferingBg"
		bg.texture = load(OFFERING_BG_PATH)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		# UIQA P1-1：供桌圖兼任 modal 視覺+輸入遮罩 — 全出血（COVERED 自行裁切）+ STOP
		bg.mouse_filter = Control.MOUSE_FILTER_STOP
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.add_to_group("fullbleed_mask")
		add_child(bg)
		move_child(bg, 0)	# 置於最底，標題/副標/籤詩卡在其上
	# 暗角加深一點，確保金字在亮供桌上仍可讀
	var vignette: Node = get_node_or_null("RSOVignette")
	if vignette is ColorRect:
		(vignette as ColorRect).color = Color(0.08, 0.04, 0.04, 0.40)
	if starting_option_container is Control:
		(starting_option_container as Control).add_theme_constant_override("separation", 14)
	# P1：神示 presenter — 乩童立繪站在右側（「這是你的起手命格」敘事）
	const PRESENTER := "res://assets/generated/portraits_v3/tongji.png"
	if get_node_or_null("RSOPresenter") == null and ResourceLoader.exists(PRESENTER):
		var presenter := TextureRect.new()
		presenter.name = "RSOPresenter"
		presenter.texture = load(PRESENTER)
		presenter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		presenter.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		presenter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		presenter.position = Vector2(936, 246)
		presenter.size = Vector2(252, 432)
		add_child(presenter)	# 置頂層：站在供桌前（右側，不擋中央籤詩卡）

## Q3-E 籤詩帶：籤詩亭解鎖後，開局籤（一利一弊）顯示在副標下方。冪等；無籤隱藏。
func _update_fortune_banner() -> void:
	var banner: Label = get_node_or_null("FortuneStickBanner") as Label
	if Global.run_fortune_stick_id == "":
		if banner != null:
			banner.visible = false
		return
	if banner == null:
		banner = Label.new()
		banner.name = "FortuneStickBanner"
		banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		banner.add_theme_font_size_override("font_size", 17)
		banner.add_theme_color_override("font_color", Color(1.0, 0.9, 0.62))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.38, 0.09, 0.07, 0.92)
		sb.border_color = COTIW_UI_THEME.get_color("incense_gold", Color(0.91, 0.77, 0.42))
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(9)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		banner.add_theme_stylebox_override("normal", sb)
		add_child(banner)
	banner.text = tr("rso.fortune_prefix") + FortuneSticks.stick_summary(FortuneSticks.load_stick(Global.run_fortune_stick_id))
	banner.visible = true
	var safe: Rect2 = COTIW_UI_THEME.get_safe_content_rect(get_viewport())
	banner.size = Vector2.ZERO
	banner.position = Vector2(safe.position.x + safe.size.x * 0.5 - 280.0, safe.position.y + 152.0)

## Q2-B 容器重排：VBox 轉橫排（BoxContainer.vertical=false）+ 依視口安全區置中。
## 四支籤詩並立 — 1200×700 與 4:3 皆以 stage 寬重算（地圖同款 runtime 置中思路）。
func _relayout_offering_strips() -> void:
	var box: BoxContainer = starting_option_container as BoxContainer
	if box == null:
		return
	if box is VBoxContainer:
		# VBoxContainer 鎖死 vertical（子類硬定向，runtime 設 false 無效 — 實測）→
		# 建 HBox 接管原節點名（driver/外部路徑不變），舊 VBox 保留隱藏（fork-first：不刪節點）。
		var parent: Node = box.get_parent()
		box.name = "StartingOptionContainerLegacy"
		box.visible = false
		var row := HBoxContainer.new()
		row.name = "StartingOptionContainer"
		parent.add_child(row)
		starting_option_container = row
		box = row
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", int(STRIP_SEPARATION))
	var safe: Rect2 = COTIW_UI_THEME.get_safe_content_rect(get_viewport())
	var width: float = minf(880.0, safe.size.x - 56.0)
	var top: float = safe.position.y + safe.size.y * 0.285
	var height: float = minf(404.0, safe.position.y + safe.size.y - top - 64.0)
	box.position = Vector2(safe.position.x + (safe.size.x - width) * 0.5, top)
	box.size = Vector2(width, height)
	# 乩童立繪：移到籤詩「後方」（tree 序在容器前 = 先繪）+ 貼安全區右緣 —
	# 1244 窄幅下不再壓到第四籤的可讀面
	var presenter: Control = get_node_or_null("RSOPresenter") as Control
	if presenter != null:
		var box_index: int = (box as Node).get_index()
		if presenter.get_index() > box_index:
			move_child(presenter, box_index)
		presenter.position = Vector2(safe.position.x + safe.size.x - presenter.size.x + 26.0,
			safe.position.y + safe.size.y - presenter.size.y - 8.0)

## Q2-B 直立籤詩：硃砂籤首帶（干支+籤等）+ 紙底金框直條 + 內文置中。
## PanelContainer 內重組為 VBox（DialogueOption 的 rich_text_label 引用是 cached var，reparent 安全）。
func _apply_offering_strip_style(option: Control, index: int, option_bbcode: String,
		qian_name: String = "", qian_verse: String = "", qian_grade: String = "") -> void:
	if option == null:
		return
	option.set_meta("qian_grade", qian_grade)	# Phase 2 視覺階梯依此分支
	var tier: int = _grade_tier(qian_grade)
	if tier == 0:
		tier = 3	# 無籤運 → 預設中平視覺
	var box: Control = starting_option_container as Control
	var strip_h: float = maxf(320.0, box.size.y if box != null else 380.0)
	# 上上額外加寬，一眼跳出（慶祝稀有）
	option.custom_minimum_size = Vector2(212 if tier == 5 else 196, strip_h)	# 寬 ≥80 舒適觸控、整支可點
	option.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var sb := StyleBoxFlat.new()
	sb.bg_color = TIER_PAPER.get(tier, COTIW_UI_THEME.get_color("paper_warm", Color(0.96, 0.91, 0.81, 0.96)))
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(4 if tier == 5 else (3 if tier >= 3 else 2))
	sb.border_color = TIER_BORDER.get(tier, Color(0.91, 0.77, 0.42))
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 0	# 籤首帶頂部貼框
	sb.content_margin_bottom = 10
	# 上上：金光暈（gold halo shadow）；其餘黑投影；下下：暗淡無暈
	if tier == 5:
		sb.shadow_color = Color(1.0, 0.85, 0.40, 0.55)
		sb.shadow_size = 13
		sb.shadow_offset = Vector2(0, 2)
	else:
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.30 if tier >= 2 else 0.18)
		sb.shadow_size = 6 if tier >= 2 else 3
		sb.shadow_offset = Vector2(0, 4)
	option.add_theme_stylebox_override("panel", sb)
	# 下下：整支灰化（灰燼感），其餘正常
	option.modulate = Color(0.82, 0.80, 0.78) if tier == 1 else Color.WHITE
	# 籤運貼圖框/印章（素材若存在；無則靠上方程序化階梯，§0.4 非阻塞）
	_apply_tier_decals(option, tier)

	# 內部重組：籤首帶 + 內文（一次性，冪等）
	if option.get_node_or_null("OmenStack") == null:
		var stack := VBoxContainer.new()
		stack.name = "OmenStack"
		stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_theme_constant_override("separation", 8)
		option.add_child(stack)

		# 籤首帶：籤名（真籤詩靈魂回 C 位，取代干支 omen.head）
		var head := Label.new()
		head.name = "OmenHead"
		head.text = qian_name if qian_name != "" else option_bbcode
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		head.custom_minimum_size = Vector2(0, 52)
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_theme_font_size_override("font_size", 19)
		head.add_theme_color_override("font_color", Color(1.0, 0.92, 0.72))
		var head_sb := StyleBoxFlat.new()
		head_sb.bg_color = TIER_HEAD_BG.get(tier, Color(0.56, 0.14, 0.10, 1.0))	# 硃砂帶（依籤運深淺）
		head_sb.corner_radius_top_left = 8
		head_sb.corner_radius_top_right = 8
		head_sb.border_width_bottom = 2
		head_sb.border_color = COTIW_UI_THEME.get_color("incense_gold", Color(0.91, 0.77, 0.42, 1.0))
		head.add_theme_stylebox_override("normal", head_sb)
		stack.add_child(head)

		# 四字籤詩（民俗詩句語氣）
		var verse := Label.new()
		verse.name = "OmenVerse"
		verse.text = qian_verse
		verse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		verse.mouse_filter = Control.MOUSE_FILTER_IGNORE
		verse.add_theme_font_size_override("font_size", 22)
		verse.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("lacquer_black", Color(0.16, 0.09, 0.08, 1.0)))
		stack.add_child(verse)

		# 籤運（Phase 2 依 tier 上色/印章）
		var grade := Label.new()
		grade.name = "OmenGrade"
		grade.text = qian_grade
		grade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grade.add_theme_font_size_override("font_size", 17 if tier == 5 else 15)
		grade.add_theme_color_override("font_color", TIER_BORDER.get(tier, Color(0.72, 0.52, 0.22, 1.0)))
		stack.add_child(grade)

		# 內文垂直置中：上下彈簧 Control 夾住 fit_content 的 RTL
		var spring_top := Control.new()
		spring_top.name = "SpringTop"
		spring_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
		spring_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(spring_top)
		var rtl: Node = option.get_node_or_null("RichTextLabel")
		if rtl is RichTextLabel:
			rtl.reparent(stack)	# DialogueOption 的引用是 @onready cached var → reparent 後仍有效
			(rtl as RichTextLabel).fit_content = true
			(rtl as Control).size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var spring_bottom := Control.new()
		spring_bottom.name = "SpringBottom"
		spring_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
		spring_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(spring_bottom)
		# 籤尾飾線（雙金線，補直條下段留白的版式重量）
		var foot := Panel.new()
		foot.name = "OmenFoot"
		foot.custom_minimum_size = Vector2(0, 8)
		foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var foot_sb := StyleBoxFlat.new()
		foot_sb.bg_color = Color.TRANSPARENT
		foot_sb.border_color = COTIW_UI_THEME.get_color("incense_gold", Color(0.91, 0.77, 0.42, 0.8))
		foot_sb.border_width_top = 2
		foot_sb.border_width_bottom = 2
		foot.add_theme_stylebox_override("panel", foot_sb)
		stack.add_child(foot)

	var rtl2: Node = option.get_node_or_null("OmenStack/RichTextLabel")
	if rtl2 is RichTextLabel:
		var r := rtl2 as RichTextLabel
		r.add_theme_color_override("default_color", COTIW_UI_THEME.get_color("lacquer_black", Color(0.16, 0.09, 0.08, 1.0)))
		r.add_theme_font_size_override("normal_font_size", 17)
		r.add_theme_font_size_override("bold_font_size", 17)
		r.parse_bbcode("[center]" + option_bbcode + "[/center]")

	# 按壓回饋（三態：常態/按下/鎖定由 modulate 表達）
	if not option.gui_input.is_connected(_on_strip_gui_input):
		option.gui_input.connect(_on_strip_gui_input.bind(option))

func _on_strip_gui_input(event: InputEvent, option: Control) -> void:
	if _resolving or option == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			option.modulate = Color(0.88, 0.88, 0.88) if mb.pressed else Color.WHITE

## P1：神示金光提示 — 供桌出現時，供桌中央一道金光脈動（擲筊問神得示）。一次性、自我清理。
const OMEN_GLOW := "res://assets/generated/fx/offering_omen_glow_v1.png"

func _play_offering_omen() -> void:
	if not ResourceLoader.exists(OMEN_GLOW):
		return
	if get_node_or_null("OfferingOmenGlow") != null:
		return
	var glow := TextureRect.new()
	glow.name = "OfferingOmenGlow"
	glow.texture = load(OMEN_GLOW)
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.size = Vector2(440, 440)
	glow.pivot_offset = Vector2(220, 220)
	glow.position = Vector2(600 - 220, 350 - 220)	# 供桌中央偏下
	glow.modulate = Color(1, 1, 1, 0)
	glow.scale = Vector2(0.5, 0.5)
	add_child(glow)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(glow, "modulate:a", 0.72, 0.24)
	tw.tween_property(glow, "scale", Vector2(1.12, 1.12), 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_property(glow, "modulate:a", 0.0, 0.55).set_delay(0.38)
	tw.chain().tween_callback(func() -> void:
		if is_instance_valid(glow):
			glow.queue_free())
