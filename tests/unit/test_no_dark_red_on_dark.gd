# 鎮島錄 — 設計忠實 P1：WCAG 對比矩陣守門（殲滅「暗紅疊暗紅」的可執行版）。
# 規則（DESIGN_TO_CODE_FIDELITY §5）：大面積漆黑底，文字/邊框一律用燙金/宣紙米/玉青（皆 ≥4.5:1）；
# 硃砂紅 on 漆黑僅 2.23:1，只能當色塊/帶，永不拿來在暗底上寫字。
# tests/ 目錄 i18n 豁免。
extends "res://tests/test_case.gd"

const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

func _rel_lum(c: Color) -> float:
	var ch: Array = [c.r, c.g, c.b]
	for i: int in 3:
		var v: float = ch[i]
		ch[i] = (v / 12.92) if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * ch[0] + 0.7152 * ch[1] + 0.0722 * ch[2]

func _contrast(a: Color, b: Color) -> float:
	var la: float = _rel_lum(a) + 0.05
	var lb: float = _rel_lum(b) + 0.05
	return (la / lb) if la > lb else (lb / la)

func test_brand_text_colors_pass_AA_on_lacquer() -> void:
	var lacquer: Color = THEME.get_color("lacquer_black", Color(0.102, 0.059, 0.051))
	# 暗底文字/邊框允用的品牌色（含既有近似名，皆已對齊 brief）皆須 ≥4.5:1
	for name: String in ["hot_gold", "paper_cream", "jade", "incense_gold", "paper_warm", "spirit_jade"]:
		var c: Color = THEME.get_color(name, Color.WHITE)
		var ratio: float = _contrast(c, lacquer)
		assert_true(ratio >= 4.5, "%s on 漆黑 對比 %.2f < 4.5（暗底文字/邊框違規）" % [name, ratio])

func test_cinnabar_is_block_only_not_text_on_dark() -> void:
	# 硃砂 on 漆黑 故意低對比（2.23）→ 守門確認它「不可」當暗底文字；若被改高表示色值漂移
	var lacquer: Color = THEME.get_color("lacquer_black", Color(0.102, 0.059, 0.051))
	var cinnabar: Color = THEME.get_color("cinnabar", Color(0.557, 0.165, 0.110))
	assert_true(_contrast(cinnabar, lacquer) < 4.5, "硃砂 on 漆黑 應 <4.5（只當色塊/帶，不寫字）")

func test_brief_core_tokens_present_and_exact() -> void:
	# brief 正典五色須在 token 檔且值精確（design_tokens.json SSOT）
	var want: Dictionary = {"cinnabar": "8e2a1c", "hot_gold": "e8c46a", "paper_cream": "f0e4c8", "jade": "46c99a"}
	for name: String in want:
		var got: String = THEME.get_color(name, Color.BLACK).to_html(false)
		assert_eq(got, want[name], "%s token 值應為 #%s，實得 #%s" % [name, want[name], got])
