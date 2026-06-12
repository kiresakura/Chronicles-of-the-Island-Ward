# 鎮島錄 Q3-E — 籤詩亭開局籤（QUESTIONS Q3-C 風險對沖型，憲龍拍板 2026-06-11）。
#
# 籤詩亭（building_fortune_pavilion）≥1 級解鎖：開局確定性抽一支籤，
# 全趟 run 生效「一利一弊」修飾。資料 external/data/fortune_sticks/*.json
# （數值全在資料層 — 鐵律 1）；抽籤走 run rng（同種子同籤，可重現）。
# Lv2 設計意圖（更多籤種）：資料驅動 — 加 JSON 即擴池，本系統不用改。
class_name FortuneSticks
extends RefCounted

const STICK_DIR: String = "res://external/data/fortune_sticks/"

static func load_stick(stick_id: String) -> Dictionary:
	var path: String = STICK_DIR + stick_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return (parsed as Dictionary).get("properties", {})

static func list_stick_ids() -> Array[String]:
	var ids: Array[String] = []
	var dir: DirAccess = DirAccess.open(STICK_DIR)
	if dir == null:
		return ids
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry.ends_with(".json"):
			ids.append(entry.trim_suffix(".json"))
		entry = dir.get_next()
	dir.list_dir_end()
	ids.sort()
	return ids

## 確定性抽籤（run rng — 同種子同籤）。空池回空字串。
static func draw_stick_id(rng: RandomNumberGenerator) -> String:
	var ids: Array[String] = list_stick_ids()
	if ids.is_empty():
		return ""
	return ids[rng.randi_range(0, ids.size() - 1)]

## 一行籤詩摘要（RSO 籤詩帶 / 詳情用）：「霧鎖前路【中下】　利：全圖現形　忌：完局香火 -15%」
static func stick_summary(props: Dictionary) -> String:
	if props.is_empty():
		return ""
	return TranslationServer.translate("fortune.summary") % [
		str(props.get("stick_name", "")), str(props.get("stick_grade", "")),
		str(props.get("stick_up_text", "")), str(props.get("stick_down_text", "")),
	]
