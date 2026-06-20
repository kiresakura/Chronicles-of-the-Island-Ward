extends Node
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_window().size = Vector2i(1244, 700)
	for i in 3: await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 70: await get_tree().process_frame
	Global.start_run("character_tongji", 20260611)
	for i in 20: await get_tree().process_frame
	var ro: Node = root.find_child("RewardOverlay", true, false)
	if ro == null: print("[RWFX] no RewardOverlay"); get_tree().quit(); return
	ro.call("_on_combat_ended")	# 觸發凱旋 juice
	for i in 24: await get_tree().process_frame	# 讓金箔雨開始落
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("/tmp/reward_fx.png")
	var vf = ro.get("_victory_fx")
	print("[RWFX] saved victory_fx_visible=", (vf.visible if vf != null else "?"))
	get_tree().quit()
