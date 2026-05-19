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
	assert_eq(path, "res://assets/ui/map/ui_node_map_shop_default.svg",
		"SHOP 節點應映射到商店節點資產")
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
