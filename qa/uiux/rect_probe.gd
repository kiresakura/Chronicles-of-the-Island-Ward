extends Node
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	await get_tree().process_frame
	await get_tree().process_frame
	get_window().size = Vector2i(1244, 700)
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 100:
		await get_tree().process_frame
	var mm: Node = root.find_child("MainMenu", true, false)
	for n in ["RowPlus2", "Util0", "Util1", "Util2"]:
		var c: Control = mm.find_child(n, true, false)
		if c: print("[RECT] ", n, " pos=", c.global_position, " size=", c.size)
	get_tree().quit(0)
