extends "res://tests/test_case.gd"

const MAP := preload("res://scripts/ui/Map.gd")
const REWARD_OVERLAY := preload("res://scripts/ui/RewardOverlay.gd")
const NEW_RUN_MENU := preload("res://scripts/ui/menus/NewRunMenu.gd")
const NEW_RUN_SHELF_PATH := "res://external/data/ui/new_run_character_shelf.json"

func test_p1_character_shelf_uses_three_concise_playstyle_tags_without_iap_pressure() -> void:
	var shelf := _load_json_array(NEW_RUN_SHELF_PATH)
	assert_true(shelf.size() >= 3, "P1 請神選角至少要呈現三個核心角色幻想")
	for raw_entry in shelf:
		assert_eq(typeof(raw_entry), TYPE_DICTIONARY, "角色 shelf entry 必須是 Dictionary")
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var character_id := str(entry.get("character_id", ""))
		var tags: Array = entry.get("tags", [])
		assert_eq(tags.size(), 3, "%s 必須剛好三個玩法 tag，避免長文說明" % character_id)
		for raw_tag in tags:
			var tag := str(raw_tag)
			assert_true(tag.length() <= 6, "%s 的 tag「%s」應短到手機上一眼可讀" % [character_id, tag])
		var all_copy := "%s %s %s" % [entry.get("locked_copy", ""), entry.get("fallback_hint", ""), entry.get("build_hint", "")]
		for forbidden in ["IAP", "課金", "付費", "元寶購買", "買戰力"]:
			assert_false(all_copy.contains(forbidden), "%s 選角/解鎖文案不可造成付費戰力壓力：%s" % [character_id, forbidden])

func test_p1_map_paths_are_pilgrimage_routes_with_boss_omen_metadata() -> void:
	var reachable_line: Line2D = MAP.make_map_path_line(Vector2(24, 32), Vector2(180, 220), MAP.ROUTE_STATE_REACHABLE)
	assert_eq(str(reachable_line.get_meta("route_story")), "pilgrimage_route", "P1 地圖連線必須宣告巡境路線語言")
	assert_eq(str(reachable_line.get_meta("direction_cue")), "incense_guidance", "可走路線必須有香火引路方向語意")
	assert_true(reachable_line.gradient != null and reachable_line.points.size() >= 3, "巡境路線需要漸層與彎折，不是裸直線")
	reachable_line.queue_free()

	var omen: Control = MAP.make_boss_omen_marker(Vector2(320, 80))
	assert_not_null(omen, "P1 地圖必須可建立 Boss 壓迫遠景 marker")
	assert_eq(str(omen.get_meta("route_story")), "boss_omen", "Boss 遠景需有穩定 metadata")
	assert_not_null(omen.get_node_or_null("BossOmenLabel"), "Boss marker 必須有虎爺關/廟門壓迫 label")
	omen.queue_free()

func test_p1_reward_overlay_builds_offering_table_language() -> void:
	var table: Panel = REWARD_OVERLAY.make_offering_table_panel(Vector2(640, 360))
	assert_not_null(table, "P1 獎勵 overlay 必須建立供桌/紅布容器")
	assert_eq(str(table.get_meta("reward_language")), "offering_table", "Reward 不應只是按鈕列表，必須宣告供桌語言")
	assert_not_null(table.get_node_or_null("OfferingCloth"), "供桌需要紅布/桌面視覺層")
	assert_not_null(table.get_node_or_null("OfferingTitle"), "供桌需要清楚提示三選一/領取語意")
	assert_not_null(table.get_node_or_null("ChoiceRuleLabel"), "供桌需要說明只能選一份，降低誤解")
	assert_true(table.has_theme_stylebox_override("panel"), "供桌 panel 必須走 theme stylebox")
	table.queue_free()

func test_p1_new_run_bottom_controls_do_not_overlap_guide_copy() -> void:
	var layout: Dictionary = NEW_RUN_MENU.calculate_p1_bottom_control_layout(Rect2(Vector2.ZERO, Vector2(2772, 1280)))
	for required_key in ["start", "seed", "hint"]:
		assert_true(layout.has(required_key), "P1 NewRun layout 必須回傳 %s rect" % required_key)
	var start_rect: Rect2 = layout["start"]
	var seed_rect: Rect2 = layout["seed"]
	var hint_rect: Rect2 = layout["hint"]
	assert_false(start_rect.intersects(hint_rect), "開始開壇 CTA 不可壓到如何開始文案")
	assert_false(start_rect.intersects(seed_rect), "開始開壇 CTA 不可壓到種子輸入")
	assert_true(start_rect.size.y >= 54.0, "開始開壇 CTA 必須維持手機可點高度")

func _load_json_array(path: String) -> Array:
	assert_true(FileAccess.file_exists(path), "%s 必須存在" % path)
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "%s 必須可讀" % path)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_eq(typeof(parsed), TYPE_ARRAY, "%s 必須是 Array" % path)
	if typeof(parsed) != TYPE_ARRAY:
		return []
	return parsed
