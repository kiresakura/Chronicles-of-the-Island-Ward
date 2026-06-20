# 鎮島錄 — 資料驅動完整性驗證
#
# 對應 CLAUDE.md §7「資料載入：每個 JSON schema 要有 validator」。
# 同時作為 P1（角色）/ P2（run_modifier i18n）修復的回歸測試，
# 以及 docs/archive/AUDIT_2026-05-17.md B3 類（敵人 status 引用錯誤）的防線。
extends "res://tests/test_case.gd"

const DATA_ROOT: String = "res://external/data/"

# ---------- P1 回歸：只有鎮島錄角色被註冊 ----------

## 鎮島錄目前可遊玩角色：乩童、鸞女、道士、家將（Phase 2C 新增道士/家將，基礎卡；
## 符位/法陣、陣型專屬機制留 Phase 3）
const COTIW_CHARACTER_IDS: Array[String] = ["character_tongji", "character_luannu", "character_daoshi", "character_jiajiang"]

func test_only_cotiw_characters_registered() -> void:
	for cotiw_id: String in COTIW_CHARACTER_IDS:
		assert_has(Global._id_to_character_data, cotiw_id,
			"鎮島錄角色 %s 必須存在於角色表" % cotiw_id)
	for str_test_id: String in ["character_red", "character_blue", "character_green", "character_orange"]:
		assert_not_has(Global._id_to_character_data, str_test_id,
			"STR 測試角色 %s 不應再被註冊（add_test_characters 已停用）" % str_test_id)

func test_cotiw_character_roster_matches_expected() -> void:
	# 鎮島錄目前的可遊玩角色清單必須與 Global.MASCOT_AVAILABLE_IDS 一致
	# （若日後新增角色，請同步更新 COTIW_CHARACTER_IDS 與 Global 兩處）
	assert_eq(Global._id_to_character_data.size(), COTIW_CHARACTER_IDS.size(),
		"鎮島錄角色表大小應為 %d（乩童/鸞女/道士/家將）" % COTIW_CHARACTER_IDS.size())
	for registered_id: String in Global._id_to_character_data.keys():
		assert_true(COTIW_CHARACTER_IDS.has(registered_id),
			"角色表中出現非鎮島錄角色：%s" % registered_id)

# ---------- 角色 → 玩家原型 / 卡牌 / 遺物 交叉引用 ----------

func test_character_player_prototypes_resolve() -> void:
	for char_id: String in Global._id_to_character_data:
		var cd: CharacterData = Global._id_to_character_data[char_id]
		assert_ne(cd.character_player_id, "",
			"%s 缺 character_player_id" % char_id)
		assert_has(Global._id_to_player_data, cd.character_player_id,
			"%s 的 player 原型 %s 不存在（SCHEMA player/ 應載入）" % [char_id, cd.character_player_id])

## 通用起手內容檢查：對所有鎮島錄角色驗證 起手卡/遺物/遺物包/顏色 都能在 Global 解析。
func test_cotiw_character_starting_content_resolves() -> void:
	for char_id: String in COTIW_CHARACTER_IDS:
		var cd: CharacterData = Global._id_to_character_data.get(char_id)
		assert_not_null(cd, "%s 角色資料缺失" % char_id)
		if cd == null:
			continue
		for card_id: String in cd.character_starting_card_object_ids:
			assert_has(Global._id_to_card_data, card_id,
				"%s 起手卡 %s 未定義" % [char_id, card_id])
		for artifact_id: String in cd.character_starting_artifact_ids:
			assert_has(Global._id_to_artifact_data, artifact_id,
				"%s 起手遺物 %s 未定義" % [char_id, artifact_id])
		for pack_id: String in cd.character_starting_artifact_pack_ids:
			assert_has(Global._id_to_artifact_pack_data, pack_id,
				"%s 遺物包 %s 未定義" % [char_id, pack_id])
		assert_has(Global._id_to_color_data, cd.character_color_id,
			"%s 顏色 %s 未定義" % [char_id, cd.character_color_id])

# ---------- P2 回歸：run_modifier i18n patch 已套用 ----------

func test_run_modifier_i18n_patches_applied() -> void:
	# object_id 必須與 STR add_test_run_modifiers() 一致，patch 才會覆寫成中文
	var endless: RunModifierData = Global._id_to_run_modifier_data.get("run_modifier_endless_mode")
	assert_not_null(endless, "run_modifier_endless_mode 不存在（object_id 與 STR 不符？）")
	if endless != null:
		assert_ne(endless.run_modifier_name, "Endless Mode",
			"無盡模式中文 patch 未套用，仍是英文")
		assert_ne(endless.run_modifier_name, "", "無盡模式名稱為空")

	var prismatic: RunModifierData = Global._id_to_run_modifier_data.get("run_modifier_draft_all_colors")
	assert_not_null(prismatic, "run_modifier_draft_all_colors 不存在（object_id 與 STR 不符？）")
	if prismatic != null:
		assert_ne(prismatic.run_modifier_name, "Prismatic",
			"七彩中文 patch 未套用，仍是英文")

# ---------- B3 類回歸：敵人攻擊狀態的 status 引用必須有效 ----------

func test_enemy_status_references_valid() -> void:
	var status_table: Dictionary = Global._id_to_status_data
	for enemy_id: String in Global._id_to_enemy_data:
		var ed: EnemyData = Global._id_to_enemy_data[enemy_id]
		var states: Dictionary = ed.enemy_attack_states
		for state_name: String in states:
			var state: Dictionary = states[state_name]
			var custom_actions: Array = state.get("custom_actions", [])
			for action_entry: Dictionary in custom_actions:
				for script_path: String in action_entry:
					var params: Dictionary = action_entry[script_path]
					if params.has("status_effect_object_id"):
						var sid: String = params["status_effect_object_id"]
						assert_has(status_table, sid,
							"敵人 %s 狀態 %s 引用未定義的 status %s" % [enemy_id, state_name, sid])

# ---------- JSON schema：所有 action 腳本路徑必須存在 ----------

func test_all_action_script_paths_exist() -> void:
	var json_files: Array[String] = []
	_collect_json_files(DATA_ROOT, json_files)
	assert_true(json_files.size() > 0, "找不到任何資料 JSON")
	for path: String in json_files:
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		_assert_script_paths_in_value(parsed, path)

func _assert_script_paths_in_value(value: Variant, source: String) -> void:
	# 遞迴掃描：任何 "res://....gd" 的 key 都必須是存在的資源
	match typeof(value):
		TYPE_DICTIONARY:
			for k: Variant in value:
				if typeof(k) == TYPE_STRING and (k as String).begins_with("res://") and (k as String).ends_with(".gd"):
					assert_true(ResourceLoader.exists(k),
						"%s 引用不存在的腳本：%s" % [source.get_file(), k])
				_assert_script_paths_in_value(value[k], source)
		TYPE_ARRAY:
			for item: Variant in value:
				_assert_script_paths_in_value(item, source)

func _collect_json_files(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full: String = dir_path + entry
		if dir.current_is_dir():
			_collect_json_files(full + "/", out)
		elif entry.ends_with(".json"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
