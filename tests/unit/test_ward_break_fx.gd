# 鎮島錄 Q1-B — 破煞演出守門（建層/節流/清理路徑；視覺由錄影驗收）。
extends "res://tests/test_case.gd"

const WardBreakFX := preload("res://scripts/ui/fx/WardBreakFX.gd")

func _host() -> Control:
	var c := Control.new()
	Global.add_child(c)
	return c

func test_play_builds_layer_with_dim_ring_shards() -> void:
	WardBreakFX._last_msec = -100000	# 重置節流（測試隔離）
	var host: Control = _host()
	WardBreakFX.play(host, Vector2(600, 300))
	var layer: Node = Global.get_tree().root.get_node_or_null("WardBreakFXLayer")
	assert_not_null(layer, "play() 應建立 WardBreakFXLayer")
	if layer != null:
		assert_not_null(layer.get_node_or_null("BreakDim"), "應有全幅降亮層")
		assert_true(layer.get_child_count() >= 2 + WardBreakFX.SHARD_COUNT, "應有 dim+環+碎片 ≥ %d 子節點" % (2 + WardBreakFX.SHARD_COUNT))
		var dim: ColorRect = layer.get_node("BreakDim")
		assert_true(dim.mouse_filter == Control.MOUSE_FILTER_IGNORE, "降亮層不得阻塞輸入（演出鐵律）")
		WardBreakFX._free_layer(layer)
	host.queue_free()

func test_throttle_blocks_same_beat_double_play() -> void:
	WardBreakFX._last_msec = -100000
	var host: Control = _host()
	WardBreakFX.play(host, Vector2(600, 300))
	WardBreakFX.play(host, Vector2(620, 300))	# 同拍第二發應被節流
	var count: int = 0
	for child: Node in Global.get_tree().root.get_children():
		if str(child.name).begins_with("WardBreakFXLayer"):
			count += 1
			WardBreakFX._free_layer(child)
	assert_eq(count, 1, "節流下同拍只允許一層演出")
	host.queue_free()

func test_dim_alpha_meets_q2_baseline() -> void:
	assert_true(WardBreakFX.DIM_ALPHA >= 0.30, "背景降亮須 ≥30%（基準 Q-2）")
	assert_true(WardBreakFX.TOTAL_LIFE <= 1.5, "演出總長須 ≤1.5s（演出鐵律）")
