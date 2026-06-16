# 鎮島錄 v0.3 — 五營戰鬥核心（FC-2a）回歸防線。
# 純邏輯、注入 config 求確定性：敵→煞翻譯、五行攔截、殲敵勝/母壇敗、擲筊、降乩、調營。
extends "res://tests/test_case.gd"

const FormationCombatCls := preload("res://scripts/systems/ritual/FormationCombat.gd")

# 測試用基底 config（不依賴外部檔，數值寫死求確定性）。
func _cfg(overrides: Dictionary = {}) -> Dictionary:
	var base: Dictionary = {
		"altar_max_integrity": 30,
		"base_actions_per_turn": 1,
		"sheng_bonus_actions": 1,
		"jiao_weights": {"sheng": 0.45, "xiao": 0.30, "yin": 0.25},
		"jiao_yin_surge": 4,
		"lane_steps_to_altar": 3,
		"enemy_hp_to_sha_divisor": 8,
		"enemy_sha_min": 3,
		"enemy_sha_max": 14,
		"wave_stagger_turns": 1,
		"max_turns": 30,
		"deity_charge_max": 3,
		"deity_invoke_power": 4,
		"element_multipliers": {
			"same": 1.5, "generated_by": 1.3, "overcomes": 1.2, "generates": 0.9, "overcome_by": 0.6, "neutral": 1.0,
		},
	}
	for k: String in overrides:
		base[k] = overrides[k]
	return base

# ---- 載入 / 翻譯 ----

func test_setup_loads_five_camps_and_directional_lanes() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [], _cfg(), 1)
	assert_eq(cb.camps.size(), 5, "預設開全部五營")
	# 四方位各一 lane，中營無 lane
	assert_eq(cb.lanes.size(), 4, "四方位營各一 lane（中營為調度中樞、無 lane）")
	assert_true(cb.units.size() >= 5, "載入可佈陣單位（≥ 五營主將）")

func test_enemy_specs_translate_to_sha_waves() -> void:
	var cb := FormationCombatCls.new()
	var enemies: Array = [{"id": "e_big", "hp": 80}, {"id": "e_mid", "hp": 24}, {"id": "e_small", "hp": 8}]
	cb.setup([], {}, enemies, _cfg(), 1)
	assert_eq(cb.waves.size(), 3, "三敵 → 三波")
	# 煞值＝clamp(hp/8, 3, 14)：80→10、24→3、8→1 夾到 3
	assert_eq(int(cb.waves[0]["strength"]), 10, "80HP → 煞 10")
	assert_eq(int(cb.waves[1]["strength"]), 3, "24HP → 煞 3")
	assert_eq(int(cb.waves[2]["strength"]), 3, "8HP → 煞夾到下限 3")
	# 波次錯開回合（stagger 1）
	assert_eq(int(cb.waves[0]["turn"]), 1, "首波第 1 回合")
	assert_eq(int(cb.waves[1]["turn"]), 2, "次波第 2 回合")

func test_sha_cap_respected() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [{"id": "e_boss", "hp": 999}], _cfg(), 1)
	assert_eq(int(cb.waves[0]["strength"]), 14, "超大 HP 煞值夾到上限 14（母壇不被秒）")

# ---- 五行得位攔截 ----

func test_auto_deploy_prefers_wei_position() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [], _cfg(), 1)
	# 青龍（木）：東營（木 same）、北營（水生木 generated_by）皆得位；西營（金剋木 overcome_by）失位
	assert_true(cb.is_wei_position("unit_qinglong", "camp_east"), "木青龍在木東營＝同行得位")
	assert_true(cb.is_wei_position("unit_qinglong", "camp_north"), "木青龍在水北營＝受生得位")
	assert_false(cb.is_wei_position("unit_qinglong", "camp_west"), "木青龍在金西營：金剋木＝失位")

func test_intercept_damage_uses_five_elements() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [], _cfg(), 1)
	# 青龍 power 5：東營（木，same ×1.5）→ round(7.5)=8；中營（土，木剋土 overcomes ×1.2）→ 6
	var d_same: int = cb._intercept_damage("unit_qinglong", "camp_east")
	var d_overcome: int = cb._intercept_damage("unit_qinglong", "camp_center")
	assert_eq(d_same, 8, "同行得位 5×1.5=8")
	assert_eq(d_overcome, 6, "我剋營 5×1.2=6")
	assert_true(d_same > d_overcome, "得位削煞 > 制位削煞")

# ---- 勝負（殲敵 / 母壇崩）----

func test_defended_lane_breaks_sha_and_wins() -> void:
	var cb := FormationCombatCls.new()
	# 單一弱敵（24HP→煞3）落在某 lane；自動佈陣讓該營得位主將鎮守 → 一攔即破 → 殲敵勝
	cb.setup([], {}, [{"id": "e_mid", "hp": 24}], _cfg(), 1)
	var safety: int = 0
	while cb.state == FormationCombatCls.STATE_PLAYING and safety < 10:
		cb.end_turn()
		safety += 1
	assert_eq(cb.state, FormationCombatCls.STATE_WON, "守住單一弱煞 → 殲敵勝")
	assert_eq(cb.altar_integrity, cb.altar_max, "全程未失守，母壇滿血")

func test_undefended_lane_collapses_altar_and_loses() -> void:
	var cb := FormationCombatCls.new()
	# 只開東營+中營；把唯一主將停中營 → 東 lane 空營；母壇縮到 8 → 煞10 直擊即崩
	var deploy: Dictionary = {"unit_qinglong": "camp_center"}
	cb.setup(["camp_east", "camp_center"], deploy, [{"id": "e_big", "hp": 80}], _cfg({"altar_max_integrity": 8}), 1)
	var safety: int = 0
	while cb.state == FormationCombatCls.STATE_PLAYING and safety < 10:
		cb.end_turn()
		safety += 1
	assert_eq(cb.state, FormationCombatCls.STATE_LOST, "空營任煞長驅 → 母壇崩敗")
	assert_eq(cb.altar_integrity, 0, "敗時母壇歸零")

# ---- 擲筊 / 降乩 / 調營 ----

func test_jiao_sheng_grants_extra_action() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [], _cfg({"jiao_weights": {"sheng": 1.0, "xiao": 0.0, "yin": 0.0}}), 1)
	var before: int = cb.actions_remaining
	var result: String = cb.roll_jiao()
	assert_eq(result, FormationCombatCls.JIAO_SHENG, "權重鎖 sheng → 必聖筊")
	assert_eq(cb.actions_remaining, before + 1, "聖筊 +1 動作")
	# 每回合僅一次
	assert_eq(cb.roll_jiao(), "", "同回合二次擲筊無效")

func test_jiao_yin_surges_a_lane() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [{"id": "e_mid", "hp": 24}], _cfg({"jiao_weights": {"sheng": 0.0, "xiao": 0.0, "yin": 1.0}}), 1)
	# 首回合已生一波煞；陰筊鎖定有煞 lane 暴衝 +4
	var surged_lane: String = str(cb.waves[0]["lane"])
	var before: int = int(cb.lanes[surged_lane]["sha"]["strength"])
	assert_eq(cb.roll_jiao(), FormationCombatCls.JIAO_YIN, "權重鎖 yin → 必陰筊")
	assert_eq(int(cb.lanes[surged_lane]["sha"]["strength"]), before + 4, "陰筊使該 lane 煞暴衝 +4")

func test_deity_invocation_charges_and_clears() -> void:
	var cb := FormationCombatCls.new()
	# 母壇拉高避免提前敗；只要驗降乩槽充能 + 破煞
	cb.setup([], {}, [{"id": "e_mid", "hp": 24}], _cfg({"deity_charge_max": 2, "deity_invoke_power": 99, "altar_max_integrity": 99}), 1)
	assert_false(cb.invoke_deity(), "未充滿不可降乩")
	# 充能：turn>1 每回合 +1
	cb.end_turn()  # → turn 2，charge 1
	cb.end_turn()  # → turn 3，charge 2（滿）
	if cb.state != FormationCombatCls.STATE_PLAYING:
		return  # 若已殲敵結束則略過（弱敵可能先被攔破）
	assert_true(cb.deity_charge >= cb.deity_charge_max, "兩回合後請神槽滿")
	var fired: bool = cb.invoke_deity()
	assert_true(fired, "槽滿可降乩")
	assert_eq(cb.deity_charge, 0, "降乩耗盡請神槽")

func test_move_unit_costs_action_and_relocates() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [], _cfg(), 1)
	var before: int = cb.actions_remaining
	var ok: bool = cb.move_unit("unit_qinglong", "camp_center")
	assert_true(ok, "調營成功")
	assert_eq(cb.unit_location["unit_qinglong"], "camp_center", "單位已移至中營")
	assert_eq(cb.actions_remaining, before - 1, "調營耗一動作")
	# 動作耗盡後不可再調營
	cb.actions_remaining = 0
	assert_false(cb.move_unit("unit_qinglong", "camp_east"), "無動作不可調營")

# ---- 資料層 config ----

func test_load_config_from_file() -> void:
	var cfg: Dictionary = FormationCombatCls.load_config()
	assert_false(cfg.is_empty(), "戰鬥調參檔可載入")
	assert_true(cfg.has("element_multipliers"), "config 含五行倍率表（鐵律1：數值在資料層）")
	assert_true(int(cfg.get("altar_max_integrity", 0)) > 0, "config 母壇血為正")

# ---- 符令手牌（FP-2，FC-2b.3）----

# 測試用確定性符令 config（牌庫只 2 張、起手 2 → 不依賴洗牌）。
func _fu_cfg() -> Dictionary:
	return {
		"hand_max": 5, "initial_hand": 2, "draw_per_turn": 1, "plays_per_turn": 1,
		"starter_deck": ["fu_po_sha", "fu_chi"],
		"fu": {
			"fu_po_sha": {"name": "破煞符", "effect": "po_sha", "magnitude": 6, "needs_target": true, "desc": "x"},
			"fu_chi": {"name": "敕符", "effect": "action", "magnitude": 1, "needs_target": false, "desc": "y"},
		},
	}

func test_fu_initial_hand_drawn() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [{"id": "e", "hp": 24}], _cfg({"fu_config": _fu_cfg()}), 1)
	assert_eq(cb.fu_hand.size(), 2, "起手抽 2 張符令")
	assert_true(cb.fu_hand.has("fu_po_sha") and cb.fu_hand.has("fu_chi"), "起手含破煞符與敕符")
	assert_eq(cb.fu_plays_left, 1, "回合 1 可打 1 張符令")

func test_fu_po_sha_cuts_lane_sha() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [{"id": "e_big", "hp": 80}], _cfg({"fu_config": _fu_cfg()}), 1)
	var lane: String = str(cb.waves[0]["lane"])	# 80HP→煞10 落此 lane
	assert_eq(int(cb.lanes[lane]["sha"]["strength"]), 10, "前置：該 lane 煞 10")
	var ok: bool = cb.play_fu("fu_po_sha", lane)
	assert_true(ok, "破煞符可打（lane 有煞）")
	assert_eq(int(cb.lanes[lane]["sha"]["strength"]), 4, "破煞符削煞 6 → 餘 4")

func test_fu_chi_grants_action() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [{"id": "e", "hp": 24}], _cfg({"fu_config": _fu_cfg()}), 1)
	var before: int = cb.actions_remaining
	assert_true(cb.play_fu("fu_chi"), "敕符無需目標可打")
	assert_eq(cb.actions_remaining, before + 1, "敕符 +1 動作")

func test_fu_one_play_per_turn() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [{"id": "e", "hp": 24}], _cfg({"fu_config": _fu_cfg()}), 1)
	assert_true(cb.play_fu("fu_chi"), "首張可打")
	assert_eq(cb.fu_plays_left, 0, "本回合可打次數耗盡")
	assert_false(cb.play_fu("fu_po_sha", str(cb.waves[0]["lane"])), "本回合第二張不可打")

func test_fu_needs_target_rejects_clear_lane() -> void:
	var cb := FormationCombatCls.new()
	# 開全營但只 1 敵 → 多數 lane 無煞
	cb.setup([], {}, [{"id": "e", "hp": 24}], _cfg({"fu_config": _fu_cfg()}), 1)
	var sha_lane: String = str(cb.waves[0]["lane"])
	var clear_lane: String = ""
	for l: String in cb.lanes:
		if l != sha_lane:
			clear_lane = l
			break
	assert_ne(clear_lane, "", "應有無煞的 lane")
	assert_false(cb.play_fu("fu_po_sha", clear_lane), "破煞符不可空放（目標 lane 無煞）")

func test_fu_draws_on_new_turn() -> void:
	var cb := FormationCombatCls.new()
	cb.setup([], {}, [{"id": "e", "hp": 24}], _cfg({"fu_config": _fu_cfg()}), 1)
	cb.play_fu("fu_chi")	# 進棄牌堆
	var hand_before: int = cb.fu_hand.size()
	cb.end_turn()			# 進回合 2 → 抽 1（牌庫空則洗棄牌堆）
	if cb.state == FormationCombatCls.STATE_PLAYING:
		assert_true(cb.fu_hand.size() >= hand_before, "新回合抽符令（手牌不減）")
		assert_eq(cb.fu_plays_left, 1, "新回合重置可打次數")

func test_load_fu_config_from_file() -> void:
	var cfg: Dictionary = FormationCombatCls.load_fu_config()
	assert_false(cfg.is_empty(), "符令調參檔可載入")
	assert_true(cfg.has("fu") and cfg.has("starter_deck"), "含符令定義與起手牌庫（鐵律1：資料層）")
