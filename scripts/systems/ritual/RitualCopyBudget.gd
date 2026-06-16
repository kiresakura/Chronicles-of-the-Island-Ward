# 鎮島錄 — 新一局文案長度預算載入器（鐵律 1：文案截斷的源頭防線）。
#
# 讀 external/data/ui/new_run_copy_budget.json → NewRunCopyBudgetData，
# 供 test_new_run_copy_schema 強制檢查、供 NewRunMenu 取上限決定版面尺寸
# （面板寬高由上限換算 → 預算內文案保證無截斷）。靜態，沿 FortuneSticks 慣例。
#
# 數字←→版面對應（調英雄面板尺寸時，兩處同步）：
#   max_tagline 18    ← 姓名下單行定位，面板寬 ~292px / 16px 字
#   max_description 60 ← 正文 autowrap 3 行區
#   max_artifact_description 64 ← 法器列正文 autowrap 區
#   max_tag_length 6 / max_tag_count 3 ← 標籤膠囊列單行 3 顆
class_name RitualCopyBudget
extends RefCounted

const BUDGET_PATH: String = "res://external/data/ui/new_run_copy_budget.json"

static var _cached: NewRunCopyBudgetData = null

static func get_budget() -> NewRunCopyBudgetData:
	if _cached != null:
		return _cached
	var b: NewRunCopyBudgetData = NewRunCopyBudgetData.new()	# 缺檔 → 用類別 @export 預設值（不炸）
	if FileAccess.file_exists(BUDGET_PATH):
		var f: FileAccess = FileAccess.open(BUDGET_PATH, FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				var props: Dictionary = (parsed as Dictionary).get("properties", {})
				b.object_id = str(props.get("object_id", "new_run_copy_budget"))
				b.max_tagline = int(props.get("max_tagline", b.max_tagline))
				b.max_description = int(props.get("max_description", b.max_description))
				b.max_artifact_description = int(props.get("max_artifact_description", b.max_artifact_description))
				b.max_tag_length = int(props.get("max_tag_length", b.max_tag_length))
				b.max_tag_count = int(props.get("max_tag_count", b.max_tag_count))
				b.max_build_hint = int(props.get("max_build_hint", b.max_build_hint))
	_cached = b
	return b
