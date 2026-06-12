# 鎮島錄 Q4-C — IAP 編排器：商品表 × 供應端 × 授與路由（單一授與入口強制紅線）。
#
# 用法（未來商城 UI）：
#   var mgr := IAPManager.new(FakeIAPProvider.new())   # 真機換 StoreKit 供應端
#   mgr.purchase_granted.connect(_on_granted)
#   mgr.purchase("iap_test_yuanbao_s", Global.profile_data)
# 授與成功即 FileLoader.save_profile()（落地走 Q4-B 加密管線）。
#
# 紅線執行點：_grant() 只認 Products.validate() 過關的商品 —
# grant_type 白名單外（香火/戰力）在資料層就被擋下，授與層再驗一次（縱深防禦）。
class_name IAPManager
extends RefCounted

const Products := preload("res://scripts/systems/iap/IAPProducts.gd")
# provider 參數不標 IAPProvider 型別：class_name 全域註冊在 headless
# 測試載入序不可靠（專案慣例 — 行為契約見 IAPProvider.gd）

## 授與完成（UI 刷新點）。granted=false 時 message 為原因。
signal purchase_granted(product_id: String, granted: bool, message: String)

var _provider: RefCounted
var _profile: ProfileData = null	# purchase() 進行中暫存（單線程序列化購買）

func _init(provider: RefCounted) -> void:
	_provider = provider
	_provider.purchase_finished.connect(_on_provider_finished)

## 發起購買。商品不合法/重複擁有 → 不觸發供應端，直接回報。
func purchase(product_id: String, profile: ProfileData) -> void:
	var props: Dictionary = Products.load_product(product_id)
	var fault: String = Products.validate(props)
	if fault != "":
		purchase_granted.emit(product_id, false, fault)
		return
	if str(props.get("iap_type", "")) == "non_consumable" \
			and product_id in profile.profile_owned_iap_skus:
		purchase_granted.emit(product_id, false, "already_owned")
		return
	_profile = profile
	_provider.request_purchase(product_id)

## 還原已購（非消耗性）：補授與缺漏的解鎖（重灌/換機場景）。回還原筆數。
func restore(profile: ProfileData) -> int:
	var restored: int = 0
	for sku: String in _provider.restore_purchases():
		var props: Dictionary = Products.load_product(sku)
		if Products.validate(props) != "":
			continue
		if str(props.get("iap_type", "")) != "non_consumable":
			continue	# 消耗品不在還原範圍（平台規則）
		if _grant(props, profile):
			restored += 1
	if restored > 0 and profile == Global.profile_data:
		FileLoader.save_profile()	# 測試用獨立 profile 不寫真檔（同 purchase 守門）
	return restored

func _on_provider_finished(product_id: String, success: bool, message: String) -> void:
	if not success or _profile == null:
		purchase_granted.emit(product_id, false, message)
		_profile = null
		return
	var props: Dictionary = Products.load_product(product_id)
	var granted: bool = Products.validate(props) == "" and _grant(props, _profile)
	if granted and _profile == Global.profile_data:
		FileLoader.save_profile()	# 走 Q4-B 加密落地；測試用獨立 profile 不寫真檔
	purchase_granted.emit(product_id, granted, message if granted else "grant_rejected")
	_profile = null

## 單一授與入口（紅線縱深防禦）。回授與是否成立。
func _grant(props: Dictionary, profile: ProfileData) -> bool:
	if Products.validate(props) != "":
		return false
	var product_id: String = str(props.get("object_id", ""))
	match str(props.get("grant_type", "")):
		"yuanbao":
			profile.add_yuanbao(int(props.get("grant_amount", 0)))
		"cosmetic_unlock", "character_unlock":
			if product_id in profile.profile_owned_iap_skus \
					and profile.has_iap_unlock(str(props.get("grant_unlock_id", ""))):
				return false	# 已擁有：不重複授與（restore 冪等）
			profile.grant_iap_unlock(str(props.get("grant_unlock_id", "")))
		_:
			return false	# validate 已擋；保險絲
	if str(props.get("iap_type", "")) == "non_consumable" \
			and product_id not in profile.profile_owned_iap_skus:
		profile.profile_owned_iap_skus.append(product_id)
	return true
