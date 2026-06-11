# 鎮島錄 Q3-E — 內容型 unlocks 守門（籤詩亭/鐘鼓樓/正殿備援神位；憲龍拍板 2026-06-11）。
extends "res://tests/test_case.gd"

# ---------- 籤詩亭 ----------

func test_fortune_pool_has_five_sticks_with_risk_hedge() -> void:
	var ids: Array[String] = FortuneSticks.list_stick_ids()
	assert_eq(ids.size(), 5, "首發籤池 5 支")
	for sid: String in ids:
		var p: Dictionary = FortuneSticks.load_stick(sid)
		assert_ne(str(p.get("stick_up_text", "")), "", "%s 缺「利」文案" % sid)
		assert_ne(str(p.get("stick_down_text", "")), "", "%s 缺「忌」文案 — 風險對沖型（憲龍拍板）每支必有弊" % sid)
		assert_ne(str(p.get("stick_verse", "")), "", "%s 缺籤文" % sid)

func test_fortune_draw_is_deterministic() -> void:
	var a := RandomNumberGenerator.new(); a.seed = 20260611
	var b := RandomNumberGenerator.new(); b.seed = 20260611
	assert_eq(FortuneSticks.draw_stick_id(a), FortuneSticks.draw_stick_id(b), "同種子同籤（可重現）")

func test_fortune_summary_format() -> void:
	var p: Dictionary = FortuneSticks.load_stick("fortune_mist_road")
	var txt: String = FortuneSticks.stick_summary(p)
	assert_true(txt.contains("霧鎖前路") and txt.contains("利：") and txt.contains("忌："), "摘要含名/利/忌：%s" % txt)

# ---------- 正殿備援神位 ----------

func test_deity_queue_tool_primary_guardian_backup() -> void:
	var g: GuardianData = RitualLoadout.load_guardian("guardian_luannu")		# 親和媽祖
	var t: RitualToolData = RitualLoadout.load_tool("tool_tiger_token")		# 親和虎爺
	var q: Array[String] = RitualLoadout.resolve_deity_queue(g, t, 2)
	assert_eq(q, ["deity_tiger_god", "deity_mazu"] as Array[String], "主=法器親和、備=護壇親和")

func test_deity_queue_falls_back_to_default() -> void:
	var t: RitualToolData = RitualLoadout.load_tool("tool_incense_censer")	# 無親和
	var g: GuardianData = RitualLoadout.load_guardian("guardian_luannu")		# 媽祖 → 主神
	var q: Array[String] = RitualLoadout.resolve_deity_queue(g, t, 2)
	assert_eq(q.size(), 2, "媽祖主神 + DEFAULT 備援")
	assert_eq(q[1], RitualLoadout.DEFAULT_DEITY_ID, "備援退 DEFAULT（虎爺）")

func test_deity_queue_respects_slots() -> void:
	var g: GuardianData = RitualLoadout.load_guardian("guardian_luannu")
	var t: RitualToolData = RitualLoadout.load_tool("tool_tiger_token")
	var q: Array[String] = RitualLoadout.resolve_deity_queue(g, t, 1)
	assert_eq(q.size(), 1, "slots=1（正殿未解鎖）只留主神")

func test_advance_deity_queue_switches_active() -> void:
	Global.run_deity_queue = ["deity_tiger_god", "deity_mazu"] as Array[String]
	Global.run_active_deity_id = "deity_tiger_god"
	var next: String = Global.advance_deity_queue()
	assert_eq(next, "deity_mazu", "釋放後次位接掌")
	assert_eq(Global.run_active_deity_id, "deity_mazu", "active 同步")
	assert_eq(Global.advance_deity_queue(), "", "無更多備援回空")
	Global.run_deity_queue = []

# ---------- 鐘鼓樓 ----------

func test_bell_tower_numbers_live_in_json() -> void:
	var props: Dictionary = RitualTemple.load_building("building_bell_tower")
	assert_true(int(props.get("passive_reveal_floors_lv1", 0)) > 0, "Lv1 揭示層數在 JSON")
	assert_true(int(props.get("passive_first_combat_deity_charge_lv2", 0)) > 0, "Lv2 首戰預充在 JSON")

func test_bell_first_charge_is_once_per_run() -> void:
	Global.run_bell_first_combat_charge = 8
	Global._run_bell_charge_granted = false
	assert_eq(Global.consume_bell_first_charge(), 8, "首戰領取預充")
	assert_eq(Global.consume_bell_first_charge(), 0, "第二戰不再領（單次/趟）")
	Global.run_bell_first_combat_charge = 0
	Global._run_bell_charge_granted = false

func test_fortune_feed_defaults_are_neutral() -> void:
	# 未解鎖/未抽籤時 feed 必須全中性（不影響既有平衡）
	assert_eq(Global.run_fortune_shop_price_mult, 1.0, "商店倍率中性")
	assert_eq(Global.run_fortune_money_gain_mult, 1.0, "銀兩倍率中性")
	assert_eq(Global.run_fortune_post_combat_heal, 0, "戰後回復 0")
	assert_eq(Global.run_fortune_incense_mult, 1.0, "香火倍率中性")
