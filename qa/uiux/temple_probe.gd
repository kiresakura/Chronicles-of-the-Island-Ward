extends Node
# Q2-D 探針：主選單修廟入口 → 修廟畫面（兩解析度）→ 修復一棟 → 等級/香火/刷新驗證

func _shot(path: String) -> void:
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png(path)
	print("[PROBE] saved ", path)

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	if OS.get_environment("PROBE_LOCALE") != "":
		TranslationServer.set_locale(OS.get_environment("PROBE_LOCALE"))
	get_window().size = Vector2i(1244, 700)
	await get_tree().process_frame
	await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 80:
		await get_tree().process_frame
	# 跳過品牌過場 overlay（擋住主選單互動）
	var ov: Node = root.find_child("RootLoadingOverlay", true, false)
	if ov != null:
		ov.queue_free()
	for i in 10:
		await get_tree().process_frame

	# 基線歸零（先前探針/QA run 可能殘留 meta）再給足香火（驗可修狀態 + 香火列刷新）
	Global.profile_data.profile_building_id_to_level.clear()
	Global.profile_data.profile_incense_balance = 500
	var menu: Node = root.get_node_or_null("TitleScreen/MainMenu")
	if menu == null:
		var found: Array = root.find_children("*", "Control", true, false).filter(func(n): return n.name == "MainMenu")
		menu = found[0] if found.size() > 0 else null
	if menu == null:
		print("[PROBE] MainMenu 不存在")
		get_tree().quit(1)
		return
	menu.call("_refresh_resources")
	for i in 4:
		await get_tree().process_frame
	_shot("/tmp/temple_probe_menu.png")	# 香火列應顯示 500（bug 修復驗證）

	# 開修廟
	menu.call("_open_temple_screen")
	for i in 10:
		await get_tree().process_frame
	_shot("/tmp/temple_probe_1244x700.png")
	get_window().size = Vector2i(1200, 900)
	for i in 8:
		await get_tree().process_frame
	var ts: Node = menu.get_node_or_null("TempleScreen")
	if ts != null:
		ts.call("_relayout")
	for i in 4:
		await get_tree().process_frame
	_shot("/tmp/temple_probe_1200x900.png")
	get_window().size = Vector2i(1244, 700)
	for i in 8:
		await get_tree().process_frame
	if ts != null:
		ts.call("_relayout")

	# 修一棟便宜的（戲台 150）
	var before_incense: int = Global.profile_data.profile_incense_balance
	var btn: Button = ts.get_node_or_null("BuildingGrid/Card_building_stage").find_children("*", "Button", true, false)[0] as Button
	print("[PROBE] stage btn disabled=", btn.disabled, " text=", btn.text)
	btn.button_up.emit()
	for i in 10:
		await get_tree().process_frame
	var lvl: int = Global.profile_data.get_building_level("building_stage")
	var after_incense: int = Global.profile_data.profile_incense_balance
	print("[PROBE] 修復後 stage_lv=%d 香火 %d→%d" % [lvl, before_incense, after_incense])
	_shot("/tmp/temple_probe_repaired.png")

	# 解鎖過濾池現場驗證
	var locked: Array = RitualLoadout.list_tool_ids_unlocked(Global.profile_data)
	Global.profile_data.profile_building_id_to_level["building_tiger_shrine"] = 1
	var opened: Array = RitualLoadout.list_tool_ids_unlocked(Global.profile_data)
	print("[PROBE] 法器池 0級=%s → 虎爺殿1級=%s" % [str(locked), str(opened)])
	# 還原 meta 欄位（修復流程會 save_profile — 探針不得污染真實存檔）
	Global.profile_data.profile_incense_balance = 0
	Global.profile_data.profile_building_id_to_level.clear()
	FileLoader.save_profile()
	print("[PROBE] profile meta 已還原（香火 0 / 建築清空）")
	get_tree().quit(0)
