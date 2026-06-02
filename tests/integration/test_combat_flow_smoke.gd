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
