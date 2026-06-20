extends Node
# c-2 外觀商店 + 立繪外框 渲染探針。
# 設 profile：100 元寶、已擁有燙金、裝備玉青 → ① 新一局立繪套玉青框 ② 外觀商店四階狀態。
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_window().size = Vector2i(1244, 700)
	for i in 3: await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 90: await get_tree().process_frame
	var ov: Node = root.find_child("RootLoadingOverlay", true, false)
	if ov != null: ov.queue_free()
	var p: ProfileData = Global.profile_data
	p.profile_yuanbao = 100
	p.own_cosmetic("frame_gold")
	p.profile_equipped_frame = "frame_jade"
	for i in 6: await get_tree().process_frame
	# ① 新一局（立繪套玉青框）
	var ts: Node = root.get_node_or_null("TitleScreen")
	if ts != null and ts.has_method("show_new_run_menu"):
		ts.call("show_new_run_menu")
	for i in 36: await get_tree().process_frame
	Signals.cosmetic_equipped.emit("frame_jade")	# 觸發新一局立繪框重套（menu 已建好）
	for i in 12: await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("/tmp/cosmetic_hero_jade.png")
	print("[COS] saved hero")
	# ② 外觀商店 overlay
	var store: Control = preload("res://scripts/ui/menus/CosmeticStoreOverlay.gd").new()
	get_tree().root.add_child(store)
	store.call("open")
	for i in 18: await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("/tmp/cosmetic_store.png")
	print("[COS] saved store")
	get_tree().quit(0)
