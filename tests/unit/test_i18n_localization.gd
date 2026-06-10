# 鎮島錄 — zh_TW 本地化靜態守門測試（i18n）。
# 掃描正式 runtime UI（Root.tscn + prefab placeholder）的 text= / tooltip_text=，
# 禁止裸英文出現在 zh_TW 介面。允許：刻意品牌英文副標、節點/類別名、debug/test/qa（不在清單內）。
# 對應 assets/translations/cotiw_main.csv 的 key-based i18n。
extends "res://tests/test_case.gd"

# zh_TW 模式下不允許出現在正式 UI 文字的裸英文（work order 指定清單）
const BANNED: Array = [
	"HP", "Turn", "Victory", "Defeat", "Back To Main Menu",
	"Pick X Cards", "Pick %d Cards", "Exhaust Pile", "Leave",
	"Card Reward", "Reward 1", "Reward", "Artifact Name", "Consumable Name",
	"Rest Action", "Run Name", "Money %s", "Pick X cards", "Description",
	"<----",
]
# 刻意保留的品牌英文副標（明確允許，不視為漏本地化）
const ALLOWED_BRAND: Array = ["Chronicles of the Island Ward"]

# 正式 UI 掃描清單（boot→主畫面→起手→地圖→戰鬥→商店→獎勵→結算 涉及的 scene / prefab placeholder）
const SCAN_FILES: Array = [
	"res://scenes/Root.tscn",
	"res://scenes/combatants/Enemy.tscn",
	"res://scenes/combatants/fades/TextFade.tscn",
	"res://scenes/ui/CustomRunModifierCheckbox.tscn",
	"res://scenes/ui/RestActionButton.tscn",
	"res://scenes/ui/general/KeywordTooltip.tscn",
	"res://scenes/ui/rewards/BaseRewardButton.tscn",
	"res://scenes/ui/rewards/MoneyRewardButton.tscn",
	"res://scenes/ui/rewards/CardRewardButton.tscn",
	"res://scenes/ui/rewards/ArtifactRewardButton.tscn",
	"res://scenes/ui/shop/CardDraftShopButton.tscn",
	"res://scenes/ui/shop/ArtifactShopButton.tscn",
	"res://scenes/ui/shop/ConsumableShopButton.tscn",
	"res://scenes/ui/shop/CardRemovalShopButton.tscn",
]

const REQUIRED_KEYS: Array = [
	"ui.level", "ui.leave", "ui.back_to_main_menu", "ui.skip", "ui.pick_x_cards", "ui.reward",
	"battle.turn_count", "battle.victory", "battle.defeat", "battle.exhaust_pile",
	"reward.card", "reward.money", "shop.artifact_placeholder",
	"shop.consumable_placeholder", "run.rest_action", "keyword.boss", "keyword.hp_short",
	"ui.back",
]

const SENTINEL: String = "￿"	# 表「此行非 text 賦值」

## 取 text = "..." 或 tooltip_text = "..." 內的字串值；非該類賦值回 SENTINEL。
func _extract_text_value(line: String) -> String:
	var key_idx: int = -1
	for prefix: String in ["tooltip_text = \"", "text = \""]:
		var i: int = line.find(prefix)
		if i != -1:
			key_idx = i + prefix.length()
			break
	if key_idx == -1:
		return SENTINEL
	var end: int = line.find("\"", key_idx)
	if end == -1:
		return SENTINEL
	return line.substr(key_idx, end - key_idx)

func _is_banned(val: String) -> bool:
	if val in ALLOWED_BRAND:
		return false
	for banned: String in BANNED:
		if val == banned or val == banned + " 1" \
				or val.begins_with(banned + " ") or val.begins_with(banned + ":") \
				or val.begins_with(banned + "  "):
			return true
	return false

func test_runtime_ui_no_bare_english() -> void:
	var violations: Array = []
	var scanned: int = 0
	for path: String in SCAN_FILES:
		if not FileAccess.file_exists(path):
			continue
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		scanned += 1
		while not f.eof_reached():
			var line: String = f.get_line()
			var stripped: String = line.strip_edges()
			if stripped.begins_with("#") or stripped.begins_with(";"):
				continue
			var val: String = _extract_text_value(line)
			if val == SENTINEL:
				continue
			if _is_banned(val):
				violations.append("%s → \"%s\"" % [path.get_file(), val])
	assert_true(scanned > 0, "應至少掃描到一個正式 UI 檔")
	assert_true(violations.is_empty(), "zh_TW 正式 UI 出現裸英文（應走 i18n key）：%s" % str(violations))

func test_translation_csv_has_required_keys() -> void:
	var path: String = "res://assets/translations/cotiw_main.csv"
	assert_true(FileAccess.file_exists(path), "翻譯 CSV 應存在")
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var key_to_zhtw: Dictionary = {}
	var header_skipped: bool = false
	while not f.eof_reached():
		var line: String = f.get_line()
		if not header_skipped:
			header_skipped = true
			continue
		if line.strip_edges() == "":
			continue
		var cols: PackedStringArray = line.split(",")
		if cols.size() >= 2:
			key_to_zhtw[cols[0]] = cols[1]
	for k: String in REQUIRED_KEYS:
		assert_true(key_to_zhtw.has(k), "CSV 應含必要 key：%s" % k)
		assert_true(str(key_to_zhtw.get(k, "")).strip_edges() != "", "zh_TW 不得為空：%s" % k)

## 銜接旗：確認 tr() 在 zh_TW 下真的回中文（i18n 架構已接上，非只擺著翻譯檔）。
func test_translation_server_resolves_zhtw() -> void:
	var prev: String = TranslationServer.get_locale()
	TranslationServer.set_locale("zh_TW")
	assert_eq(TranslationServer.translate("battle.victory"), "鎮煞成功", "zh_TW battle.victory 應翻成鎮煞成功")
	assert_eq(TranslationServer.translate("ui.leave"), "離開", "zh_TW ui.leave 應翻成離開")
	assert_eq(TranslationServer.translate("keyword.hp_short"), "元神", "zh_TW keyword.hp_short 應翻成元神")
	assert_eq(TranslationServer.translate("ui.back"), "返回", "zh_TW ui.back 應翻成返回")
	TranslationServer.set_locale(prev)
