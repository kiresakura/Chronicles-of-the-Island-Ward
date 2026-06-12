# 鎮島錄 Q4-C — IAP 平台供應端抽象基類。
#
# 契約：UI/Manager 先接 purchase_finished 再呼叫 request_purchase（Fake 端同步發訊，
# 真 StoreKit 端非同步 — 訂閱順序錯誤在沙盒就會現形，刻意如此）。
# 真機適配（StoreKit 2 via godot-ios-plugins）排 Q4-F TestFlight 輪；
# 屆時新增 StoreKitIAPProvider extends 本類，IAPManager 按平台路由，呼叫端零改動。
class_name IAPProvider
extends RefCounted

## product_id；success；message（失敗原因 / i18n key 或平台訊息）
signal purchase_finished(product_id: String, success: bool, message: String)

## 發起購買（覆寫端負責最終 emit purchase_finished）。
@warning_ignore("unused_parameter")
func request_purchase(product_id: String) -> void:
	push_error("IAPProvider.request_purchase 未實作（抽象基類）")

## 還原已購（非消耗性）：回 sku 清單。覆寫端實作平台還原流程。
func restore_purchases() -> Array[String]:
	return []
