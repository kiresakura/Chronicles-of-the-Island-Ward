extends Node
# 新一局畫面三語×解析度截圖自查（DoD #5）
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	var loc: String = OS.get_environment("PROBE_LOCALE")
	if loc != "":
		TranslationServer.set_locale(loc)
	var res: String = OS.get_environment("PROBE_RES")
	var dims: PackedStringArray = (res if res != "" else "1244x700").split("x")
	get_window().size = Vector2i(int(dims[0]), int(dims[1]))
	await get_tree().process_frame
	await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 90:
		await get_tree().process_frame
	var ov: Node = root.find_child("RootLoadingOverlay", true, false)
	if ov != null: ov.queue_free()
	for i in 8: await get_tree().process_frame
	var ts: Node = root.get_node_or_null("TitleScreen")
	if ts != null and ts.has_method("show_new_run_menu"):
		ts.call("show_new_run_menu")
	for i in 40: await get_tree().process_frame
	RenderingServer.force_draw()
	var out: String = "/tmp/newrun_%s_%s.png" % [loc if loc != "" else "zhTW", (dims[0])]
	get_viewport().get_texture().get_image().save_png(out)
	print("[PROBE] saved ", out)
	get_tree().quit(0)
