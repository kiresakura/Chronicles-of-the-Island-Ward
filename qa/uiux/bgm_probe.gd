extends Node
# BGM 冷啟動探針：Root 進樹後主選單 BGM 應自動播放（TitleScreen._ready 補的起點）
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	await get_tree().process_frame
	await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 90:
		await get_tree().process_frame
	var am: Node = get_node("/root/AudioManager")
	print("[PROBE] boot: scene='", am._bgm_scene, "' playing=", am._bgm_player.playing,
		" stream=", am._bgm_player.stream != null)
	get_tree().quit(0)
