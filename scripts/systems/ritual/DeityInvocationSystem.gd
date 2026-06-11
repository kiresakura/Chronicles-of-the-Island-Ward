# 鎮島錄 — 請神（Deity Invocation）核心運算 + 神明資料載入。
#
# 純函式 + 一個 disk 載入器（神明資料目前不入 Global SCHEMA，由此就地讀取）。
# 請神槽「累積狀態」在 DeityChargeController；降乩「效果」在 Combat。本檔只負責
# 「這張卡/這個事件，為某神累積多少請神值」與「神明資料怎麼讀」。
# 對應 docs/design/deity_invocation_system.md。
class_name DeityInvocationSystem
extends RefCounted

const DEITY_DIR: String = "res://external/data/deities/"

## 一張卡為某神累積的請神值：卡的 ritual_tags 與神明 charge_tags 有交集 → card_deity_charge，否則 0。
static func charge_from_card(deity_charge_tags: Array, card: CardData) -> int:
	if card == null:
		return 0
	if RitualTags.intersects(card.card_ritual_tags, deity_charge_tags):
		return maxi(0, card.card_deity_charge)
	return 0

## 加上請神值並夾在 [0, max]。
static func add_charge(current: int, delta: int, max_charge: int) -> int:
	return clampi(current + delta, 0, max_charge)

## 請神槽是否已滿（可降乩）。
static func is_ready(current: int, max_charge: int) -> bool:
	return max_charge > 0 and current >= max_charge

## 從 external/data/deities/<id>.json 就地載入 DeityData（MVP：戰鬥端不經 Global）。
## 僅讀取請神所需欄位，且以正確型別建構 Array[String]，避免 typed-array 反序列化問題。
static func load_deity(deity_id: String) -> DeityData:
	var path: String = DEITY_DIR + deity_id + ".json"
	if not FileAccess.file_exists(path):
		return null
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var props: Dictionary = (parsed as Dictionary).get("properties", {})
	var d: DeityData = DeityData.new()
	d.object_id = str(props.get("object_id", deity_id))
	d.deity_name = str(props.get("deity_name", ""))
	d.deity_description = str(props.get("deity_description", ""))
	d.deity_texture_path = str(props.get("deity_texture_path", ""))	# Q1-D：cut-in 立繪
	var tags: Array[String] = []
	for t: Variant in props.get("deity_charge_tags", []):
		tags.append(str(t))
	d.deity_charge_tags = tags
	d.deity_max_charge = int(props.get("deity_max_charge", 100))
	d.deity_starting_charge = int(props.get("deity_starting_charge", 0))
	d.deity_trigger_condition = str(props.get("deity_trigger_condition", "manual"))
	d.deity_invocation_effect = str(props.get("deity_invocation_effect", ""))
	d.deity_invocation_description = str(props.get("deity_invocation_description", ""))
	d.deity_passive_effect = str(props.get("deity_passive_effect", ""))
	return d
