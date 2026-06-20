extends Node
# Q3-A 探針：Boss 戰 → 打到覺醒閾值 → cut-in 三幀（掃入/定格/煞盾重灌後）

func _shot(path: String) -> void:
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png(path)
	print("[PROBE] saved ", path)

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_window().size = Vector2i(1244, 700)
	await get_tree().process_frame
	await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 80:
		await get_tree().process_frame
	var ov: Node = root.find_child("RootLoadingOverlay", true, false)
	if ov != null:
		ov.queue_free()
	for i in 10:
		await get_tree().process_frame

	Global.start_run("character_tongji", 20260612)
	for i in 30:
		await get_tree().process_frame
	var rso: Node = root.get_node_or_null("RunScreen/RunStartOptions")
	var container: Node = rso.get_node_or_null("StartingOptionContainer")
	(container.get_child(1) as DialogueOption).dialogue_option_clicked.emit(container.get_child(1))
	for i in 200:
		await get_tree().process_frame
		var m: CanvasItem = root.get_node_or_null("RunScreen/Map") as CanvasItem
		if m != null and m.visible:
			break

	# 直入 Boss 節點
	var boss_loc: LocationData = null
	for loc: LocationData in Global.get_all_act_locations():
		if loc.location_type == LocationData.LOCATION_TYPES.BOSS:
			boss_loc = loc
			break
	ActionGenerator.generate_visit_location(boss_loc.location_id)
	var combat: CanvasItem = root.get_node_or_null("RunScreen/Combat") as CanvasItem
	for i in 300:
		await get_tree().process_frame
		if combat.visible:
			break
	for i in 30:
		await get_tree().process_frame

	# 找 Boss 敵 → 打到閾值下
	var boss_enemy: Enemy = null
	for e: Node in root.get_node("RunScreen/Combat/EnemyContainer").find_children("*", "Enemy", true, false):
		if (e as Enemy).enemy_data != null and (e as Enemy).enemy_data.enemy_awaken_threshold > 0.0:
			boss_enemy = e as Enemy
			break
	if boss_enemy == null:
		print("[PROBE] Boss 敵未找到")
		get_tree().quit(1)
		return
	print("[PROBE] boss hp=", boss_enemy.enemy_data.enemy_health)
	boss_enemy.damage(80, true)	# 150 → 70 (≤75 閾值) → 覺醒
	await get_tree().create_timer(0.28).timeout
	_shot("/tmp/boss_awaken_sweep.png")
	await get_tree().create_timer(0.35).timeout
	_shot("/tmp/boss_awaken_peak.png")
	await get_tree().create_timer(0.9).timeout
	_shot("/tmp/boss_awaken_after.png")
	print("[PROBE] awakened=", boss_enemy.enemy_data.enemy_is_awakened,
		" ward=", boss_enemy.enemy_data.enemy_ward_shield, "/", boss_enemy.enemy_data.enemy_max_ward_shield)
	get_tree().quit(0)
