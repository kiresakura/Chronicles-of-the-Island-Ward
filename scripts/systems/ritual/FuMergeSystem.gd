extends RefCounted
class_name FuMergeSystem

# 鎮島錄 v0.3 — 合符（FP-3）。兩張同符令 → 一張上位符令（formation_fu.json 的 merge_result）。
# 對「持久 run 牌庫」（Array[String] of fu_id，即 Global.run_fu_deck）就地操作。
# 邏輯/顯示分離：本系統只動資料；UI（商店/休息站）呼叫後自行刷新。
# 名詞紅線：合符（非「升階/合成」）。

const FormationCombatCls := preload("res://scripts/systems/ritual/FormationCombat.gd")

## deck 內是否存在任一可合對（同 fu_id ≥2 張且該符有 merge_result）。
static func has_any_merge(deck: Array) -> bool:
	return first_mergeable(deck) != ""

## 回傳第一個可合的 fu_id（deck 中數量 ≥2 且可合）；無則 ""。
static func first_mergeable(deck: Array) -> String:
	var counts: Dictionary = {}
	for id_v: Variant in deck:
		var id: String = str(id_v)
		counts[id] = int(counts.get(id, 0)) + 1
	for id: String in counts:
		if int(counts[id]) >= 2 and FormationCombatCls.fu_can_merge(id):
			return id
	return ""

## 列出所有「目前可合」的 fu_id（給 UI 列選項）。
static func mergeable_ids(deck: Array) -> Array[String]:
	var counts: Dictionary = {}
	for id_v: Variant in deck:
		var id: String = str(id_v)
		counts[id] = int(counts.get(id, 0)) + 1
	var out: Array[String] = []
	for id: String in counts:
		if int(counts[id]) >= 2 and FormationCombatCls.fu_can_merge(id):
			out.append(id)
	return out

## 對 deck 就地合一次：移除 2 張 fu_id、加 1 張 merge_result。
## 回傳 {ok:bool, from:String, to:String}；不可合回 {ok:false}。
static func merge(deck: Array, fu_id: String) -> Dictionary:
	var result: String = FormationCombatCls.fu_merge_result(fu_id)
	if result == "" or deck.count(fu_id) < 2:
		return {"ok": false}
	deck.erase(fu_id)
	deck.erase(fu_id)
	deck.append(result)
	return {"ok": true, "from": fu_id, "to": result}
