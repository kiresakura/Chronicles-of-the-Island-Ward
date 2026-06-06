# 鎮島錄 — 遶境路線指派 + 特徵載入（2E）。
#
# 純函式 + disk 載入器（route_traits 不入 Global SCHEMA，由此就地讀取）。
# 供 ActionGeneratePilgrimage 依樓層深度指派路線（山路→夜市路→廟路→荒宅路），
# 並把污染度 / 香火回報 / 危險度標記到 LocationData。對應 docs/design/pilgrimage_route_system.md。
class_name PilgrimageRoutes
extends RefCounted

const ROUTE_DIR: String = "res://external/data/route_traits/"

## 依樓層深度（0..total）指派遶境路線 id：早段山路、中段夜市/廟路、末段荒宅路。
static func route_id_for_floor(floor_k: int, total_floors: int) -> String:
	var ratio: float = float(floor_k) / float(maxi(1, total_floors))
	if ratio < 0.30:
		return "route_mountain_path"
	elif ratio < 0.55:
		return "route_night_market"
	elif ratio < 0.78:
		return "route_temple_path"
	return "route_haunted_house"

## 載入路線特徵 properties（route_flavor / pollution_level / incense_reward_modifier / danger_rating）。
static func load_route(route_id: String) -> Dictionary:
	var path: String = ROUTE_DIR + route_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return (parsed as Dictionary).get("properties", {})
