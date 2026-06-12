# UI 重修 P0-1 — 匾額廟級語意守門。
# 規則：profile 未就緒 → -1（UI 據此隱藏整組匾額）；無建築 → 0（只顯廟名）；
# 有建築 → 等級總和（顯示「鎮島廟 Lv.N」）。
extends "res://tests/test_case.gd"

const RitualTempleScript := preload("res://scripts/systems/ritual/RitualTemple.gd")

func test_null_profile_means_hidden() -> void:
	assert_eq(RitualTempleScript.temple_level(null), -1, "profile 未就緒應回 -1（匾額隱藏）")

func test_zero_buildings_means_name_only() -> void:
	var p: ProfileData = ProfileData.new()
	assert_eq(RitualTempleScript.temple_level(p), 0, "無建築應回 0（只顯廟名）")

func test_level_is_sum_of_buildings() -> void:
	var p: ProfileData = ProfileData.new()
	p.profile_building_id_to_level = {"building_stage": 2, "building_tiger_shrine": 1}
	assert_eq(RitualTempleScript.temple_level(p), 3, "廟級應為建築等級總和")

func test_plaque_i18n_keys_exist() -> void:
	# 兩個 key 缺一就會在匾額上顯示 key 本身（空狀態鐵則破功）
	assert_ne(tr("menu.plaque_temple_name"), "menu.plaque_temple_name", "廟名 key 應已入 CSV 並編譯")
	assert_true(tr("menu.plaque_with_level").contains("%d"), "帶級 key 應含 %d 格式位")
