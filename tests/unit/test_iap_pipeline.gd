# 鎮島錄 Q4-C — IAP 管線守門。
# 範圍：商品表載入/驗證、紅線白名單（香火/戰力不可販售）、沙盒購買授與、
# 非消耗性防重複、restore 冪等補授、IAP 角色解鎖第二路徑。
# 全程用獨立 ProfileData 實例 — 不碰 Global.profile_data、不寫真實存檔。
extends "res://tests/test_case.gd"

const IAPProductsScript := preload("res://scripts/systems/iap/IAPProducts.gd")
const IAPManagerScript := preload("res://scripts/systems/iap/IAPManager.gd")
const FakeProviderScript := preload("res://scripts/systems/iap/FakeIAPProvider.gd")

var _last_granted: Array = []	# [product_id, granted, message]

func _make_manager() -> RefCounted:
	var mgr: RefCounted = IAPManagerScript.new(FakeProviderScript.new())
	mgr.purchase_granted.connect(func(pid: String, ok: bool, msg: String) -> void:
		_last_granted = [pid, ok, msg])
	return mgr

func test_product_table_loads_and_validates() -> void:
	var ids: Array[String] = IAPProductsScript.list_product_ids()
	assert_true(ids.size() >= 4, "測試商品表至少 4 件")
	for pid: String in ids:
		var props: Dictionary = IAPProductsScript.load_product(pid)
		assert_eq(IAPProductsScript.validate(props), "", "商品應全數合法：%s" % pid)
		assert_true(bool(props.get("is_test_product", false)), "Q4-A 定案前應全為測試佔位品：%s" % pid)

func test_redline_rejects_incense_and_power() -> void:
	# 紅線：香火與戰力不可販售 — grant_type 白名單外一律 invalid
	for bad_type: String in ["incense", "power", "max_health", "damage_buff"]:
		var fault: String = IAPProductsScript.validate({
			"object_id": "iap_bad", "iap_type": "consumable",
			"grant_type": bad_type, "grant_amount": 100,
		})
		assert_ne(fault, "", "紅線應擋下 grant_type=%s" % bad_type)

func test_consumable_purchase_grants_yuanbao() -> void:
	var profile: ProfileData = ProfileData.new()
	var mgr: RefCounted = _make_manager()
	mgr.purchase("iap_test_yuanbao_s", profile)
	assert_eq(_last_granted[1], true, "沙盒購買應成功")
	assert_eq(profile.profile_yuanbao, 60, "元寶小包應 +60")
	mgr.purchase("iap_test_yuanbao_s", profile)
	assert_eq(profile.profile_yuanbao, 120, "消耗品可重複購買")

func test_non_consumable_dedups() -> void:
	var profile: ProfileData = ProfileData.new()
	var mgr: RefCounted = _make_manager()
	mgr.purchase("iap_test_skin_tongji_gold", profile)
	assert_eq(_last_granted[1], true, "首購應成功")
	assert_true(profile.has_iap_unlock("skin_tongji_gold"), "應授與外觀解鎖")
	assert_has(profile.profile_owned_iap_skus, "iap_test_skin_tongji_gold", "sku 應入已購清單")
	mgr.purchase("iap_test_skin_tongji_gold", profile)
	assert_eq(_last_granted[1], false, "重複購買應被擋")
	assert_eq(_last_granted[2], "already_owned", "原因應為 already_owned")

func test_simulated_decline_grants_nothing() -> void:
	OS.set_environment("COTIW_IAP_FAIL", "1")
	var profile: ProfileData = ProfileData.new()
	var mgr: RefCounted = _make_manager()
	mgr.purchase("iap_test_yuanbao_m", profile)
	OS.set_environment("COTIW_IAP_FAIL", "")
	assert_eq(_last_granted[1], false, "模擬拒付應失敗")
	assert_eq(profile.profile_yuanbao, 0, "拒付不得授與元寶")

func test_restore_replays_unlocks_idempotently() -> void:
	var profile: ProfileData = ProfileData.new()
	var provider: RefCounted = FakeProviderScript.new()
	var mgr: RefCounted = IAPManagerScript.new(provider)
	mgr.purchase("iap_test_char_jiajiang", profile)
	# 模擬重灌：解鎖 token 遺失、商店端仍記得已購 sku
	profile.profile_iap_unlock_ids.clear()
	var restored: int = mgr.restore(profile)
	assert_eq(restored, 1, "restore 應補授 1 筆")
	assert_true(profile.has_iap_unlock("character_jiajiang"), "角色解鎖 token 應還原")
	assert_eq(mgr.restore(profile), 0, "再次 restore 應冪等（0 筆）")

func test_iap_character_unlock_second_path() -> void:
	# 家將需 8 勝；IAP 解鎖應繞過勝場需求（紅線內：角色解鎖可販售）
	var original: ProfileData = Global.profile_data
	var profile: ProfileData = ProfileData.new()
	Global.profile_data = profile
	assert_false(Global.is_character_unlocked("character_jiajiang"), "0 勝未解鎖（前置）")
	profile.grant_iap_unlock("character_jiajiang")
	assert_true(Global.is_character_unlocked("character_jiajiang"), "IAP 解鎖應立即生效")
	Global.profile_data = original
