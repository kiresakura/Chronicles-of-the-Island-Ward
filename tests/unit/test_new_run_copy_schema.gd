# 鎮島錄 — 新一局／開壇設定畫面文案長度 schema 驗證（鐵律 1：杜絕截斷的源頭防線）。
#
# 對應重排任務 DoD #2「schema validator 含文案長度上限」。預算來自
# RitualCopyBudget（external/data/ui/new_run_copy_budget.json）。任一角色／平安符／
# 標籤文案超過英雄面板可無截斷顯示的上限 → fail，迫使改資料而非事後切字。
extends "res://tests/test_case.gd"

const SHELF_PATH: String = "res://external/data/ui/new_run_character_shelf.json"
const FORBIDDEN_NOUN_SUBSTR: Array[String] = ["韌性", "弱點擊破", "升階", "終結"]	# 名詞紅線
const RSO_SCRIPT := preload("res://scripts/ui/RunStartOptions.gd")	# 籤運階梯來源
const MAX_QIAN_NAME: int = 8		# 籤名上限（避免供桌籤首截斷）
const MAX_QIAN_VERSE: int = 8		# 四字籤詩上限

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

# ---- 神示供桌籤詩（RSO 重設計 Phase 1）----

func test_qian_ladder_is_five_tier() -> void:
	var ladder: Array = RSO_SCRIPT.load_qian_ladder()
	assert_eq(ladder.size(), 5, "籤運統一階梯恰 5 階（上上/上吉/中平/中下/下下）")

func test_run_start_option_qian_data_loaded() -> void:
	# 確認 JSON 籤詩資料確實合進選項物件（非僅程式預設空）
	var d: RunStartOptionData = Global.get_run_start_option_data("run_start_option_artifact_swap")
	assert_not_null(d, "artifact_swap 選項存在")
	if d == null:
		return
	assert_eq(d.option_qian_grade, "上上", "完整選項籤運=上上（確認籤詩資料已載入）")
	assert_ne(d.option_qian_verse, "", "四字籤詩已載入")

func test_run_start_option_qian_grade_in_ladder() -> void:
	var ladder: Array = RSO_SCRIPT.load_qian_ladder()
	for oid: String in Global._id_to_run_start_option_data:
		var d: RunStartOptionData = Global._id_to_run_start_option_data[oid]
		if d.option_qian_grade != "":
			assert_true(ladder.has(d.option_qian_grade), "%s 籤運非法：%s" % [oid, d.option_qian_grade])

func test_run_start_option_qian_within_budget() -> void:
	for oid: String in Global._id_to_run_start_option_data:
		var d: RunStartOptionData = Global._id_to_run_start_option_data[oid]
		assert_true(d.option_qian_name.length() <= MAX_QIAN_NAME,
			"%s 籤名 %d 字超上限 %d" % [oid, d.option_qian_name.length(), MAX_QIAN_NAME])
		assert_true(d.option_qian_verse.length() <= MAX_QIAN_VERSE,
			"%s 四字籤詩 %d 字超上限 %d" % [oid, d.option_qian_verse.length(), MAX_QIAN_VERSE])

# §2/§5：別讓英文「Boss」外洩到畫面（artifact_boss_* 測試遺物用「大醮遺物」呈現）。
func test_no_boss_leak_in_run_start_option_bbcode() -> void:
	for oid: String in Global._id_to_run_start_option_data:
		var bb: String = Global._id_to_run_start_option_data[oid].run_start_option_bb_code
		assert_false(bb.containsn("boss"), "%s bb_code 外洩英文 Boss：%s" % [oid, bb])

func test_artifact_boss_excluded_from_draft_packs() -> void:
	# 測試用 artifact_boss_* 不得進正式抽池（否則「Boss」遺物會出現在玩家選擇）
	var dir := DirAccess.open("res://external/data/artifact_packs/")
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry.ends_with(".json"):
			var f := FileAccess.open("res://external/data/artifact_packs/" + entry, FileAccess.READ)
			if f != null:
				assert_false(f.get_as_text().contains("artifact_boss"),
					"artifact_pack %s 含 artifact_boss（測試遺物外洩抽池）" % entry)
		entry = dir.get_next()
	dir.list_dir_end()

func test_budget_loads_from_data() -> void:
	var budget: NewRunCopyBudgetData = RitualCopyBudget.get_budget()
	assert_eq(budget.object_id, "new_run_copy_budget", "預算應由 JSON 載入（object_id 對得上）")
	assert_true(budget.max_tag_count >= 1 and budget.max_description >= 1, "預算上限須為正")
