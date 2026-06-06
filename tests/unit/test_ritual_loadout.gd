# 鎮島錄 — 班底（主祭/護壇/法器）載入 + 出戰神明解析單元測試（RitualLoadout）。
# 純函式 + disk 載入器；同步、無場景。對應 PRD §主祭/護壇/法器、PHASE_2_PLAN 2B。
extends "res://tests/test_case.gd"

func _mk_guardian(deity_id: String) -> GuardianData:
	var g: GuardianData = GuardianData.new()
	g.guardian_affinity_deity_id = deity_id
	return g

func _mk_tool(deity_id: String) -> RitualToolData:
	var t: RitualToolData = RitualToolData.new()
	t.tool_affinity_deity_id = deity_id
	return t

# ---------- resolve_active_deity 優先序 ----------

func test_resolve_priority_tool_over_guardian() -> void:
	assert_eq(RitualLoadout.resolve_active_deity(_mk_guardian("deity_chenghuang"), _mk_tool("deity_tiger_god")),
		"deity_tiger_god", "法器 affinity 優先於護壇")

func test_resolve_falls_to_guardian_when_tool_blank() -> void:
	assert_eq(RitualLoadout.resolve_active_deity(_mk_guardian("deity_mazu"), _mk_tool("")),
		"deity_mazu", "法器無 affinity → 取護壇 affinity")

func test_resolve_default_when_none() -> void:
	assert_eq(RitualLoadout.resolve_active_deity(null, null),
		"deity_tiger_god", "皆無 → 預設虎爺")

# ---------- disk 載入真實資料 ----------

func test_load_real_guardian_has_support_cards() -> void:
	var g: GuardianData = RitualLoadout.load_guardian("guardian_luannu")
	assert_not_null(g, "guardian_luannu 應載入")
	if g != null:
		assert_true(g.guardian_support_card_ids.size() > 0, "鸞女護壇應帶支援卡")

func test_load_real_tool_tiger_token() -> void:
	var t: RitualToolData = RitualLoadout.load_tool("tool_tiger_token")
	assert_not_null(t, "tool_tiger_token 應載入")
	if t != null:
		assert_eq(t.tool_affinity_deity_id, "deity_tiger_god", "虎牌 affinity 虎爺")
		assert_eq(t.tool_bonus_break_damage, 1, "虎牌破煞 +1")

# ---------- 角色預設班底 → 出戰神明（證明「非固定虎爺」）----------

func test_tongji_default_loadout_channels_tiger() -> void:
	var g: GuardianData = RitualLoadout.load_guardian("guardian_luannu")
	var t: RitualToolData = RitualLoadout.load_tool("tool_tiger_token")
	assert_eq(RitualLoadout.resolve_active_deity(g, t), "deity_tiger_god", "乩童預設班底 → 虎爺")

func test_luannu_default_loadout_channels_chenghuang() -> void:
	# 鸞女預設：護壇家將前鋒（城隍 affinity）+ 法器香爐（無 affinity）→ 城隍
	var g: GuardianData = RitualLoadout.load_guardian("guardian_jiajiang_front")
	var t: RitualToolData = RitualLoadout.load_tool("tool_incense_censer")
	assert_eq(RitualLoadout.resolve_active_deity(g, t), "deity_chenghuang", "鸞女預設班底 → 城隍")
	if t != null:
		assert_eq(t.tool_bonus_deity_charge, 3, "香爐請神 +3")

func test_daoshi_default_loadout_channels_mazu() -> void:
	# 道士預設（Phase 2C）：護壇鸞女（媽祖 affinity）+ 法器香爐（無 affinity）→ 媽祖
	var g: GuardianData = RitualLoadout.load_guardian("guardian_luannu")
	var t: RitualToolData = RitualLoadout.load_tool("tool_incense_censer")
	assert_eq(RitualLoadout.resolve_active_deity(g, t), "deity_mazu", "道士預設班底 → 媽祖")

func test_jiajiang_default_loadout_channels_tiger() -> void:
	# 家將預設（Phase 2C）：護壇家將前鋒（城隍 affinity）+ 法器虎牌（虎爺 affinity）→ 虎爺（法器優先）
	var g: GuardianData = RitualLoadout.load_guardian("guardian_jiajiang_front")
	var t: RitualToolData = RitualLoadout.load_tool("tool_tiger_token")
	assert_eq(RitualLoadout.resolve_active_deity(g, t), "deity_tiger_god", "家將預設班底 → 虎爺（法器優先）")

# ---------- 2B-UI：選擇器選項資料驅動 ----------

func test_list_guardian_and_tool_ids() -> void:
	var guardians: Array[String] = RitualLoadout.list_guardian_ids()
	assert_true(guardians.has("guardian_luannu"), "護壇清單應含 guardian_luannu")
	assert_true(guardians.has("guardian_jiajiang_front"), "護壇清單應含 guardian_jiajiang_front")
	var tools: Array[String] = RitualLoadout.list_tool_ids()
	assert_true(tools.has("tool_tiger_token"), "法器清單應含 tool_tiger_token")
	assert_true(tools.has("tool_incense_censer"), "法器清單應含 tool_incense_censer")
	assert_true(tools.size() >= 3, "法器至少 3 件（虎牌/香爐/七星令旗）")
