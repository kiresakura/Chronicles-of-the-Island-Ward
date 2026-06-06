# 鎮島錄 — 遶境路線指派單元測試（PilgrimageRoutes，2E）。
# 純函式 + disk 載入；同步、無場景。對應 docs/design/pilgrimage_route_system.md。
extends "res://tests/test_case.gd"

func test_route_id_for_floor_progression() -> void:
	# 早段山路 → 中段夜市/廟路 → 末段荒宅路
	assert_eq(PilgrimageRoutes.route_id_for_floor(0, 10), "route_mountain_path", "起段山路")
	assert_eq(PilgrimageRoutes.route_id_for_floor(2, 10), "route_mountain_path", "前段山路")
	assert_eq(PilgrimageRoutes.route_id_for_floor(4, 10), "route_night_market", "中段夜市路")
	assert_eq(PilgrimageRoutes.route_id_for_floor(7, 10), "route_temple_path", "後段廟路")
	assert_eq(PilgrimageRoutes.route_id_for_floor(9, 10), "route_haunted_house", "末段荒宅路")

func test_load_real_route_haunted() -> void:
	var p: Dictionary = PilgrimageRoutes.load_route("route_haunted_house")
	assert_false(p.is_empty(), "荒宅路應從 external/data/route_traits 載入")
	assert_eq(int(p.get("danger_rating", 0)), 4, "荒宅路 danger_rating 應為 4")
	assert_eq(str(p.get("route_flavor", "")), "haunted", "荒宅路 flavor 應為 haunted")

func test_load_missing_route_returns_empty() -> void:
	assert_true(PilgrimageRoutes.load_route("route_nonexistent").is_empty(), "不存在的路線回空 dict")
