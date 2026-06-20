extends Node
# Q2-A 探針：開局 → 顯示遶境地圖 → 三解析度截圖（蜿蜒重映射/符紙/色環/Boss 壓迫感目視驗證）

const RES_LIST := [Vector2i(1244, 700), Vector2i(1515, 700), Vector2i(1200, 900)]

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
	var rso: Node = root.get_node_or_null("RunScreen/RunStartOptions")
	var container: Node = rso.get_node_or_null("StartingOptionContainer") if rso != null else null
	if container != null and container.get_child_count() > 1:
		var opt: DialogueOption = container.get_child(1) as DialogueOption
		if opt != null:
			opt.dialogue_option_clicked.emit(opt)
	for i in 60:
		await get_tree().process_frame

	var map: Control = root.get_node_or_null("RunScreen/Map") as Control
	if map == null:
		print("[PROBE] Map 不存在")
		get_tree().quit(1)
		return
	for res: Vector2i in RES_LIST:
		get_window().size = res
		for i in 8:
			await get_tree().process_frame
		map.call("show_map")
		for i in 14:
			await get_tree().process_frame
		RenderingServer.force_draw()
		var img: Image = get_viewport().get_texture().get_image()
		var path: String = "/tmp/map_probe_%dx%d.png" % [res.x, res.y]
		img.save_png(path)
		print("[PROBE] saved ", path)
	# Boss 區（卷軸捲到頂）
	var sc: ScrollContainer = map.get_node_or_null("ScrollContainer") as ScrollContainer
	if sc != null:
		sc.scroll_vertical = 0
		for i in 10:
			await get_tree().process_frame
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_png("/tmp/map_probe_boss_top.png")
		print("[PROBE] saved /tmp/map_probe_boss_top.png")
	# 結構自檢：符紙/路基/色環/煞氣存在性
	var lc: Node = map.get_node_or_null("ScrollContainer/LocationContainer")
	var has_scroll: bool = lc != null and lc.get_node_or_null("TalismanScroll") != null
	var beds: int = 0
	var rings: int = 0
	var aura: bool = false
	if lc != null:
		for child in lc.get_children():
			# Godot 撞名自動改名為 @類名@N → 名稱不可靠，用 meta 計數
			if String(child.name).contains("RouteLineLayer"):
				for l in child.get_children():
					if l.has_meta("route_story") and str(l.get_meta("route_story")) == "road_bed":
						beds += 1
			if String(child.name).contains("BossOmenLayer"):
				for o in child.get_children():
					if String(o.name).contains("BossShaAura") or (o is TextureRect and String(o.name).contains("@TextureRect")):
						aura = true
			if child is MapLocation:
				if (child as Control).get_node_or_null("TypeRing") != null:
					rings += 1
	print("[PROBE] TalismanScroll=%s RoadBeds=%d TypeRings=%d BossAura=%s" % [str(has_scroll), beds, rings, str(aura)])
	# 層級傾印（debug）
	if lc != null:
		var counts: Dictionary = {}
		for child in lc.get_children():
			var key: String = String(child.name).lstrip("@").split("@")[0]
			if child is MapLocation:
				key = "MapLocation"
			counts[key] = int(counts.get(key, 0)) + 1
			if String(child.name).contains("RouteLineLayer"):
				var sub: Dictionary = {}
				for l in child.get_children():
					var k2: String = String(l.name).lstrip("@").split("@")[0]
					sub[k2] = int(sub.get(k2, 0)) + 1
				print("[PROBE]   RouteLineLayer children: ", sub)
		print("[PROBE] lc children: ", counts)
	get_tree().quit(0)
