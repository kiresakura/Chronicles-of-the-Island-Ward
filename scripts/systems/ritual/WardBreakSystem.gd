# 鎮島錄 — 破煞（Ward Break）核心運算。
#
# 純函式、無場景耦合、決定性 → 可在 headless 下單元測試（見 tests/unit/test_ward_break_system.gd）。
# 戰鬥端整合（從 ActionAttack/Hand 呼叫）屬 PRD Phase 1B；本檔先把規則落地成可呼叫、可測的程式骨架，
# 不改動 STR 既有戰鬥流程。對應 docs/design/ward_break_system.md。
class_name WardBreakSystem
extends RefCounted

## 計算一張卡對某敵煞盾的削減量。
##  - 敵人無煞盾機制（max_ward_shield <= 0）→ 0
##  - 命中弱點 → break_damage + weakness_break_bonus
##  - 未命中弱點 → 鈍擊，僅 floor(break_damage / 2)
static func compute_ward_damage(card: CardData, enemy: EnemyData) -> int:
	if card == null or enemy == null:
		return 0
	if enemy.enemy_max_ward_shield <= 0:
		return 0
	if RitualTags.hits_weakness(card.card_ritual_tags, enemy.enemy_weaknesses):
		return maxi(0, card.card_break_damage + card.card_weakness_break_bonus)
	return int(card.card_break_damage / 2.0)

## 對敵人套用煞盾削減。回傳 true 代表「本次造成破煞」（盾由 >0 歸 0）。
## 已破煞狀態下不再重複削減。
static func apply_ward_damage(enemy: EnemyData, amount: int) -> bool:
	if enemy == null or enemy.enemy_max_ward_shield <= 0 or amount <= 0:
		return false
	if enemy.enemy_is_broken:
		return false
	var before: int = enemy.enemy_ward_shield
	enemy.enemy_ward_shield = maxi(0, enemy.enemy_ward_shield - amount)
	if before > 0 and enemy.enemy_ward_shield == 0:
		enemy.enemy_is_broken = true
		enemy.enemy_broken_turns_remaining = maxi(1, enemy.enemy_broken_turns)
		return true
	return false

## 破煞爆發窗口期間，受到的傷害加成倍率（供傷害結算端查詢）。
const BROKEN_DAMAGE_MULTIPLIER: float = 1.5

static func damage_multiplier_for(enemy: EnemyData) -> float:
	if enemy != null and enemy.enemy_is_broken:
		return BROKEN_DAMAGE_MULTIPLIER
	return 1.0

## 回合結束時遞減破煞窗口；歸零 → 煞盾回滿、解除破煞（敵人重新立盾）。
static func tick_broken_state(enemy: EnemyData) -> void:
	if enemy == null or not enemy.enemy_is_broken:
		return
	enemy.enemy_broken_turns_remaining -= 1
	if enemy.enemy_broken_turns_remaining <= 0:
		enemy.enemy_is_broken = false
		enemy.enemy_ward_shield = enemy.enemy_max_ward_shield

## 戰鬥開始時初始化煞盾（current = max）。
static func init_ward(enemy: EnemyData) -> void:
	if enemy == null:
		return
	enemy.enemy_is_broken = false
	enemy.enemy_broken_turns_remaining = 0
	enemy.enemy_ward_shield = maxi(0, enemy.enemy_max_ward_shield)
