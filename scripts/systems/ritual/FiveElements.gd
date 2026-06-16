# 鎮島錄 v0.3 — 五行相生相剋（formation_progression_v0.3.md §1.2，FP-3 完整版）。
#
# 得位/失位判定核心：把單位 element 與所在營 element 比對 → 關係 → 加成倍率。
# 純函式、靜態，沿 FortuneSticks/RitualTemple 慣例；倍率值資料層注入（戰鬥腳本不硬編）。
#
# 五行：木 火 土 金 水（wood fire earth metal water）
#   相生（生）：木→火→土→金→水→木（生我者扶持）
#   相剋（剋）：木→土→水→火→金→木（我剋者被我制）
class_name FiveElements
extends RefCounted

const ELEMENTS: Array[String] = ["wood", "fire", "earth", "metal", "water"]

## 相生：key 生 value（木生火…）
const GENERATES: Dictionary = {
	"wood": "fire", "fire": "earth", "earth": "metal", "metal": "water", "water": "wood",
}
## 相剋：key 剋 value（木剋土…）
const OVERCOMES: Dictionary = {
	"wood": "earth", "earth": "water", "water": "fire", "fire": "metal", "metal": "wood",
}

## 單位 element（unit_el）站在營 element（camp_el）上的關係：
##   same          同行 → 得位（最旺）
##   generated_by  營生我（camp 生 unit）→ 受扶持（旺）
##   overcomes     我剋營（unit 剋 camp）→ 制煞（攻勢加成）
##   generates     我生營（unit 生 camp）→ 洩氣（小衰）
##   overcome_by   營剋我（camp 剋 unit）→ 失位（最衰）
##   neutral       —（含任一為空 = 中性）
static func relationship(unit_el: String, camp_el: String) -> String:
	if unit_el == "" or camp_el == "":
		return "neutral"
	if unit_el == camp_el:
		return "same"
	if GENERATES.get(camp_el, "") == unit_el:
		return "generated_by"
	if OVERCOMES.get(unit_el, "") == camp_el:
		return "overcomes"
	if GENERATES.get(unit_el, "") == camp_el:
		return "generates"
	if OVERCOMES.get(camp_el, "") == unit_el:
		return "overcome_by"
	return "neutral"

## 得位＝同行或受營扶持（攻守皆強的正向位）。
static func is_wei_position(unit_el: String, camp_el: String) -> bool:
	var rel: String = relationship(unit_el, camp_el)
	return rel == "same" or rel == "generated_by"

## 削煞倍率：由資料層 multipliers（關係鍵 → 倍率）查得；缺鍵回 1.0（中性，向後相容）。
static func damage_multiplier(unit_el: String, camp_el: String, multipliers: Dictionary) -> float:
	return float(multipliers.get(relationship(unit_el, camp_el), 1.0))

## 是否合法五行（validator / 防呆用；空字串視為中性合法）。
static func is_valid_element(el: String) -> bool:
	return el == "" or ELEMENTS.has(el)
