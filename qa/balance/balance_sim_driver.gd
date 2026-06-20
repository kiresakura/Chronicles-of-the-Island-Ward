extends Node
# 鎮島錄 Q3-F — 平衡模擬 driver（DELEGATION：「蒐集模擬數據給憲龍拍板，不擅自定平衡」）。
#
# 真實戰鬥樹模擬：start_run → 傳送至指定樓層戰鬥節點 → 貪婪 AI 打完 → 統計。
# 變體（env BAL_VARIANT）：base（廟 0 級現狀）/ backup_deity（正殿 1 級備援神位）/
# merge_cost1（合符消耗 1 神力 — Q3-F 實驗開關）。
# env：BAL_SEEDS（預設 12）、BAL_OUT（JSON 輸出，預設 /tmp/balance_<variant>.json）。
# Engine.time_scale 加速演出；profile meta 模擬前清空、模擬後還原歸零（不污染存檔）。

var BATTLE_FLOORS: Array[int] = [1, 2, 3, 5]	# 三場遇煞 + 第 5 層惡煞據點；BAL_FLOORS env 可覆寫（如 "1,2,3,5,10" 含 Boss）
const FRAME_CAP_PER_BATTLE: int = 6000
const PLAYS_PER_TURN_CAP: int = 14	# AI 防呆

var _variant: String = "base"
var _seeds: int = 12
var _out_path: String = ""

var _turns: int = 0
var _is_my_turn: bool = false
var _combat_over: bool = false
var _breaks: int = 0
var _card_use: Dictionary = {}	# card_object_id -> 次數
var _battle_records: Array = []

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	Engine.time_scale = 8.0
	_variant = OS.get_environment("BAL_VARIANT")
	if _variant == "":
		_variant = "base"
	var seeds_env: String = OS.get_environment("BAL_SEEDS")
	_seeds = int(seeds_env) if seeds_env != "" else 12
	var floors_env: String = OS.get_environment("BAL_FLOORS")
	if floors_env != "":
		BATTLE_FLOORS.clear()
		for tok: String in floors_env.split(","):
			BATTLE_FLOORS.append(int(tok))
	_out_path = OS.get_environment("BAL_OUT")
	if _out_path == "":
		_out_path = "/tmp/balance_%s.json" % _variant

	await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 70:
		await get_tree().process_frame
	var ov: Node = root.find_child("RootLoadingOverlay", true, false)
	if ov != null:
		ov.queue_free()
	for i in 10:
		await get_tree().process_frame

	Signals.player_turn_started.connect(func() -> void: _turns += 1; _is_my_turn = true)
	Signals.player_turn_ended.connect(func() -> void: _is_my_turn = false)
	Signals.combat_ended.connect(func() -> void: _combat_over = true)
	Signals.enemy_broken.connect(func(_e) -> void: _breaks += 1)
	Signals.card_played.connect(func(req: CardPlayRequest) -> void:
		if req != null and req.card_data != null:
			_card_use[req.card_data.object_id] = int(_card_use.get(req.card_data.object_id, 0)) + 1)

	print("[BAL] variant=%s seeds=%d time_scale=%.0f" % [_variant, _seeds, Engine.time_scale])
	for seed_i: int in _seeds:
		await _simulate_run(root, 31000 + seed_i)
	_write_report()
	get_tree().quit(0)

func _simulate_run(root: Node, run_seed: int) -> void:
	# profile meta 清空 + 變體設定（不污染真實存檔：結束歸零再存）
	Global.profile_data.profile_building_id_to_level.clear()
	Global.profile_data.profile_incense_balance = 0
	if _variant == "backup_deity":
		Global.profile_data.profile_building_id_to_level["building_main_hall"] = 1

	Global.start_run("character_tongji", run_seed)
	if _variant == "merge_cost1":
		Global.run_merge_energy_cost = 1
	for i in 20:
		await get_tree().process_frame

	# RSO：選 index 1（即時效果，不開卡選 overlay）
	var rso: Node = root.get_node_or_null("RunScreen/RunStartOptions")
	var container: Node = rso.get_node_or_null("StartingOptionContainer") if rso != null else null
	if container != null and container.get_child_count() > 1:
		var opt: DialogueOption = container.get_child(1) as DialogueOption
		if opt != null:
			opt.dialogue_option_clicked.emit(opt)
	var map_node: CanvasItem = root.get_node_or_null("RunScreen/Map") as CanvasItem
	for i in 600:
		await get_tree().process_frame
		if map_node != null and map_node.visible:
			break

	var combat: Node = root.get_node_or_null("RunScreen/Combat")
	var hand: Node = root.get_node_or_null("RunScreen/Combat/Hand")
	var hp_start: int = Global.player_data.player_health

	for floor_k: int in BATTLE_FLOORS:
		var loc: LocationData = _find_battle_location(floor_k)
		if loc == null:
			continue
		_turns = 0
		_combat_over = false
		_breaks = 0
		var merges: int = 0
		var invokes: int = 0
		ActionGenerator.generate_visit_location(loc.location_id)
		for i in 200:
			await get_tree().process_frame
			if combat != null and (combat as CanvasItem).visible:
				break

		# ── AI 戰鬥迴圈 ──
		var frames: int = 0
		var timed_out: bool = false
		while not _combat_over:
			await get_tree().process_frame
			frames += 1
			if frames > FRAME_CAP_PER_BATTLE:
				timed_out = true
				break
			if not Global.get_player().is_alive():
				break
			if ActionHandler.actions_being_performed or not _is_my_turn:
				continue
			# 我方回合、行動空檔 → AI 一步
			var acted: bool = false
			# 1) 合符（每回合限額由遊戲端管）
			var pair: Array = _find_merge_pair()
			if pair.size() == 2 and hand.merge_cards(pair[0], pair[1]):
				merges += 1
				acted = true
			# 2) 出一張付得起的卡
			if not acted:
				acted = _play_one_card(hand, root)
			# 3) 降乩
			if not acted and combat._deity_controller != null and combat._deity_controller.is_ready():
				combat._on_invoke_button_pressed()
				invokes += 1
				acted = true
			# 4) 無事可做 → 結束回合
			if not acted:
				_is_my_turn = false
				combat._on_end_turn_button_up()
			for j in 4:
				await get_tree().process_frame

		var victory: bool = _combat_over and Global.get_player().is_alive()
		_battle_records.append({
			"variant": _variant, "seed": run_seed, "floor": floor_k,
			"enemy_event": loc.location_event_object_id if loc.location_event_object_id != "" else loc.location_event_pool_object_id,
			"victory": victory, "timeout": timed_out, "turns": _turns,
			"hp_left": Global.player_data.player_health, "hp_max": Global.player_data.player_health_max,
			"merges": merges, "invokes": invokes, "breaks": _breaks,
		})
		if not victory:
			break
		# 戰勝 → 收掉獎勵 overlay（不領卡：卡組固定，對照乾淨）
		await _dismiss_reward(root)

	print("[BAL] seed %d done（hp %d→%d）" % [run_seed, hp_start, Global.player_data.player_health])
	Global.end_run(Global.RUN_ENDS.QUIT)
	Global.run_merge_energy_cost = 0
	Global.profile_data.profile_building_id_to_level.clear()
	Global.profile_data.profile_incense_balance = 0
	FileLoader.save_profile()
	for i in 20:
		await get_tree().process_frame

func _find_battle_location(floor_k: int) -> LocationData:
	for loc: LocationData in Global.get_all_act_locations():
		if loc.location_floor == floor_k and not loc.location_visited \
				and (loc.location_type == LocationData.LOCATION_TYPES.COMBAT
					or loc.location_type == LocationData.LOCATION_TYPES.MINIBOSS
					or loc.location_type == LocationData.LOCATION_TYPES.BOSS):
			return loc
	return null

func _find_merge_pair() -> Array:
	var hand_cards: Array = Global.player_data.player_hand
	for i in hand_cards.size():
		for j in range(i + 1, hand_cards.size()):
			var a: CardData = hand_cards[i]
			var b: CardData = hand_cards[j]
			if TalismanMergeSystem.can_merge(a, b) and Global._id_to_card_data.has(a.card_merge_result_id):
				return [a, b]
	return []

func _play_one_card(hand: Node, root: Node) -> bool:
	var energy: int = Global.player_data.player_energy
	for card_data: CardData in Global.player_data.player_hand:
		if card_data.card_energy_cost > energy:
			continue
		var request: CardPlayRequest = CardPlayRequest.new()
		request.card_data = card_data
		request.card_values = card_data.card_values.duplicate(true)
		if card_data.card_requires_target:
			var target: Enemy = _lowest_hp_enemy(root)
			if target == null:
				continue
			request.selected_target = target
		hand.add_card_to_play_queue(request, true, false)
		return true
	return false

func _lowest_hp_enemy(root: Node) -> Enemy:
	var best: Enemy = null
	var container: Node = root.get_node_or_null("RunScreen/Combat/EnemyContainer")
	if container == null:
		return null
	for e: Node in container.find_children("*", "Enemy", true, false):
		var enemy: Enemy = e as Enemy
		if enemy != null and enemy.is_alive():
			if best == null or enemy.enemy_data.enemy_health < best.enemy_data.enemy_health:
				best = enemy
	return best

func _dismiss_reward(root: Node) -> void:
	for i in 240:
		await get_tree().process_frame
		var reward: Control = root.get_node_or_null("RunScreen/RewardOverlay") as Control
		if reward != null and reward.visible:
			var btn: Button = reward.get_node_or_null("ContinueButton") as Button
			if btn != null:
				btn.button_up.emit()
			for j in 20:
				await get_tree().process_frame
			return
		var map_node: CanvasItem = root.get_node_or_null("RunScreen/Map") as CanvasItem
		if map_node != null and map_node.visible:
			return

func _write_report() -> void:
	var f: FileAccess = FileAccess.open(_out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"variant": _variant, "battles": _battle_records, "card_use": _card_use}, "\t"))
	f.close()
	var wins: int = 0
	for r: Dictionary in _battle_records:
		if bool(r.get("victory", false)):
			wins += 1
	print("[BAL] battles=%d wins=%d → %s" % [_battle_records.size(), wins, _out_path])
