# 鎮島錄 Q1-A — HUD 三層閱讀秩序守門（HudFocus 純函式行為）。
extends "res://tests/test_case.gd"

const HudFocus := preload("res://scripts/ui/theme/HudFocus.gd")

func _make_item() -> ColorRect:
	var c := ColorRect.new()
	Global.add_child(c)	# 需在樹內（pulse 檢查 is_inside_tree）
	return c

func test_mark_low_freq_dims_and_groups() -> void:
	var c: ColorRect = _make_item()
	HudFocus.mark_low_freq(c)
	assert_true(c.is_in_group(HudFocus.GROUP), "低頻元素應入 group")
	assert_true(absf(c.modulate.a - HudFocus.IDLE_ALPHA) < 0.001, "idle 應降權至 IDLE_ALPHA")
	c.queue_free()

func test_set_operational_restores_full_alpha() -> void:
	var c: ColorRect = _make_item()
	HudFocus.mark_low_freq(c)
	HudFocus.set_operational(c, true)
	assert_true(absf(c.modulate.a - 1.0) < 0.001, "operational 應恆亮")
	HudFocus.set_operational(c, false)
	assert_true(absf(c.modulate.a - HudFocus.IDLE_ALPHA) < 0.001, "退出 operational 應回 idle")
	c.queue_free()

func test_pulse_only_affects_registered() -> void:
	var stranger: ColorRect = _make_item()
	stranger.modulate.a = 0.9
	HudFocus.pulse(stranger)	# 未註冊 → 不應建立 tween/改值
	assert_true(absf(stranger.modulate.a - 0.9) < 0.001, "未註冊元素不受 pulse 影響")
	assert_false(stranger.has_meta(HudFocus.META_TWEEN), "未註冊不應掛 tween")
	stranger.queue_free()

func test_operational_blocks_pulse() -> void:
	var c: ColorRect = _make_item()
	HudFocus.mark_low_freq(c)
	HudFocus.set_operational(c, true)
	HudFocus.pulse(c)
	assert_true(absf(c.modulate.a - 1.0) < 0.001, "operational 中 pulse 不應改變恆亮")
	c.queue_free()
