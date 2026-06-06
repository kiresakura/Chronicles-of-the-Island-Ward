# Displays run start options
extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

var _option_type_to_option_ids: Dictionary = {}
const MIXED_OPTION_COUNT: int = 3	# number of options to populate that have both an upside and downside
const COMPLETE_OPTION_COUNT: int = 1	# number of unique options to populate

@onready var starting_option_container = $StartingOptionContainer
@onready var map = $%Map

## P0-1 神示供桌：供桌背景素材（取代 debug 紅黑底，建立「擲筊問神」舞台）
const OFFERING_BG_PATH := "res://assets/generated/pixellab/run_start_offering_bg_v1.png"

func _ready():
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
		_apply_offering_card_style(run_start_option_button)	# P0-1：籤詩/供品牌樣式

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
		_apply_offering_card_style(run_start_option_button)	# P0-1：籤詩/供品牌樣式

		run_start_option_button.dialogue_option_clicked.connect(_on_dialogue_option_clicked)
	
func clear_run_start_options() -> void:
	for child in starting_option_container.get_children():
		child.queue_free()
	
func _on_dialogue_option_clicked(dialogue_option: DialogueOption):
	var player: Player = Global.get_player()
	var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(player, null, [player], dialogue_option.action_data, null)
	ActionHandler.add_actions(generated_actions)
	clear_run_start_options()
	visible = false
	
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	
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
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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

## 把選項條變成「籤詩 / 供品牌」：高觸控、紙金卡面、深字可讀、置中。
func _apply_offering_card_style(option: Control) -> void:
	if option == null:
		return
	option.custom_minimum_size = Vector2(560, 90)	# ≥88 觸控高度
	option.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = COTIW_UI_THEME.get_color("paper_warm", Color(0.96, 0.91, 0.81, 1.0))
	sb.bg_color.a = 0.95
	sb.set_corner_radius_all(12)
	sb.set_border_width_all(3)
	sb.border_color = COTIW_UI_THEME.get_color("incense_gold", Color(0.91, 0.77, 0.42, 1.0))
	sb.set_content_margin_all(14)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	option.add_theme_stylebox_override("panel", sb)
	var rtl: Node = option.get_node_or_null("RichTextLabel")
	if rtl is RichTextLabel:
		(rtl as RichTextLabel).add_theme_color_override("default_color", COTIW_UI_THEME.get_color("lacquer_black", Color(0.16, 0.09, 0.08, 1.0)))

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
