# 鎮島錄 v0.3 — 敕封封神榜（FC-5）回歸防線。
# 驗位階進程 將→帥→神→帝、香火扣款、封頂、grants 累計、讀檔；
# 🔴 變現紅線：敕封只扣香火，元寶永遠不動（can_canonize 也不看元寶）。
extends "res://tests/test_case.gd"

const CanonCls := preload("res://scripts/systems/ritual/CanonizationSystem.gd")

func _profile(incense: int = 0, yuanbao: int = 0) -> ProfileData:
	var p := ProfileData.new()
	p.profile_incense_balance = incense
	p.profile_yuanbao = yuanbao
	return p

func test_default_rank_and_names() -> void:
	var p := _profile()
	assert_eq(CanonCls.rank_of(p, "deity_mazu"), 0, "未敕封預設 0（將）")
	assert_eq(CanonCls.rank_name(0), "將", "rank 0＝將")
	assert_eq(CanonCls.rank_name(3), "帝", "rank 3＝帝")

func test_cost_progression() -> void:
	var p := _profile()
	assert_eq(CanonCls.cost_for_next(p, "d"), 50, "將→帥 = 50")
	p.profile_deity_rank["d"] = 1
	assert_eq(CanonCls.cost_for_next(p, "d"), 120, "帥→神 = 120")
	p.profile_deity_rank["d"] = 2
	assert_eq(CanonCls.cost_for_next(p, "d"), 250, "神→帝 = 250")
	p.profile_deity_rank["d"] = 3
	assert_eq(CanonCls.cost_for_next(p, "d"), -1, "帝＝封頂，無下一階")

func test_canonize_spends_incense_and_raises_rank() -> void:
	var p := _profile(100)
	assert_true(CanonCls.can_canonize(p, "d"), "香火 100 ≥ 50 可敕封")
	var r: Dictionary = CanonCls.canonize(p, "d")
	assert_true(r["success"], "敕封成功")
	assert_eq(int(r["new_rank"]), 1, "升到帥(1)")
	assert_eq(p.profile_incense_balance, 50, "扣 50 香火（餘 50）")
	assert_eq(CanonCls.rank_of(p, "d"), 1, "位階持久為帥")

func test_cannot_afford() -> void:
	var p := _profile(30)	# < 50
	assert_false(CanonCls.can_canonize(p, "d"), "香火不足不可敕封")
	var r: Dictionary = CanonCls.canonize(p, "d")
	assert_false(r["success"], "敕封失敗")
	assert_eq(p.profile_incense_balance, 30, "失敗不扣香火")

func test_full_progression_to_emperor_then_capped() -> void:
	var p := _profile(1000)
	assert_true(CanonCls.canonize(p, "d")["success"], "→帥")
	assert_true(CanonCls.canonize(p, "d")["success"], "→神")
	assert_true(CanonCls.canonize(p, "d")["success"], "→帝")
	assert_eq(CanonCls.rank_of(p, "d"), 3, "已達帝")
	assert_eq(p.profile_incense_balance, 1000 - 50 - 120 - 250, "累計扣 420 香火")
	assert_false(CanonCls.can_canonize(p, "d"), "帝後封頂不可再敕封")
	assert_false(CanonCls.canonize(p, "d")["success"], "封頂敕封失敗")

func test_grants_accumulate() -> void:
	var p := _profile(1000)
	CanonCls.canonize(p, "d")	# 帥
	CanonCls.canonize(p, "d")	# 神
	var grants: Array = CanonCls.grants_for(p, "d")
	assert_true(grants.has("camp_slot_eligibility"), "含帥階 grant")
	assert_true(grants.has("fu_draft_plus_one"), "含神階 grant")
	assert_false(grants.has("affinity_unlock"), "未到帝，不含帝階 grant")

# 🔴 變現紅線：敕封絕不碰元寶
func test_canonize_never_touches_yuanbao() -> void:
	var p := _profile(100, 9999)
	var yuanbao_before: int = p.profile_yuanbao
	CanonCls.canonize(p, "d")
	assert_eq(p.profile_yuanbao, yuanbao_before, "敕封後元寶不變（紅線）")

func test_yuanbao_cannot_substitute_incense() -> void:
	# 香火 0、元寶爆量 → 仍不可敕封（敕封只認香火）
	var p := _profile(0, 999999)
	assert_false(CanonCls.can_canonize(p, "d"), "元寶再多也不能拿來敕封（只認香火）")
	assert_false(CanonCls.canonize(p, "d")["success"], "元寶不可代香火")

func test_profile_has_grant() -> void:
	var p := _profile(1000)
	assert_false(CanonCls.profile_has_grant(p, "fu_draft_plus_one"), "未敕封無 grant")
	CanonCls.canonize(p, "deity_x")	# 帥（camp_slot_eligibility）
	CanonCls.canonize(p, "deity_x")	# 神（fu_draft_plus_one）
	assert_true(CanonCls.profile_has_grant(p, "fu_draft_plus_one"), "敕封到神 → 解鎖 +1符令draft")
	assert_true(CanonCls.profile_has_grant(p, "camp_slot_eligibility"), "亦累計帥階 grant")
	assert_false(CanonCls.profile_has_grant(p, "nonexistent"), "無此 grant")

func test_load_tiers_from_file() -> void:
	var t: Dictionary = CanonCls.load_tiers()
	assert_false(t.is_empty(), "rank_tiers 可載入")
	assert_eq((t.get("rank_names", []) as Array).size(), 4, "四位階 將帥神帝")
	assert_eq((t.get("tiers", []) as Array).size(), 3, "三段敕封階梯")
