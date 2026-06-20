extends RefCounted
class_name CotiwUiTheme

const DESIGN_TOKENS_PATH: String = "res://docs/design/design_tokens.json"
const MOBILE_SAFE_CARD_DIR: String = "res://assets/generated/cards/mobile_safe"

## 鎮島錄 UIQA — 集中式 CanvasLayer / z_index 分層 token（避免散落 magic number；見 docs/design/UI_LAYOUT_SAFE_AREA_GUIDE.md）
const LAYER_BACKGROUND: int = 0
const LAYER_WORLD: int = 10
const LAYER_HUD: int = 20
const LAYER_FX: int = 30
const LAYER_OVERLAY: int = 60
const LAYER_TOAST: int = 80
const LAYER_TOUCH_DETAIL: int = 90

const CARD_FRAME_BY_RARITY: Dictionary = {
	CardData.CARD_RARITIES.BASIC: "res://assets/ui/frames/ui_frame_card_common_default.svg",
	CardData.CARD_RARITIES.COMMON: "res://assets/ui/frames/ui_frame_card_common_default.svg",
	CardData.CARD_RARITIES.UNCOMMON: "res://assets/ui/frames/ui_frame_card_uncommon_default.svg",
	CardData.CARD_RARITIES.RARE: "res://assets/ui/frames/ui_frame_card_rare_default.svg",
	CardData.CARD_RARITIES.GENERATED: "res://assets/ui/frames/ui_frame_card_rare_default.svg",
}

## P0-3 符令卡框 v2（動漫稀有度雙層：符印費角 + 大插圖窗 + 職業/稀有度色）。
## opt-in：不取代既有 CARD_FRAME_BY_RARITY，直到 Card 顯式改用 get_card_frame_v2_path()；
## 先供 Gallery / 預覽使用，避免一次性破壞整條卡牌鏈與測試。
const CARD_FRAME_V2_DIR: String = "res://assets/ui/frames_v2/"
const CARD_FRAME_V2_BY_RARITY: Dictionary = {
	CardData.CARD_RARITIES.BASIC: "ui_frame_card_common_anime.svg",
	CardData.CARD_RARITIES.COMMON: "ui_frame_card_common_anime.svg",
	CardData.CARD_RARITIES.UNCOMMON: "ui_frame_card_uncommon_anime.svg",
	CardData.CARD_RARITIES.RARE: "ui_frame_card_rare_anime.svg",
	CardData.CARD_RARITIES.GENERATED: "ui_frame_card_rare_anime.svg",
}

## 取得 v2 符令卡框路徑（opt-in）。rarity 為 CardData.CARD_RARITIES 列舉；找不到回共通框。
static func get_card_frame_v2_path(rarity: int) -> String:
	var fname: String = CARD_FRAME_V2_BY_RARITY.get(rarity, "ui_frame_card_common_anime.svg")
	return CARD_FRAME_V2_DIR + fname

## P1：全域 opt-in 旗標 — true 時整條卡牌鏈改用 v2 符令框（Gallery/預覽用）；
## live 預設 false，不動既有卡面與 161 測試。
static var use_card_frame_v2: bool = true	# UIQA P2-4：v2 符令框轉正式（v1 STR 白底敘述區突兀）

## 依 opt-in 旗標回傳當前卡框路徑（v2 或既有 v1）。Card.gd 統一走這個。
static func get_active_card_frame_path(rarity: int) -> String:
	if use_card_frame_v2:
		return get_card_frame_v2_path(rarity)
	return get_card_frame_path(rarity)

## P1 動漫化：Q 版地標節點 icon（v2）。戰=紅符令 / 事=籤筒 / 商=古錢 / 休=香爐 / 菁=虎爪 / Boss=黑紅神門。
## 舊 node_*.svg 保留未刪；此處 repoint 到 v2。
const MAP_NODE_BY_LOCATION_TYPE: Dictionary = {
	LocationData.LOCATION_TYPES.COMBAT: "res://assets/generated/icons/map_nodes_v2/node_combat_anime.svg",
	LocationData.LOCATION_TYPES.MINIBOSS: "res://assets/generated/icons/map_nodes_v2/node_elite_anime.svg",
	LocationData.LOCATION_TYPES.BOSS: "res://assets/generated/icons/map_nodes_v2/node_boss_anime.svg",
	LocationData.LOCATION_TYPES.EVENT: "res://assets/generated/icons/map_nodes_v2/node_event_anime.svg",
	LocationData.LOCATION_TYPES.TREASURE: "res://assets/generated/icons/map_nodes_v2/node_treasure_anime.svg",	# Q2-A：寶匣專屬（原誤共用 event 籤筒）
	LocationData.LOCATION_TYPES.SHOP: "res://assets/generated/icons/map_nodes_v2/node_shop_anime.svg",
	LocationData.LOCATION_TYPES.REST_SITE: "res://assets/generated/icons/map_nodes_v2/node_rest_anime.svg",
}

const PANEL_ASSET_BY_KIND: Dictionary = {
	"reward": "res://assets/ui/panels/ui_panel_reward_choice_default.svg",
	"shop": "res://assets/ui/panels/ui_panel_shop_item_default.svg",
	"rest": "res://assets/ui/panels/ui_panel_rest_action_default.svg",
}

## 面板材質鐵律：大型可點選卡片用 SVG texture；資料徽章 / tooltip / 一般容器用 StyleBoxFlat。
## 這裡是唯一決策表，Scene 不准各自猜材質語言。
const PANEL_MATERIAL_RULE_BY_KIND: Dictionary = {
	"reward": "svg_texture",
	"shop": "svg_texture",
	"rest": "svg_texture",
	"card": "svg_texture",
	"hud_badge": "stylebox_flat",
	"tooltip": "stylebox_flat",
	"dialogue": "stylebox_flat",
	"system_panel": "stylebox_flat",
}

## Q2-A：節點短標走民俗語彙（遇煞/惡煞據點/鎮煞大醮/民俗問事/寶匣/夜市香鋪/入廟安神），
## 與遶境敘事同一套符號系統（基準 Q-4），不用通用 roguelike 字。
const LOCATION_LABELS: Dictionary = {
	LocationData.LOCATION_TYPES.COMBAT: "map.label.combat",
	LocationData.LOCATION_TYPES.MINIBOSS: "map.label.miniboss",
	LocationData.LOCATION_TYPES.BOSS: "map.label.boss",
	LocationData.LOCATION_TYPES.EVENT: "map.label.event",
	LocationData.LOCATION_TYPES.TREASURE: "map.label.treasure",
	LocationData.LOCATION_TYPES.SHOP: "map.label.shop",
	LocationData.LOCATION_TYPES.REST_SITE: "map.label.rest",
}

## Q2-A：節點型別色環 — 地圖辨型別的第二符號軸（色 + 字 + 圖三重編碼，遠看靠色近看靠圖）。
const MAP_NODE_RING_BY_TYPE: Dictionary = {
	LocationData.LOCATION_TYPES.COMBAT: Color(0.85, 0.29, 0.17, 0.95),		# festival_red
	LocationData.LOCATION_TYPES.MINIBOSS: Color(0.58, 0.10, 0.24, 0.95),	# 暗血紅
	LocationData.LOCATION_TYPES.BOSS: Color(0.30, 0.04, 0.07, 1.0),		# 煞黑紅
	LocationData.LOCATION_TYPES.EVENT: Color(0.36, 0.70, 0.82, 0.95),		# 問事青
	LocationData.LOCATION_TYPES.TREASURE: Color(0.93, 0.76, 0.30, 0.95),	# incense_gold
	LocationData.LOCATION_TYPES.SHOP: Color(0.95, 0.55, 0.18, 0.95),		# 燈籠橙
	LocationData.LOCATION_TYPES.REST_SITE: Color(0.45, 0.66, 0.34, 0.95),	# 安神綠
}

const CARD_TYPE_ACCENT_TOKEN: Dictionary = {
	CardData.CARD_TYPES.ATTACK: "festival_red",
	CardData.CARD_TYPES.SKILL: "spirit_jade",
	CardData.CARD_TYPES.POWER: "sign_blue",
	CardData.CARD_TYPES.STATUS: "warning_orange",
	CardData.CARD_TYPES.CURSE: "mystic_purple",
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

static func get_panel_material_rule(panel_kind: String) -> String:
	return PANEL_MATERIAL_RULE_BY_KIND.get(panel_kind, "stylebox_flat")

static func get_typography_size(token_name: String, fallback: int) -> int:
	var typography: Dictionary = _get_design_tokens().get("typography", {})
	var token: Dictionary = typography.get(token_name, {})
	return int(token.get("size", fallback))

## 公開 spacing/radii getter（token SSOT 對外；給 kit 元件用，取代散落數字）
static func get_spacing(spacing_name: String, fallback: int = 16) -> int:
	return _get_spacing_value(spacing_name, fallback)

static func get_radius(radius_name: String, fallback: int = 0) -> int:
	return _get_radius_value(radius_name, fallback)

## 鎮島錄 UIQA — 安全內容區（委派 Responsive autoload 單一真相來源；
## 無 Responsive 時回退 viewport / 設計畫布）。UI 定位請以此為基準，勿散落 magic Vector2。
static func get_safe_content_rect(viewport: Viewport = null) -> Rect2:
	var r: Object = _responsive()
	if r != null:
		return r.safe_rect
	if viewport != null:
		return Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
	return Rect2(Vector2.ZERO, get_stage_size())

## 完整邏輯畫布尺寸（全出血用）。
static func get_stage_size() -> Vector2:
	var r: Object = _responsive()
	if r != null:
		return r.screen_rect.size
	return Vector2(1200, 700)

## 把 rect 夾進 safe_rect 內（先夾尺寸不超過安全區，再夾位置使整塊在內）。
static func clamp_rect_to_safe_area(rect: Rect2, safe_rect: Rect2) -> Rect2:
	var w: float = minf(rect.size.x, safe_rect.size.x)
	var h: float = minf(rect.size.y, safe_rect.size.y)
	var x: float = clampf(rect.position.x, safe_rect.position.x, safe_rect.position.x + safe_rect.size.x - w)
	var y: float = clampf(rect.position.y, safe_rect.position.y, safe_rect.position.y + safe_rect.size.y - h)
	return Rect2(Vector2(x, y), Vector2(w, h))

## 取 Responsive autoload（CotiwUiTheme 為 RefCounted 無 tree，經主迴圈 root 取得）。
static func _responsive() -> Object:
	var loop: Object = Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root.get_node_or_null("/root/Responsive")
	return null

static func get_semantic_role(role_name: String) -> Dictionary:
	var roles: Dictionary = _get_design_tokens().get("semantic_roles", {})
	var role: Variant = roles.get(role_name, {})
	if role is Dictionary:
		return (role as Dictionary).duplicate(true)
	return {}

static func get_motion_duration(token_name: String, fallback_ms: int) -> int:
	var motion: Dictionary = _get_design_tokens().get("motion", {})
	return int(motion.get(token_name, fallback_ms))

static func get_card_type_accent(card_type: int) -> Color:
	var token_name: String = CARD_TYPE_ACCENT_TOKEN.get(card_type, "festival_red")
	return get_color(token_name, get_color("festival_red", Color(0.85, 0.29, 0.17)))

static func get_location_short_label(location_type: int) -> String:
	# Q4-A i18n：const 存 key、讀取點翻譯（static context 用 TranslationServer）
	return TranslationServer.translate(LOCATION_LABELS.get(location_type, "？"))

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
	# P0-2 像素化：focus 框同樣硬邊無光暈（radius 參數保留簽名相容，值忽略）
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0)  # 僅邊框，不蓋背景
	s.border_color = border_color
	s.set_border_width_all(2)
	s.set_corner_radius_all(0)
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
	texture_rect.set_meta("panel_material_rule", get_panel_material_rule(panel_kind))

static func style_reward_button(button: Button, kind: String = "card", rarity: int = 0) -> void:
	if button == null:
		return
	button.set_meta("cotiw_component", "reward_button")
	button.set_meta("panel_material_rule", get_panel_material_rule("reward"))
	button.flat = true
	button.custom_minimum_size = Vector2(320, 112)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.clip_text = true
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", get_typography_size("h2", 24))
	button.add_theme_constant_override("h_separation", _get_spacing_value("md", 16))
	button.add_theme_constant_override("icon_max_width", 40)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(color_name, get_color("paper_warm", Color.WHITE))
	button.add_theme_color_override("font_disabled_color", get_color("smoke_gray", Color.GRAY))
	button.add_theme_color_override("font_shadow_color", get_color("text_shadow_soft", Color(0, 0, 0, 0.65)))
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 1)
	var style: Dictionary = get_reward_button_style(kind, rarity)
	var normal := make_stylebox(style["fill_color"], style["rim_color"], _get_radius_value("lg", 16), int(style["border_width"]), 0.58)
	var hover := make_stylebox((style["fill_color"] as Color).lightened(0.06), (style["rim_color"] as Color).lightened(0.08), _get_radius_value("lg", 16), int(style["border_width"]), 0.62)
	var pressed := make_stylebox((style["fill_color"] as Color).darkened(0.08), style["rim_color"], _get_radius_value("lg", 16), maxi(2, int(style["border_width"]) - 1), 0.50)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", make_stylebox(get_color("panel_bg_lock", Color(0.13, 0.09, 0.08, 0.8)), get_color("smoke_gray", Color.GRAY), _get_radius_value("lg", 16), _get_border_value("default", 2), 0.38))
	button.set_meta("reward_style", style)
	button.set_meta("touch_feedback_particle_hook", style["fx_hook"])
	# 取代場景預設 res://icon.svg placeholder：money/card 套既有主題 icon；
	# 其餘 kind 若仍是預設 icon.svg 才清空（artifact 等由各自 script 覆寫，不動）
	var _reward_icon: String = {
		"money": "res://assets/generated/icons_v2/status/incense_money.svg",
		"card": "res://assets/generated/icons/ui_v2/ui_deck.svg",
	}.get(kind, "")
	if _reward_icon != "" and ResourceLoader.exists(_reward_icon):
		button.icon = load(_reward_icon)
	elif button.icon != null and button.icon.resource_path == "res://icon.svg":
		button.icon = null
	var panel_background := button.get_node_or_null("PanelBackground") as TextureRect
	if panel_background != null:
		apply_panel_texture(panel_background, "reward")
		panel_background.modulate = Color.WHITE if not button.disabled else get_color("disabled_tint", Color(0.6, 0.6, 0.6, 0.85))

static func get_reward_button_style(kind: String, rarity: int = 0) -> Dictionary:
	if kind == "money":
		return {"rim_color": get_color("incense_gold", Color(1.0, 0.78, 0.22)), "fill_color": get_color("wood_brown", Color(0.20, 0.12, 0.03)), "border_width": _get_border_value("cta", 4), "glyph": "金", "fx_hook": "fu_light_selected"}
	if kind == "artifact":
		return {"rim_color": get_color("mystic_purple", Color(0.64, 0.35, 0.95)), "fill_color": get_color("night_ink", Color(0.10, 0.04, 0.12)), "border_width": _get_border_value("strong", 3), "glyph": "器", "fx_hook": "fu_light_selected"}
	match rarity:
		CardData.CARD_RARITIES.RARE:
			return {"rim_color": get_color("festival_red", Color(0.96, 0.23, 0.18)), "fill_color": get_color("danger_crimson", Color(0.20, 0.02, 0.03)), "border_width": 6, "glyph": "稀", "fx_hook": "fu_light_selected"}
		CardData.CARD_RARITIES.UNCOMMON:
			return {"rim_color": get_color("energy_cyan", Color(0.22, 0.84, 0.92)), "fill_color": get_color("sign_blue", Color(0.02, 0.12, 0.16)), "border_width": _get_border_value("cta", 4), "glyph": "奇", "fx_hook": "fu_light_pressed"}
		CardData.CARD_RARITIES.BASIC:
			return {"rim_color": get_color("smoke_gray", Color(0.62, 0.54, 0.42)), "fill_color": get_color("lacquer_black", Color(0.12, 0.09, 0.07)), "border_width": _get_border_value("default", 2), "glyph": "基", "fx_hook": "fu_light_pressed"}
		_:
			return {"rim_color": get_color("old_gold", Color(0.84, 0.64, 0.28)), "fill_color": get_color("panel_bg", Color(0.13, 0.08, 0.04)), "border_width": _get_border_value("strong", 3), "glyph": "常", "fx_hook": "fu_light_pressed"}

static func style_shop_button(target: Control, is_unaffordable: bool = false) -> void:
	if target == null:
		return
	target.set_meta("cotiw_component", "shop_button")
	target.set_meta("panel_material_rule", get_panel_material_rule("shop"))
	var panel_background := target.get_node_or_null("PanelBackground") as TextureRect
	if panel_background != null:
		apply_panel_texture(panel_background, "shop")
		panel_background.modulate = Color.WHITE if not is_unaffordable else get_color("disabled_tint", Color(0.72, 0.72, 0.72, 0.9))
	var price_label := target.get_node_or_null("PriceLabel") as Label
	if price_label != null:
		price_label.add_theme_color_override("font_color", get_color("warning_orange", Color.ORANGE) if is_unaffordable else get_color("incense_gold", Color.GOLD))
		price_label.add_theme_color_override("font_shadow_color", get_color("text_shadow_soft", Color(0, 0, 0, 0.65)))
		price_label.add_theme_constant_override("shadow_offset_x", 1)
		price_label.add_theme_constant_override("shadow_offset_y", 1)
		price_label.add_theme_font_size_override("font_size", get_typography_size("caption", 18))

static func style_hud_badge(panel: Control, accent_token: String = "incense_gold") -> void:
	if panel == null:
		return
	panel.set_meta("cotiw_component", "hud_badge")
	panel.set_meta("panel_material_rule", get_panel_material_rule("hud_badge"))
	var fill := _get_component_color("hud_badge", "fill", get_color("panel_bg", Color(0.15, 0.08, 0.07, 0.93)))
	var border := get_color(accent_token, _get_component_color("hud_badge", "border", get_color("old_gold", Color(0.64, 0.49, 0.16))))
	panel.add_theme_stylebox_override("panel", make_stylebox(fill, border, _get_radius_value("md", 12), _get_border_value("default", 2), 0.36))

static func style_map_node(node: TextureButton, location_type: int, label: Label = null, state_glow: ColorRect = null, is_reachable: bool = false, is_current: bool = false, is_travel_mode: bool = false, is_visited: bool = false) -> void:
	if node == null:
		return
	node.set_meta("cotiw_component", "map_node")
	node.set_meta("panel_material_rule", "svg_icon")
	var texture := load(get_map_node_path(location_type))
	node.texture_normal = texture
	node.texture_hover = texture
	node.texture_pressed = texture
	node.texture_disabled = texture
	node.ignore_texture_size = true
	node.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var node_size := Vector2(_get_touch_target_value("minimum", 88), _get_touch_target_value("minimum", 88))
	node.custom_minimum_size = node_size
	node.size = node_size
	_ensure_map_node_type_ring(node, location_type, node_size)
	if state_glow != null:
		state_glow.visible = false
		state_glow.color = Color.TRANSPARENT
	node.scale = Vector2.ONE
	node.self_modulate = Color.WHITE
	var font_color := get_color("paper_warm", Color.WHITE)
	if is_current:
		font_color = get_color("incense_gold", Color.GOLD)
		if state_glow != null:
			state_glow.visible = true
			state_glow.color = font_color
	elif is_reachable:
		font_color = get_color("neon_cyan", Color.DEEP_SKY_BLUE).lightened(0.1)
		if state_glow != null:
			state_glow.visible = true
			state_glow.color = get_color("neon_cyan", Color.DEEP_SKY_BLUE)
	elif is_visited:
		node.self_modulate = get_color("paper_warm", Color(0.92, 0.88, 0.8, 1.0))
	elif is_travel_mode:
		var smoke_a := get_color("smoke_gray", Color(0.55, 0.49, 0.45, 1.0))
		node.self_modulate = Color(smoke_a.r, smoke_a.g, smoke_a.b, 0.82)
		font_color = smoke_a
	if label != null:
		label.add_theme_color_override("font_color", font_color)
		label.add_theme_font_size_override("font_size", get_typography_size("micro", 16))

## Q2-A：節點型別色環（程序化 StyleBoxFlat 圓環，零素材依賴；冪等 — 重複 style 只更新色）。
static func _ensure_map_node_type_ring(node: TextureButton, location_type: int, node_size: Vector2) -> void:
	var ring: Panel = node.get_node_or_null("TypeRing") as Panel
	if ring == null:
		ring = Panel.new()
		ring.name = "TypeRing"
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(ring)
	var pad: float = 3.0
	ring.position = Vector2(-pad, -pad)
	ring.size = node_size + Vector2(pad, pad) * 2.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = MAP_NODE_RING_BY_TYPE.get(location_type, Color(0.6, 0.6, 0.6, 0.9))
	sb.set_border_width_all(4)
	sb.anti_aliasing = true
	# P0-2 例外保留：此處 radius = 尺寸一半 → 幾何「圓形節點環」（地圖節點造型），
	# 非圓角面板元件 — 像素化鐵則不適用（圓環是地圖視覺語彙，動它=改地圖設計）
	var radius: int = int(ring.size.x * 0.5)
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	ring.add_theme_stylebox_override("panel", sb)

static func style_overlay_backdrop(scrim: ColorRect, panel: ColorRect = null) -> void:
	scrim.color = Color(0.07, 0.04, 0.04, 0.74)
	if panel != null:
		panel.color = get_color("panel", Color(0.15, 0.08, 0.07, 0.93))

static func get_mobile_safe_card_art_path(original_path: String) -> String:
	# 回傳值統一規則（修 root cause：先前 fallback 直接回 raw 相對路徑，導致 caller
	# 拿到混合形態 — mobile_safe / cards_v3 分支回 res://，但 fallback 卻是裸 assets/...）：
	#   • bundled（assets/... 或 res://...）一律正規化為 res:// 前綴
	#   • external/...、user://... 等 FileLoader 範疇路徑「不」強制加 res://，原樣回傳
	#     —— FileLoader 內部會自行 prepend user:// (mobile) 或 res:// (debug)
	# 對應卡圖優先級：mobile_safe 變體 > 原圖（已正規化）
	if original_path.is_empty():
		return original_path
	# FileLoader 範疇：external 資產 / user:// 已絕對 — 保留原樣
	if original_path.begins_with("external/") or original_path.begins_with("user://"):
		return original_path

	# 已在 mobile_safe 子目錄 → 確保 res:// 前綴後直接回
	if original_path.contains("/cards/mobile_safe/"):
		return normalize_resource_path(original_path)
	# v3 NBP 卡圖：assets/generated/cards_v3/* — bundled，直接正規化
	if original_path.contains("/cards_v3/"):
		return normalize_resource_path(original_path)

	var file_name: String = original_path.get_file()
	var candidate_file_name: String = file_name.replace("_art_v1.", "_mobile_safe_v1.")
	if candidate_file_name == file_name:
		candidate_file_name = file_name.get_basename() + "_mobile_safe_v1." + file_name.get_extension()

	var candidate_path: String = MOBILE_SAFE_CARD_DIR.path_join(candidate_file_name)
	if ResourceLoader.exists(candidate_path):
		return candidate_path
	# Fallback：bundled 路徑也走 res:// 正規化，與上方分支對齊（root cause）
	return normalize_resource_path(original_path)

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

static func _get_spacing_value(spacing_name: String, fallback: int) -> int:
	var spacing: Dictionary = _get_design_tokens().get("spacing", {})
	return int(spacing.get(spacing_name, fallback))

static func _get_touch_target_value(size_name: String, fallback: int) -> int:
	var touch_targets: Dictionary = _get_design_tokens().get("touch_targets", {})
	return int(touch_targets.get(size_name, fallback))

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
	# P0-2 像素化鐵則：工廠入口統一硬邊 — 圓角/柔影一律歸零（radius 參數保留
	# 簽名相容，值被忽略）。柔影改為 1px 硬位移影（保留層次感、無漸層柔邊）。
	# TODO(美術): 像素 9-slice 素材到位後，本工廠改回傳 StyleBoxTexture
	# （region/margin 由素材定義），呼叫端零改動。
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(0)
	if shadow_alpha > 0.0:
		style.shadow_color = Color(0, 0, 0, shadow_alpha)
		style.shadow_size = 2
		style.shadow_offset = Vector2(2, 2)	# 位移硬影（像素風）取代四向柔暈
	return style

static func _create_button_stylebox(fill_color: Color, border_color: Color, radius: int, border_width: int) -> StyleBoxFlat:
	return make_stylebox(fill_color, border_color, radius, border_width)
