# 鎮島錄 — 修廟 meta progression 單元測試（RitualTemple，2D）。
# 純函式 + disk 載入 + ProfileData 操作；同步、無場景。對應 docs/design/meta_temple_progression.md。
extends "res://tests/test_case.gd"

func _profile(incense: int) -> ProfileData:
	var p: ProfileData = ProfileData.new()
	p.profile_incense_balance = incense
	return p

# ---------- 修復成本 ----------

func test_repair_cost_scales_with_level() -> void:
	var props: Dictionary = RitualTemple.load_building("building_main_hall")
	assert_false(props.is_empty(), "正殿應從 meta_buildings 載入")
	var base: int = int(props.get("repair_cost_incense", 0))
	assert_eq(RitualTemple.repair_cost(props, 0), base, "首級成本 = base")
	assert_eq(RitualTemple.repair_cost(props, 1), base * 2, "次級成本 = base×2")

# ---------- can_repair 受香火 + 滿級限制 ----------

func test_can_repair_gated_by_incense() -> void:
	var props: Dictionary = RitualTemple.load_building("building_main_hall")
	var cost0: int = RitualTemple.repair_cost(props, 0)
	assert_false(RitualTemple.can_repair(_profile(cost0 - 1), "building_main_hall"), "香火不足不可修")
	assert_true(RitualTemple.can_repair(_profile(cost0), "building_main_hall"), "香火足夠可修")

func test_repair_deducts_incense_and_levels_up() -> void:
	var props: Dictionary = RitualTemple.load_building("building_main_hall")
	var cost0: int = RitualTemple.repair_cost(props, 0)
	var p: ProfileData = _profile(cost0 + 10)
	assert_true(RitualTemple.repair(p, "building_main_hall"), "修廟應成功")
	assert_eq(p.get_building_level("building_main_hall"), 1, "等級 +1")
	assert_eq(p.profile_incense_balance, 10, "香火扣除 cost0")

func test_max_level_blocks_further_repair() -> void:
	var p: ProfileData = _profile(999999)
	var props: Dictionary = RitualTemple.load_building("building_main_hall")
	var maxl: int = int(props.get("max_level", 1))
	for i: int in maxl:
		RitualTemple.repair(p, "building_main_hall")
	assert_eq(p.get_building_level("building_main_hall"), maxl, "升到滿級")
	assert_false(RitualTemple.can_repair(p, "building_main_hall"), "滿級不可再修")

# ---------- 解鎖聚合 ----------

func test_unlocked_features_aggregates_from_repaired() -> void:
	var p: ProfileData = _profile(999999)
	RitualTemple.repair(p, "building_main_hall")	# unlocks [deity_slot]
	assert_true(RitualTemple.has_unlock(p, "deity_slot"), "正殿修復解鎖神明位")
	assert_false(RitualTemple.has_unlock(p, "ritual_tool_ward_break"), "未修虎爺殿則無破煞法器解鎖")
	RitualTemple.repair(p, "building_tiger_shrine")	# unlocks [ritual_tool_ward_break]
	assert_true(RitualTemple.has_unlock(p, "ritual_tool_ward_break"), "虎爺殿修復解鎖破煞法器")

# ---------- 香火結算（ProfileData.add_incense）----------

func test_add_incense_clamps_non_negative() -> void:
	var p: ProfileData = _profile(100)
	p.add_incense(50)
	assert_eq(p.profile_incense_balance, 150, "加香火")
	p.add_incense(-999)
	assert_eq(p.profile_incense_balance, 0, "扣到負夾為 0")
