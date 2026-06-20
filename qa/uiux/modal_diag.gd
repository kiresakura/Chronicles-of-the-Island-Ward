extends Node
func _ready() -> void:
	get_window().size = Vector2i(1515, 700)
	for i in 50: await get_tree().process_frame
	var root := get_tree().root
	var resp := root.get_node_or_null("Responsive")
	var vp_rect: Rect2 = get_viewport().get_visible_rect()
	print("[DIAG] viewport.visible_rect=", vp_rect.size, "  Responsive.screen_rect=", (resp.screen_rect.size if resp else Vector2.ZERO))
	for path in ["RunScreen", "RunScreen/RewardOverlay", "RunScreen/RewardOverlay/Background", "RunScreen/ShopOverlay", "RunScreen/ShopOverlay/Background"]:
		var n := root.get_node_or_null(path)
		if n is Control:
			print("[DIAG] ", path, "  size=", (n as Control).size, "  global_rect=", (n as Control).get_global_rect(), "  in_group=", n.is_in_group("fullbleed_mask"))
		else:
			print("[DIAG] ", path, " = ", n)
	get_tree().quit()
