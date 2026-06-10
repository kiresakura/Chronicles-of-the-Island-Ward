# 鎮島錄 — 起手賜禮卡池守門（UIQA P1-4）。
# 媽祖賜禮曾從 card_pack_white 漏出 STR 無色工具卡（無卡圖 legacy）；
# 此測試釘住：colorless 起手選項必須走驗證型 draft（玩家卡池 ∩ 稀有度），不得再掛卡包。
extends "res://tests/test_case.gd"

func test_colorless_boon_uses_validator_draft_not_white_pack() -> void:
	var rod: RunStartOptionData = Global._id_to_run_start_option_data.get("run_start_option_draft_colorless_card", null)
	assert_not_null(rod, "colorless 起手選項應已註冊")
	if rod == null:
		return
	assert_true(rod.run_start_option_actions.size() > 0, "應有 action")
	var action_config: Dictionary = rod.run_start_option_actions[0].get(Scripts.ACTION_PICK_CARDS, {})
	assert_false(action_config.has("draft_card_pack_id"), "不得再使用 card_pack_white 卡包路徑（legacy 污染源）")
	var validators: Array = action_config.get("validator_data", [])
	assert_true(validators.size() >= 2, "應有稀有度 + 玩家卡池 validator")
	var has_draftable: bool = false
	for v: Variant in validators:
		if (v as Dictionary).has(Scripts.VALIDATOR_CARD_DRAFTABLE):
			has_draftable = true
	assert_true(has_draftable, "必須含 VALIDATOR_CARD_DRAFTABLE（玩家角色卡池快取過濾）")

func test_active_prefix_cards_have_texture() -> void:
	# 防回歸：玩家可抽到的卡（active prefixes）都應有卡圖路徑（不再出 Godot icon 卡）
	var prefixes: Array = ["card_tongji_", "card_luannu_", "card_daoshi_", "card_jiajiang_"]
	var missing: Array = []
	for card_id: String in Global._id_to_card_data.keys():
		for p: String in prefixes:
			if str(card_id).begins_with(p):
				var cd: CardData = Global.get_card_data(card_id)
				if cd != null and str(cd.card_texture_path).strip_edges() == "":
					missing.append(card_id)
	assert_true(missing.is_empty(), "active 卡缺卡圖：%s" % str(missing))

func test_zh_event_lines_use_canonical_terms() -> void:
	# UIQA P1-3 防回歸：中文事件台詞不得用「金錢」（應為銀兩）或裸「HP」（應為元神）
	var f: FileAccess = FileAccess.open("res://autoload/Global.gd", FileAccess.READ)
	assert_not_null(f, "Global.gd 應可讀")
	if f == null:
		return
	var bad: Array = []
	var line_no: int = 0
	while not f.eof_reached():
		var line: String = f.get_line()
		line_no += 1
		# 只掃含中文的 bbcode/prompt 行（避開英文 STR 測試事件）
		if not (line.contains("bbcode") and line.contains("「") or line.contains("bbcode = \"")):
			continue
		var has_zh: bool = false
		for ch in ["廟", "山", "香", "婆", "神", "祭", "供"]:
			if line.contains(ch):
				has_zh = true
				break
		if not has_zh:
			continue
		if line.contains("金錢"):
			bad.append("L%d 金錢" % line_no)
		if line.contains(" HP"):
			bad.append("L%d HP" % line_no)
	assert_true(bad.is_empty(), "中文事件台詞含舊術語：%s" % str(bad))
