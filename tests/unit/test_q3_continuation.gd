# 鎮島錄 Q3-D — PRD 續調守門：香火路線加權結算 + AoE 破煞判定。
extends "res://tests/test_case.gd"

func _loc(modifier: float, visited: bool, type: int = LocationData.LOCATION_TYPES.COMBAT) -> LocationData:
	var l: LocationData = LocationData.new()
	l.location_incense_modifier = modifier
	l.location_visited = visited
	l.location_type = type
	return l

# ---------- 香火路線加權 ----------

func test_incense_multiplier_averages_visited_only() -> void:
	var locs: Array[LocationData] = [
		_loc(1.5, true), _loc(0.8, true),	# 行經：荒宅 + 廟路
		_loc(1.3, false),					# 未走過不計
		_loc(2.0, true, LocationData.LOCATION_TYPES.STARTING),	# 起點不計
	]
	assert_true(absf(Global.incense_route_multiplier(locs) - 1.15) < 0.001,
		"行經加權 = (1.5+0.8)/2 = 1.15")

func test_incense_multiplier_empty_run_is_neutral() -> void:
	var locs: Array[LocationData] = [_loc(1.5, false)]
	assert_eq(Global.incense_route_multiplier(locs), 1.0, "無行經紀錄回 1.0（直接退局）")

func test_incense_multiplier_zero_modifier_treated_as_one() -> void:
	var locs: Array[LocationData] = [_loc(0.0, true)]
	assert_eq(Global.incense_route_multiplier(locs), 1.0, "未標路線的節點視為 1.0")

# ---------- AoE 破煞判定 ----------

func _enemy_in_tree() -> Enemy:
	var e: Enemy = Scenes.ENEMY.instantiate() if "ENEMY" in Scenes else null
	if e == null:
		e = load("res://prefabs/combatants/enemy.tscn").instantiate() if ResourceLoader.exists("res://prefabs/combatants/enemy.tscn") else null
	assert_not_null(e, "需要可實例化的 Enemy prefab")
	Global.add_child(e)
	return e

func _request(card_id: String, target: BaseCombatant) -> CardPlayRequest:
	var r: CardPlayRequest = CardPlayRequest.new()
	r.card_data = Global.get_card_data(card_id)
	r.selected_target = target
	return r

func test_aoe_card_hits_every_enemy_ward() -> void:
	var e: Enemy = _enemy_in_tree()
	var r: CardPlayRequest = _request("card_tongji_firecracker_volley", null)
	assert_not_null(r.card_data, "鞭炮陣應已註冊進卡池")
	assert_false(r.card_data.card_requires_target, "鞭炮陣為免選目標 AoE")
	assert_true(e._card_play_hits_ward(r), "AoE 卡（ALL_ENEMIES override）應波及本敵削盾")
	e.queue_free()

func test_single_target_card_only_hits_selected() -> void:
	var e: Enemy = _enemy_in_tree()
	var other: Enemy = _enemy_in_tree()
	var r: CardPlayRequest = _request("card_tongji_charge", other)
	assert_false(e._card_play_hits_ward(r), "單體卡指了別人，不波及本敵")
	var r2: CardPlayRequest = _request("card_tongji_charge", e)
	assert_true(e._card_play_hits_ward(r2), "單體卡指本敵則結算")
	e.queue_free()
	other.queue_free()

func test_aoe_card_break_numbers_registered() -> void:
	var c: CardData = Global.get_card_data("card_tongji_firecracker_volley")
	assert_not_null(c, "鞭炮陣已載入")
	assert_true(c.card_break_damage > 0, "AoE 卡帶削盾值（各敵各算）")
	assert_true(c.card_ritual_tags.has("fire"), "鞭炮屬火儀法（弱點判定用）")

# ---------- Q3-F 合符神力消耗實驗開關 ----------

func test_merge_energy_cost_defaults_to_free() -> void:
	assert_eq(Global.run_merge_energy_cost, 0, "預設 0 = 現狀免費（經濟定案前不動）")

func test_merge_energy_cost_gates_when_broke() -> void:
	var hand: Node = load("res://scripts/ui/Hand.gd").new()
	Global.add_child(hand)
	Global.run_merge_energy_cost = 1
	var saved_energy: int = Global.player_data.player_energy
	Global.player_data.player_energy = 0
	var a: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
	var b: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
	assert_false(hand.merge_cards(a, b), "神力不足時合符被擋（gate 在 can_merge 之前）")
	Global.run_merge_energy_cost = 0
	Global.player_data.player_energy = saved_energy
	hand.queue_free()

# ---------- Q3-A Boss 覺醒（多階段轉場）----------

func _awaken_enemy(hp_ratio: float) -> Enemy:
	var e: Enemy = _enemy_in_tree()
	e.enemy_data = Global.get_enemy_data_from_prototype("enemy_tiger_god")
	e.enemy_data.enemy_health = int(e.enemy_data.enemy_health_max * hp_ratio)
	return e

func test_boss_awaken_json_carries_numbers() -> void:
	var d: EnemyData = Global.get_enemy_data_from_prototype("enemy_tiger_god")
	assert_true(d.enemy_awaken_threshold > 0.0, "百年虎爺應有覺醒閾值（JSON）")
	assert_true(d.enemy_awaken_restore_ward, "覺醒應重灌煞盾（第二輪破煞循環）")
	assert_ne(d.enemy_awaken_title, "", "覺醒標題在 JSON")

func test_awaken_triggers_once_below_threshold() -> void:
	var e: Enemy = _awaken_enemy(0.45)
	e.enemy_data.enemy_ward_shield = 0
	e.enemy_data.enemy_is_broken = true
	AwakenCutInFX._last_msec = -100000
	e._check_awaken()
	assert_true(e.enemy_data.enemy_is_awakened, "血量 45% ≤ 閾值 50% 應覺醒")
	assert_eq(e.enemy_data.enemy_ward_shield, e.enemy_data.enemy_max_ward_shield, "覺醒煞盾重灌")
	assert_false(e.enemy_data.enemy_is_broken, "覺醒清除破煞態（第二輪循環）")
	var ward_after: int = e.enemy_data.enemy_ward_shield
	e.enemy_data.enemy_ward_shield = 3
	e._check_awaken()
	assert_eq(e.enemy_data.enemy_ward_shield, 3, "覺醒只觸發一次（不重灌第二次）")
	var layer: Node = Global.get_tree().root.get_node_or_null("AwakenCutInLayer")
	if layer != null:
		AwakenCutInFX._free_layer(layer)
	e.queue_free()

func test_awaken_not_triggered_above_threshold() -> void:
	var e: Enemy = _awaken_enemy(0.8)
	e._check_awaken()
	assert_false(e.enemy_data.enemy_is_awakened, "血量 80% > 閾值不覺醒")
	e.queue_free()

func test_normal_enemies_never_awaken() -> void:
	var e: Enemy = _enemy_in_tree()
	e.enemy_data = Global.get_enemy_data_from_prototype("enemy_tiger_aunt")
	e.enemy_data.enemy_health = 1
	e._check_awaken()
	assert_false(e.enemy_data.enemy_is_awakened, "threshold 0 的敵人不進覺醒路徑")
	e.queue_free()

func test_awaken_cutin_contract() -> void:
	assert_true(AwakenCutInFX.TOTAL_LIFE <= 1.5, "覺醒 cut-in ≤1.5s（演出鐵律）")
	assert_true(AwakenCutInFX.DIM_ALPHA >= 0.30, "壓暗 ≥30%（基準 Q-2）")
