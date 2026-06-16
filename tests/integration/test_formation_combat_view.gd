# 鎮島錄 v0.3 — 五營戰鬥畫面（FC-2b.1a）headless 煙霧測試。
# 驗 View 與 FC-2a 核心的接線：UI 建構完整、勝/敗發訊號（接縫用）、戰況結構化事件有渲染。
# 同步斷言（run_all 不 await）：add_child 同步觸發 _ready → 建 UI + 起場；訊號同步發。
extends "res://tests/test_case.gd"

const VIEW_SCENE: String = "res://scenes/ui/FormationCombatView.tscn"
const FormationCombatCls := preload("res://scripts/systems/ritual/FormationCombat.gd")

var _won: bool = false
var _lost: bool = false

func _mark_won() -> void:
	_won = true

func _mark_lost() -> void:
	_lost = true

func _add_view() -> Control:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var scene: PackedScene = load(VIEW_SCENE)
	if scene == null:
		return null
	var view: Control = scene.instantiate()
	tree.root.add_child(view)	# 同步觸發 _ready：建 UI + 起示範場
	return view

func test_view_builds_all_camps_lanes_and_controls() -> void:
	var view: Control = _add_view()
	assert_not_null(view, "View 應可實例化")
	if view == null:
		return
	# 重啟一場確定性戰（弱敵、自動佈陣）以穩定斷言
	view.start([], {}, [{"id": "e", "hp": 24}], 7)
	assert_eq(view._camp_tiles.size(), 5, "五營 tile 全部建立")
	assert_eq(view._lane_markers.size(), 4, "四方位 lane 標記")
	assert_not_null(view._altar_bar, "母壇條存在")
	assert_eq(int(view._altar_bar.max_value), int(view._core.altar_max), "母壇條上限同步核心")
	assert_not_null(view._jiao_button, "擲筊鈕存在")
	assert_not_null(view._deity_button, "降乩鈕存在")
	assert_not_null(view._end_turn_button, "結束回合鈕存在")
	view.queue_free()

func test_view_emits_won_and_renders_log() -> void:
	var view: Control = _add_view()
	if view == null:
		return
	_won = false
	view.formation_won.connect(_mark_won)
	# 單一弱敵：自動佈陣讓得位主將鎮守 → 一攔即破 → 殲敵勝
	view.start([], {}, [{"id": "e", "hp": 24}], 7)
	var safety: int = 0
	while view._core.state == FormationCombatCls.STATE_PLAYING and safety < 15:
		view._on_end_turn()
		safety += 1
	assert_eq(view._core.state, FormationCombatCls.STATE_WON, "守住單一弱煞 → 勝")
	assert_true(_won, "勝利時發 formation_won 訊號（接縫用）")
	assert_true(view._banner.visible, "勝利橫幅顯示")
	assert_ne(view._log_label.text, "", "戰況 log 有渲染（結構化事件 → 文字）")
	view.queue_free()

func test_view_emits_lost_on_altar_collapse() -> void:
	var view: Control = _add_view()
	if view == null:
		return
	_lost = false
	view.formation_lost.connect(_mark_lost)
	# 只佈一個單位進中營，其餘單位不佈陣 → 四方位 lane 全空營；多敵直擊 → 母壇崩
	var deploy: Dictionary = {"unit_qinglong": "camp_center"}
	var enemies: Array = [{"id": "a", "hp": 80}, {"id": "b", "hp": 80}, {"id": "c", "hp": 80}, {"id": "d", "hp": 80}]
	view.start([], deploy, enemies, 7)
	var safety: int = 0
	while view._core.state == FormationCombatCls.STATE_PLAYING and safety < 25:
		view._on_end_turn()
		safety += 1
	assert_eq(view._core.state, FormationCombatCls.STATE_LOST, "空營任煞長驅 → 母壇崩敗")
	assert_true(_lost, "敗北時發 formation_lost 訊號（接縫用）")
	assert_true(view._banner.visible, "敗北橫幅顯示")
	view.queue_free()
