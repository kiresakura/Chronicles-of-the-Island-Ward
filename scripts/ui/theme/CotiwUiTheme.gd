extends RefCounted
class_name CotiwUiTheme

const DESIGN_TOKENS_PATH: String = "res://docs/design/design_tokens.json"
const MOBILE_SAFE_CARD_DIR: String = "res://assets/generated/cards/mobile_safe"

const CARD_FRAME_BY_RARITY: Dictionary = {
	CardData.CARD_RARITIES.BASIC: "res://assets/ui/frames/ui_frame_card_common_default.svg",
	CardData.CARD_RARITIES.COMMON: "res://assets/ui/frames/ui_frame_card_common_default.svg",
	CardData.CARD_RARITIES.UNCOMMON: "res://assets/ui/frames/ui_frame_card_uncommon_default.svg",
	CardData.CARD_RARITIES.RARE: "res://assets/ui/frames/ui_frame_card_rare_default.svg",
	CardData.CARD_RARITIES.GENERATED: "res://assets/ui/frames/ui_frame_card_rare_default.svg",
}

const MAP_NODE_BY_LOCATION_TYPE: Dictionary = {
	LocationData.LOCATION_TYPES.COMBAT: "res://assets/generated/icons/map_nodes/node_combat.svg",
	LocationData.LOCATION_TYPES.MINIBOSS: "res://assets/generated/icons/map_nodes/node_elite.svg",
	LocationData.LOCATION_TYPES.BOSS: "res://assets/generated/icons/map_nodes/node_boss.svg",
	LocationData.LOCATION_TYPES.EVENT: "res://assets/generated/icons/map_nodes/node_event.svg",
	LocationData.LOCATION_TYPES.TREASURE: "res://assets/generated/icons/map_nodes/node_event.svg",
	LocationData.LOCATION_TYPES.SHOP: "res://assets/generated/icons/map_nodes/node_shop.svg",
	LocationData.LOCATION_TYPES.REST_SITE: "res://assets/generated/icons/map_nodes/node_rest.svg",
}

const PANEL_ASSET_BY_KIND: Dictionary = {
	"reward": "res://assets/ui/panels/ui_panel_reward_choice_default.svg",
	"shop": "res://assets/ui/panels/ui_panel_shop_item_default.svg",
	"rest": "res://assets/ui/panels/ui_panel_rest_action_default.svg",
}

const LOCATION_LABELS: Dictionary = {
	LocationData.LOCATION_TYPES.COMBAT: "戰",
	LocationData.LOCATION_TYPES.MINIBOSS: "菁",
	LocationData.LOCATION_TYPES.BOSS: "王",
	LocationData.LOCATION_TYPES.EVENT: "事",
	LocationData.LOCATION_TYPES.TREASURE: "寶",
	LocationData.LOCATION_TYPES.SHOP: "商",
	LocationData.LOCATION_TYPES.REST_SITE: "休",
}

static var _design_tokens_cache: Dictionary = {}

static func get_color(token_name: String, fallback: Color = Color.WHITE) -> Color:
	var colors: Dictionary = _get_design_tokens().get("colors", {})
	var raw_value: Variant = colors.get(token_name, "")
	if raw_value is String and not raw_value.is_empty():
		return Color.from_string(raw_value, fallback)
	return fallback

static func get_card_frame_path(card_rarity: int) -> String:
	return CARD_FRAME_BY_RARITY.get(card_rarity, CARD_FRAME_BY_RARITY[CardData.CARD_RARITIES.COMMON])

static func get_map_node_path(location_type: int) -> String:
	return MAP_NODE_BY_LOCATION_TYPE.get(location_type, MAP_NODE_BY_LOCATION_TYPE[LocationData.LOCATION_TYPES.EVENT])

static func get_panel_asset_path(panel_kind: String) -> String:
	return PANEL_ASSET_BY_KIND.get(panel_kind, "")

static func get_location_short_label(location_type: int) -> String:
	return LOCATION_LABELS.get(location_type, "？")

static func apply_primary_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _create_button_stylebox(
		get_color("festival_red", Color(0.85, 0.29, 0.17)),
		get_color("incense_gold", Color.GOLD),
		int(_get_component_value("primary_button", "radius", 16)),
		int(_get_border_value("cta", 4))
	))
	button.add_theme_stylebox_override("hover", _create_button_stylebox(
		get_color("festival_red", Color(0.85, 0.29, 0.17)).lightened(0.08),
		get_color("incense_gold", Color.GOLD),
		int(_get_component_value("primary_button", "radius", 16)),
		int(_get_border_value("cta", 4))
	))
	button.add_theme_stylebox_override("pressed", _create_button_stylebox(
		get_color("temple_red", Color(0.65, 0.18, 0.12)),
		get_color("old_gold", Color(0.64, 0.49, 0.16)),
		int(_get_component_value("primary_button", "radius", 16)),
		int(_get_border_value("strong", 3))
	))
	button.add_theme_stylebox_override("disabled", _create_button_stylebox(
		Color(0.23, 0.17, 0.14, 0.92),
		get_color("smoke_gray", Color.GRAY),
		int(_get_component_value("primary_button", "radius", 16)),
		int(_get_border_value("default", 2))
	))
	button.add_theme_color_override("font_color", get_color("paper_warm", Color.WHITE))
	button.add_theme_color_override("font_disabled_color", get_color("ash_beige", Color(0.84, 0.77, 0.64)))
	apply_focus_style(button)

static func apply_secondary_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _create_button_stylebox(
		get_color("lacquer_black", Color(0.1, 0.06, 0.05)),
		get_color("old_gold", Color(0.64, 0.49, 0.16)),
		int(_get_component_value("secondary_button", "radius", 12)),
		int(_get_border_value("strong", 3))
	))
	button.add_theme_stylebox_override("hover", _create_button_stylebox(
		get_color("wood_brown", Color(0.29, 0.18, 0.13)),
		get_color("incense_gold", Color.GOLD),
		int(_get_component_value("secondary_button", "radius", 12)),
		int(_get_border_value("strong", 3))
	))
	button.add_theme_stylebox_override("pressed", _create_button_stylebox(
		get_color("night_ink", Color.BLACK),
		get_color("old_gold", Color(0.64, 0.49, 0.16)),
		int(_get_component_value("secondary_button", "radius", 12)),
		int(_get_border_value("default", 2))
	))
	button.add_theme_stylebox_override("disabled", _create_button_stylebox(
		Color(0.12, 0.09, 0.08, 0.92),
		get_color("smoke_gray", Color.GRAY),
		int(_get_component_value("secondary_button", "radius", 12)),
		int(_get_border_value("default", 2))
	))
	button.add_theme_color_override("font_color", get_color("incense_gold", Color.GOLD))
	button.add_theme_color_override("font_disabled_color", get_color("smoke_gray", Color.GRAY))
	apply_focus_style(button)

## 共用 focus 樣式：incense_gold 半透明邊+微光暈。
## 觸控優先畫面可用 button.focus_mode = FOCUS_NONE 或覆寫 StyleBoxEmpty opt-out。
static func make_focus_stylebox(border_color: Color = Color(0.91, 0.77, 0.42, 0.85), radius: int = 12) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)  # 僅邊框與光暈，不蓋背景
	s.border_color = border_color
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.30)
	s.shadow_size = 6
	return s

static func apply_focus_style(button: Button) -> void:
	button.add_theme_stylebox_override("focus", make_focus_stylebox(
		get_color("incense_gold", Color(0.91, 0.77, 0.42)),
		_get_radius_value("md", 12)
	))

## 通用面板樣式：讀 design_tokens.components.panel（fill 可為 hex 或 token 名）
static func apply_panel_style(target: Control) -> void:
	var fill := _get_component_color("panel", "fill", Color(0.15, 0.08, 0.07, 0.93))
	var border := _get_component_color("panel", "border", get_color("old_gold", Color(0.64, 0.49, 0.16)))
	var radius_name: String = str(_get_component_value("panel", "radius", "lg"))
	var radius: int = _get_radius_value(radius_name, 16)
	target.add_theme_stylebox_override("panel",
		make_stylebox(fill, border, radius, _get_border_value("strong", 3)))

## Tooltip 樣式：讀 design_tokens.components.tooltip + text token
static func apply_tooltip_style(target: Control) -> void:
	var fill := _get_component_color("tooltip", "fill", Color(0.10, 0.06, 0.05, 0.95))
	var border := _get_component_color("tooltip", "border", get_color("incense_gold", Color(0.91, 0.77, 0.42)))
	var radius_name: String = str(_get_component_value("tooltip", "radius", "md"))
	var radius: int = _get_radius_value(radius_name, 12)
	var text_color := _get_component_color("tooltip", "text", get_color("paper_warm", Color(0.96, 0.91, 0.81)))
	target.add_theme_stylebox_override("panel",
		make_stylebox(fill, border, radius, _get_border_value("default", 2)))
	target.add_theme_color_override("font_color", text_color)

static func apply_panel_texture(texture_rect: TextureRect, panel_kind: String) -> void:
	var panel_path: String = get_panel_asset_path(panel_kind)
	if panel_path != "" and ResourceLoader.exists(panel_path):
		texture_rect.texture = load(panel_path)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func style_overlay_backdrop(scrim: ColorRect, panel: ColorRect = null) -> void:
	scrim.color = Color(0.07, 0.04, 0.04, 0.74)
	if panel != null:
		panel.color = get_color("panel", Color(0.15, 0.08, 0.07, 0.93))

static func get_mobile_safe_card_art_path(original_path: String) -> String:
	var normalized_path: String = normalize_resource_path(original_path)
	if normalized_path.is_empty():
		return normalized_path
	if normalized_path.contains("/cards/mobile_safe/"):
		return normalized_path

	var file_name: String = normalized_path.get_file()
	var candidate_file_name: String = file_name.replace("_art_v1.", "_mobile_safe_v1.")
	if candidate_file_name == file_name:
		candidate_file_name = file_name.get_basename() + "_mobile_safe_v1." + file_name.get_extension()

	var candidate_path: String = MOBILE_SAFE_CARD_DIR.path_join(candidate_file_name)
	if ResourceLoader.exists(candidate_path):
		return candidate_path
	return normalized_path

static func normalize_resource_path(resource_path: String) -> String:
	if resource_path.is_empty():
		return resource_path
	if resource_path.begins_with("res://"):
		return resource_path
	return "res://" + resource_path.trim_prefix("/")

static func _get_design_tokens() -> Dictionary:
	if _design_tokens_cache.is_empty():
		var file: FileAccess = FileAccess.open(DESIGN_TOKENS_PATH, FileAccess.READ)
		if file == null:
			return {}
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			_design_tokens_cache = parsed
	return _design_tokens_cache

static func _get_component_value(component_name: String, key: String, fallback: Variant) -> Variant:
	var components: Dictionary = _get_design_tokens().get("components", {})
	var component: Dictionary = components.get(component_name, {})
	return component.get(key, fallback)

static func _get_border_value(border_name: String, fallback: int) -> int:
	var borders: Dictionary = _get_design_tokens().get("borders", {})
	return int(borders.get(border_name, fallback))

static func _get_radius_value(radius_name: String, fallback: int) -> int:
	var radii: Dictionary = _get_design_tokens().get("radii", {})
	return int(radii.get(radius_name, fallback))

## 讀 components.<name>.<key> 並解析成 Color：
## - 以 # 開頭視為 hex（支援 #RRGGBBAA）
## - 否則視為 colors.* token 名，轉發給 get_color()
static func _get_component_color(component_name: String, key: String, fallback: Color) -> Color:
	var raw: Variant = _get_component_value(component_name, key, "")
	if raw is String and not (raw as String).is_empty():
		var s: String = raw
		if s.begins_with("#"):
			return Color.from_string(s, fallback)
		return get_color(s, fallback)
	return fallback

## 全專案唯一的 StyleBoxFlat 建構入口。任何 UI（含主畫面 MainMenu）
## 都應透過此函式建立面板/按鈕底框，確保圓角/邊框/陰影語言一致。
static func make_stylebox(fill_color: Color, border_color: Color, radius: int, border_width: int, shadow_alpha: float = 0.30) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, shadow_alpha)
	style.shadow_size = 4
	return style

static func _create_button_stylebox(fill_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	return make_stylebox(fill_color, border_color, radius, border_width)
