# 鎮島錄 v0.3 — 緣分合祀（formation_progression_v0.3.md §2.3，FC-6）。
#
# 神話緣分：把有緣單位「合祀」在相鄰的營 → 啟用合擊/陣眼加成。養成從一條數值變成
# 一張你拼湊的神話關係網，且直接餵給陣型（誰擺誰旁邊有差）。
# 仿靜態系統風格；緣分資料 external/data/affinities/*.json（資料夾直讀、不經 mod loader）。
#
# 鄰接（五營羅盤）：中營＝樞紐（與四方位皆鄰）＋四方位環（北-東-南-西-北）。
# 緣分啟用＝全部成員已佈陣 且（若要求鄰接）其所在營構成連通子圖。
# 合擊「效果」整合進 FormationCombat＝FC-6b；本檔只負責偵測（純函式、可測）。
class_name AffinitySystem
extends RefCounted

const AFFINITY_DIR := "res://external/data/affinities/"
const RING := ["north", "east", "south", "west"]	# 方位環（順時針鄰接）

## 讀全部緣分（資料夾直讀，回 [properties...]）。
static func load_affinities() -> Array:
	var out: Array = []
	var dir := DirAccess.open(AFFINITY_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry.ends_with(".json"):
			var f := FileAccess.open(AFFINITY_DIR + entry, FileAccess.READ)
			if f != null:
				var parsed: Variant = JSON.parse_string(f.get_as_text())
				if typeof(parsed) == TYPE_DICTIONARY:
					out.append((parsed as Dictionary).get("properties", {}))
		entry = dir.get_next()
	dir.list_dir_end()
	return out

## 鄰接圖：camp_id → {鄰接 camp_id: true}。中營樞紐 + 方位環。
static func adjacency_map(camps: Array) -> Dictionary:
	var center_id: String = ""
	var dir_to_id: Dictionary = {}
	for c: Dictionary in camps:
		var lane: String = str(c.get("lane", ""))
		if lane == "":
			center_id = str(c.get("id"))
		else:
			dir_to_id[lane] = str(c.get("id"))
	var adj: Dictionary = {}
	for c: Dictionary in camps:
		adj[str(c.get("id"))] = {}
	# 中營 ↔ 各方位
	if center_id != "":
		for d: String in dir_to_id:
			adj[center_id][dir_to_id[d]] = true
			adj[dir_to_id[d]][center_id] = true
	# 方位環 北-東-南-西-北
	for i: int in range(RING.size()):
		var a: String = str(dir_to_id.get(RING[i], ""))
		var b: String = str(dir_to_id.get(RING[(i + 1) % RING.size()], ""))
		if a != "" and b != "":
			adj[a][b] = true
			adj[b][a] = true
	return adj

## camp_ids（去重後）是否在鄰接圖中連通。
static func _connected(camp_ids: Array, adj: Dictionary) -> bool:
	var uniq: Dictionary = {}
	for c: Variant in camp_ids:
		uniq[str(c)] = true
	var nodes: Array = uniq.keys()
	if nodes.size() <= 1:
		return true
	var visited: Dictionary = {}
	var queue: Array = [nodes[0]]
	visited[nodes[0]] = true
	while not queue.is_empty():
		var n: String = str(queue.pop_back())
		for m: Variant in adj.get(n, {}):
			if uniq.has(str(m)) and not visited.has(str(m)):
				visited[str(m)] = true
				queue.append(str(m))
	return visited.size() == uniq.size()

## 目前佈陣（unit_id→camp_id）下啟用的緣分（回緣分 properties 陣列）。
static func active_affinities(unit_location: Dictionary, camps: Array) -> Array:
	var adj: Dictionary = adjacency_map(camps)
	var out: Array = []
	for aff: Dictionary in load_affinities():
		var members: Array = aff.get("affinity_member_ids", [])
		var camps_of: Array = []
		var all_deployed: bool = true
		for m: Variant in members:
			if unit_location.has(str(m)):
				camps_of.append(str(unit_location[str(m)]))
			else:
				all_deployed = false
				break
		if not all_deployed:
			continue
		if bool(aff.get("affinity_adjacency_required", true)) and not _connected(camps_of, adj):
			continue
		out.append(aff)
	return out

## 啟用緣分的合擊效果鍵清單（FC-6b 戰鬥整合用）。
static func active_combo_effects(unit_location: Dictionary, camps: Array) -> Array:
	var out: Array = []
	for aff: Dictionary in active_affinities(unit_location, camps):
		var eff: String = str(aff.get("affinity_combo_effect", ""))
		if eff != "":
			out.append(eff)
	return out
