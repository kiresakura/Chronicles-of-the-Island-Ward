# 鎮島錄 v0.3 — 符令 draft 獎勵覆層（FC-2b.3b-2）測試。
extends "res://tests/test_case.gd"

const FU_DRAFT_SCENE: String = "res://scenes/ui/FuDraftView.tscn"
const FormationCombatCls := preload("res://scripts/systems/ritual/FormationCombat.gd")

var _picked: String = ""

func _on_picked(fu_id: String) -> void:
	_picked = fu_id

func _add() -> Control:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var s: PackedScene = load(FU_DRAFT_SCENE)
	if s == null:
		return null
	var v: Control = s.instantiate()
	tree.root.add_child(v)
	return v

func test_offer_shows_three_and_pick_emits() -> void:
	var v: Control = _add()
	assert_not_null(v, "FuDraftView 應可實例")
	if v == null:
		return
	_picked = ""
	v.fu_picked.connect(_on_picked)
	var defs: Dictionary = {
		"fu_chi": {"name": "敕符", "desc": "+1動作"},
		"fu_po_sha": {"name": "破煞符", "desc": "削煞6"},
		"fu_zhen": {"name": "鎮符", "desc": "延緩"},
	}
	v.offer(["fu_chi", "fu_po_sha", "fu_zhen"], defs)
	assert_true(v.visible, "offer 後顯示")
	assert_eq(v._buttons.size(), 3, "三選一：3 候選按鈕")
	v._on_pick("fu_po_sha")
	assert_eq(_picked, "fu_po_sha", "點選發 fu_picked(id)")
	assert_false(v.visible, "選後覆層收起")
	v.queue_free()

func test_draft_choices_distinct() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var c: Array = FormationCombatCls.draft_fu_choices(3, rng)
	assert_eq(c.size(), 3, "抽 3 個候選")
	var seen: Dictionary = {}
	for fid: Variant in c:
		assert_false(seen.has(fid), "候選相異：%s" % str(fid))
		seen[fid] = true
