# 鎮島錄 c-3 FTUE — 啟用條件 / 拍去重 / 未啟用不顯（純邏輯 + 實例；不走會存檔的 _skip/_mark_done）。
extends "res://tests/test_case.gd"

const FtueCoach := preload("res://scripts/systems/ftue/FtueCoach.gd")

func test_should_activate_only_when_not_done() -> void:
	var p := ProfileData.new()
	assert_true(FtueCoach.should_activate(p), "未完成 FTUE → 啟用")
	p.profile_ftue_done = true
	assert_false(FtueCoach.should_activate(p), "已完成 → 不啟用")
	assert_false(FtueCoach.should_activate(null), "null profile → 不啟用")

func test_beat_shows_once_then_dedups() -> void:
	var coach: CanvasLayer = FtueCoach.new()
	Global.add_child(coach)
	coach._active = true
	coach._show_beat("oracle", "T", "B")
	assert_true(coach.visible, "首次顯示該拍")
	coach._hide()
	coach._show_beat("oracle", "T2", "B2")
	assert_false(coach.visible, "同拍二次不重顯（已 dedup）")
	coach.queue_free()

func test_inactive_coach_ignores_signals() -> void:
	var coach: CanvasLayer = FtueCoach.new()
	Global.add_child(coach)
	coach._active = false
	coach._on_combat_started("evt")
	assert_false(coach.visible, "未啟用時戰鬥訊號不顯拍")
	coach.queue_free()

func test_non_starting_location_does_not_show_oracle_beat() -> void:
	var coach: CanvasLayer = FtueCoach.new()
	Global.add_child(coach)
	coach._active = true
	var loc := LocationData.new()
	loc.location_type = LocationData.LOCATION_TYPES.COMBAT
	coach._on_map_location_selected(loc)
	assert_false(coach.visible, "非起始節點不顯擲筊拍")
	coach.queue_free()
