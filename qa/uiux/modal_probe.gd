extends Node
# 一次性探針：overlay 遮罩 runtime 幾何 + mouse_filter + 真實點擊穿透測試（1515 寬）

func _ready() -> void:
	get_window().size = Vector2i(1515, 700)
	await get_tree().process_frame
	await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 70:
		await get_tree().process_frame

	print("[PROBE] vp=", get_viewport().get_visible_rect())
	for p in ["RunScreen", "TitleScreen"]:
		var n: Control = root.get_node_or_null(p) as Control
		if n != null:
			print("[PROBE] %s rect=%s" % [p, str(n.get_global_rect())])

	const FILTERS := {0: "STOP", 1: "PASS", 2: "IGNORE"}
	for ov in ["PauseOverlay","ShopOverlay","RestOverlay","DialogueOverlay","RewardOverlay","RunSummaryOverlay","CardSelectionOverlay","CardDraftSelectionOverlay","RunStartOptions"]:
		var o: Control = root.get_node_or_null("RunScreen/" + ov) as Control
		if o == null:
			continue
		var line: String = "[PROBE] %s root=%s f=%s" % [ov, str(o.get_global_rect()), FILTERS.get(o.mouse_filter, "?")]
		for bgname in ["Background", "RSOBackdrop"]:
			var bg: Control = o.get_node_or_null(bgname) as Control
			if bg != null:
				line += " | %s=%s f=%s" % [bgname, str(bg.get_global_rect()), FILTERS.get(bg.mouse_filter, "?")]
		print(line)

	# --- 真實穿透測試：開一局進戰鬥，開暫停，點右側帶的結束回合 ---
	Global.start_run("character_tongji", 20260607)
	for i in 30:
		await get_tree().process_frame
	var rso: Node = root.get_node_or_null("RunScreen/RunStartOptions")
	var container: Node = rso.get_node_or_null("StartingOptionContainer") if rso != null else null
	if container != null and container.get_child_count() > 1:
		var opt: DialogueOption = container.get_child(1) as DialogueOption
		if opt != null:
			opt.dialogue_option_clicked.emit(opt)
	for i in 60:
		await get_tree().process_frame
	var locs: Array = Global.get_all_act_locations()
	for l in locs:
		if (l as LocationData).location_type == LocationData.LOCATION_TYPES.COMBAT:
			ActionGenerator.generate_visit_location((l as LocationData).location_id)
			break
	for i in 90:
		await get_tree().process_frame

	var endturn: Button = root.get_node_or_null("RunScreen/Combat/EndTurnButton") as Button
	if endturn == null:
		print("[PROBE] EndTurnButton 不存在，跳過穿透測試")
		get_tree().quit(0)
		return
	print("[PROBE] EndTurn rect=", endturn.get_global_rect(), " visible=", endturn.is_visible_in_tree())
	var hits: Array = []
	endturn.button_up.connect(func() -> void: hits.append("button_up"))
	endturn.pressed.connect(func() -> void: hits.append("pressed"))

	Global.pause_game()
	for i in 12:
		await get_tree().process_frame
	var pause: Control = root.get_node_or_null("RunScreen/PauseOverlay") as Control
	print("[PROBE] Pause visible=", pause.is_visible_in_tree() if pause != null else "?")

	var pos: Vector2 = endturn.get_global_rect().get_center()
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		get_viewport().push_input(ev)
		await get_tree().process_frame
	for i in 8:
		await get_tree().process_frame
	print("[PROBE] 暫停中點擊結束回合(%s) → hits=%s %s" % [str(pos), str(hits), "⚠️ 穿透成立" if hits.size() > 0 else "✓ 被遮罩擋下"])
	Global.unpause_game()
	# 開商店看 Background 實際狀態
	var shop: Control = root.get_node_or_null("RunScreen/ShopOverlay") as Control
	if shop != null:
		shop.call("populate_shop")
		shop.visible = true
		for i in 12:
			await get_tree().process_frame
		var sbg: Control = shop.get_node_or_null("Background") as Control
		print("[PROBE] Shop open: Background rect=%s visible=%s filter=%d" % [str(sbg.get_global_rect()) if sbg != null else "null", str(sbg.is_visible_in_tree()) if sbg != null else "?", sbg.mouse_filter if sbg != null else -1])
		for c: Node in shop.get_children():
			if c is Control:
				print("[PROBE]   shop child %s rect=%s vis=%s" % [c.name, str((c as Control).get_global_rect()), str((c as CanvasItem).visible)])
	get_tree().quit(0)
