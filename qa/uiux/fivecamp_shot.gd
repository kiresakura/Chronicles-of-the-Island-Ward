extends Node
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_window().size = Vector2i(1244, 700)
	await get_tree().process_frame
	await get_tree().process_frame
	var scene: PackedScene = load("res://prototypes/five_camp/five_camp_probe.tscn")
	var root: Control = scene.instantiate()
	get_tree().root.add_child(root)
	for i in 20: await get_tree().process_frame
	root._on_jiao()
	for i in 6: await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("/tmp/fivecamp.png")
	print("[SHOT] saved")
	get_tree().quit(0)
