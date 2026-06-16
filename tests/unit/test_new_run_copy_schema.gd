# 鎮島錄 — 新一局／開壇設定畫面文案長度 schema 驗證（鐵律 1：杜絕截斷的源頭防線）。
#
# 對應重排任務 DoD #2「schema validator 含文案長度上限」。預算來自
# RitualCopyBudget（external/data/ui/new_run_copy_budget.json）。任一角色／平安符／
# 標籤文案超過英雄面板可無截斷顯示的上限 → fail，迫使改資料而非事後切字。
extends "res://tests/test_case.gd"

const SHELF_PATH: String = "res://external/data/ui/new_run_character_shelf.json"
const FORBIDDEN_NOUN_SUBSTR: Array[String] = ["韌性", "弱點擊破", "升階", "終結"]	# 名詞紅線

func _load_shelf() -> Array:
	if not FileAccess.file_exists(SHELF_PATH):
		return []
	var f: FileAccess = FileAccess.open(SHELF_PATH, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_ARRAY else []

func test_character_descriptions_within_budget() -> void:
	var budget: NewRunCopyBudgetData = RitualCopyBudget.get_budget()
	for char_id: String in Global._id_to_character_data:
		var cd: CharacterData = Global._id_to_character_data[char_id]
		assert_true(cd.character_description.length() <= budget.max_description,
			"%s 描述 %d 字超過上限 %d（會截斷）：%s" % [char_id, cd.character_description.length(), budget.max_description, cd.character_description])

func test_shelf_copy_within_budget() -> void:
	var budget: NewRunCopyBudgetData = RitualCopyBudget.get_budget()
	for entry: Dictionary in _load_shelf():
		var cid: String = str(entry.get("character_id", "?"))
		assert_true(str(entry.get("locked_copy", "")).length() <= budget.max_description,
			"%s locked_copy 超過上限 %d" % [cid, budget.max_description])
		assert_true(str(entry.get("build_hint", "")).length() <= budget.max_build_hint,
			"%s build_hint 超過上限 %d" % [cid, budget.max_build_hint])
		var tags: Array = entry.get("tags", [])
		assert_true(tags.size() <= budget.max_tag_count,
			"%s 標籤 %d 個超過上限 %d" % [cid, tags.size(), budget.max_tag_count])
		for t: Variant in tags:
			assert_true(str(t).length() <= budget.max_tag_length,
				"%s 標籤「%s」%d 字超過上限 %d" % [cid, str(t), str(t).length(), budget.max_tag_length])

func test_starting_artifact_descriptions_within_budget() -> void:
	var budget: NewRunCopyBudgetData = RitualCopyBudget.get_budget()
	for char_id: String in Global._id_to_character_data:
		var cd: CharacterData = Global._id_to_character_data[char_id]
		for aid: String in cd.character_starting_artifact_ids:
			var ad: ArtifactData = Global.get_artifact_data(aid)
			if ad == null:
				continue
			assert_true(ad.artifact_description.length() <= budget.max_artifact_description,
				"平安符 %s 說明 %d 字超過上限 %d（會截斷）" % [aid, ad.artifact_description.length(), budget.max_artifact_description])

## 名詞紅線：開壇畫面文案不得含禁用詞（防 STR 殘留／回潮）
func test_shelf_copy_obeys_noun_redline() -> void:
	for entry: Dictionary in _load_shelf():
		var blob: String = str(entry.get("locked_copy", "")) + " " + str(entry.get("build_hint", "")) + " " + " ".join(PackedStringArray(entry.get("tags", [])))
		for bad: String in FORBIDDEN_NOUN_SUBSTR:
			assert_false(blob.contains(bad),
				"%s 文案含名詞紅線「%s」：%s" % [str(entry.get("character_id", "?")), bad, blob])

func test_budget_loads_from_data() -> void:
	var budget: NewRunCopyBudgetData = RitualCopyBudget.get_budget()
	assert_eq(budget.object_id, "new_run_copy_budget", "預算應由 JSON 載入（object_id 對得上）")
	assert_true(budget.max_tag_count >= 1 and budget.max_description >= 1, "預算上限須為正")
