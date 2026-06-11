# 鎮島錄 Q2-B — 擲筊演出守門（建層/節流/時長契約/零輸入阻塞；視覺由探針截圖驗收）。
extends "res://tests/test_case.gd"

const FX := preload("res://scripts/ui/fx/JiaoBeiFX.gd")

func _host() -> Control:
	var c := Control.new()
	Global.add_child(c)
	return c

func test_play_builds_layer_with_two_cups() -> void:
	FX._last_msec = -100000	# 重置節流（測試隔離）
	var host: Control = _host()
	FX.play(host, Vector2(600, 400))
	var layer: Node = Global.get_tree().root.get_node_or_null("JiaoBeiLayer")
	assert_not_null(layer, "play() 應建立 JiaoBeiLayer")
	if layer != null:
		var cups: int = 0
		for child: Node in layer.get_children():
			if child is TextureRect:
				cups += 1
				assert_true((child as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE,
					"筊杯不得阻塞輸入（演出鐵律）")
		assert_eq(cups, 2, "應擲出兩枚筊杯")
		FX._free_layer(layer)
	host.queue_free()

func test_throttle_blocks_same_beat_double_play() -> void:
	FX._last_msec = -100000
	var host: Control = _host()
	FX.play(host, Vector2(600, 400))
	FX.play(host, Vector2(620, 400))	# 同拍第二發應被節流
	var count: int = 0
	for child: Node in Global.get_tree().root.get_children():
		if str(child.name).begins_with("JiaoBeiLayer") or str(child.name).begins_with("@JiaoBeiLayer"):
			count += 1
			FX._free_layer(child)
	assert_eq(count, 1, "節流下同拍只允許一層演出")
	host.queue_free()

func test_beat_meets_ritual_contract() -> void:
	assert_true(FX.TOTAL_LIFE <= 1.5, "演出總長須 ≤1.5s（演出鐵律）")
	assert_true(FX.TOSS_TIME < FX.TOTAL_LIFE, "拋擲段須短於總長（落定後要留聖筊判定拍）")
	assert_true(ResourceLoader.exists(FX.TEX_ROUND) and ResourceLoader.exists(FX.TEX_FLAT),
		"筊杯凸/平面素材必須存在（缺檔會整段靜默跳過）")
