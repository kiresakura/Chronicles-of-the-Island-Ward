# 鎮島錄 Q1-E — 儀法璽印章守門。
extends "res://tests/test_case.gd"

const WeaknessChips := preload("res://scripts/ui/theme/WeaknessChips.gd")

func test_make_builds_one_chip_per_valid_tag() -> void:
	var row: HBoxContainer = WeaknessChips.make(["fist", "fire", "curse"])
	assert_eq(row.get_child_count(), 3, "三個有效標籤應出三枚璽印")
	row.free()

func test_make_skips_unknown_tags() -> void:
	var row: HBoxContainer = WeaknessChips.make(["fist", "not_a_tag", ""])
	assert_eq(row.get_child_count(), 1, "未知標籤應略過")
	row.free()

func test_all_six_ritual_tags_have_glyphs() -> void:
	var row: HBoxContainer = WeaknessChips.make(RitualTags.ALL)
	assert_eq(row.get_child_count(), 6, "六道儀法應六枚俱全")
	row.free()
