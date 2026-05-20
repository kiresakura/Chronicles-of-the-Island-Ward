extends "res://tests/test_case.gd"

const UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

func test_ui_theme_returns_design_token_color() -> void:
	var expected: Color = Color.from_string("#A62F1F", Color.BLACK)
	assert_eq(UI_THEME.get_color("temple_red", Color.BLACK), expected,
		"theme helper 應從 design_tokens.json 讀到 temple_red")

func test_ui_theme_card_rarity_maps_to_frame_asset() -> void:
	var path: String = UI_THEME.get_card_frame_path(CardData.CARD_RARITIES.UNCOMMON)
	assert_eq(path, "res://assets/ui/frames/ui_frame_card_uncommon_default.svg",
		"UNCOMMON 應映射到對應卡框")
	assert_true(ResourceLoader.exists(path), "映射出的卡框資產必須存在")

func test_ui_theme_location_type_maps_to_node_asset() -> void:
	var path: String = UI_THEME.get_map_node_path(LocationData.LOCATION_TYPES.SHOP)
	assert_eq(path, "res://assets/generated/icons/map_nodes/node_shop.svg",
		"SHOP 節點應映射到 v2 商店節點資產（Recraft 像素）")
	assert_true(ResourceLoader.exists(path), "映射出的地圖節點資產必須存在")

func test_ui_theme_mobile_safe_prefers_mobile_variant() -> void:
	var source: String = "assets/generated/cards/card_tongji_punch_art_v1.png"
	var resolved: String = UI_THEME.get_mobile_safe_card_art_path(source)
	assert_eq(resolved,
		"res://assets/generated/cards/mobile_safe/card_tongji_punch_mobile_safe_v1.png",
		"若 mobile-safe 存在，應優先回傳 mobile-safe 卡圖")

func test_ui_theme_mobile_safe_falls_back_to_original_path() -> void:
	var source: String = "assets/generated/cards/nonexistent_card_art_v1.png"
	var resolved: String = UI_THEME.get_mobile_safe_card_art_path(source)
	assert_eq(resolved, "res://assets/generated/cards/nonexistent_card_art_v1.png",
		"找不到 mobile-safe 對應圖時，應回原始路徑")

func test_ui_theme_location_short_label_is_compact() -> void:
	assert_eq(UI_THEME.get_location_short_label(LocationData.LOCATION_TYPES.MINIBOSS), "菁",
		"地圖節點短標籤應符合 mobile-first 小尺寸需求")

## 2026-05-19 新增的 7 個語意 token 必須可讀，防止下游引用時打錯 token 名
func test_ui_theme_new_semantic_tokens_resolve() -> void:
	for token: String in [
			"panel_bg", "panel_bg_hover", "panel_bg_lock",
			"text_shadow_strong", "text_shadow_soft",
			"boot_splash_red", "disabled_tint"]:
		var sentinel := Color(0.12345, 0.67890, 0.13579, 0.97531)
		var c: Color = UI_THEME.get_color(token, sentinel)
		assert_ne(c, sentinel,
			"token %s 必須能從 design_tokens.json 讀到（避免下游 get_color 拿回 fallback）" % token)

## 戰鬥 HUD 語意色 token 必須存在（Combat._combat_label 依賴）
func test_ui_theme_combat_semantic_tokens_resolve() -> void:
	for token: String in ["incense_gold", "hp_red", "energy_cyan", "armor_gold"]:
		var sentinel := Color(0.99876, 0.54321, 0.13579, 0.86420)
		var c: Color = UI_THEME.get_color(token, sentinel)
		assert_ne(c, sentinel, "戰鬥 HUD 語意 token %s 必須存在" % token)

## focus 樣式必須回傳有邊框的 StyleBoxFlat（不可被當預設用 StyleBoxEmpty 替）
func test_ui_theme_make_focus_stylebox_has_border() -> void:
	var sb: StyleBoxFlat = UI_THEME.make_focus_stylebox()
	assert_not_null(sb, "make_focus_stylebox 應回傳 StyleBoxFlat")
	if sb != null:
		assert_true(sb.border_width_left > 0, "focus 樣式 border 寬必須 > 0（玩家要看得到 focus ring）")
		assert_true(sb.corner_radius_top_left > 0, "focus 樣式應有圓角")

## apply_panel_style 後 Panel 必須拿到 stylebox，且圓角/邊框讀自 tokens.radii/borders
func test_ui_theme_apply_panel_style_sets_stylebox() -> void:
	var p: Panel = Panel.new()
	UI_THEME.apply_panel_style(p)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel", "Panel") as StyleBoxFlat
	assert_not_null(sb, "apply_panel_style 必須設定 panel stylebox")
	if sb != null:
		# tokens.radii.lg=16 / borders.strong=3（design_tokens.json）
		assert_eq(sb.corner_radius_top_left, 16, "Panel 圓角應為 radii.lg=16")
		assert_eq(sb.border_width_left, 3, "Panel 邊框寬應為 borders.strong=3")
	p.queue_free()

## apply_tooltip_style 後文字色為 paper_warm、stylebox 圓角=radii.md=12
func test_ui_theme_apply_tooltip_style_sets_text_and_box() -> void:
	var p: Panel = Panel.new()
	UI_THEME.apply_tooltip_style(p)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel", "Panel") as StyleBoxFlat
	assert_not_null(sb, "apply_tooltip_style 必須設定 panel stylebox")
	if sb != null:
		assert_eq(sb.corner_radius_top_left, 12, "Tooltip 圓角應為 radii.md=12")
	var text_color: Color = p.get_theme_color("font_color", "Panel")
	var paper_warm: Color = UI_THEME.get_color("paper_warm", Color.BLACK)
	assert_eq(text_color, paper_warm, "Tooltip 文字色應為 paper_warm token")
	p.queue_free()

func test_ui_theme_panel_assets_exist() -> void:
	var reward_panel: String = UI_THEME.get_panel_asset_path("reward")
	var shop_panel: String = UI_THEME.get_panel_asset_path("shop")
	var rest_panel: String = UI_THEME.get_panel_asset_path("rest")
	assert_eq(reward_panel, "res://assets/ui/panels/ui_panel_reward_choice_default.svg")
	assert_eq(shop_panel, "res://assets/ui/panels/ui_panel_shop_item_default.svg")
	assert_eq(rest_panel, "res://assets/ui/panels/ui_panel_rest_action_default.svg")
	assert_true(ResourceLoader.exists(reward_panel), "reward panel 資產必須存在")
	assert_true(ResourceLoader.exists(shop_panel), "shop panel 資產必須存在")
	assert_true(ResourceLoader.exists(rest_panel), "rest panel 資產必須存在")
