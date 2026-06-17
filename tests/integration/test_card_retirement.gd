# 鎮島錄 v0.3 — FC-2b.2 卡牌退役守門測試。
# 五營換骨 + 符令經濟全面就位後，鎖定「戰鬥/經濟一律走符令，不回卡牌」。
# 註：卡牌戰鬥節點為「隱藏且不可達」（Combat 一律轉五營），其實體死碼刪除屬高風險、
# 收益低（隱藏碼不傷遊戲），依硬停原則延後；本檔以行為守門鎖住退役狀態。
extends "res://tests/test_case.gd"

const FC := preload("res://scripts/systems/ritual/FormationCombat.gd")
const CodexCls := preload("res://scripts/ui/menus/CodexMenu.gd")

func test_codex_migrated_to_fu_tab() -> void:
	# 圖鑑已增符令分頁（卡牌頁保留作 meta 骨幹）
	assert_true(CodexCls.TAB.has("FU"), "CodexMenu.TAB 應含 FU 分頁（圖鑑已遷符令）")

func test_shop_pool_is_all_fu_not_cards() -> void:
	var pool: Array = FC.fu_shop_pool()
	assert_true(pool.size() > 0, "商店進貨池非空")
	for fid: Variant in pool:
		assert_true(str(fid).begins_with("fu_"), "商店進貨為符令（非卡牌）：%s" % str(fid))

func test_combat_economy_pools_are_all_fu() -> void:
	var cfg: Dictionary = FC.load_fu_config()
	for key: String in ["starter_deck", "draft_pool"]:
		var pool: Array = cfg.get(key, [])
		assert_true(pool.size() > 0, "%s 非空" % key)
		for fid: Variant in pool:
			assert_true(str(fid).begins_with("fu_"), "%s 項為符令：%s" % [key, str(fid)])

func test_all_base_fu_are_mergeable() -> void:
	# 每個進場用基礎符（draft_pool）皆可合符（FP-3 合符鏈完整）
	for fid: Variant in FC.load_fu_config().get("draft_pool", []):
		assert_true(FC.fu_can_merge(str(fid)), "基礎符 %s 應可合符（有上位成品）" % str(fid))

func test_shop_data_carries_fu_inventory() -> void:
	# ShopData 結構已帶符令庫存欄位（商店結構性遷移）
	var sd := ShopData.new()
	sd.shop_fu = ["fu_po_sha"]
	sd.shop_fu_prices = [45]
	assert_eq(sd.shop_fu.size(), 1, "ShopData 帶 shop_fu 庫存")
	assert_eq(sd.get_shop_fu_price("fu_po_sha"), 45, "符令定價可查")
