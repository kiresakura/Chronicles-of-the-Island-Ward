# 鎮島錄 Q1-D — 降乩 cut-in 守門（建層/節流/演出鐵律契約）。
extends "res://tests/test_case.gd"

const DeityCutInFX := preload("res://scripts/ui/fx/DeityCutInFX.gd")
const DeityInvocationSystem := preload("res://scripts/systems/ritual/DeityInvocationSystem.gd")

func _deity() -> DeityData:
	return DeityInvocationSystem.load_deity("deity_tiger_god")

func test_play_builds_cutin_layer() -> void:
	DeityCutInFX._last_msec = -100000
	var host := Control.new()
	Global.add_child(host)
	var deity: DeityData = _deity()
	assert_not_null(deity, "虎爺資料應存在")
	DeityCutInFX.play(host, deity)
	var layer: Node = Global.get_tree().root.get_node_or_null("DeityCutInLayer")
	assert_not_null(layer, "play() 應建立 DeityCutInLayer")
	if layer != null:
		assert_not_null(layer.get_node_or_null("CutInDim"), "應有全幅降亮層")
		var has_title: bool = false
		for c: Node in layer.get_children():
			if c is Label and (c as Label).text.contains("降乩"):
				has_title = true
		assert_true(has_title, "應有「神名・降乩」牌匾字")
		DeityCutInFX._free_layer(layer)
	host.queue_free()

func test_cutin_meets_fx_iron_rules() -> void:
	assert_true(DeityCutInFX.TOTAL_LIFE <= 1.5, "演出總長 ≤1.5s（鐵律）")
	assert_true(DeityCutInFX.DIM_ALPHA >= 0.30, "背景降亮 ≥30%（基準 Q-2）")

func test_throttle_blocks_double_play() -> void:
	DeityCutInFX._last_msec = -100000
	var host := Control.new()
	Global.add_child(host)
	var deity: DeityData = _deity()
	DeityCutInFX.play(host, deity)
	DeityCutInFX.play(host, deity)
	var count: int = 0
	for c: Node in Global.get_tree().root.get_children():
		if str(c.name).begins_with("DeityCutInLayer"):
			count += 1
			DeityCutInFX._free_layer(c)
	assert_eq(count, 1, "同拍重複降乩只允許一層")
	host.queue_free()
