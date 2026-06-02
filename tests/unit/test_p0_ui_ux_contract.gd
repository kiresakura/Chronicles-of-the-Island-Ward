extends "res://tests/test_case.gd"

const COMBAT_HUD := preload("res://scripts/ui/theme/CombatHudOverlay.gd")
const UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const LOBBY_ACTIONS_PATH := "res://external/data/ui/lobby_actions.json"

func _load_json_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "測試資料必須可讀：%s" % path)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Array, "JSON 必須是陣列：%s" % path)
	if parsed is Array:
		return parsed
	return []

func test_lobby_p0_has_single_primary_run_action_without_battle_label() -> void:
	var actions := _load_json_array(LOBBY_ACTIONS_PATH)
	var run_actions: Array = []
	for action: Dictionary in actions:
		if str(action.get("act", "")) == "run":
			run_actions.append(action)
		assert_ne(str(action.get("label", "")), "戰鬥", "P0 主畫面不可把主入口命名成戰鬥，避免主畫面混入戰鬥語意")
	assert_eq(run_actions.size(), 1, "P0 主畫面只能有一個 run 主入口，其他功能降權")
	if not run_actions.is_empty():
		assert_eq(str(run_actions[0].get("label", "")), "新局", "run 入口應是新局/起駕語意，不是戰鬥 HUD 語意")
		assert_eq(str(run_actions[0].get("priority", "")), "high", "run 入口必須標記 high priority，供 layout 做高頻/低頻分層")

func test_lobby_p0_actions_are_grouped_by_frequency() -> void:
	var actions := _load_json_array(LOBBY_ACTIONS_PATH)
	var high_count := 0
	var low_count := 0
	for action: Dictionary in actions:
		match str(action.get("priority", "")):
			"high":
				high_count += 1
			"low":
				low_count += 1
			_:
				_fail("每個 lobby action 都必須標記 priority=high/low：%s" % str(action))
	assert_eq(high_count, 3, "P0 高頻入口應固定三個：角色/新局/收藏")
	assert_eq(low_count, 3, "P0 低頻入口應固定三個：陣型/商店/招募")

func test_combat_hud_incoming_damage_label_is_not_hostility() -> void:
	var state := {
		"energy": 3,
		"energy_max": 3,
		"health": 50,
		"health_max": 50,
		"block": 0,
		"incoming_damage": 15,
		"deity_affinity": [],
	}
	var strip: Control = COMBAT_HUD._make_status_strip(state)
	assert_not_null(strip.get_node_or_null("PriorityPill_預兆"), "incoming damage 應標成預兆/將傷，不可叫敵意造成誤解")
	assert_eq(strip.get_meta("hud_priority_layer"), "L1", "玩家 HP/護身符/敵方預兆屬於 L1 立即決策資訊")
	strip.queue_free()

func test_ui_theme_exposes_p0_semantic_and_motion_tokens() -> void:
	for semantic_name: String in ["primary_action", "available_path", "sacred_reward", "danger_choice", "disabled_or_locked"]:
		var semantic: Dictionary = UI_THEME.get_semantic_role(semantic_name)
		assert_true(not semantic.is_empty(), "P0 semantic role 必須存在：%s" % semantic_name)
		assert_true(semantic.has("fill") or semantic.has("accent"), "semantic role 必須提供 fill/accent 用於一致決策：%s" % semantic_name)

	assert_eq(UI_THEME.get_motion_duration("tap_press_ms", 0), 100, "tap press motion token 應固定在 80-120ms 中央值")
	assert_eq(UI_THEME.get_motion_duration("screen_transition_ms", 0), 420, "screen transition 應低於 500ms，符合碎片遊玩節奏")

func test_card_type_accent_uses_cotiw_semantic_palette() -> void:
	assert_eq(UI_THEME.get_card_type_accent(CardData.CARD_TYPES.ATTACK), UI_THEME.get_color("festival_red"), "攻擊卡應用 festival_red，不要硬編孤立紅色")
	assert_eq(UI_THEME.get_card_type_accent(CardData.CARD_TYPES.SKILL), UI_THEME.get_color("spirit_jade"), "技能卡應用 spirit_jade")
	assert_eq(UI_THEME.get_card_type_accent(CardData.CARD_TYPES.POWER), UI_THEME.get_color("sign_blue"), "能力卡應用 sign_blue")
	assert_eq(UI_THEME.get_card_type_accent(CardData.CARD_TYPES.CURSE), UI_THEME.get_color("mystic_purple"), "詛咒/咒術卡應用 mystic_purple")
