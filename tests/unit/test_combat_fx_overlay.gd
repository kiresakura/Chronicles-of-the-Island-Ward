extends "res://tests/test_case.gd"

const COMBAT_FX := preload("res://scripts/ui/theme/CombatFxOverlay.gd")

func test_fx_throttle_snapshot_exposes_mobile_safe_limits() -> void:
	COMBAT_FX.reset_fx_throttle_state()
	var snapshot: Dictionary = COMBAT_FX.get_fx_throttle_snapshot()
	assert_true(float(snapshot.get("cooldown_sec", 0.0)) > 0.0, "FX 應公開 cooldown 設定，避免同幀/短時間多段傷害刷滿畫面")
	assert_true(float(snapshot.get("merge_window_sec", 0.0)) >= float(snapshot.get("cooldown_sec", 0.0)), "merge window 應至少涵蓋 cooldown，才能把短連段合併到現有 FX")
	assert_eq(snapshot.get("last_fx_count"), 0, "reset 後不應殘留上一場戰鬥的限流 bucket")

func test_fx_bucket_is_per_event_and_target() -> void:
	var target_a := Control.new()
	var target_b := Control.new()
	var damage_a: String = COMBAT_FX._make_fx_bucket_key("damage", target_a)
	var block_a: String = COMBAT_FX._make_fx_bucket_key("block", target_a)
	var damage_b: String = COMBAT_FX._make_fx_bucket_key("damage", target_b)
	assert_ne(damage_a, block_a, "同一目標的不同事件類型應分開限流，避免 block 吃掉 damage 回饋")
	assert_ne(damage_a, damage_b, "不同敵人/玩家目標應分開限流，避免多目標戰鬥只剩一個 FX")
	target_a.queue_free()
	target_b.queue_free()

func test_fx_should_emit_respects_cooldown_boundary() -> void:
	COMBAT_FX.reset_fx_throttle_state()
	var bucket := "damage:test-target"
	assert_true(COMBAT_FX._should_emit_fx(bucket, 10.0), "第一次 FX 必須允許播放")
	COMBAT_FX._last_fx_time_by_bucket[bucket] = 10.0
	assert_false(COMBAT_FX._should_emit_fx(bucket, 10.0 + COMBAT_FX.FX_COOLDOWN_SEC * 0.5), "cooldown 內的同 bucket FX 應被合併/限流")
	assert_true(COMBAT_FX._should_emit_fx(bucket, 10.0 + COMBAT_FX.FX_COOLDOWN_SEC + 0.01), "超過 cooldown 後應允許下一個清楚可見的 FX")
