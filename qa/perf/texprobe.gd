extends Node
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	await get_tree().process_frame
	await get_tree().process_frame
	var before_tex: float = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0
	print("[TEX] autoload 階段（Root 未進樹）: %.1fMB" % before_tex)
	print("[TEX] FileLoader cached_textures=", FileLoader._cached_textures.size(),
		" cached_animations=", FileLoader._cached_animations.size())
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 120:
		await get_tree().process_frame
	var after_tex: float = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0
	print("[TEX] 主選單階段: %.1fMB" % after_tex)
	print("[TEX] FileLoader cached_textures=", FileLoader._cached_textures.size(),
		" cached_animations=", FileLoader._cached_animations.size())
	get_tree().quit(0)
