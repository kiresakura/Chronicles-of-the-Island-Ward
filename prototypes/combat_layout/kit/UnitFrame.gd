class_name CmbUnitFrame
extends VBoxContainer
## 戰鬥單位名牌 kit：名稱＋意圖＋資源條（敵：元神+煞盾+意圖；我：元神）。組合 CmbResourceBar。
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

func setup_enemy(unit_name: String, hp: float, hp_max: float, ward: float, ward_max: float, intent: String) -> CmbUnitFrame:
	_header(unit_name, intent)
	add_child(CmbResourceBar.new().setup("元神", "hp", hp, hp_max))
	if ward_max > 0.0:
		add_child(CmbResourceBar.new().setup("煞盾", "ward", ward, ward_max))
	return self

func setup_player(unit_name: String, hp: float, hp_max: float) -> CmbUnitFrame:
	_header(unit_name, "")
	add_child(CmbResourceBar.new().setup("元神", "hp", hp, hp_max))
	return self

func _header(unit_name: String, intent: String) -> void:
	add_theme_constant_override("separation", maxi(4, THEME.get_spacing("xs", 8) / 2))
	var head := HBoxContainer.new()
	var nm := Label.new()
	nm.add_theme_font_size_override("font_size", THEME.get_typography_size("h2", 28))
	nm.add_theme_color_override("font_color", THEME.get_color("hot_gold"))
	nm.text = unit_name
	head.add_child(nm)
	if intent != "":
		var sp := Control.new(); sp.size_flags_horizontal = SIZE_EXPAND_FILL; head.add_child(sp)
		var it := Label.new()
		it.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
		it.add_theme_color_override("font_color", THEME.get_color("festival_red"))
		it.text = "⚔ " + intent
		head.add_child(it)
	add_child(head)
