extends Node
# 符令圖鑑分頁渲染探針：載 Root → 開圖鑑 → 切到符令分頁 → 截圖。
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_window().size = Vector2i(1244, 700)
	await get_tree().process_frame
	await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 90:
		await get_tree().process_frame
	var ov: Node = root.find_child("RootLoadingOverlay", true, false)
	if ov != null:
		ov.queue_free()
	for i in 8:
		await get_tree().process_frame
	var ts: Node = root.get_node_or_null("TitleScreen")
	if ts != null and ts.has_method("show_codex_menu"):
		ts.call("show_codex_menu")
	for i in 20:
		await get_tree().process_frame
	var codex: Node = root.find_child("CodexMenu", true, false)
	if codex != null and codex.has_method("_show_tab"):
		codex.call("_show_tab", 3)	# TAB.FU
	for i in 24:
		await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("/tmp/codex_fu.png")
	print("[CODEX] saved /tmp/codex_fu.png")
	get_tree().quit(0)
