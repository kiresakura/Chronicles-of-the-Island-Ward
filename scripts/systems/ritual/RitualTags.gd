# 鎮島錄 — 六道儀法標籤的「單一事實來源」。
#
# 卡牌 card_ritual_tags、敵人 enemy_weaknesses、神明 deity_charge_tags、
# 法器 tool_modify_tags 全部引用此處的鍵字串，避免散落硬編碼。
# 對應 PRD §戰鬥系統「破煞」與 docs/design/ward_break_system.md。
class_name RitualTags
extends RefCounted

const FIST := "fist"			# 拳：乩童附體、肉身鎮煞
const TALISMAN := "talisman"	# 符：道士／鸞女符令
const FIRE := "fire"			# 火：聖火、香火、化金
const BELL := "bell"			# 鈴：法鈴、淨壇、驅邪
const ARRAY := "array"			# 陣：法陣、家將陣型
const CURSE := "curse"			# 咒：咒術、邪氣、降煞

const ALL: Array[String] = [FIST, TALISMAN, FIRE, BELL, ARRAY, CURSE]

## 標籤 → 繁中單字（UI 標示用）
const DISPLAY := {
	"fist": "拳", "talisman": "符", "fire": "火",
	"bell": "鈴", "array": "陣", "curse": "咒",
}

static func is_valid(tag: String) -> bool:
	return ALL.has(tag)

## 卡牌標籤是否命中敵人任一弱點。
static func hits_weakness(card_tags: Array, enemy_weaknesses: Array) -> bool:
	for t: Variant in card_tags:
		if enemy_weaknesses.has(t):
			return true
	return false

## 兩組標籤是否有交集（用於請神值歸屬：卡 ritual_tags ∩ 神明 charge_tags）。
static func intersects(tags_a: Array, tags_b: Array) -> bool:
	for t: Variant in tags_a:
		if tags_b.has(t):
			return true
	return false
