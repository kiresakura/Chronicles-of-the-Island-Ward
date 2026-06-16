# 鎮島錄 v0.3 — 戰鬥接縫換骨（FC-2b.1b）headless 整合測試。
# 取代退役的 test_combat_flow_smoke（卡牌戰鬥）。驗：在真實 Root 樹中，戰鬥接縫
# （combat_started）開的是「五營戰鬥」而非卡牌；勝→combat_ended 轉接既有獎勵流程。
# 同步斷言（run_all 不 await）：add_child 同步觸發 Root 整棵 _ready；訊號同步發。
extends "res://tests/test_case.gd"

const ROOT_SCENE_PATH: String = "res://scenes/Root.tscn"
const SMOKE_CHARACTER_ID: String = "character_tongji"
const SMOKE_EVENT_ID: String = "event_act_1_easy_combat_1"
const SMOKE_RUN_SEED: int = 20260616
const FormationCombatCls := preload("res://scripts/systems/ritual/FormationCombat.gd")

var _combat_ended_fired: bool = false

func _on_combat_ended_flag() -> void:
	_combat_ended_fired = true

func _build_env() -> Dictionary:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return {}
	var root_scene: PackedScene = load(ROOT_SCENE_PATH)
	if root_scene == null:
		return {}
	var root: Node = root_scene.instantiate()
	tree.root.add_child(root)	# 同步觸發 Combat._ready → _build_formation_view
	Global.start_run(SMOKE_CHARACTER_ID, SMOKE_RUN_SEED)
	return {"root": root, "combat": root.get_node_or_null("RunScreen/Combat")}

func _teardown(env: Dictionary) -> void:
	if Global.is_run:
		Global.end_run(Global.RUN_ENDS.QUIT)
	var root: Node = env.get("root")
	if root != null and is_instance_valid(root):
		var tree := Engine.get_main_loop() as SceneTree
		tree.root.remove_child(root)
		root.free()

# 接縫：combat_started 開的是五營戰鬥（非卡牌），卡牌 HUD 收起。
func test_combat_started_launches_formation_not_cards() -> void:
	var env: Dictionary = _build_env()
	var combat: Node = env.get("combat")
	assert_not_null(combat, "Root.tscn 應含 RunScreen/Combat")
	if combat == null:
		_teardown(env)
		return
	Signals.combat_started.emit(SMOKE_EVENT_ID)
	var view: Control = combat._formation_view
	assert_not_null(view, "換骨後 Combat 應已建五營戰鬥畫面")
	if view == null:
		_teardown(env)
		return
	assert_true(view.visible, "combat_started 後五營畫面應顯示")
	assert_not_null(view._core, "五營核心應已 setup")
	assert_eq(view._core.state, FormationCombatCls.STATE_PLAYING, "開戰即進行中")
	# 真實事件敵人須解析成非空煞波（否則每場秒勝＝敵料解析壞）
	assert_true(view._core.waves.size() > 0, "真實 event 敵人應解析成 ≥1 道煞波（_resolve_enemy_specs 有效）")
	# 卡牌戰鬥節點應收起（汰換）
	var hand: Node = combat.get_node_or_null("Hand")
	if hand != null:
		assert_false((hand as CanvasItem).visible, "卡牌手牌應收起（換骨）")
	var end_turn_button: Node = combat.get_node_or_null("EndTurnButton")
	if end_turn_button != null:
		assert_false((end_turn_button as CanvasItem).visible, "卡牌結束回合鈕應收起")
	_teardown(env)

# 勝負轉接：五營戰勝（破盡諸煞）→ Combat._on_formation_won → 發 combat_ended（獎勵流程）。
func test_formation_win_emits_combat_ended() -> void:
	var env: Dictionary = _build_env()
	var combat: Node = env.get("combat")
	if combat == null:
		_teardown(env)
		return
	_combat_ended_fired = false
	Signals.combat_ended.connect(_on_combat_ended_flag)
	Signals.combat_started.emit(SMOKE_EVENT_ID)
	var view: Control = combat._formation_view
	if view == null:
		Signals.combat_ended.disconnect(_on_combat_ended_flag)
		_teardown(env)
		return
	# 覆寫成單一弱敵以確定性取勝（驗接縫轉接，不依賴事件敵料強弱）
	view.start([], {}, [{"id": "weak", "hp": 16}], 1)
	var safety: int = 0
	while view._core.state == FormationCombatCls.STATE_PLAYING and safety < 15:
		view._on_end_turn()
		safety += 1
	assert_eq(view._core.state, FormationCombatCls.STATE_WON, "守住單一弱煞 → 殲敵勝")
	assert_true(_combat_ended_fired, "五營戰勝 → 發 combat_ended（接通既有獎勵流程）")
	assert_false(view.visible, "勝後五營畫面收起")
	if Signals.combat_ended.is_connected(_on_combat_ended_flag):
		Signals.combat_ended.disconnect(_on_combat_ended_flag)
	_teardown(env)
