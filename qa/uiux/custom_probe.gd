extends Node
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_window().size = Vector2i(1244, 700)
	await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 90: await get_tree().process_frame
	var ov: Node = root.find_child("RootLoadingOverlay", true, false)
	if ov != null: ov.queue_free()
	for i in 8: await get_tree().process_frame
	var ts: Node = root.get_node_or_null("TitleScreen")
	if ts != null and ts.has_method("show_new_run_menu"): ts.call("show_new_run_menu")
	for i in 30: await get_tree().process_frame
	var nr: Node = root.find_child("NewRunMenu", true, false)
	if nr != null and nr.has_method("_select_mode"):
		nr.call("_select_mode", "custom")
	for i in 20: await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("/tmp/newrun_custom.png")
	# 檢查 custom 容器 rect 不越過 cta
	var cc: Node = nr.get_node_or_null("CustomRunModifierButtonContainer")
	var sb: Node = nr.get_node_or_null("StartRunButton")
	if cc != null and sb != null:
		var cr: Rect2 = Rect2(cc.position, cc.size)
		var sr: Rect2 = Rect2(sb.position, sb.size)
		print("[PROBE] custom_rect=", cr, " start_rect=", sr, " overlap=", cr.intersects(sr))
	get_tree().quit(0)
