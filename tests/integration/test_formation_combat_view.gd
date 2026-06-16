# 鎮島錄 v0.3 — 五營戰鬥畫面（FC-2b.1a）headless 煙霧測試。
# 驗 View 與 FC-2a 核心的接線：UI 建構完整、勝/敗發訊號（接縫用）、戰況結構化事件有渲染。
# 同步斷言（run_all 不 await）：add_child 同步觸發 _ready → 建 UI + 起場；訊號同步發。
extends "res://tests/test_case.gd"

const VIEW_SCENE: String = "res://scenes/ui/FormationCombatView.tscn"
const FormationCombatCls := preload("res://scripts/systems/ritual/FormationCombat.gd")
const ViewCls := preload("res://scripts/ui/FormationCombatView.gd")
const DESIGN := Vector2(1200, 700)

# 確定性符令 config（牌庫 2 張、起手 2 → 不依賴洗牌）：一張無目標(敕符)、一張需目標(破煞符)。
func _fu_cfg() -> Dictionary:
	return {"fu_config": {
		"hand_max": 5, "initial_hand": 2, "draw_per_turn": 1, "plays_per_turn": 1,
		"starter_deck": ["fu_chi", "fu_po_sha"],
		"fu": {
			"fu_chi": {"name": "敕符", "effect": "action", "magnitude": 1, "needs_target": false, "desc": "+1動作"},
			"fu_po_sha": {"name": "破煞符", "effect": "po_sha", "magnitude": 6, "needs_target": true, "desc": "削煞6"},
		},
	}}

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

# 響應式：設計畫布依安全區置中+fit縮放，保證內容不溢出（不截斷）、不放大（保像素清晰）。
func test_stage_transform_fits_without_truncation() -> void:
	var cases: Array = [
		Rect2(0, 0, 1522, 700),		# 寬手機（iPhone landscape ~2.17:1）
		Rect2(0, 0, 1200, 900),		# 高平板（4:3）
		Rect2(44, 8, 1478, 684),	# 瀏海/安全區內縮
		Rect2(0, 0, 1100, 640),		# 安全區小於設計 → 須縮以塞入
		Rect2(0, 0, 1200, 700),		# 剛好等於設計
	]
	var eps: float = 0.5
	for safe: Rect2 in cases:
		var t: Dictionary = ViewCls.compute_stage_transform(safe, DESIGN)
		var s: float = float(t["scale"])
		var pos: Vector2 = t["position"]
		assert_true(s > 0.0 and s <= 1.0, "縮放須落在 (0,1]（不放大）：%s → %f" % [str(safe), s])
		assert_true(pos.x >= safe.position.x - eps, "左不溢出：%s" % str(safe))
		assert_true(pos.y >= safe.position.y - eps, "上不溢出：%s" % str(safe))
		assert_true(pos.x + DESIGN.x * s <= safe.position.x + safe.size.x + eps, "右不溢出：%s" % str(safe))
		assert_true(pos.y + DESIGN.y * s <= safe.position.y + safe.size.y + eps, "下不溢出（橫幅不截斷）：%s" % str(safe))

# 符令手牌：槽位反映手牌、無目標符令即點即打、需目標符令點方位營後生效。
func test_fu_hand_renders_and_plays() -> void:
	var view: Control = _add_view()
	if view == null:
		return
	view.start([], {}, [{"id": "e_big", "hp": 80}], 1, _fu_cfg())
	# 槽位顯示數 == 手牌數（2）
	var visible_slots: int = 0
	for b: Button in view._fu_slots:
		if b.visible:
			visible_slots += 1
	assert_eq(visible_slots, 2, "底部符令槽顯示數 == 手牌數")
	# 無目標符令（敕符 idx 視手牌順序）：找其槽即點即打 → 動作 +1
	var chi_idx: int = view._core.fu_hand.find("fu_chi")
	assert_true(chi_idx >= 0, "手牌應含敕符")
	var actions_before: int = view._core.actions_remaining
	view._on_fu_slot_pressed(chi_idx)
	assert_eq(view._core.actions_remaining, actions_before + 1, "點敕符即打 → +1 動作")
	assert_eq(view._pending_fu, "", "無目標符令打完不進選方位")

func test_fu_target_play_via_lane_tap() -> void:
	var view: Control = _add_view()
	if view == null:
		return
	view.start([], {}, [{"id": "e_big", "hp": 80}], 1, _fu_cfg())
	var lane: String = str(view._core.waves[0]["lane"])	# 80HP→煞10
	var sha_camp: String = str(view._core.lanes[lane]["camp"])
	var po_idx: int = view._core.fu_hand.find("fu_po_sha")
	assert_true(po_idx >= 0, "手牌應含破煞符")
	# 點破煞符 → 進選方位
	view._on_fu_slot_pressed(po_idx)
	assert_eq(view._pending_fu, "fu_po_sha", "需目標符令進選方位狀態")
	# 點該 lane 的營 → 削煞 6（煞 10→4）
	view._on_camp_pressed(sha_camp)
	assert_eq(view._pending_fu, "", "放完清除選方位")
	assert_eq(int(view._core.lanes[lane]["sha"]["strength"]), 4, "破煞符經畫面削煞 6 → 餘 4")
	view.queue_free()
