extends Node
# Q2-B 探針：神示供桌四籤詩 → 三解析度截圖 → 點籤 → 擲筊演出三幀（拋起/落定/聖筊字）

const RES_LIST := [Vector2i(1244, 700), Vector2i(1515, 700), Vector2i(1200, 900)]

func _shot(path: String) -> void:
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png(path)
	print("[PROBE] saved ", path)

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_window().size = RES_LIST[0]
	await get_tree().process_frame
	await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 70:
		await get_tree().process_frame

	Global.start_run("character_tongji", 20260611)
	for i in 30:
		await get_tree().process_frame

	var rso: Control = root.get_node_or_null("RunScreen/RunStartOptions") as Control
	if rso == null or not rso.visible:
		print("[PROBE] RSO 未顯示")
		get_tree().quit(1)
		return
	var container: Node = rso.get_node_or_null("StartingOptionContainer")
	print("[PROBE] strips=", container.get_child_count() if container != null else -1)
	var bc: BoxContainer = container as BoxContainer
	print("[PROBE] container vertical=", bc.vertical if bc != null else "?", " size=", (container as Control).size, " pos=", (container as Control).position)
	for c in container.get_children():
		if c is Control:
			print("[PROBE]   strip rect=", (c as Control).get_rect(), " flags_h=", (c as Control).size_flags_horizontal)

	# 三解析度靜態構圖（重新 populate 以套 relayout）
	for res: Vector2i in RES_LIST:
		get_window().size = res
		for i in 6:
			await get_tree().process_frame
		rso.call("clear_run_start_options")
		rso.call("populate_run_start_options")
		for i in 8:
			await get_tree().process_frame
		_shot("/tmp/rso_probe_%dx%d.png" % [res.x, res.y])

	# §2 兩段擲筊驗證（基準解析度）
	get_window().size = RES_LIST[0]
	for i in 6:
		await get_tree().process_frame
	rso.call("clear_run_start_options")
	rso.call("populate_run_start_options")
	for i in 8:
		await get_tree().process_frame
	# 第一段：點籤 → 選取 + 現「擲筊問神」CTA（不立即定案）
	var opt: DialogueOption = container.get_child(1) as DialogueOption
	opt.dialogue_option_clicked.emit(opt)
	for i in 10:
		await get_tree().process_frame
	var cta: Node = rso.get_node_or_null("JiaoCta")
	print("[PROBE] stage1 CTA visible=", (cta.visible if cta != null else "?"), " pending=", rso.get("_pending_option") != null)
	_shot("/tmp/rso_probe_select.png")
	# 第二段：擲筊直到聖筊定案（聖 0.55，平均 ~2 次）
	var committed: bool = false
	for tries in 14:
		rso.call("_on_jiao_cta_pressed")
		await get_tree().create_timer(0.6).timeout
		if not rso.visible:
			committed = true
			break
	print("[PROBE] committed_after_jiao=", committed)
	await get_tree().create_timer(0.6).timeout
	var map_node: CanvasItem = root.get_node_or_null("RunScreen/Map") as CanvasItem
	print("[PROBE] map_visible_after_commit=", map_node.visible if map_node != null else "?")
	_shot("/tmp/rso_probe_committed.png")
	get_tree().quit(0)
