# 鎮島錄 — 破煞戰鬥整合測試（Phase 1B）
#
# 用「真實載入的」乩童/鸞女卡 + act1 敵人（Global 原型）跑 WardBreakSystem，
# 證明資料 + 運算層端到端串得起來；並驗證 Enemy.gd 的破煞效果 → status 對應表合法。
# 全程同步、無場景（敵人原型 .duplicate(true) 取獨立副本，避免污染其他測試）。
extends "res://tests/test_case.gd"

func _enemy_copy(enemy_id: String) -> EnemyData:
	var proto: EnemyData = Global._id_to_enemy_data.get(enemy_id)
	if proto == null:
		return null
	var ed: EnemyData = proto.duplicate(true)
	WardBreakSystem.init_ward(ed)
	return ed

func _card(card_id: String) -> CardData:
	return Global._id_to_card_data.get(card_id)

# ---------- 真實資料：命中弱點破煞 ----------

func test_real_fist_card_breaks_fist_weak_boar() -> void:
	# 山豬精：煞盾 8、弱拳；攻拳：fist、break2/+3 → 命中 5/次 → 2 下破煞
	var boar: EnemyData = _enemy_copy("enemy_mountain_boar")
	var punch: CardData = _card("card_tongji_punch")
	assert_not_null(boar, "enemy_mountain_boar 未載入")
	assert_not_null(punch, "card_tongji_punch 未載入")
	if boar == null or punch == null:
		return
	assert_eq(WardBreakSystem.compute_ward_damage(punch, boar), 5, "攻拳命中拳弱點應削 5 煞盾")
	var broke1: bool = WardBreakSystem.apply_ward_damage(boar, WardBreakSystem.compute_ward_damage(punch, boar))
	assert_false(broke1, "第一下（8→3）不應破煞")
	var broke2: bool = WardBreakSystem.apply_ward_damage(boar, WardBreakSystem.compute_ward_damage(punch, boar))
	assert_true(broke2, "第二下（3→0）應破煞")
	assert_true(boar.enemy_is_broken, "破煞後 is_broken 應為 true")
	assert_eq(WardBreakSystem.damage_multiplier_for(boar), 1.5, "破煞窗口傷害倍率應為 1.5")

func test_real_fire_card_breaks_tree_spirit_in_one() -> void:
	# 樹靈：煞盾 6、弱火；聖火焚邪：fire、break3/+5 → 命中 8 ≥ 6 → 一下破煞
	var tree: EnemyData = _enemy_copy("enemy_tree_spirit")
	var holy_fire: CardData = _card("card_luannu_holy_fire")
	assert_not_null(tree, "enemy_tree_spirit 未載入")
	assert_not_null(holy_fire, "card_luannu_holy_fire 未載入")
	if tree == null or holy_fire == null:
		return
	assert_eq(WardBreakSystem.compute_ward_damage(holy_fire, tree), 8, "聖火命中火弱點應削 8")
	assert_true(WardBreakSystem.apply_ward_damage(tree, 8), "8 ≥ 煞盾 6 → 一下破煞")
	assert_true(tree.enemy_is_broken, "樹靈應已破煞")

# ---------- 真實資料：未命中弱點 → 鈍擊 ----------

func test_real_non_weakness_is_blunted() -> void:
	# 聖火（fire）打山豬精（弱拳，不含火）→ 鈍擊 floor(3/2)=1
	var boar: EnemyData = _enemy_copy("enemy_mountain_boar")
	var holy_fire: CardData = _card("card_luannu_holy_fire")
	if boar == null or holy_fire == null:
		return
	assert_eq(WardBreakSystem.compute_ward_damage(holy_fire, boar), 1,
		"未命中弱點應鈍擊 floor(break_damage/2)=1")

# ---------- 跨角色協同：乩童破不了純火弱點，需鸞女 ----------

func test_cross_character_synergy_fire_only_enemy() -> void:
	# 紙紮兵：弱火。乩童無 fire 卡 → 只能鈍擊；鸞女聖火 → 命中。體現主祭/護壇互補。
	var paper: EnemyData = _enemy_copy("enemy_paper_soldier")
	var punch: CardData = _card("card_tongji_punch")          # fist
	var holy_fire: CardData = _card("card_luannu_holy_fire")  # fire
	if paper == null or punch == null or holy_fire == null:
		return
	var by_tongji: int = WardBreakSystem.compute_ward_damage(punch, paper)
	var by_luannu: int = WardBreakSystem.compute_ward_damage(holy_fire, paper)
	assert_true(by_luannu > by_tongji,
		"鸞女聖火（命中火弱點 %d）應遠勝乩童拳擊（鈍擊 %d）" % [by_luannu, by_tongji])

# ---------- Enemy.gd 破煞效果 → status 對應合法性 ----------

func test_break_effect_status_mapping_valid() -> void:
	# Enemy.BREAK_EFFECT_STATUSES 引用的每個 status 必須真實存在
	for be: String in Enemy.BREAK_EFFECT_STATUSES:
		for pair: Array in Enemy.BREAK_EFFECT_STATUSES[be]:
			var sid: String = str(pair[0])
			assert_has(Global._id_to_status_data, sid,
				"破煞效果 %s 對應的 status %s 不存在" % [be, sid])
	# 每個有煞盾的 act1 敵人，其 break_effect 必須在對應表內（否則破煞無回饋）
	for enemy_id: String in Global._id_to_enemy_data:
		var ed: EnemyData = Global._id_to_enemy_data[enemy_id]
		if ed.enemy_max_ward_shield > 0:
			assert_true(Enemy.BREAK_EFFECT_STATUSES.has(ed.enemy_break_effect),
				"敵人 %s 的 break_effect「%s」未在 Enemy.BREAK_EFFECT_STATUSES 對應" % [enemy_id, ed.enemy_break_effect])
