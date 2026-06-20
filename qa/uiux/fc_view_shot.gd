extends Node
# 生產版五營戰鬥畫面真機渲染探針（fivecamp_shot.gd 載入已不存在的 prototype，故另寫此）。
# 直接實例化 scenes/ui/FormationCombatView.tscn（embedded=false → _ready 自動跑示範戰），
# 真 GL 視窗存 PNG。FC_RES 環境變數指定解析度（預設 1244x700）。
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	var res: String = OS.get_environment("FC_RES")
	var dims: PackedStringArray = (res if res != "" else "1244x700").split("x")
	get_window().size = Vector2i(int(dims[0]), int(dims[1]))
	await get_tree().process_frame
	await get_tree().process_frame
	var view: Control = load("res://scenes/ui/FormationCombatView.tscn").instantiate()
	get_tree().root.add_child(view)
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 30:
		await get_tree().process_frame
	RenderingServer.force_draw()
	var out: String = "/tmp/fc_view_%s.png" % dims[0]
	get_viewport().get_texture().get_image().save_png(out)
	print("[FC] saved " + out)
	get_tree().quit(0)
