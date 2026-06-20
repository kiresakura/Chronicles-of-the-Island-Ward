# 鎮島錄 設計忠實「貴層」— 鎏金氛圍層守門（建層/穿透/結構/參數鉗制）。視覺由實機截圖驗收。
extends "res://tests/test_case.gd"

const GildedDepthLayer := preload("res://scripts/ui/fx/GildedDepthLayer.gd")

func _host() -> Control:
	var c := Control.new()
	c.size = Vector2(1200, 700)
	Global.add_child(c)
	return c

func test_attach_builds_light_haze_and_embers() -> void:
	var host: Control = _host()
	var layer: Control = GildedDepthLayer.attach(host, GildedDepthLayer.ACCENT_GOLD, 1.0, 8)
	assert_not_null(layer, "attach() 應回傳氛圍層")
	assert_not_null(layer.get_node_or_null("TopLight"), "應有神光 TopLight")
	assert_not_null(layer.get_node_or_null("BottomHaze"), "應有壇底暖暈 BottomHaze")
	var embers: int = 0
	for child: Node in layer.get_children():
		if str(child.name).begins_with("Ember"):
			embers += 1
	assert_eq(embers, 8, "餘燼數應＝指定 8")
	host.queue_free()

func test_layer_never_blocks_input() -> void:
	var host: Control = _host()
	var layer: Control = GildedDepthLayer.attach(host)
	assert_true(layer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "貴層全程穿透，不得擋輸入（演出鐵律）")
	for child: Node in layer.get_children():
		if child is Control:
			assert_true((child as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "子層亦須穿透")
	host.queue_free()

func test_intensity_is_clamped() -> void:
	var host: Control = _host()
	var layer: Control = GildedDepthLayer.attach(host, GildedDepthLayer.ACCENT_GOLD, 9.0)
	assert_true(layer._intensity <= 2.0, "強度上限 2.0（防過曝洗白像素字）")
	host.queue_free()

func test_attach_null_host_is_safe() -> void:
	assert_true(GildedDepthLayer.attach(null) == null, "null host 應安全回 null（不崩）")
