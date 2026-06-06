# 鎮島錄 — 破煞系統純函式單元測試（WardBreakSystem）。
#
# 全程以 CardData.new() / EnemyData.new() 建立 Resource（無場景、無 await），
# 符合 run_all.gd 的同步呼叫約束。對應 docs/design/ward_break_system.md。
extends "res://tests/test_case.gd"

func _make_card(tags: Array[String], break_damage: int, weakness_bonus: int) -> CardData:
	var c: CardData = CardData.new()
	c.card_ritual_tags = tags
	c.card_break_damage = break_damage
	c.card_weakness_break_bonus = weakness_bonus
	return c

func _make_enemy(max_ward: int, weaknesses: Array[String], broken_turns: int = 1) -> EnemyData:
	var e: EnemyData = EnemyData.new()
	e.enemy_max_ward_shield = max_ward
	e.enemy_ward_shield = max_ward
	e.enemy_weaknesses = weaknesses
	e.enemy_broken_turns = broken_turns
	return e

# ---------- compute_ward_damage ----------

func test_weakness_hit_uses_bonus() -> void:
	var card: CardData = _make_card(["fist"], 3, 4)
	var enemy: EnemyData = _make_enemy(8, ["fist"])
	assert_eq(WardBreakSystem.compute_ward_damage(card, enemy), 7,
		"命中弱點應為 break_damage + weakness_break_bonus = 7")

func test_non_weakness_is_blunted() -> void:
	var card: CardData = _make_card(["fire"], 4, 5)
	var enemy: EnemyData = _make_enemy(8, ["fist"])
	assert_eq(WardBreakSystem.compute_ward_damage(card, enemy), 2,
		"未命中弱點應為 floor(break_damage/2) = 2")

func test_no_ward_enemy_returns_zero() -> void:
	var card: CardData = _make_card(["fist"], 5, 5)
	var enemy: EnemyData = _make_enemy(0, [])
	assert_eq(WardBreakSystem.compute_ward_damage(card, enemy), 0,
		"無煞盾機制的敵人破煞傷害為 0")

# ---------- apply_ward_damage + 破煞 ----------

func test_apply_breaks_on_zero() -> void:
	var enemy: EnemyData = _make_enemy(6, ["fire"], 2)
	var broke_first: bool = WardBreakSystem.apply_ward_damage(enemy, 4)
	assert_false(broke_first, "削到剩 2 不應破煞")
	assert_eq(enemy.enemy_ward_shield, 2, "煞盾應剩 2")
	var broke_second: bool = WardBreakSystem.apply_ward_damage(enemy, 5)
	assert_true(broke_second, "歸零應觸發破煞")
	assert_true(enemy.enemy_is_broken, "is_broken 應為 true")
	assert_eq(enemy.enemy_broken_turns_remaining, 2, "爆發窗口應等於 broken_turns")

func test_broken_enemy_not_rebroken() -> void:
	var enemy: EnemyData = _make_enemy(4, ["fist"])
	WardBreakSystem.apply_ward_damage(enemy, 4)
	var again: bool = WardBreakSystem.apply_ward_damage(enemy, 4)
	assert_false(again, "已破煞狀態不應重複觸發破煞")

# ---------- 破煞窗口傷害加成 ----------

func test_damage_multiplier_when_broken() -> void:
	var enemy: EnemyData = _make_enemy(4, ["fist"])
	assert_eq(WardBreakSystem.damage_multiplier_for(enemy), 1.0, "未破煞倍率 1.0")
	WardBreakSystem.apply_ward_damage(enemy, 4)
	assert_eq(WardBreakSystem.damage_multiplier_for(enemy), 1.5, "破煞窗口倍率 1.5")

# ---------- tick + 回盾 ----------

func test_tick_restores_ward_when_window_ends() -> void:
	var enemy: EnemyData = _make_enemy(6, ["fire"], 1)
	WardBreakSystem.apply_ward_damage(enemy, 6)
	assert_true(enemy.enemy_is_broken, "應已破煞")
	WardBreakSystem.tick_broken_state(enemy)
	assert_false(enemy.enemy_is_broken, "窗口結束應解除破煞")
	assert_eq(enemy.enemy_ward_shield, 6, "解除破煞後煞盾回滿")

func test_init_ward_sets_full() -> void:
	var enemy: EnemyData = _make_enemy(10, ["array"])
	enemy.enemy_ward_shield = 0
	enemy.enemy_is_broken = true
	WardBreakSystem.init_ward(enemy)
	assert_eq(enemy.enemy_ward_shield, 10, "init 後煞盾 = max")
	assert_false(enemy.enemy_is_broken, "init 後非破煞")
