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
	assert_eq(path, "res://assets/generated/icons/map_nodes_v2/node_shop_anime.svg",
		"SHOP 節點應映射到 v2 動漫化地標節點資產（古錢/香油錢牌）")
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
	assert_eq(UI_THEME.get_location_short_label(LocationData.LOCATION_TYPES.MINIBOSS), "惡",
		"地圖節點短標籤走民俗語彙（Q2-A：惡煞據點）")
	assert_eq(UI_THEME.get_location_short_label(LocationData.LOCATION_TYPES.BOSS), "醮",
		"Boss 短標應為鎮煞大醮的「醮」")

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
		assert_eq(sb.corner_radius_top_left, 0, "P0-2 像素化：focus 樣式必須硬邊零圓角")

## apply_panel_style 後 Panel 必須拿到 stylebox，且圓角/邊框讀自 tokens.radii/borders
func test_ui_theme_apply_panel_style_sets_stylebox() -> void:
	var p: Panel = Panel.new()
	UI_THEME.apply_panel_style(p)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel", "Panel") as StyleBoxFlat
	assert_not_null(sb, "apply_panel_style 必須設定 panel stylebox")
	if sb != null:
		# P0-2 像素化：tokens.radii 全歸零（borders.strong=3 不變）
		assert_eq(sb.corner_radius_top_left, 0, "P0-2 像素化：Panel 圓角必須為 0（radii.lg 已歸零）")
		assert_eq(sb.border_width_left, 3, "Panel 邊框寬應為 borders.strong=3")
	p.queue_free()

## apply_tooltip_style 後文字色為 paper_warm、stylebox 圓角=0（P0-2 像素化）
func test_ui_theme_apply_tooltip_style_sets_text_and_box() -> void:
	var p: Panel = Panel.new()
	UI_THEME.apply_tooltip_style(p)
	var sb: StyleBoxFlat = p.get_theme_stylebox("panel", "Panel") as StyleBoxFlat
	assert_not_null(sb, "apply_tooltip_style 必須設定 panel stylebox")
	if sb != null:
		assert_eq(sb.corner_radius_top_left, 0, "P0-2 像素化：Tooltip 圓角必須為 0")
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

func test_ui_theme_exposes_unified_component_api() -> void:
	var theme := UI_THEME.new()
	for method_name: String in ["style_reward_button", "style_shop_button", "style_hud_badge", "style_map_node"]:
		assert_true(theme.has_method(method_name), "CotiwUiTheme 必須提供 component API：%s" % method_name)

func test_ui_theme_panel_material_rules_are_explicit() -> void:
	assert_eq(UI_THEME.get_panel_material_rule("reward"), "svg_texture", "reward 必須用 SVG panel texture，避免和 StyleBoxFlat 混語言")
	assert_eq(UI_THEME.get_panel_material_rule("shop"), "svg_texture", "shop item 必須用 SVG panel texture")
	assert_eq(UI_THEME.get_panel_material_rule("hud_badge"), "stylebox_flat", "HUD badge 是資料徽章，必須用 StyleBoxFlat")
	assert_eq(UI_THEME.get_panel_material_rule("tooltip"), "stylebox_flat", "tooltip 必須用 StyleBoxFlat")

func test_ui_theme_component_api_applies_metadata_and_tokens() -> void:
	var reward := Button.new()
	UI_THEME.style_reward_button(reward, "card", CardData.CARD_RARITIES.RARE)
	assert_eq(reward.get_meta("cotiw_component"), "reward_button", "reward button 必須標記元件來源")
	assert_eq(reward.get_meta("panel_material_rule"), "svg_texture", "reward button 必須宣告 panel 材質規則")
	assert_true(reward.has_theme_stylebox_override("normal"), "reward button 必須由 theme API 給 stylebox")
	reward.queue_free()

	var shop := Control.new()
	var price := Label.new()
	price.name = "PriceLabel"
	shop.add_child(price)
	UI_THEME.style_shop_button(shop, false)
	assert_eq(shop.get_meta("cotiw_component"), "shop_button", "shop item 必須標記元件來源")
	assert_eq(price.get_theme_font_size("font_size", "Label"), 18, "shop price 字級必須由 theme API 管")
	shop.queue_free()

	var badge := Panel.new()
	UI_THEME.style_hud_badge(badge, "energy_cyan")
	assert_eq(badge.get_meta("panel_material_rule"), "stylebox_flat", "HUD badge 必須宣告 StyleBoxFlat 規則")
	assert_true(badge.has_theme_stylebox_override("panel"), "HUD badge 必須有 theme stylebox")
	badge.queue_free()

func test_ui_component_gallery_scene_exists_and_covers_core_components() -> void:
	var path := "res://scenes/dev/UIComponentGallery.tscn"
	assert_true(ResourceLoader.exists(path), "必須建立 UI 元件圖鑑測試場景")
	var packed := load(path) as PackedScene
	assert_not_null(packed, "UI 元件圖鑑必須可載入")
	if packed == null:
		return
	var scene := packed.instantiate()
	for node_name: String in ["ButtonSamples", "PanelSamples", "BadgeSamples", "TooltipSample", "RewardSamples", "ShopItemSamples", "MapNodeSamples"]:
		assert_not_null(scene.get_node_or_null(node_name), "UI 元件圖鑑缺少區塊：%s" % node_name)
	scene.queue_free()
