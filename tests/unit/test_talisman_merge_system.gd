# 鎮島錄 — 符階合成判定單元測試（TalismanMergeSystem）。
# 純函式、同步、無場景。對應 docs/design/talisman_merge_system.md。
extends "res://tests/test_case.gd"

func _mk(group: String, tier: int, result: String) -> CardData:
	var c: CardData = CardData.new()
	c.card_merge_group = group
	c.card_merge_tier = tier
	c.card_merge_result_id = result
	return c

func _proto(id: String) -> CardData:
	# 取「獨立實例」（同 prototype 兩次呼叫得到不同物件，才可互相合符）
	return Global.get_card_data_from_prototype(id)

# ---------- can_merge ----------

func test_same_group_and_tier_can_merge() -> void:
	assert_true(TalismanMergeSystem.can_merge(_mk("g", 1, "x"), _mk("g", 1, "x")),
		"同組同階且有結果 → 可合符")

func test_different_group_cannot() -> void:
	assert_false(TalismanMergeSystem.can_merge(_mk("g", 1, "x"), _mk("h", 1, "x")),
		"不同 merge_group 不可合")

func test_different_tier_cannot() -> void:
	assert_false(TalismanMergeSystem.can_merge(_mk("g", 1, "x"), _mk("g", 2, "x")),
		"不同 merge_tier 不可合")

func test_no_group_or_tier_zero_cannot() -> void:
	assert_false(TalismanMergeSystem.can_merge(_mk("", 0, ""), _mk("", 0, "")),
		"無 merge_group / tier 0 不可合")

func test_top_tier_without_result_cannot() -> void:
	assert_false(TalismanMergeSystem.can_merge(_mk("g", 3, ""), _mk("g", 3, "")),
		"頂階敕符（無 merge_result_id）不可再合")

func test_same_object_cannot() -> void:
	var a: CardData = _mk("g", 1, "x")
	assert_false(TalismanMergeSystem.can_merge(a, a), "同一張卡不可與自己合")

# ---------- 真實卡 ----------

func test_real_two_punches_can_merge_to_heavy_strike() -> void:
	var a: CardData = _proto("card_tongji_punch")
	var b: CardData = _proto("card_tongji_punch")
	assert_true(TalismanMergeSystem.can_merge(a, b), "兩張攻拳應可合符")
	assert_eq(a.card_merge_result_id, "card_tongji_heavy_strike", "攻拳合符結果應為重擊")

func test_real_punch_and_talisman_cannot_merge() -> void:
	# 攻拳 merge_tongji_fist vs 護身符 merge_tongji_ward → 不同族群
	assert_false(TalismanMergeSystem.can_merge(_proto("card_tongji_punch"), _proto("card_tongji_talisman")),
		"攻拳與護身符不同族群，不可合")

# ---------- find_merge_partner / has_any_merge ----------

func test_find_partner_skips_self_and_nonmatching() -> void:
	var a: CardData = _proto("card_tongji_punch")
	var b: CardData = _proto("card_tongji_punch")
	var t: CardData = _proto("card_tongji_talisman")
	var hand: Array = [a, t, b]
	assert_eq(TalismanMergeSystem.find_merge_partner(a, hand), b, "應找到另一張攻拳為夥伴")
	assert_true(TalismanMergeSystem.find_merge_partner(t, hand) == null, "孤張護身符無夥伴")
	assert_true(TalismanMergeSystem.has_any_merge(hand), "手牌存在可合符組合")

func test_has_any_merge_false_when_all_unique() -> void:
	var hand: Array = [_proto("card_tongji_punch"), _proto("card_tongji_talisman"), _proto("card_tongji_draw_charm")]
	assert_false(TalismanMergeSystem.has_any_merge(hand), "無同組同階配對 → 無可合符")
