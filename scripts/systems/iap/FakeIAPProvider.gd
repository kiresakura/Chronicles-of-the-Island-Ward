# 鎮島錄 Q4-C — 沙盒假供應端：無商店環境下驗整條購買管線（dev / 模擬器 / 測試）。
#
# 行為：request_purchase 同步成功（COTIW_IAP_FAIL=1 時模擬玩家取消/扣款失敗）；
# restore_purchases 重放本 session 內成功購買的 sku（真平台由商店帳號回填）。
class_name FakeIAPProvider
extends "res://scripts/systems/iap/IAPProvider.gd"
# ↑ path-based extends：class_name 全域註冊在 headless 測試載入序不可靠（專案慣例）

var _session_purchased_skus: Array[String] = []

func request_purchase(product_id: String) -> void:
	if OS.get_environment("COTIW_IAP_FAIL") == "1":
		purchase_finished.emit(product_id, false, "sandbox_simulated_decline")
		return
	if product_id not in _session_purchased_skus:
		_session_purchased_skus.append(product_id)
	purchase_finished.emit(product_id, true, "sandbox_ok")

func restore_purchases() -> Array[String]:
	return _session_purchased_skus.duplicate()
