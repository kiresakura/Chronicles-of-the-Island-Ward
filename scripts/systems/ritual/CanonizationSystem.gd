# 鎮島錄 v0.3 — 敕封封神榜（formation_progression_v0.3.md §2.2，FC-5）。
#
# 跨局長線養成：用香火（玩出來的）把神明/家將位階往上敕封 將→帥→神→帝（rank 0..3）。
# 仿 RitualTemple 靜態函式風格；位階持久於 ProfileData.profile_deity_rank。
# 每升一階解鎖「選項」(grants：營位資格/符令draft/緣分)，非堆數值（防 grind-wall）。
# 階級成本/解鎖資料化於 external/data/canonization/rank_tiers.json（直接讀檔、不經 mod loader）。
#
# 🔴 變現紅線：敕封只扣 profile_incense_balance（香火），元寶（profile_yuanbao）永遠碰不到。
#   test_canonization 強制驗證此點。修廟與敕封共用同一香火池＝廣度vs深度的 meta 抉擇。
class_name CanonizationSystem
extends RefCounted

const TIERS_PATH := "res://external/data/canonization/rank_tiers.json"
const MAX_RANK := 3		# 將(0) 帥(1) 神(2) 帝(3)

## 讀位階階梯（res://，回 properties；失敗回 {}）。
static func load_tiers() -> Dictionary:
	if not FileAccess.file_exists(TIERS_PATH):
		return {}
	var f := FileAccess.open(TIERS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed.get("properties", {})

## 目前位階（0=將；未敕封預設 0）。
static func rank_of(profile: ProfileData, deity_id: String) -> int:
	if profile == null:
		return 0
	return int(profile.profile_deity_rank.get(deity_id, 0))

## 位階名稱（資料層；rank 越界回空）。
static func rank_name(rank: int) -> String:
	var names: Array = load_tiers().get("rank_names", [])
	if rank >= 0 and rank < names.size():
		return str(names[rank])
	return ""

## 取「升到 target_rank」的階梯資料（{} 若無）。
static func _tier_for(target_rank: int) -> Dictionary:
	for t: Variant in load_tiers().get("tiers", []):
		if int((t as Dictionary).get("rank", -1)) == target_rank:
			return t
	return {}

## 下一階所需香火（-1＝已封頂）。
static func cost_for_next(profile: ProfileData, deity_id: String) -> int:
	var cur: int = rank_of(profile, deity_id)
	if cur >= MAX_RANK:
		return -1
	var tier: Dictionary = _tier_for(cur + 1)
	if tier.is_empty():
		return -1
	return int(tier.get("cost_incense", 0))

## 可否敕封：未封頂 且 香火足夠（只看香火，不看元寶）。
static func can_canonize(profile: ProfileData, deity_id: String) -> bool:
	if profile == null:
		return false
	var cost: int = cost_for_next(profile, deity_id)
	if cost < 0:
		return false
	return profile.profile_incense_balance >= cost

## 敕封一階：扣香火、位階 +1。回 {success, new_rank, grants}。
## 🔴 只動 profile_incense_balance，絕不碰 profile_yuanbao。
static func canonize(profile: ProfileData, deity_id: String) -> Dictionary:
	if not can_canonize(profile, deity_id):
		return {"success": false, "new_rank": rank_of(profile, deity_id), "grants": []}
	var target: int = rank_of(profile, deity_id) + 1
	var tier: Dictionary = _tier_for(target)
	profile.profile_incense_balance -= int(tier.get("cost_incense", 0))
	profile.profile_deity_rank[deity_id] = target
	var grants: Array = []
	grants.assign(tier.get("grants", []))
	return {"success": true, "new_rank": target, "grants": grants}

## 已解鎖的全部 grants（累計到目前位階）。
static func grants_for(profile: ProfileData, deity_id: String) -> Array:
	var out: Array = []
	var cur: int = rank_of(profile, deity_id)
	for r: int in range(1, cur + 1):
		var tier: Dictionary = _tier_for(r)
		for g: Variant in tier.get("grants", []):
			out.append(str(g))
	return out
