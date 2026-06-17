# 鎮島錄 v0.3 — FP-3 符令經濟基盤守門測試（稀有度/定價/商店池/合符）。
# 對應 plan-A：商店/圖鑑/合符全建於此基盤之上。tests/ 目錄 i18n 豁免。
extends "res://tests/test_case.gd"

const FC := preload("res://scripts/systems/ritual/FormationCombat.gd")
const FuMerge := preload("res://scripts/systems/ritual/FuMergeSystem.gd")

func test_fu_library_loads_all_eight() -> void:
	var lib: Dictionary = FC.fu_library()
	assert_true(lib.size() >= 8, "符令庫至少 8 種（4 base + 4 合符成品），實得 %d" % lib.size())
	assert_true(lib.has("fu_po_sha"), "含基礎 fu_po_sha")
	assert_true(lib.has("fu_po_sha_2"), "含合符成品 fu_po_sha_2")

func test_every_fu_has_rarity_and_valid_price() -> void:
	for fu_id: String in FC.fu_library():
		var r: String = FC.fu_rarity(fu_id)
		assert_true(r in ["common", "uncommon", "rare"], "%s 稀有度非法：%s" % [fu_id, r])
		assert_true(FC.fu_price(fu_id) > 0, "%s 定價須為正" % fu_id)

func test_rare_costs_more_than_common() -> void:
	assert_true(FC.fu_price("fu_po_sha_2") > FC.fu_price("fu_po_sha"), "稀有符應比普通符貴")

func test_shop_pool_ids_all_valid() -> void:
	var lib: Dictionary = FC.fu_library()
	for fu_id: Variant in FC.fu_shop_pool():
		assert_true(lib.has(str(fu_id)), "商店池 %s 不在符令庫" % str(fu_id))

func test_tier1_merges_to_tier2_and_tier2_is_max() -> void:
	assert_true(FC.fu_can_merge("fu_po_sha"), "tier1 破煞符可合")
	assert_eq(FC.fu_merge_result("fu_po_sha"), "fu_po_sha_2", "破煞符合符成品")
	assert_false(FC.fu_can_merge("fu_po_sha_2"), "tier2 不可再合（頂級）")

func test_merge_consumes_two_and_yields_result() -> void:
	var deck: Array = ["fu_po_sha", "fu_po_sha", "fu_chi"]
	assert_true(FuMerge.has_any_merge(deck), "有可合對")
	assert_eq(FuMerge.first_mergeable(deck), "fu_po_sha", "可合者為破煞符")
	var r: Dictionary = FuMerge.merge(deck, "fu_po_sha")
	assert_true(bool(r.get("ok")), "合符成功")
	assert_eq(str(r.get("to")), "fu_po_sha_2", "成品為大破煞符")
	assert_eq(deck.size(), 2, "牌庫 3→2（吃 2 出 1）")
	assert_true(deck.has("fu_po_sha_2"), "牌庫含成品")
	assert_false(deck.has("fu_po_sha"), "原破煞符已被吃光")

func test_merge_rejects_single_or_max_tier() -> void:
	assert_false(bool(FuMerge.merge(["fu_po_sha"], "fu_po_sha").get("ok")), "只有 1 張不可合")
	assert_false(bool(FuMerge.merge(["fu_po_sha_2", "fu_po_sha_2"], "fu_po_sha_2").get("ok")), "頂級符不可合")

func test_no_forbidden_nouns_in_fu_copy() -> void:
	var bad: Array = ["韌性", "弱點擊破", "升階", "終結"]
	for fu_id: String in FC.fu_library():
		var blob: String = str(FC.fu_def(fu_id).get("name", "")) + " " + str(FC.fu_def(fu_id).get("desc", ""))
		for b: String in bad:
			assert_false(blob.contains(b), "%s 含名詞紅線「%s」" % [fu_id, b])
