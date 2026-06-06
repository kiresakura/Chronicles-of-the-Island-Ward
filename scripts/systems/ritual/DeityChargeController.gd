# 鎮島錄 — 請神槽控制器（Phase 1D）。
#
# 掛在 Combat 下，追蹤「當前出戰神明」的請神值：監聽出牌（ritual_tags 與 charge_tags 交集）
# 與破煞事件累積，滿槽可降乩。降乩「效果」在 Combat（需敵人清單 + action 系統）；
# 本控制器只管「狀態」（累積 / 是否滿 / 重置）。對應 docs/design/deity_invocation_system.md。
class_name DeityChargeController
extends Node

signal charge_changed(current: int, max_charge: int)

## 破煞為 on_enemy_broken 神明累積的固定請神值（遊戲規則，集中於此；Q-R2 數值待平衡）。
const BREAK_CHARGE: int = 25

var deity: DeityData = null
var _charge: int = 0

func _ready() -> void:
	# 只連一次（Combat 跨戰鬥複用本控制器；請神值由 setup() 每場重置）
	if not Signals.card_played.is_connected(_on_card_played):
		Signals.card_played.connect(_on_card_played)
	if not Signals.enemy_broken.is_connected(_on_enemy_broken):
		Signals.enemy_broken.connect(_on_enemy_broken)

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
		_charge = DeityInvocationSystem.add_charge(_charge, delta, deity.deity_max_charge)
		_emit()

func _on_enemy_broken(_enemy: Enemy) -> void:
	if deity == null:
		return
	# 虎爺等 on_enemy_broken 神明：破煞額外累積請神值（連通 1B 破煞 → 1D 請神）
	if deity.deity_trigger_condition == "on_enemy_broken":
		_charge = DeityInvocationSystem.add_charge(_charge, BREAK_CHARGE, deity.deity_max_charge)
		_emit()

func _emit() -> void:
	charge_changed.emit(_charge, get_max())
