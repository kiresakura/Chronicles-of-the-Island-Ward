# 鎮島錄 — 請神槽控制器（Phase 1D）。
#
# 掛在 Combat 下，追蹤「當前出戰神明」的請神值：監聽出牌（ritual_tags 與 charge_tags 交集）
# 與破煞事件累積，滿槽可降乩。降乩「效果」在 Combat（需敵人清單 + action 系統）；
# 本控制器只管「狀態」（累積 / 是否滿 / 重置）。對應 docs/design/deity_invocation_system.md。
class_name DeityChargeController
extends Node

signal charge_changed(current: int, max_charge: int)

## 各觸發事件累積的固定請神值（遊戲規則，集中於此；Q-R2 數值待平衡）。
const BREAK_CHARGE: int = 25	# on_enemy_broken（虎爺）
const BLOCK_CHARGE: int = 10	# on_block_gained（媽祖）
const DEBUFF_CHARGE: int = 12	# on_debuff_applied（城隍）

var deity: DeityData = null
var _charge: int = 0

func _ready() -> void:
	# 只連一次（Combat 跨戰鬥複用本控制器；請神值由 setup() 每場重置）
	if not Signals.card_played.is_connected(_on_card_played):
		Signals.card_played.connect(_on_card_played)
	if not Signals.enemy_broken.is_connected(_on_enemy_broken):
		Signals.enemy_broken.connect(_on_enemy_broken)
	if not Signals.combatant_block_added.is_connected(_on_combatant_block_added):
		Signals.combatant_block_added.connect(_on_combatant_block_added)
	if not Signals.debuff_applied.is_connected(_on_debuff_applied):
		Signals.debuff_applied.connect(_on_debuff_applied)

## 每場戰鬥開始呼叫：設定出戰神明、重置請神值。
func setup(active_deity: DeityData) -> void:
	deity = active_deity
	_charge = deity.deity_starting_charge if deity != null else 0
	_emit()

func get_charge() -> int:
	return _charge

func get_max() -> int:
	return deity.deity_max_charge if deity != null else 0

func is_ready() -> bool:
	return deity != null and DeityInvocationSystem.is_ready(_charge, deity.deity_max_charge)

## 降乩後重置請神值。
func consume() -> void:
	if deity == null:
		return
	_charge = 0
	_emit()

func _on_card_played(request: CardPlayRequest) -> void:
	if deity == null or request == null or request.card_data == null:
		return
	var delta: int = DeityInvocationSystem.charge_from_card(deity.deity_charge_tags, request.card_data)
	if delta > 0:
		delta += Global.run_tool_deity_charge_bonus	# 法器請神加成（2B：香爐等 tool_bonus_deity_charge）
		_charge = DeityInvocationSystem.add_charge(_charge, delta, deity.deity_max_charge)
		_emit()

# 事件觸發累積：依出戰神明的 trigger_condition 路由（不符則忽略）。
func _on_enemy_broken(_enemy: Enemy) -> void:
	_charge_on_trigger("on_enemy_broken", BREAK_CHARGE)

func _on_combatant_block_added(combatant: BaseCombatant) -> void:
	# 媽祖：玩家獲得護身符時（敵人獲得 block 不算）
	if combatant != null and combatant.is_in_group("enemies"):
		return
	_charge_on_trigger("on_block_gained", BLOCK_CHARGE)

func _on_debuff_applied(_target: BaseCombatant) -> void:
	_charge_on_trigger("on_debuff_applied", DEBUFF_CHARGE)

func _charge_on_trigger(trigger: String, amount: int) -> void:
	if deity == null or deity.deity_trigger_condition != trigger:
		return
	_charge = DeityInvocationSystem.add_charge(_charge, amount, deity.deity_max_charge)
	_emit()

func _emit() -> void:
	charge_changed.emit(_charge, get_max())
