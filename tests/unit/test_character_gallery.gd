extends "res://tests/test_case.gd"

const GALLERY_SCENE := preload("res://scenes/ui/menus/CharacterGallery.tscn")
const SLOT_SCENE := preload("res://scenes/ui/menus/CharacterPortraitSlot.tscn")
const NEW_RUN_SHELF_PATH := "res://external/data/ui/new_run_character_shelf.json"
const LOBBY_ACTIONS_PATH := "res://external/data/ui/lobby_actions.json"
const LOBBY_UTILITIES_PATH := "res://external/data/ui/lobby_utilities.json"
const PORTRAIT_DIR := "res://assets/generated/portraits_v3/"

func test_character_gallery_scene_exists_and_instantiates() -> void:
	assert_true(ResourceLoader.exists("res://scenes/ui/menus/CharacterGallery.tscn"), "CharacterGallery scene 必須存在")
	assert_true(ResourceLoader.exists("res://scenes/ui/menus/CharacterPortraitSlot.tscn"), "CharacterPortraitSlot scene 必須存在")
	var gallery := GALLERY_SCENE.instantiate()
	assert_not_null(gallery, "CharacterGallery 必須可實例化")
	if gallery != null:
		gallery.free()

func test_new_run_character_shelf_json_is_valid() -> void:
	assert_true(FileAccess.file_exists(NEW_RUN_SHELF_PATH), "New Run 角色展示資料 JSON 必須存在")
	var file := FileAccess.open(NEW_RUN_SHELF_PATH, FileAccess.READ)
	assert_not_null(file, "New Run 角色展示資料 JSON 必須可讀")
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_eq(typeof(parsed), TYPE_ARRAY, "New Run 角色展示資料必須是 Array")
	if typeof(parsed) != TYPE_ARRAY:
		return
	var seen_ids: Dictionary = {}
	for raw_entry in parsed:
		assert_eq(typeof(raw_entry), TYPE_DICTIONARY, "每個角色展示 entry 必須是 Dictionary")
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = raw_entry
		var character_id: String = str(entry.get("character_id", ""))
		var portrait_file: String = str(entry.get("portrait_file", ""))
		assert_ne(character_id, "", "角色展示 entry 缺 character_id")
		assert_ne(str(entry.get("label", "")), "", "%s 缺 label" % character_id)
		assert_ne(portrait_file, "", "%s 缺 portrait_file" % character_id)
		assert_true(ResourceLoader.exists(PORTRAIT_DIR + portrait_file),
			"%s portrait_file 不存在：%s" % [character_id, portrait_file])
		assert_eq(typeof(entry.get("tags", [])), TYPE_ARRAY, "%s tags 必須是 Array" % character_id)
		assert_ne(str(entry.get("build_hint", "")), "", "%s 缺 build_hint" % character_id)
		seen_ids[character_id] = true
	for registered_id: String in Global._id_to_character_data.keys():
		assert_has(seen_ids, registered_id,
			"已註冊角色 %s 必須出現在 New Run 展示資料中" % registered_id)

func test_lobby_action_and_utility_json_are_valid() -> void:
	var actions: Array = _load_json_array(LOBBY_ACTIONS_PATH)
	assert_eq(actions.size(), 6, "Lobby action slot 應維持 6 格，避免破壞底部構圖")
	for raw_action in actions:
		assert_eq(typeof(raw_action), TYPE_DICTIONARY, "Lobby action 必須是 Dictionary")
		if typeof(raw_action) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = raw_action
		assert_ne(str(action.get("node", "")), "", "Lobby action 缺 node")
		assert_ne(str(action.get("label", "")), "", "Lobby action 缺 label")
		assert_true(ResourceLoader.exists("res://assets/ui/icons/ui_icon_%s_default.svg" % str(action.get("icon", ""))),
			"Lobby action icon 不存在：%s" % str(action.get("icon", "")))
		assert_eq(typeof(action.get("ready", false)), TYPE_BOOL, "%s ready 必須是 bool" % str(action.get("node", "")))
		if bool(action.get("ready", false)):
			assert_true(["run", "codex", "character"].has(str(action.get("act", ""))),
				"%s 已開放 action 必須有有效 act" % str(action.get("node", "")))

	var utilities: Array = _load_json_array(LOBBY_UTILITIES_PATH)
	assert_eq(utilities.size(), 3, "Lobby utility 應維持 3 顆角落工具鈕")
	for raw_utility in utilities:
		assert_eq(typeof(raw_utility), TYPE_DICTIONARY, "Lobby utility 必須是 Dictionary")
		if typeof(raw_utility) != TYPE_DICTIONARY:
			continue
		var utility: Dictionary = raw_utility
		assert_ne(str(utility.get("name", "")), "", "Lobby utility 缺 name")
		assert_true(ResourceLoader.exists("res://assets/ui/icons/ui_icon_%s_default.svg" % str(utility.get("icon", ""))),
			"Lobby utility icon 不存在：%s" % str(utility.get("icon", "")))

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

func test_character_gallery_builds_slot_components_and_tracks_selection() -> void:
	var gallery := GALLERY_SCENE.instantiate()
	Engine.get_main_loop().root.add_child(gallery)
	gallery.size = Vector2(720, 420)
	gallery.setup_entries([
		{
			"character_id": "character_tongji",
			"label": "乩童",
			"portrait_path": "res://assets/generated/portraits_v3/tongji.png",
			"locked": false,
			"tags": ["近戰爆發", "請神"],
			"description": "近身爆發測試",
		},
		{
			"character_id": "character_luannu",
			"label": "鸞女",
			"portrait_path": "res://assets/generated/portraits_v3/luannu.png",
			"locked": false,
			"tags": ["符咒防禦", "控場"],
			"description": "控場測試",
		},
	])
	gallery.select_character("character_luannu")
	var slot_root := gallery.get_node_or_null("SlotRoot") as Control
	assert_not_null(slot_root, "CharacterGallery 必須有 SlotRoot 容器")
	if slot_root != null:
		assert_eq(slot_root.get_child_count(), 2, "CharacterGallery 應依 entries 建立對應 slot 數量")
	assert_eq(gallery.get_selected_character_id(), "character_luannu", "CharacterGallery 必須追蹤目前選中的角色")
	gallery.free()

func test_character_portrait_slot_selected_state_enables_beam_and_smoke() -> void:
	var slot := SLOT_SCENE.instantiate()
	Engine.get_main_loop().root.add_child(slot)
	slot.size = Vector2(160, 360)
	slot.setup({
		"character_id": "character_tongji",
		"label": "乩童",
		"portrait_path": "res://assets/generated/portraits_v3/tongji.png",
		"locked": false,
		"tags": ["近戰爆發", "請神"],
		"description": "測試描述",
	})
	slot.set_selected(true)
	var beam := slot.get_node_or_null("LightBeam") as ColorRect
	var halo := slot.get_node_or_null("AltarHalo") as Panel
	var smoke := slot.get_node_or_null("SmokeParticles") as CPUParticles2D
	var tags := slot.get_node_or_null("TagFlow") as HFlowContainer
	assert_not_null(beam, "slot 必須有選中燈光層")
	assert_not_null(halo, "slot 必須有神壇頂部光暈")
	assert_not_null(smoke, "slot 必須有香煙粒子")
	assert_not_null(tags, "slot 必須有玩法 tag 容器")
	if beam != null:
		assert_true(beam.visible, "選中時燈光必須亮起")
		assert_true(beam.color.a > 0.15, "選中燈光 alpha 不可太弱")
	if halo != null:
		assert_true(halo.visible, "選中時神壇頂部光暈必須亮起")
	if smoke != null:
		assert_true(smoke.emitting, "選中時香煙必須上升")
	if tags != null:
		assert_eq(tags.get_child_count(), 2, "slot 必須建立對應數量的玩法 tags")
	slot.queue_free()

func test_character_portrait_slot_locked_state_uses_seal_instead_of_plain_gray() -> void:
	var slot := SLOT_SCENE.instantiate()
	Engine.get_main_loop().root.add_child(slot)
	slot.size = Vector2(160, 360)
	slot.setup({
		"character_id": "character_daoshi",
		"label": "道士",
		"portrait_path": "res://assets/generated/portraits_v3/daoshi.png",
		"locked": true,
		"unlock_hint": "1 / 3 勝場",
		"tags": ["符陣操作"],
		"description": "封印測試",
	})
	var veil := slot.get_node_or_null("LockVeil") as ColorRect
	var seal := slot.get_node_or_null("SealPaper") as Panel
	var thread_top := slot.get_node_or_null("RedThreadTop") as ColorRect
	var hint := slot.get_node_or_null("HintLabel") as Label
	assert_not_null(veil, "locked slot 必須有遮罩")
	assert_not_null(seal, "locked slot 必須有符紙封印")
	assert_not_null(thread_top, "locked slot 必須有紅線")
	if veil != null:
		assert_true(veil.visible, "locked slot 遮罩必須顯示")
	if seal != null:
		assert_true(seal.visible, "locked slot 符紙不可缺席")
	if thread_top != null:
		assert_true(thread_top.visible, "locked slot 紅線不可缺席")
	if hint != null:
		assert_true(hint.text.contains("1 / 3 勝場"), "locked slot 提示必須帶出期待感與解鎖進度")
	slot.queue_free()
