# 鎮島錄 v0.3 — 封神榜畫面（FC-5c）headless 煙霧測試。
# 驗畫面建構（每單位一卡）、敕封按鈕扣香火升位階、元寶紅線。
extends "res://tests/test_case.gd"

const ScreenCls := preload("res://scripts/ui/menus/CanonizationScreen.gd")
const CanonCls := preload("res://scripts/systems/ritual/CanonizationSystem.gd")

func _add() -> Control:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	var s: Control = ScreenCls.new()
	tree.root.add_child(s)	# 同步 _ready 建卡
	return s

func test_screen_builds_card_per_unit() -> void:
	var screen: Control = _add()
	assert_not_null(screen, "封神榜可實例")
	if screen == null:
		return
	var unit_count: int = Global._id_to_formation_unit_data.size()
	assert_true(unit_count > 0, "有可佈陣單位")
	assert_eq(screen._cards.size(), unit_count, "每個可佈陣單位一張敕封卡")
	screen.queue_free()

func test_screen_canonize_spends_incense_raises_rank() -> void:
	var screen: Control = _add()
	if screen == null:
		return
	var prof: ProfileData = Global.profile_data
	var inc_before: int = prof.profile_incense_balance
	var yuanbao_before: int = prof.profile_yuanbao
	var uid: String = str(screen._cards.keys()[0])
	var rank_before: int = CanonCls.rank_of(prof, uid)
	prof.profile_incense_balance = 1000	# 確保負擔得起
	screen.open()
	screen._on_canonize_pressed(uid)
	assert_eq(CanonCls.rank_of(prof, uid), rank_before + 1, "敕封鈕 → 位階 +1")
	assert_true(prof.profile_incense_balance < 1000, "敕封扣香火")
	assert_eq(prof.profile_yuanbao, yuanbao_before, "🔴 敕封不動元寶（紅線）")
	# 還原全域 profile 狀態（避免污染其他測試）
	prof.profile_deity_rank.erase(uid)
	prof.profile_incense_balance = inc_before
	screen.queue_free()
