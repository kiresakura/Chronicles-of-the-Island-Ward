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
		var icon_name: String = str(action.get("icon", ""))
		assert_true(ResourceLoader.exists("res://assets/ui/icons/ui_icon_%s_default.svg" % icon_name)
			or ResourceLoader.exists("res://assets/generated/icons_v2/icon_%s.svg" % icon_name),
			"Lobby action icon 不存在（v1/v2 皆無）：%s" % icon_name)
		assert_eq(typeof(action.get("ready", false)), TYPE_BOOL, "%s ready 必須是 bool" % str(action.get("node", "")))
		if bool(action.get("ready", false)):
			assert_true(["run", "codex", "character", "temple"].has(str(action.get("act", ""))),
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

# 重排後：陣容磚選中態 = 霓虹選中環點亮（稀缺資源）；磚不再重複玩法 tag
# （唯一真相在左側英雄面板）。
func test_character_portrait_slot_selected_state_lights_neon_ring() -> void:
	var slot := SLOT_SCENE.instantiate()
	Engine.get_main_loop().root.add_child(slot)
	slot.size = Vector2(120, 150)
	slot.setup({
		"character_id": "character_tongji",
		"label": "乩童",
		"portrait_path": "res://assets/generated/portraits_v3/tongji.png",
		"locked": false,
		"tags": ["近戰爆發", "請神"],
		"description": "測試描述",
	})
	slot.set_selected(true)
	var ring := slot.get_node_or_null("SelectionRing") as Panel
	assert_not_null(ring, "陣容磚必須有霓虹選中環")
	if ring != null:
		assert_true(ring.visible, "選中時霓虹環必須亮起")
	# 減法 + 單一真相：磚不得再有重複的玩法 tag 容器
	assert_true(slot.get_node_or_null("TagFlow") == null, "陣容磚不應重複顯示 tag（真相在英雄面板）")
	slot.queue_free()

func test_character_portrait_slot_unselected_ring_is_dark() -> void:
	# 霓虹稀缺：未選中磚的環必須暗（對比才出得來）
	var slot := SLOT_SCENE.instantiate()
	Engine.get_main_loop().root.add_child(slot)
	slot.size = Vector2(120, 150)
	slot.setup({
		"character_id": "character_tongji", "label": "乩童",
		"portrait_path": "res://assets/generated/portraits_v3/tongji.png", "locked": false,
	})
	slot.set_selected(false)
	var ring := slot.get_node_or_null("SelectionRing") as Panel
	if ring != null:
		assert_false(ring.visible, "未選中磚的霓虹環必須暗（霓虹是稀缺資源）")
	slot.queue_free()

# 重排後：鎖態 = 剪影（暗化立繪）+ 解鎖進度章（再勝 N 場），勾引而非訓斥。
# 移除原紅叉「封」印（紅線：禁止感 → 期待感）。
func test_character_portrait_slot_locked_state_uses_silhouette_and_progress_stamp() -> void:
	var slot := SLOT_SCENE.instantiate()
	Engine.get_main_loop().root.add_child(slot)
	slot.size = Vector2(120, 150)
	slot.setup({
		"character_id": "character_daoshi",
		"label": "道士",
		"portrait_path": "res://assets/generated/portraits_v3/daoshi.png",
		"locked": true,
		"unlock_hint": "再勝 3 場",
		"tags": ["符陣操作"],
		"description": "封印測試",
	})
	var veil := slot.get_node_or_null("LockVeil") as ColorRect
	var stamp := slot.get_node_or_null("UnlockStamp") as Panel
	var stamp_label := slot.get_node_or_null("UnlockStamp/StampLabel") as Label
	assert_not_null(veil, "鎖態磚必須有剪影遮罩")
	assert_not_null(stamp, "鎖態磚必須有解鎖進度章")
	assert_not_null(stamp_label, "鎖態磚進度章必須有文字")
	if veil != null:
		assert_true(veil.visible, "鎖態剪影遮罩必須顯示")
	if stamp != null:
		assert_true(stamp.visible, "鎖態進度章必須顯示")
	if stamp_label != null:
		assert_true(stamp_label.text.contains("再勝 3 場"), "進度章必須帶出解鎖進度（勾引）")
	# 移除紅叉：不得再有符紙封印與紅線
	assert_true(slot.get_node_or_null("SealPaper") == null, "鎖態不應再有「封」印（禁止感）")
	assert_true(slot.get_node_or_null("RedThreadTop") == null, "鎖態不應再有紅叉紅線")
	slot.queue_free()
