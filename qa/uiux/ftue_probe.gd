extends Node
# c-3 FTUE 渲染探針：強制首局導引 → 開壇後供桌上應浮現「開壇問神」coach-mark。
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_window().size = Vector2i(1244, 700)
	for i in 3: await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 90: await get_tree().process_frame
	var ov: Node = root.find_child("RootLoadingOverlay", true, false)
	if ov != null: ov.queue_free()
	Global.profile_data.profile_ftue_done = false	# 強制首局導引
	for i in 6: await get_tree().process_frame
	Global.start_run("character_tongji", 20260620)	# run_started → map_location_selected(STARTING) → oracle 拍
	for i in 44: await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("/tmp/ftue_oracle.png")
	print("[FTUE] saved; coach visible=", FtueCoach.visible)
	get_tree().quit(0)
