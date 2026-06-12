# 鎮島錄 Q4-C — IAP 商品表（資料驅動；external/data/iap_products/*.json）。
#
# 紅線（DELEGATION/PRD）：元寶只買「外觀 / 角色解鎖」— 香火與戰力不可販售。
# 本層以 grant_type 白名單強制：任何資料檔宣告白名單外的授與一律判 invalid，
# IAPManager 拒絕授與。改商品 = 加/改 JSON（鐵律 1：數值在資料層）。
#
# 商品 schema（properties 內，沿 fortune_sticks 直讀慣例）：
#   object_id            商品 id（= sku；檔名同名）
#   iap_type             "consumable" | "non_consumable"
#   grant_type           "yuanbao" | "cosmetic_unlock" | "character_unlock"
#   grant_amount         元寶數（grant_type=yuanbao 用；> 0）
#   grant_unlock_id      解鎖 token（unlock 類用；如 character_daoshi）
#   store_price_label    顯示用價格佔位（正式價格以商店後台為準）
#   is_test_product      true = 測試佔位（憲龍定案 IAP 結構前的管線驗證品）
class_name IAPProducts
extends RefCounted

const PRODUCT_DIR: String = "res://external/data/iap_products/"

## 紅線白名單：可販售的授與類型。香火（incense）/戰力（power/stat）永不入列。
const ALLOWED_GRANT_TYPES: Array[String] = ["yuanbao", "cosmetic_unlock", "character_unlock"]
const ALLOWED_IAP_TYPES: Array[String] = ["consumable", "non_consumable"]

static func load_product(product_id: String) -> Dictionary:
	var path: String = PRODUCT_DIR + product_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return (parsed as Dictionary).get("properties", {})

static func list_product_ids() -> Array[String]:
	var ids: Array[String] = []
	var dir: DirAccess = DirAccess.open(PRODUCT_DIR)
	if dir == null:
		return ids
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry.ends_with(".json"):
			ids.append(entry.trim_suffix(".json"))
		entry = dir.get_next()
	dir.list_dir_end()
	ids.sort()
	return ids

## 商品合法性（含紅線）。回空字串 = 合法；否則回機器面 fault code
## （非玩家可見 — UI 層若要顯示，屆時自行映射 i18n key）。
static func validate(props: Dictionary) -> String:
	if props.is_empty():
		return "empty_product"
	if str(props.get("object_id", "")) == "":
		return "missing_object_id"
	var iap_type: String = str(props.get("iap_type", ""))
	if iap_type not in ALLOWED_IAP_TYPES:
		return "invalid_iap_type:" + iap_type
	var grant_type: String = str(props.get("grant_type", ""))
	if grant_type not in ALLOWED_GRANT_TYPES:
		return "redline_grant_type:" + grant_type	# 香火/戰力不可販售
	if grant_type == "yuanbao":
		if iap_type != "consumable":
			return "yuanbao_must_be_consumable"
		if int(props.get("grant_amount", 0)) <= 0:
			return "grant_amount_not_positive"
	else:
		if iap_type != "non_consumable":
			return "unlock_must_be_non_consumable"
		if str(props.get("grant_unlock_id", "")) == "":
			return "missing_grant_unlock_id"
	return ""
