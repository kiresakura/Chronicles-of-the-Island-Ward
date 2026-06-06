# 鎮島錄 — 戰鬥主流程 headless smoke test
#
# 目的（P0）：用最低成本確認「進入戰鬥 → 第一回合就緒 → 結束回合」的核心 UI
# 與狀態轉換沒有壞掉。屬冒煙測試（smoke），不驗傷害數值（那在 test_combat_math）。
#
# 重要限制：run_all.gd 以 instance.call(method) 執行，**不 await 測試方法**，
# 因此本測試全程「同步」斷言：
#   - add_child(Root) 會同步觸發整棵 _ready 鏈
#   - Global.start_run() 同步建立 player_data + 生成世界 + emit run_started
#   - Signals.combat_started.emit() 的同步段：populate 敵人 / 開戰鬥顯示 / 重置牌庫
#   - Combat.queue_end_turn() 的同步段：emit disable_hand_requested(true) + 鎖結束鈕
# 非同步的抽牌動畫鏈（start_turn 動畫 → 抽牌 await）不在同步段內，故不在此斷言。
extends "res://tests/test_case.gd"

const ROOT_SCENE_PATH: String = "res://scenes/Root.tscn"
const SMOKE_CHARACTER_ID: String = "character_tongji"
const SMOKE_EVENT_ID: String = "event_act_1_easy_combat_1"   # act1 山道 — 簡單戰鬥，敵人固定
const SMOKE_RUN_SEED: int = 20260602


## 建立一個可用的戰鬥環境：實例化 Root.tscn + 開一局 run。
## 回傳 { root, combat }；失敗時回傳空字典。
func _build_combat_env() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return {}
	var root_scene: PackedScene = load(ROOT_SCENE_PATH)
	if root_scene == null:
		return {}
	var root: Node = root_scene.instantiate()
	# add_child 會同步觸發 Root 整棵子樹的 _ready（含 Combat / Hand / HUD overlay）
	tree.root.add_child(root)

	# 建立可用 run 狀態（同步：player_data + 世界 + run_started）
	Global.start_run(SMOKE_CHARACTER_ID, SMOKE_RUN_SEED)

	var combat: Node = root.get_node_or_null("RunScreen/Combat")
	return {"root": root, "combat": combat}


## 拆除環境：先結束 run（讓還在樹上的節點正常處理 run_ended），再移除並釋放 Root。
func _teardown_env(env: Dictionary) -> void:
	if Global.is_run:
		Global.end_run(Global.RUN_ENDS.QUIT)
	var root: Node = env.get("root")
	if root != null and is_instance_valid(root):
		var tree := Engine.get_main_loop() as SceneTree
		tree.root.remove_child(root)
		root.free()


# ───────────────────────── 測試 1：核心 UI 節點 + 戰鬥啟動顯示 ─────────────────────────

func test_combat_boot_exposes_core_ui_and_starts_display() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "Root.tscn 應包含 RunScreen/Combat 戰鬥節點")
	if combat == null:
		_teardown_env(env)
		return

	# 核心 UI 節點存在
	var hand: Node = combat.get_node_or_null("Hand")
	var end_turn_button: Node = combat.get_node_or_null("EndTurnButton")
	var select_target_label: Node = combat.get_node_or_null("SelectTargetLabel")
	var hud_layer: Node = combat.get_node_or_null("CombatHudOverlay")
	assert_not_null(hand, "戰鬥應有 Hand 手牌容器節點")
	assert_not_null(end_turn_button, "戰鬥應有 EndTurnButton 結束回合鈕")
	assert_true(end_turn_button is Button, "EndTurnButton 應為 Button 型別，才能 disabled/觸發")
	assert_not_null(select_target_label, "戰鬥應有 SelectTargetLabel 選敵提示節點")
	assert_not_null(hud_layer, "戰鬥 HUD（CombatHudOverlay CanvasLayer）應已掛載")

	# 進入戰鬥：直接帶有效 event 的 combat_started（避開 location 推導依賴）
	Signals.combat_started.emit(SMOKE_EVENT_ID)

	# combat_started 同步段後置條件
	assert_true(end_turn_button.visible, "combat_started 後戰鬥顯示應開啟（EndTurnButton 可見）")
	var tree := Engine.get_main_loop() as SceneTree
	var enemies: Array = tree.get_nodes_in_group("enemies")
	assert_true(enemies.size() > 0, "combat_started 後應至少生成 1 個敵人（enemies 群組非空）")
	assert_true(Global.player_data.player_draw.size() > 0, "combat_started 後牌庫 player_draw 應完成初始化且非空")

	_teardown_env(env)


# ───────────────────────── 測試 2：手牌啟用 + 結束回合鎖定 ─────────────────────────

func test_combat_turn_hand_enable_then_end_turn_locks_controls() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "Root.tscn 應包含 RunScreen/Combat 戰鬥節點")
	if combat == null:
		_teardown_env(env)
		return
	var hand: Node = combat.get_node_or_null("Hand")
	var end_turn_button: Node = combat.get_node_or_null("EndTurnButton")
	assert_not_null(hand, "戰鬥應有 Hand 手牌容器")
	assert_not_null(end_turn_button, "戰鬥應有 EndTurnButton")
	if hand == null or end_turn_button == null:
		_teardown_env(env)
		return

	Signals.combat_started.emit(SMOKE_EVENT_ID)

	# 模擬「玩家回合就緒、手牌可操作」：disable_hand_requested(false) 是回合內啟用手牌的同步機制
	Signals.disable_hand_requested.emit(false)
	assert_false(hand.hand_disabled, "玩家回合就緒後，手牌應解除 disabled（可手動出牌）")

	# 模擬「玩家按下結束回合」：queue_end_turn 同步段會 emit disable_hand_requested(true) 並鎖結束鈕
	combat.queue_end_turn()
	assert_true(hand.hand_disabled, "結束回合後手牌應 disabled（避免結算期間繼續出牌）")
	assert_true(end_turn_button.disabled, "結束回合後 EndTurnButton 應 disabled（避免重複觸發結束）")

	_teardown_env(env)


# ──────────── 測試 3：破煞戰鬥接線（Phase 1B）— 真實樹中煞盾 UI + 出牌破煞 ────────────
# 在真正的 Combat 場景樹裡生成真實 Enemy 節點，驗證：
#   (a) Enemy.init() 對有煞盾的敵人建立頭頂煞盾指示 _ward_label
#   (b) Enemy 已連上 Signals.card_played
#   (c) 命中弱點且削穿煞盾 → enemy_is_broken + 套破煞 status + UI 轉「破煞！」
# 全程同步：combat_started 同步生敵、直接呼叫破煞 handler（避免觸發無關 card_played 監聽者）。

func test_combat_enemy_shows_ward_and_breaks_on_weakness_card() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "需要 Combat 節點")
	if combat == null:
		_teardown_env(env)
		return

	Signals.combat_started.emit(SMOKE_EVENT_ID)
	var tree := Engine.get_main_loop() as SceneTree
	var enemies: Array = tree.get_nodes_in_group("enemies")
	assert_true(enemies.size() > 0, "combat_started 後應生成敵人")

	# 找一個具煞盾機制的真實 Enemy 節點
	var target: Enemy = null
	for e: Node in enemies:
		if e is Enemy and (e as Enemy).enemy_data != null and (e as Enemy).enemy_data.enemy_max_ward_shield > 0:
			target = e as Enemy
			break
	assert_not_null(target, "act1 敵人應具煞盾機制（max_ward_shield>0）")
	if target == null:
		_teardown_env(env)
		return

	# (a) 煞盾 UI 已在真實樹中建立；(b) 已連上 card_played
	assert_not_null(target._ward_label, "有煞盾的敵人應已建立頭頂煞盾指示 Label")
	assert_true(Signals.card_played.is_connected(target._on_card_played_ward),
		"Enemy 應已連上 Signals.card_played（出牌時結算破煞）")
	assert_false(target.enemy_data.enemy_is_broken, "戰鬥開始不應處於破煞")
	var ward_before: int = target.enemy_data.enemy_ward_shield
	assert_eq(ward_before, target.enemy_data.enemy_max_ward_shield, "開戰煞盾應為滿值")

	# (c) 構造「必中弱點且一擊削穿」的卡，直接走破煞 handler
	var tags: Array[String] = []
	for w: Variant in target.enemy_data.enemy_weaknesses:
		tags.append(str(w))
	var hit_card: CardData = CardData.new()
	hit_card.card_ritual_tags = tags
	hit_card.card_break_damage = 99
	var req: CardPlayRequest = CardPlayRequest.new()
	req.card_data = hit_card
	req.selected_target = target

	target._on_card_played_ward(req)

	assert_true(target.enemy_data.enemy_is_broken, "命中弱點削穿煞盾後敵人應破煞")
	assert_true(target._ward_label.text.contains("破煞"), "破煞後煞盾指示應顯示「破煞」")
	# 破煞窗口傷害加成生效
	assert_eq(WardBreakSystem.damage_multiplier_for(target.enemy_data), 1.5,
		"破煞窗口我方傷害倍率應為 1.5")

	# P1-1：破煞窗口在玩家回合結束遞減（_on_player_turn_ended 呼叫 super + tick_broken_state）
	var window_before: int = target.enemy_data.enemy_broken_turns_remaining
	target._on_player_turn_ended()
	if window_before <= 1:
		assert_false(target.enemy_data.enemy_is_broken, "窗口=1 → 回合結束解除破煞")
		assert_eq(target.enemy_data.enemy_ward_shield, target.enemy_data.enemy_max_ward_shield, "解除後煞盾回滿")
	else:
		assert_eq(target.enemy_data.enemy_broken_turns_remaining, window_before - 1, "窗口>1 → 遞減 1")

	_teardown_env(env)


# ──────────── 測試 4：符階合成（Phase 1C）— 真實樹中合符升階 + 每回合限額 ────────────
# 在真正的 Combat/Hand 節點上以真實卡牌走 Hand.merge_cards：
#   card_a 原地 transform 成高階符、夥伴 card_b 被 banish 移除、每回合限額生效。

func test_combat_merge_transforms_card_and_consumes_partner() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "需要 Combat 節點")
	if combat == null:
		_teardown_env(env)
		return
	Signals.combat_started.emit(SMOKE_EVENT_ID)
	var hand: Node = combat.get_node_or_null("Hand")
	assert_not_null(hand, "需要 Hand 節點")
	if hand == null:
		_teardown_env(env)
		return

	# 用兩張真實「攻拳」建立手牌（含 Card UI 節點）
	var a: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
	var b: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
	var hand_ab: Array[CardData] = [a, b]
	Global.player_data.player_hand = hand_ab
	var created: Array = hand.create_cards(hand_ab)

	# 走右鍵觸發路徑：_try_merge_card → find_merge_partner → merge_cards（端到端 UX 入口）
	var ok: bool = hand._try_merge_card(created[0])
	assert_true(ok, "右鍵可合符的攻拳應觸發合符成功")
	assert_eq(a.card_name, "重擊", "card_a 應 transform 成重擊")
	assert_eq(a.card_merge_tier, 2, "重擊應為二劃符（tier 2）")
	assert_eq(a.card_break_damage, 3, "重擊 break_damage 應為 3（已 transform）")
	assert_false(Global.player_data.player_hand.has(b), "夥伴卡 b 應已從手牌移除")
	assert_eq(hand._merges_used_this_turn, 1, "本回合合符次數應為 1")

	# 每回合限額：用罄後再給一對「護身符」也不可合
	var c: CardData = Global.get_card_data_from_prototype("card_tongji_talisman")
	var d: CardData = Global.get_card_data_from_prototype("card_tongji_talisman")
	var hand_cd: Array[CardData] = [c, d]
	Global.player_data.player_hand = hand_cd
	var created2: Array = hand.create_cards(hand_cd)
	# P1-2：限額用完 + 有夥伴 → 攔截（顯示 toast）但不實際合符（不落回右鍵）
	assert_true(hand._try_merge_card(created2[0]), "限額用完仍應攔截（toast、不落回右鍵 action）")
	assert_eq(c.card_name, "護身符", "限額用完不應實際合符（c 未升階為鐵布衫）")

	_teardown_env(env)


# ──────────── 測試 5：請神（Phase 1D）— 真實樹中累積 → 滿槽 → 降乩 AoE + 重置 ────────────
# 驗證請神閉環：出 fist 卡 + 破煞累積請神值 → 滿槽降乩按鈕可點 → 虎爺降乩對全體造成傷害 → 重置。
# 連通性（card_played + enemy_broken）以斷言確認；累積以直接呼叫 handler 隔離（不觸發無關監聽者）。

func test_combat_deity_charge_accumulate_and_invoke() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "需要 Combat 節點")
	if combat == null:
		_teardown_env(env)
		return
	Signals.combat_started.emit(SMOKE_EVENT_ID)

	var controller: Variant = combat._deity_controller
	assert_not_null(controller, "Combat 應建立請神槽控制器")
	if controller == null:
		_teardown_env(env)
		return
	# combat_started 已 setup 虎爺、請神值歸 0
	assert_not_null(controller.deity, "出戰神明應已載入")
	assert_eq(controller.deity.deity_name, "虎爺", "MVP 出戰神明為虎爺")
	assert_eq(controller.get_charge(), 0, "開戰請神值應為 0")
	# 連通：控制器已連 card_played + enemy_broken（1B 破煞 → 1D 請神）
	assert_true(Signals.card_played.is_connected(controller._on_card_played), "應連 card_played")
	assert_true(Signals.enemy_broken.is_connected(controller._on_enemy_broken), "應連 enemy_broken")

	# 出 fist 卡累積（攻拳 deity_charge 8）
	var req: CardPlayRequest = CardPlayRequest.new()
	req.card_data = Global.get_card_data_from_prototype("card_tongji_punch")
	controller._on_card_played(req)
	assert_eq(controller.get_charge(), 8, "攻拳（fist）應累積 8 請神值")

	# 破煞累積（+25）
	controller._on_enemy_broken(null)
	assert_eq(controller.get_charge(), 33, "破煞應再累積 25 → 33")

	# 充到滿（再 3 次破煞：33 + 75 = 108 → 夾在 100）
	controller._on_enemy_broken(null)
	controller._on_enemy_broken(null)
	controller._on_enemy_broken(null)
	assert_true(controller.is_ready(), "請神值應已滿、可降乩")
	assert_false(combat._invoke_button.disabled, "滿槽時降乩按鈕應可點")
	assert_true(combat._invoke_button.text.contains("降乩"), "滿槽按鈕應顯示「降乩」")

	# 降乩：對全體敵人造成傷害 + 重置請神值
	var before: int = _sum_enemy_health()
	combat._on_invoke_button_pressed()
	assert_eq(controller.get_charge(), 0, "降乩後請神值應重置為 0")
	assert_true(combat._invoke_button.disabled, "降乩後按鈕應回到 disabled")
	var after: int = _sum_enemy_health()
	assert_true(after < before, "虎爺降乩應對敵人造成傷害（敵方總血量下降）")

	_teardown_env(env)

func _sum_enemy_health() -> int:
	var tree := Engine.get_main_loop() as SceneTree
	var total: int = 0
	for e: Node in tree.get_nodes_in_group("enemies"):
		if e is Enemy and (e as Enemy).enemy_data != null:
			total += (e as Enemy).enemy_data.enemy_health
	return total


# ──────────── 測試 6：多神請神（Phase 2A）— 觸發路由 + 三神降乩效果 ────────────

func test_deity_trigger_routing_per_deity() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "需要 Combat")
	if combat == null:
		_teardown_env(env)
		return
	Signals.combat_started.emit(SMOKE_EVENT_ID)
	var controller: Variant = combat._deity_controller
	assert_not_null(controller, "需要請神控制器")
	if controller == null:
		_teardown_env(env)
		return

	# 媽祖（on_block_gained）：玩家獲護身符 → 累積；debuff → 不累積
	controller.setup(DeityInvocationSystem.load_deity("deity_mazu"))
	assert_eq(controller.get_charge(), 0, "媽祖開局請神值 0")
	controller._on_combatant_block_added(combat.player)
	assert_eq(controller.get_charge(), DeityChargeController.BLOCK_CHARGE, "媽祖：玩家獲護身符應累積")
	controller._on_debuff_applied(null)
	assert_eq(controller.get_charge(), DeityChargeController.BLOCK_CHARGE, "媽祖：debuff 非其觸發、不累積")

	# 城隍（on_debuff_applied）：施 debuff → 累積；block → 不累積
	controller.setup(DeityInvocationSystem.load_deity("deity_chenghuang"))
	assert_eq(controller.get_charge(), 0, "城隍 setup 重置為 0")
	controller._on_debuff_applied(null)
	assert_eq(controller.get_charge(), DeityChargeController.DEBUFF_CHARGE, "城隍：施 debuff 應累積")
	controller._on_combatant_block_added(combat.player)
	assert_eq(controller.get_charge(), DeityChargeController.DEBUFF_CHARGE, "城隍：block 非其觸發、不累積")

	_teardown_env(env)

func test_multi_deity_invocation_effects() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "需要 Combat")
	if combat == null:
		_teardown_env(env)
		return
	Signals.combat_started.emit(SMOKE_EVENT_ID)
	var tree := Engine.get_main_loop() as SceneTree

	# 城隍 judgment：全體敵人獲驚嚇
	var enemy: Enemy = null
	for e: Node in tree.get_nodes_in_group("enemies"):
		if e is Enemy:
			enemy = e as Enemy
			break
	assert_not_null(enemy, "需要敵人")
	if enemy == null:
		_teardown_env(env)
		return
	combat._execute_deity_invocation(DeityInvocationSystem.load_deity("deity_chenghuang"))
	assert_true(enemy.get_status_charges("status_effect_vulnerable") > 0, "城隍夜審應給敵人驚嚇")

	# 媽祖 merciful_tide：玩家獲護身符
	var block_before: int = Global.player_data.player_block
	combat._execute_deity_invocation(DeityInvocationSystem.load_deity("deity_mazu"))
	assert_true(Global.player_data.player_block > block_before, "媽祖慈航應給玩家護身符")

	# 土地公 land_blessing：玩家獲護身符（抽牌異步，驗 block）
	var block_before2: int = Global.player_data.player_block
	combat._execute_deity_invocation(DeityInvocationSystem.load_deity("deity_tudigong"))
	assert_true(Global.player_data.player_block > block_before2, "土地公福德應給玩家護身符")

	_teardown_env(env)


# ──────────── 測試 7：主祭/護壇/法器 loadout（Phase 2B）— start_run 套用 ────────────
# _build_combat_env 內部 start_run("character_tongji") → 驗證本局班底已套用：
#   出戰神明由 loadout 解析（非固定虎爺）、法器破煞加成、護壇支援卡入起始牌庫。

func test_run_loadout_applied_on_start() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "需要 Combat")
	if combat == null:
		_teardown_env(env)
		return
	# 乩童預設班底 → 出戰虎爺（法器虎牌 affinity）、破煞 +1
	assert_eq(Global.get_run_active_deity_id(), "deity_tiger_god", "乩童預設班底出戰虎爺（由 loadout 解析）")
	assert_eq(Global.run_tool_break_bonus, 1, "乩童法器虎牌 → 破煞 +1")
	# 鸞女護壇支援卡入起始牌庫
	var has_support: bool = false
	for c: CardData in Global.player_data.player_deck:
		if c.object_id == "card_luannu_protection":
			has_support = true
			break
	assert_true(has_support, "鸞女護壇支援卡（card_luannu_protection）應入起始牌庫")
	_teardown_env(env)


# ──────────── 測試 9：遶境地圖生成器（Phase 2E）— 有效圖 + 路線標記 ────────────
# act_1 已切到 ActionGeneratePilgrimage。明確觸發生成後檢查：節點數、起點/大醮存在、
# 大醮可達（有節點連向它）、節點帶遶境 route_flavor。

func test_pilgrimage_map_generates_valid_graph() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "需要 Combat 節點")
	if combat == null:
		_teardown_env(env)
		return
	# 明確觸發第一章遶境地圖生成
	ActionGenerator.generate_act("act_1", 1)
	var locations: Array = Global.get_all_act_locations()
	assert_true(locations.size() >= 10, "遶境地圖應生成多個節點（得 %d）" % locations.size())

	var has_start: bool = false
	var has_boss: bool = false
	var boss_loc: LocationData = null
	var route_flavor_seen: bool = false
	for loc: Variant in locations:
		var l: LocationData = loc as LocationData
		if l.location_type == LocationData.LOCATION_TYPES.STARTING:
			has_start = true
		if l.location_type == LocationData.LOCATION_TYPES.BOSS:
			has_boss = true
			boss_loc = l
		if l.location_route_flavor != "":
			route_flavor_seen = true
	assert_true(has_start, "應有出巡起點（STARTING）")
	assert_true(has_boss, "應有鎮煞大醮（BOSS）")
	assert_true(route_flavor_seen, "節點應標記遶境路線 flavor（route_flavor）")

	# 鎮煞大醮可達：至少一個節點的 next 連向它
	var boss_reachable: bool = false
	if boss_loc != null:
		for loc2: Variant in locations:
			if (loc2 as LocationData).location_next_location_ids.has(boss_loc.location_id):
				boss_reachable = true
				break
	assert_true(boss_reachable, "鎮煞大醮應可達（有節點連向它）")

	_teardown_env(env)


# ──────────── 測試 10：UIQA — toast lane / cancel 鈕 / 合符提示 safe-area 行為 ────────────

func _rect_in_safe(inner: Rect2, outer: Rect2) -> bool:
	return inner.position.x >= outer.position.x - 1.0 \
		and inner.position.y >= outer.position.y - 1.0 \
		and inner.position.x + inner.size.x <= outer.position.x + outer.size.x + 1.0 \
		and inner.position.y + inner.size.y <= outer.position.y + outer.size.y + 1.0

func test_uiqa_toast_cancel_merge_affordance() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "需要 Combat")
	if combat == null:
		_teardown_env(env)
		return
	Signals.combat_started.emit(SMOKE_EVENT_ID)
	var safe: Rect2 = CotiwUiTheme.get_safe_content_rect(combat.get_viewport())

	# toast：safe rect 內、非畫面中心固定值、連觸不堆疊
	combat.show_combat_toast("測試短訊")
	var toast: Variant = combat._combat_toast
	assert_not_null(toast, "toast 應建立")
	assert_true(_rect_in_safe(Rect2(toast.position, toast.size), safe), "toast 應在 safe rect 內")
	assert_true(toast.position != Vector2(400.0, 300.0), "toast 不再固定畫面中心 (400,300)")
	combat.show_combat_toast("第二則")
	combat.show_combat_toast("第三則")
	var toast_count: int = 0
	for c: Node in combat.get_children():
		if c.name == "CombatToast":
			toast_count += 1
	assert_eq(toast_count, 1, "多 toast 連觸不應堆疊出多個節點")

	# cancel target 鈕：safe rect 內、非 (520,250)
	var hand: Node = combat.get_node_or_null("Hand")
	assert_not_null(hand, "需要 Hand")
	if hand == null:
		_teardown_env(env)
		return
	hand._ensure_cancel_target_button()
	hand._position_cancel_target_button()
	var btn: Variant = hand._cancel_target_button
	assert_not_null(btn, "cancel button 應建立")
	assert_true(btn.position != Vector2(520, 250), "cancel 不再固定 Vector2(520,250)")
	assert_true(_rect_in_safe(Rect2(btn.position, btn.size), safe), "cancel button 應在 safe rect 內")

	# 合符 affordance：兩張攻拳 → 暖金提示；移除夥伴 → 提示消失
	var a: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
	var b: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
	var pair: Array[CardData] = [a, b]
	Global.player_data.player_hand = pair
	var created: Array = hand.create_cards(pair)
	hand.card_data_to_hand_card[a] = created[0]	# create_cards 為輕量 helper，手動補映射（真機 draw 會自動建）
	hand.card_data_to_hand_card[b] = created[1]
	hand._refresh_merge_affordance()
	assert_eq(created[0].modulate, Color(1.18, 1.06, 0.72), "可合符卡應有暖金提示（MERGE_HINT_TINT）")
	hand.card_data_to_hand_card.erase(b)
	Global.player_data.player_hand = [a] as Array[CardData]
	hand._refresh_merge_affordance()
	assert_eq(created[0].modulate, Color(1, 1, 1), "無夥伴時不顯示合符提示")

	_teardown_env(env)


# ──────────── 測試 8：手機長按合符入口（P0-1）— Card._on_long_press_attempt ────────────
# 經由「卡牌長按入口」（真機路徑：TouchFeedback timer → Card._on_long_press_attempt
# → long_press_handler → Hand.try_mobile_merge）驗證手機可達合符，不只直接呼叫 _try_merge_card。

func test_mobile_long_press_merge_entry() -> void:
	var env: Dictionary = _build_combat_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "需要 Combat")
	if combat == null:
		_teardown_env(env)
		return
	Signals.combat_started.emit(SMOKE_EVENT_ID)
	var hand: Node = combat.get_node_or_null("Hand")
	assert_not_null(hand, "需要 Hand")
	if hand == null:
		_teardown_env(env)
		return
	hand.hand_disabled = false

	# 兩張攻拳 + 模擬 draw_cards 對手牌卡掛上的長按 handler（create_cards 為輕量 helper，不自動掛）
	var a: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
	var b: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
	var hand_ab: Array[CardData] = [a, b]
	Global.player_data.player_hand = hand_ab
	var created: Array = hand.create_cards(hand_ab)
	for card: Variant in created:
		card.long_press_handler = hand.try_mobile_merge

	# 經由 Card 長按入口合符（= 真機長按路徑）
	assert_true(created[0]._on_long_press_attempt(), "手機長按入口應合符成功")
	assert_eq(a.card_name, "重擊", "a 應升階為重擊")
	assert_false(Global.player_data.player_hand.has(b), "夥伴卡應從手牌移除")

	# 第二對護身符
	var c: CardData = Global.get_card_data_from_prototype("card_tongji_talisman")
	var d: CardData = Global.get_card_data_from_prototype("card_tongji_talisman")
	var hand_cd: Array[CardData] = [c, d]
	Global.player_data.player_hand = hand_cd
	var created2: Array = hand.create_cards(hand_cd)
	for card2: Variant in created2:
		card2.long_press_handler = hand.try_mobile_merge

	# guard：手牌禁用時長按不合符（落回詳情）
	hand.hand_disabled = true
	assert_false(created2[0]._on_long_press_attempt(), "手牌禁用時長按不合符（落回詳情）")
	hand.hand_disabled = false
	# P1-2：限額用完 → 攔截但不實際合符
	assert_true(created2[0]._on_long_press_attempt(), "限額用完長按應攔截（toast、不落回詳情）")
	assert_eq(c.card_name, "護身符", "限額用完不應實際合符")

	_teardown_env(env)
