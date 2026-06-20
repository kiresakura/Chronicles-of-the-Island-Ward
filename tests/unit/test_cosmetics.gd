# 鎮島錄 c-2 外觀變現 — 目錄/購買/裝備 + 變現紅線守門（元寶只換外觀、永不碰戰力）。
extends "res://tests/test_case.gd"

const Catalog := preload("res://scripts/systems/cosmetics/CosmeticCatalog.gd")

func _profile() -> ProfileData:
	return ProfileData.new()

func test_catalog_loads_four_tiers() -> void:
	assert_eq(Catalog.frames().size(), 4, "外觀目錄應 4 階（素/燙金/玉青/神話）")

func test_su_is_free_default_and_always_owned() -> void:
	var p := _profile()
	assert_eq(Catalog.price("frame_su"), 0, "素免費")
	assert_true(Catalog.owns(p, "frame_su"), "素永遠擁有（免費預設）")
	assert_eq(Catalog.equipped_id(p), "frame_su", "預設裝備素")

func test_purchase_deducts_yuanbao_and_grants() -> void:
	var p := _profile()
	p.profile_yuanbao = 100
	assert_true(Catalog.purchase(p, "frame_gold"), "餘額足應購得")
	assert_eq(p.profile_yuanbao, 70, "扣 30 元寶")
	assert_true(Catalog.owns(p, "frame_gold"), "購後擁有")

func test_purchase_rejects_when_insufficient() -> void:
	var p := _profile()
	p.profile_yuanbao = 10
	assert_false(Catalog.purchase(p, "frame_gold"), "餘額不足拒絕")
	assert_false(Catalog.owns(p, "frame_gold"), "未購得")
	assert_eq(p.profile_yuanbao, 10, "餘額不變")

func test_purchase_rejects_double_buy() -> void:
	var p := _profile()
	p.profile_yuanbao = 100
	Catalog.purchase(p, "frame_gold")
	assert_false(Catalog.purchase(p, "frame_gold"), "已擁有不可重買")
	assert_eq(p.profile_yuanbao, 70, "不重複扣款")

func test_purchase_never_touches_incense_redline() -> void:
	var p := _profile()
	p.profile_yuanbao = 200
	p.profile_incense_balance = 500
	Catalog.purchase(p, "frame_myth")	# 120 元寶
	assert_eq(p.profile_incense_balance, 500, "紅線：買外觀永不動香火/戰力")
	assert_eq(p.profile_yuanbao, 80, "只扣元寶 120")

func test_equip_requires_ownership() -> void:
	var p := _profile()
	assert_false(Catalog.equip(p, "frame_jade"), "未擁有不可裝備")
	p.profile_yuanbao = 100
	Catalog.purchase(p, "frame_jade")
	assert_true(Catalog.equip(p, "frame_jade"), "擁有後可裝備")
	assert_eq(Catalog.equipped_id(p), "frame_jade", "裝備生效")

func test_equip_su_resets_to_empty() -> void:
	var p := _profile()
	p.profile_equipped_frame = "frame_gold"
	Catalog.equip(p, "frame_su")
	assert_eq(p.profile_equipped_frame, "", "裝備素 → 還原空字串")
	assert_eq(Catalog.equipped_id(p), "frame_su", "等同素預設")

func test_all_frames_have_required_fields() -> void:
	for fr in Catalog.frames():
		assert_true(fr.has("id") and fr.has("tier") and fr.has("price_yuanbao") and fr.has("border_token"),
			"每階外觀須有 id/tier/price/border_token")
