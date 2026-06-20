extends Node
# Q4-E 效能探針：冷啟動毫秒（Root 進樹→主選單互動）+ 主選單 draw calls / 紋理記憶體
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	await get_tree().process_frame
	await get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	# 等主選單可互動（RootLoadingOverlay 收場）
	var menu: Node = null
	for i in 600:
		await get_tree().process_frame
		menu = root.find_child("MainMenu", true, false)
		var ov: Node = root.find_child("RootLoadingOverlay", true, false)
		# 互動就緒 = 選單存在且 splash 不再可見（節點 free 時機是雜訊，不可量）
		if menu != null and (ov == null or not (ov as CanvasItem).visible):
			break
	var boot_ms: int = Time.get_ticks_msec() - t0
	for i in 30:
		await get_tree().process_frame	# 穩定幾幀再量
	var draw_calls: int = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var tex_mb: float = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0
	var vid_mb: float = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0
	print("[PERF] boot_to_menu=%dms draw_calls=%d tex_mem=%.1fMB video_mem=%.1fMB" % [boot_ms, draw_calls, tex_mb, vid_mb])
	get_tree().quit(0)
