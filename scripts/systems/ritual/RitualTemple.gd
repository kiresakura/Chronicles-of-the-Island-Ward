# 鎮島錄 — 修廟 meta progression（2D）。
#
# 香火（ProfileData.profile_incense_balance）修復鎮島廟建築（profile_building_id_to_level），
# 建築等級解鎖內容（神明位/破煞法器/籤詩/商店/被動/外觀）。建築資料就地讀 meta_buildings/。
# 對應 docs/design/meta_temple_progression.md。
# 變現鐵則：修廟只花「香火」（玩出來的），元寶純外觀——本系統不碰元寶。
class_name RitualTemple
extends RefCounted

const BUILDING_DIR: String = "res://external/data/meta_buildings/"

static func load_building(building_id: String) -> Dictionary:
	var path: String = BUILDING_DIR + building_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return (parsed as Dictionary).get("properties", {})

static func list_building_ids() -> Array[String]:
	var ids: Array[String] = []
	var dir: DirAccess = DirAccess.open(BUILDING_DIR)
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

## 修到下一級的香火成本（隨等級遞增：base × (current_level + 1)）。
static func repair_cost(building_props: Dictionary, current_level: int) -> int:
	return int(building_props.get("repair_cost_incense", 0)) * (current_level + 1)

## 是否可修（未滿級 + 香火足夠）。
static func can_repair(profile: ProfileData, building_id: String) -> bool:
	if profile == null:
		return false
	var props: Dictionary = load_building(building_id)
	if props.is_empty():
		return false
	var lvl: int = profile.get_building_level(building_id)
	if lvl >= int(props.get("max_level", 1)):
		return false
	return profile.profile_incense_balance >= repair_cost(props, lvl)

## 修一級：扣香火 + 等級 +1。回傳是否成功。
static func repair(profile: ProfileData, building_id: String) -> bool:
	if not can_repair(profile, building_id):
		return false
	var props: Dictionary = load_building(building_id)
	var lvl: int = profile.get_building_level(building_id)
	profile.profile_incense_balance -= repair_cost(props, lvl)
	profile.profile_building_id_to_level[building_id] = lvl + 1
	return true

## 已修建築聚合出的解鎖功能鍵（供 run-start 查詢：
## deity_slot / ritual_tool_ward_break / run_modifier_fortune / shop_stock / start_passive / cosmetic...）。
static func unlocked_features(profile: ProfileData) -> Array[String]:
	var feats: Array[String] = []
	if profile == null:
		return feats
	for bid: String in list_building_ids():
		if profile.get_building_level(bid) > 0:
			for u: Variant in load_building(bid).get("unlocks", []):
				var key: String = str(u)
				if not feats.has(key):
					feats.append(key)
	return feats

static func has_unlock(profile: ProfileData, feature: String) -> bool:
	return unlocked_features(profile).has(feature)
