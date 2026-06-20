extends Node
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	await get_tree().process_frame
	await get_tree().process_frame
	var t0: int = Time.get_ticks_msec()
	var packed: PackedScene = load("res://scenes/Root.tscn")
	var t1: int = Time.get_ticks_msec()
	var root: Node = packed.instantiate()
	var t2: int = Time.get_ticks_msec()
	get_tree().root.add_child(root)
	var t3: int = Time.get_ticks_msec()
	for i in 600:
		await get_tree().process_frame
		if root.find_child("RootLoadingOverlay", true, false) == null and root.find_child("MainMenu", true, false) != null:
			break
	var t4: int = Time.get_ticks_msec()
	print("[SPLIT] load=%d inst=%d add_child=%d overlay_wait=%d total=%d" % [t1-t0, t2-t1, t3-t2, t4-t3, t4-t0])
	get_tree().quit(0)
