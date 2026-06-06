# 鎮島錄 — 符階合成（Talisman Merge）核心判定。
#
# 純函式、無場景耦合、決定性 → 可在 headless 下單元測試（tests/unit/test_talisman_merge_system.gd）。
# 合符「執行」（transform + 移除夥伴 + 每回合限額 + UI）在 Hand.gd；本檔只負責「能不能合、跟誰合」。
# 對應 docs/design/talisman_merge_system.md。一劃符 → 二劃符 → 三劃敕符。
class_name TalismanMergeSystem
extends RefCounted

## 兩張卡是否可合符：
##  - 皆非空、且非同一張物件
##  - 同 merge_group（非空字串）
##  - 同 merge_tier（≥1；0 表示不可合成）
##  - card_a 有 merge_result_id（頂階敕符留空 → 不可再合）
static func can_merge(a: CardData, b: CardData) -> bool:
	if a == null or b == null or a == b:
		return false
	if a.card_merge_group == "" or a.card_merge_tier < 1:
		return false
	if a.card_merge_group != b.card_merge_group:
		return false
	if a.card_merge_tier != b.card_merge_tier:
		return false
	if a.card_merge_result_id == "":
		return false
	return true

## 在 hand（Array[CardData]）中找出 card 的第一個可合符夥伴（排除自己）。找不到回 null。
static func find_merge_partner(card: CardData, hand: Array) -> CardData:
	if card == null:
		return null
	for other: Variant in hand:
		if other is CardData and other != card and can_merge(card, other as CardData):
			return other as CardData
	return null

## hand 中是否存在「任一」可合符的組合（供 UI 提示用）。
static func has_any_merge(hand: Array) -> bool:
	for i: int in range(hand.size()):
		for j: int in range(i + 1, hand.size()):
			if hand[i] is CardData and hand[j] is CardData and can_merge(hand[i], hand[j]):
				return true
	return false
