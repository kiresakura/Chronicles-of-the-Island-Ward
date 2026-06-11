# 鎮島錄 Q2-D — 修廟結構型解鎖實套守門（QUESTIONS Q2-A 選項 A / Q2-B 選項 A）。
# 虎爺殿→破煞法器進池、夜市香鋪→商店加成（數值在 building JSON）、dev 全開旗標。
extends "res://tests/test_case.gd"

func _profile(levels: Dictionary = {}, incense: int = 0) -> ProfileData:
	var p: ProfileData = ProfileData.new()
	p.profile_incense_balance = incense
	for bid: String in levels:
		p.profile_building_id_to_level[bid] = int(levels[bid])
	return p

func test_tool_pool_gates_ward_break_at_level_zero() -> void:
	# 0 級基線：破煞向法器（虎牌）不在池內，但至少還有 2 把可選（溫和收窄）
	var ids: Array[String] = RitualLoadout.list_tool_ids_unlocked(_profile())
	assert_false(ids.has("tool_tiger_token"), "0 級不應含破煞向虎牌")
	assert_true(ids.size() >= 2, "0 級仍須有非破煞法器可選（溫和收窄）")
	for tool_id: String in ids:
		var t: RitualToolData = RitualLoadout.load_tool(tool_id)
		assert_true(t == null or t.tool_rule_domain != "ward_break", "0 級池內不得有 ward_break 域法器")

func test_tool_pool_opens_with_tiger_shrine() -> void:
	var ids: Array[String] = RitualLoadout.list_tool_ids_unlocked(_profile({"building_tiger_shrine": 1}))
	assert_true(ids.has("tool_tiger_token"), "虎爺殿 1 級後虎牌應進池")
	assert_eq(ids.size(), RitualLoadout.list_tool_ids().size(), "解鎖後池應與全清單一致")

func test_shop_bonus_scales_with_night_market_level() -> void:
	assert_eq(RitualTemple.shop_bonus_cards(_profile()), 0, "0 級無商店加成")
	assert_eq(RitualTemple.shop_bonus_consumables(_profile()), 0, "0 級無消耗品加成")
	assert_eq(RitualTemple.shop_bonus_cards(_profile({"building_night_market": 1})), 1, "1 級 +1 卡")
	assert_eq(RitualTemple.shop_bonus_cards(_profile({"building_night_market": 3})), 3, "3 級 +3 卡")
	assert_eq(RitualTemple.shop_bonus_consumables(_profile({"building_night_market": 2})), 1, "≥1 級 +1 消耗品")

func test_dev_flag_opens_everything() -> void:
	OS.set_environment("COTIW_TEMPLE_ALL", "1")
	var ids: Array[String] = RitualLoadout.list_tool_ids_unlocked(_profile())
	var bonus: int = RitualTemple.shop_bonus_cards(_profile())
	OS.set_environment("COTIW_TEMPLE_ALL", "")	# 還原（測試隔離）
	assert_true(ids.has("tool_tiger_token"), "dev 旗標下虎牌直接進池")
	assert_true(bonus >= 1, "dev 旗標下商店視同 1 級加成")

func test_night_market_json_carries_bonus_numbers() -> void:
	# 鐵律 1：加成數值必須在資料層（不是寫死在程式）
	var props: Dictionary = RitualTemple.load_building("building_night_market")
	assert_true(props.has("shop_stock_bonus_cards_per_level"), "JSON 應含每級加卡數")
	assert_true(props.has("shop_stock_bonus_consumables"), "JSON 應含消耗品加成數")
