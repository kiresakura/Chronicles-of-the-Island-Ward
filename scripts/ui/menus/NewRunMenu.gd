extends Control

# 鎮島錄 — 新一局／開壇設定（重排：三區單向動線 ① 選將 → ② 設定 → ③ 開壇）。
# ① 你是誰（左）：英雄面板 = 角色資訊唯一真相（立繪/姓名/一句定位/元神·銀兩/
#    3 標籤/平安符完整不截斷）+ 下方陣容列（只切換角色）。
# ② 怎麼開壇（右上）：一張卡框住 — 難度 stepper + 模式分段 + 護壇 + 法器。
# ③ 開壇（右下）：巨大獨佔高對比「開始開壇」CTA；種子收進預設摺疊「進階」。
# 霓虹紀律：僅「選中角色環」與「開始開壇」用霓虹，其餘壓暗。

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const CHARACTER_GALLERY_SCENE := preload("res://scenes/ui/menus/CharacterGallery.tscn")
const GILDED_DEPTH := preload("res://scripts/ui/fx/GildedDepthLayer.gd")	# 設計忠實「貴層」

const CHARACTER_SHELF_PATH := "res://external/data/ui/new_run_character_shelf.json"
const PORTRAIT_DIR := "res://assets/generated/portraits_v3/"

# 模式分段 → run_modifier（NR-2 決策 A：100% 復用現有資料，不發明玩法；
# 難度 stepper（敵 HP 0..5）與模式正交）。
const MODE_STANDARD := "standard"
const MODE_EASY := "easy"
const MODE_ENDLESS := "endless"
const MODE_CUSTOM := "custom"
const MODE_TO_MODIFIERS := {
	"standard": [],
	"easy": ["run_modifier_custom_easy_mode"],
	"endless": ["run_modifier_endless_mode"],
	"custom": [],	# 自訂走 checkbox 容器
}
# 自訂清單排除（NR-3）：STR 無實效佔位（custom_1/2）+ 已成獨立模式者（易/無盡）
const CUSTOM_LIST_EXCLUDE := ["run_modifier_custom_1", "run_modifier_custom_2",
	"run_modifier_custom_easy_mode", "run_modifier_endless_mode"]

@onready var title_screen: Control = $%TitleScreen

@onready var character_name_label: Label = $CharacterNameLabel
@onready var character_health_label: Label = $CharacterHealthLabel
@onready var character_money_label: Label = $CharacterMoneyLabel
@onready var character_description_label: Label = $CharacterDescriptionLabel

@onready var character_artifact_texture_rect: TextureRect = $CharacterArtifactTextureRect
@onready var character_artifact_name_label: Label = $CharacterArtifactNameLabel
@onready var character_artifact_description_label: Label = $CharacterArtifactDescriptionLabel

@onready var decrease_difficulty_button: Button = $DifficultySelect/DecreaseDifficultyButton
@onready var difficulty_label: Label = $DifficultySelect/DifficultyLabel
@onready var increase_difficulty_button: Button = $DifficultySelect/IncreaseDifficultyButton
@onready var difficulty_select: Control = $DifficultySelect

@onready var custom_run_modifier_button_container: ScrollContainer = $CustomRunModifierButtonContainer
@onready var character_button_container: ScrollContainer = $CharacterButtonContainer

@onready var start_run_button: Button = $StartRunButton
@onready var seed_input: LineEdit = $SeedInput
@onready var back_button: Button = $BackButton

var selected_character_object_id: String = ""
var selected_difficulty_level: int = 0
var selected_guardian_id: String = ""
var selected_ritual_tool_id: String = ""
var _selected_mode: String = MODE_STANDARD
var _advanced_open: bool = false

var _guardian_picker: OptionButton = null
var _tool_picker: OptionButton = null

var _character_gallery
var _hero_panel: Panel
var _setup_card: Panel
var _hero_portrait: TextureRect
var _hero_portrait_frame: Panel
var _hero_spot: TextureRect	# §A 聚光燈：立繪後暖金徑向光（設計稿「聚光燈打亮立繪」）
var _tagline_label: Label
var _character_tags_flow: HFlowContainer
var _info_heading_label: Label
var _run_heading_label: Label
var _difficulty_hint_label: Label
var _mode_heading_label: Label
var _mode_buttons: Array = []
var _advanced_toggle: Button
var _seed_heading_label: Label
var _character_shelf: Array = []

## 三區版面（純函式，可測；inner 子件位置在 _relayout 依此推算）。
## ① hero + roster（左）　② setup（右上）　③ cta（右下）　back（左上）
static func calculate_layout(safe: Rect2) -> Dictionary:
	var pad: float = 24.0
	var top: float = safe.position.y + 12.0
	var back := Rect2(Vector2(safe.position.x + 16.0, top), Vector2(176.0, 72.0))
	var content_top: float = top + 72.0
	var content_bottom: float = safe.position.y + safe.size.y - pad
	var content_h: float = content_bottom - content_top
	# 左欄：英雄面板 + 陣容列
	var left_x: float = safe.position.x + pad
	var left_w: float = clampf(safe.size.x * 0.42, 432.0, 540.0)
	var roster_h: float = 132.0
	var hero_h: float = content_h - roster_h - 12.0
	var hero := Rect2(Vector2(left_x, content_top), Vector2(left_w, hero_h))
	var roster := Rect2(Vector2(left_x, content_top + hero_h + 12.0), Vector2(left_w, roster_h))
	# 右欄：② 設定卡（上）+ ③ 開壇區（下）
	var right_x: float = left_x + left_w + pad
	var right_w: float = (safe.position.x + safe.size.x - pad) - right_x
	var cta_h: float = 132.0
	var setup_h: float = content_h - cta_h - 12.0
	var setup := Rect2(Vector2(right_x, content_top), Vector2(right_w, setup_h))
	var cta_zone := Rect2(Vector2(right_x, content_top + setup_h + 12.0), Vector2(right_w, cta_h))
	# ③ 開壇區水平切：左窄欄 = 進階(上)+種子(下)，右寬欄 = 巨大 CTA（不互擠）
	var adv_w: float = clampf(right_w * 0.32, 150.0, 220.0)
	var advanced := Rect2(cta_zone.position, Vector2(adv_w, 64.0))
	var seed := Rect2(Vector2(cta_zone.position.x, cta_zone.position.y + 72.0), Vector2(adv_w, cta_h - 72.0))
	var start := Rect2(Vector2(cta_zone.position.x + adv_w + 16.0, cta_zone.position.y),
		Vector2(right_w - adv_w - 16.0, cta_h))
	return {
		"back": back, "hero": hero, "roster": roster, "setup": setup,
		"cta_zone": cta_zone, "start": start, "advanced": advanced, "seed": seed,
	}

func _ready() -> void:
	_character_shelf = _load_character_shelf()
	start_run_button.button_up.connect(_on_start_run_button_up)
	back_button.button_up.connect(_on_back_button_up)
	decrease_difficulty_button.button_up.connect(_on_decrease_difficulty_button)
	increase_difficulty_button.button_up.connect(_on_increase_difficulty_button)
	seed_input.text_changed.connect(_on_seed_input_text_changed)
	Signals.character_selected.connect(_on_character_selected)
	Signals.run_ended.connect(_on_run_ended)
	if not resized.is_connected(_relayout_runtime_chrome):
		resized.connect(_relayout_runtime_chrome)
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_relayout_runtime_chrome):
		viewport.size_changed.connect(_relayout_runtime_chrome)
	if not Responsive.changed.is_connected(_relayout_runtime_chrome):
		Responsive.changed.connect(_relayout_runtime_chrome)

	const PixelSkinCls = preload("res://scripts/ui/theme/PixelSkin.gd")
	const PixelFXCls = preload("res://scripts/ui/fx/PixelFX.gd")
	var newrun_layer := PixelSkinCls.apply_background(self, "newrun_bg_v5.png")
	if newrun_layer:
		PixelFXCls.apply(newrun_layer, PixelFXCls.Preset.SMOKE)
	_restyle_scene_backdrops()
	_build_gilded_atmosphere()	# 設計忠實「貴層」：深舞台神光+香火餘燼（墊於三層深底之上、面板/立繪之下）

	_hide_legacy_static_labels()
	_style_static_controls()
	_build_runtime_chrome()
	_build_loadout_pickers()
	_build_setup_card()
	_build_character_gallery()
	populate_new_run_menu()
	await get_tree().process_frame
	_relayout_runtime_chrome()

## 打掉暗紅疊暗紅 + 修死板尺寸：場景三層底（DimBackground/NewRunBackdrop/NewRunVignette）
## 原為 1200×700 固定的「暗紅疊暗紅」死色塊（NewRunBackdrop=不透明硃砂），蓋住 PixelSkin
## 質感底圖且寬螢幕不滿版。改：沉成半透深舞台（露底圖質感、殺純紅）、滿版自適應、壓到面板(z-1)之下。
func _restyle_scene_backdrops() -> void:
	var dim := get_node_or_null("DimBackground") as ColorRect
	if dim != null:
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.color = Color(0.04, 0.025, 0.03, 0.74)
		dim.z_index = -2
		dim.mouse_filter = Control.MOUSE_FILTER_STOP	# 仍當 modal 攔截，防穿透
	var backdrop := get_node_or_null("NewRunBackdrop") as ColorRect
	if backdrop != null:
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.color = Color(0, 0, 0, 0)		# 移除主硃砂塊（暗紅元兇）
		backdrop.z_index = -2
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vig := get_node_or_null("NewRunVignette") as ColorRect
	if vig != null:
		vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vig.color = Color(0, 0, 0, 0)			# 移除中央紅罩
		vig.z_index = -2
		vig.mouse_filter = Control.MOUSE_FILTER_IGNORE

## 設計忠實「貴層」：鎏金氛圍層墊於深舞台之上、面板/立繪之下（z=-2）—
## 神光自上灑下 + 香火餘燼飄升，與供桌/結算同一套縱深語言（加性光，不蓋立繪）。
func _build_gilded_atmosphere() -> void:
	if get_node_or_null("GildedDepthLayer") != null:
		return
	var layer: Control = GILDED_DEPTH.attach(self, GILDED_DEPTH.ACCENT_GOLD, 0.9, 10)
	if layer != null:
		layer.z_index = -2

## 立繪聚光燈紋理（暖金徑向光，中心亮 → 透明邊）。
func _make_spot_texture() -> Texture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.86, 0.55, 0.26), Color(1.0, 0.82, 0.50, 0.08), Color(1.0, 0.80, 0.50, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.45)
	t.fill_to = Vector2(1.0, 0.45)
	t.width = 128
	t.height = 128
	return t

## 隱藏 STR/舊版殘留靜態標籤（「新一局」大標題鬼影 + 「種子」「自訂修正」副標）—
## 重排後由「返回正殿」+ 區段卡頭接手；舊大標未進 calculate_layout，留著會漂到畫面中央透出。
func _hide_legacy_static_labels() -> void:
	for legacy_name: String in ["Label", "Label2", "Label3", "Label4"]:
		var node: Node = get_node_or_null(legacy_name)
		if node is CanvasItem:
			(node as CanvasItem).visible = false

func _style_static_controls() -> void:
	COTIW_UI_THEME.apply_primary_button_style(start_run_button)
	COTIW_UI_THEME.apply_secondary_button_style(back_button)
	COTIW_UI_THEME.apply_secondary_button_style(decrease_difficulty_button)
	COTIW_UI_THEME.apply_secondary_button_style(increase_difficulty_button)
	start_run_button.text = tr("newrun.start")
	back_button.text = tr("temple.back")
	seed_input.placeholder_text = tr("newrun.seed_hint")
	seed_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_button_container.visible = false
	# 靜態節點 anchors 歸 TOP_LEFT：避免 runtime 設 size 時觸發
	# 「non-equal opposite anchors」warning（log 乾淨契約）
	for n: Control in [character_name_label, character_health_label, character_money_label,
			character_description_label, character_artifact_name_label,
			character_artifact_description_label, difficulty_label]:
		n.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	# 平安符 / 描述：autowrap，預算內保證不截斷（鐵律 1）
	character_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_artifact_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_artifact_name_label.clip_text = false
	difficulty_label.add_theme_font_size_override("font_size", 24)
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_update_difficulty_label()
	_start_run_button_state(false)

func _build_runtime_chrome() -> void:
	if _hero_panel == null:
		_hero_panel = Panel.new()
		_hero_panel.name = "HeroPanel"
		_hero_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hero_panel.z_index = -1
		add_child(_hero_panel)
		# 打掉暗紅疊暗紅：面板改近不透明深漆底 + 飽和燙金 3px 硬框，從紅底圖跳出來。
		_hero_panel.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
			Color(0.12, 0.075, 0.055, 1.0), COTIW_UI_THEME.get_color("incense_gold"), 0, 3, 0.0))
	if _setup_card == null:
		_setup_card = Panel.new()
		_setup_card.name = "SetupCard"
		_setup_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_setup_card.z_index = -1
		add_child(_setup_card)
		_setup_card.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
			Color(0.12, 0.075, 0.055, 1.0), COTIW_UI_THEME.get_color("incense_gold"), 0, 3, 0.0))
	if _hero_spot == null:
		# 聚光燈墊於立繪後（z-1：在面板之上、立繪之下）
		_hero_spot = TextureRect.new()
		_hero_spot.name = "HeroSpot"
		_hero_spot.texture = _make_spot_texture()
		_hero_spot.stretch_mode = TextureRect.STRETCH_SCALE
		_hero_spot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hero_spot.z_index = -1
		add_child(_hero_spot)
	if _hero_portrait == null:
		_hero_portrait = TextureRect.new()
		_hero_portrait.name = "HeroPortrait"
		_hero_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_hero_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_hero_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_hero_portrait.clip_contents = true
		_hero_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_hero_portrait)
	if _hero_portrait_frame == null:
		# 英雄立繪燙金描邊（§A：立繪作英雄焦點）。透明底 + 飽和金硬框，疊在立繪邊緣。
		_hero_portrait_frame = Panel.new()
		_hero_portrait_frame.name = "HeroPortraitFrame"
		_hero_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hero_portrait_frame.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
			Color(0, 0, 0, 0), COTIW_UI_THEME.get_color("incense_gold"), 0, 3, 0.0))
		add_child(_hero_portrait_frame)
	if _tagline_label == null:
		_tagline_label = Label.new()
		_tagline_label.name = "TaglineLabel"
		_tagline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_tagline_label.add_theme_font_size_override("font_size", 15)
		_tagline_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.66, 0.92))
		_tagline_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_tagline_label)
	if _info_heading_label == null:
		_info_heading_label = _make_heading(tr("newrun.who_gets_what"))
	if _run_heading_label == null:
		_run_heading_label = _make_heading(tr("newrun.how_to_start"))
	if _character_tags_flow == null:
		_character_tags_flow = HFlowContainer.new()
		_character_tags_flow.name = "CharacterTagsFlow"
		_character_tags_flow.alignment = FlowContainer.ALIGNMENT_BEGIN
		_character_tags_flow.add_theme_constant_override("h_separation", 6)
		_character_tags_flow.add_theme_constant_override("v_separation", 6)
		_character_tags_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_character_tags_flow)

func _make_heading(text_value: String) -> Label:
	var lbl := Label.new()
	lbl.text = text_value
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold"))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	return lbl

## ② 設定卡：模式分段（明確選中態）+ 難度說明 + 進階摺疊（種子）
func _build_setup_card() -> void:
	if not _mode_buttons.is_empty():
		return
	_mode_heading_label = _make_heading(tr("newrun.mode"))
	_difficulty_hint_label = Label.new()
	_difficulty_hint_label.name = "DifficultyHint"
	_difficulty_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_difficulty_hint_label.add_theme_font_size_override("font_size", 13)
	_difficulty_hint_label.add_theme_color_override("font_color", Color(0.92, 0.84, 0.70, 0.86))
	_difficulty_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_difficulty_hint_label.text = tr("newrun.difficulty_hint")
	add_child(_difficulty_hint_label)

	for mode: String in [MODE_STANDARD, MODE_EASY, MODE_ENDLESS, MODE_CUSTOM]:
		var b := Button.new()
		b.name = "Mode_" + mode
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.text = tr("newrun.mode_" + mode)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.button_up.connect(_on_mode_picked.bind(mode))
		add_child(b)
		_mode_buttons.append(b)

	# 進階摺疊：種子預設收起（避免誤改 16 位種子碼）
	_seed_heading_label = Label.new()
	_seed_heading_label.name = "SeedHeading"
	_seed_heading_label.add_theme_font_size_override("font_size", 14)
	_seed_heading_label.add_theme_color_override("font_color", Color(0.90, 0.82, 0.68, 0.86))
	_seed_heading_label.text = tr("newrun.seed")
	_seed_heading_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_seed_heading_label)

	_advanced_toggle = Button.new()
	_advanced_toggle.name = "AdvancedToggle"
	_advanced_toggle.focus_mode = Control.FOCUS_NONE
	_advanced_toggle.flat = true
	_advanced_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_advanced_toggle.button_up.connect(_on_advanced_toggle)
	COTIW_UI_THEME.apply_secondary_button_style(_advanced_toggle)
	add_child(_advanced_toggle)

	_select_mode(MODE_STANDARD)
	_set_advanced_open(false)

func _build_character_gallery() -> void:
	if _character_gallery != null:
		return
	_character_gallery = CHARACTER_GALLERY_SCENE.instantiate()
	if _character_gallery == null:
		return
	_character_gallery.name = "CharacterGallery"
	add_child(_character_gallery)
	if _character_gallery.has_method("set_compact"):
		_character_gallery.set_compact(true)	# 陣容列模式
	_character_gallery.character_selected.connect(func(character_id: String): Signals.character_selected.emit(character_id))

func _relayout_runtime_chrome() -> void:
	var safe: Rect2 = Responsive.safe_rect if Responsive != null else Rect2(Vector2.ZERO, get_viewport_rect().size)
	safe.position -= global_position	# 螢幕座標 → parent-local（4:3 置中偏移）
	var L: Dictionary = calculate_layout(safe)
	var hero: Rect2 = L["hero"]
	var roster: Rect2 = L["roster"]
	var setup: Rect2 = L["setup"]
	var cta_zone: Rect2 = L["cta_zone"]
	var start_rect: Rect2 = L["start"]
	var advanced_rect: Rect2 = L["advanced"]
	var back_rect: Rect2 = L["back"]

	# 區塊面板
	if _hero_panel != null:
		_hero_panel.position = hero.position
		_hero_panel.size = hero.size
	if _setup_card != null:
		_setup_card.position = setup.position
		_setup_card.size = setup.size

	# ── ① 英雄面板內容（左半立繪、右半資訊）──
	var hp_pad: float = 16.0
	var portrait_w: float = hero.size.x * 0.42
	if _hero_portrait != null:
		_hero_portrait.position = hero.position + Vector2(hp_pad, hp_pad)
		_hero_portrait.size = Vector2(portrait_w, hero.size.y - hp_pad * 2.0 - 96.0)	# 底部留平安符列
	if _hero_portrait_frame != null and _hero_portrait != null:
		_hero_portrait_frame.position = _hero_portrait.position
		_hero_portrait_frame.size = _hero_portrait.size
	if _hero_spot != null and _hero_portrait != null:
		var spot_grow := Vector2(72.0, 72.0)
		_hero_spot.position = _hero_portrait.position - spot_grow * 0.5
		_hero_spot.size = _hero_portrait.size + spot_grow
	var info_x: float = hero.position.x + portrait_w + hp_pad * 2.0
	var info_w: float = hero.size.x - portrait_w - hp_pad * 3.0
	var info_y: float = hero.position.y + hp_pad
	if _info_heading_label != null:
		_info_heading_label.position = Vector2(info_x, info_y)
		_info_heading_label.size = Vector2(info_w, 22.0)
	if character_name_label != null:
		character_name_label.position = Vector2(info_x, info_y + 26.0)
		character_name_label.size = Vector2(info_w, 34.0)
		character_name_label.add_theme_font_size_override("font_size", 28)
	if _tagline_label != null:
		_tagline_label.position = Vector2(info_x, info_y + 64.0)
		_tagline_label.size = Vector2(info_w, 40.0)
	if character_health_label != null:
		character_health_label.position = Vector2(info_x, info_y + 110.0)
		character_health_label.size = Vector2(info_w * 0.5, 28.0)
	if character_money_label != null:
		character_money_label.position = Vector2(info_x + info_w * 0.5, info_y + 110.0)
		character_money_label.size = Vector2(info_w * 0.5, 28.0)
	if _character_tags_flow != null:
		_character_tags_flow.position = Vector2(info_x, info_y + 144.0)
		_character_tags_flow.size = Vector2(info_w, 64.0)
	# 平安符列（橫貫面板底部，描述完整 autowrap）
	var charm_y: float = hero.position.y + hero.size.y - 86.0
	if character_artifact_texture_rect != null:
		character_artifact_texture_rect.position = Vector2(hero.position.x + hp_pad, charm_y)
		character_artifact_texture_rect.size = Vector2(64, 64)
	if character_artifact_name_label != null:
		character_artifact_name_label.position = Vector2(hero.position.x + hp_pad + 76.0, charm_y)
		character_artifact_name_label.size = Vector2(hero.size.x - hp_pad * 2.0 - 76.0, 26.0)
	if character_artifact_description_label != null:
		character_artifact_description_label.position = Vector2(hero.position.x + hp_pad + 76.0, charm_y + 28.0)
		character_artifact_description_label.size = Vector2(hero.size.x - hp_pad * 2.0 - 76.0, 56.0)
	# 舊描述標籤併入 tagline 概念，隱藏避免重複（單一真相）
	if character_description_label != null:
		character_description_label.visible = false

	# ── 陣容列 ──
	if _character_gallery != null:
		_character_gallery.position = roster.position
		_character_gallery.size = roster.size

	# ── ② 設定卡內容（緊湊堆疊，1200×700 不溢出；觸控 ≥64）──
	var sx: float = setup.position.x + hp_pad
	var sw: float = setup.size.x - hp_pad * 2.0
	var sy: float = setup.position.y + 14.0
	var setup_bottom: float = setup.position.y + setup.size.y
	if _run_heading_label != null:
		_run_heading_label.position = Vector2(sx, sy)
		_run_heading_label.size = Vector2(sw, 20.0)
	# 難度 stepper（− 數字 +）
	if difficulty_select != null:
		difficulty_select.position = Vector2(sx, sy + 26.0)
		difficulty_select.size = Vector2(sw, 72.0)
	if decrease_difficulty_button != null:
		decrease_difficulty_button.position = Vector2(0, 0)
		decrease_difficulty_button.size = Vector2(72, 72)
	if increase_difficulty_button != null:
		increase_difficulty_button.position = Vector2(sw - 72.0, 0)
		increase_difficulty_button.size = Vector2(72, 72)
	if difficulty_label != null:
		difficulty_label.position = Vector2(80.0, 0)
		difficulty_label.size = Vector2(sw - 160.0, 72.0)
	if _difficulty_hint_label != null:
		_difficulty_hint_label.position = Vector2(sx, sy + 102.0)
		_difficulty_hint_label.size = Vector2(sw, 32.0)
	# 模式分段（觸控 ≥64）
	var mode_y: float = sy + 140.0
	if _mode_heading_label != null:
		_mode_heading_label.position = Vector2(sx, mode_y)
		_mode_heading_label.size = Vector2(sw, 20.0)
	var seg_y: float = mode_y + 24.0
	var seg_gap: float = 8.0
	var seg_w: float = (sw - seg_gap * float(_mode_buttons.size() - 1)) / float(maxi(1, _mode_buttons.size()))
	for i: int in _mode_buttons.size():
		var b: Button = _mode_buttons[i]
		b.position = Vector2(sx + float(i) * (seg_w + seg_gap), seg_y)
		b.size = Vector2(seg_w, 64.0)
	# 護壇 / 法器（觸控 ≥64）
	var picker_y: float = seg_y + 70.0
	if _guardian_picker != null:
		_guardian_picker.position = Vector2(sx, picker_y)
		_guardian_picker.size = Vector2(sw, 64.0)
	if _tool_picker != null:
		_tool_picker.position = Vector2(sx, picker_y + 70.0)
		_tool_picker.size = Vector2(sw, 64.0)
	# 自訂 checkbox 容器（僅自訂模式可見）：設定卡底部剩餘空間（ScrollContainer 自捲）
	if custom_run_modifier_button_container != null:
		var cc_y: float = picker_y + 140.0
		custom_run_modifier_button_container.position = Vector2(sx, cc_y)
		custom_run_modifier_button_container.size = Vector2(sw, maxf(40.0, setup_bottom - cc_y - 8.0))

	# ── ③ 開壇 CTA（右寬欄巨大獨佔）+ 進階/種子（左窄欄，不互擠）──
	if start_run_button != null:
		start_run_button.position = start_rect.position
		start_run_button.size = start_rect.size
		start_run_button.add_theme_font_size_override("font_size", 32)
	if _advanced_toggle != null:
		_advanced_toggle.position = advanced_rect.position
		_advanced_toggle.size = advanced_rect.size
	var seed_rect: Rect2 = L["seed"]
	var seed_visible: bool = _advanced_open
	if _seed_heading_label != null:
		_seed_heading_label.visible = seed_visible
		_seed_heading_label.position = seed_rect.position
		_seed_heading_label.size = Vector2(seed_rect.size.x, 24.0)
	if seed_input != null:
		seed_input.visible = seed_visible
		seed_input.position = Vector2(seed_rect.position.x, seed_rect.position.y + 26.0)
		seed_input.size = Vector2(seed_rect.size.x, maxf(32.0, seed_rect.size.y - 26.0))

	# 返回正殿（左上）
	if back_button != null:
		back_button.position = back_rect.position
		back_button.size = back_rect.size

func _on_seed_input_text_changed(new_text: String) -> void:
	var caret_column: int = seed_input.caret_column
	seed_input.text = str(new_text.to_int())
	seed_input.caret_column = min(caret_column, len(seed_input.text))

func _on_character_selected(character_object_id: String) -> void:
	selected_character_object_id = character_object_id
	populate_character_info(selected_character_object_id)
	if _character_gallery != null:
		_character_gallery.select_character(character_object_id)
	_start_run_button_state(not selected_character_object_id.is_empty())

func _on_decrease_difficulty_button() -> void:
	selected_difficulty_level = max(0, selected_difficulty_level - 1)
	_update_difficulty_label()

func _on_increase_difficulty_button() -> void:
	selected_difficulty_level = min(selected_difficulty_level + 1, len(PlayerData.DIFFICULTY_RUN_MODIFIER_OBJECT_IDS))
	_update_difficulty_label()

func _update_difficulty_label() -> void:
	difficulty_label.text = tr("newrun.difficulty") % selected_difficulty_level

## 模式分段：選中態明確（toggle pressed）+ 設定 run_modifier；自訂展開 checkbox 容器
func _on_mode_picked(mode: String) -> void:
	_select_mode(mode)

func _select_mode(mode: String) -> void:
	_selected_mode = mode
	for b: Button in _mode_buttons:
		b.set_pressed_no_signal(b.name == "Mode_" + mode)
	if custom_run_modifier_button_container != null:
		custom_run_modifier_button_container.visible = (mode == MODE_CUSTOM)

func _collect_run_modifiers() -> Array[String]:
	var out: Array[String] = []
	if _selected_mode == MODE_CUSTOM:
		for m: String in custom_run_modifier_button_container.selected_custom_run_modififers:
			out.append(m)
	else:
		for m: Variant in MODE_TO_MODIFIERS.get(_selected_mode, []):
			out.append(str(m))
	return out

func _on_advanced_toggle() -> void:
	_set_advanced_open(not _advanced_open)

func _set_advanced_open(value: bool) -> void:
	_advanced_open = value
	if _advanced_toggle != null:
		_advanced_toggle.text = tr("newrun.advanced_open") if not value else tr("newrun.advanced_close")
	_relayout_runtime_chrome()

func populate_new_run_menu() -> void:
	custom_run_modifier_button_container.populate_custom_run_modifiers(CUSTOM_LIST_EXCLUDE)
	_refresh_character_gallery()
	_select_default_character_if_needed()

func populate_character_info(character_object_id: String) -> void:
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data == null:
		character_name_label.text = tr("newrun.pick_first")
		character_health_label.text = tr("newrun.hp_empty")
		character_money_label.text = tr("newrun.money_empty")
		if _tagline_label != null:
			_tagline_label.text = tr("newrun.altar_unset")
		if _hero_portrait != null:
			_hero_portrait.texture = null
		character_artifact_texture_rect.texture = null
		character_artifact_name_label.text = tr("newrun.charm_tbd")
		character_artifact_description_label.text = tr("newrun.pick_to_see")
		_populate_character_tags([])
		return

	character_name_label.text = character_data.character_name
	character_health_label.text = tr("newrun.hp") % character_data.character_starting_health
	character_money_label.text = tr("newrun.money") % character_data.character_starting_money
	if _tagline_label != null:
		_tagline_label.text = character_data.character_description
	if _hero_portrait != null:
		var portrait_path: String = PORTRAIT_DIR + _portrait_file_for(character_object_id)
		_hero_portrait.texture = load(portrait_path) if ResourceLoader.exists(portrait_path) else null
	_populate_character_tags(_tags_for_character(character_object_id))

	var starter_artifact_name: String = tr("newrun.no_charm")
	var starter_artifact_description: String = ""
	character_artifact_texture_rect.texture = null
	if len(character_data.character_starting_artifact_ids) > 0:
		var artifact_data: ArtifactData = Global.get_artifact_data(character_data.character_starting_artifact_ids[0])
		if artifact_data != null:
			character_artifact_texture_rect.texture = CardArtRegistry.resolve_artifact_texture(artifact_data)
			starter_artifact_name = artifact_data.artifact_name
			starter_artifact_description = artifact_data.artifact_description
	character_artifact_name_label.text = starter_artifact_name
	character_artifact_description_label.text = starter_artifact_description if not starter_artifact_description.is_empty() else tr("newrun.no_relic")

func _populate_character_tags(tags: Array) -> void:
	if _character_tags_flow == null:
		return
	for child in _character_tags_flow.get_children():
		child.queue_free()
	for raw_tag in tags:
		var tag_text: String = str(raw_tag)
		if tag_text.is_empty():
			continue
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(0, 26)
		panel.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
			Color(0.20, 0.08, 0.05, 0.94), Color(0.90, 0.68, 0.26, 0.84), 0, 1, 0.0))
		var label := Label.new()
		label.text = tag_text
		label.position = Vector2(9, 2)
		label.size = Vector2(maxf(58.0, float(tag_text.length()) * 16.0), 22.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.82, 1.0))
		panel.custom_minimum_size.x = label.size.x + 18.0
		panel.add_child(label)
		_character_tags_flow.add_child(panel)

func _refresh_character_gallery() -> void:
	if _character_gallery == null:
		return
	_character_gallery.setup_entries(_build_gallery_entries())
	_character_gallery.select_character(selected_character_object_id)

func _build_gallery_entries() -> Array:
	var entries: Array = []
	for shelf_entry in _character_shelf:
		var entry: Dictionary = shelf_entry.duplicate(true)
		var character_id: String = str(entry.get("character_id", ""))
		var character_data: CharacterData = Global.get_character_data(character_id)
		var has_data: bool = character_data != null
		var unlocked: bool = has_data and Global.is_character_unlocked(character_id)
		var unlock_hint: String = Global.get_unlock_hint(character_id)
		if unlock_hint.is_empty():
			unlock_hint = str(entry.get("fallback_hint", ""))
		entry["locked"] = not unlocked
		entry["portrait_path"] = PORTRAIT_DIR + str(entry.get("portrait_file", ""))
		entry["unlock_hint"] = unlock_hint
		if has_data:
			entry["label"] = character_data.character_name
			entry["description"] = character_data.character_description
			if len(character_data.character_starting_artifact_ids) > 0:
				var artifact_data: ArtifactData = Global.get_artifact_data(character_data.character_starting_artifact_ids[0])
				if artifact_data != null:
					entry["starter_name"] = artifact_data.artifact_name
					entry["starter_description"] = artifact_data.artifact_description
		else:
			entry["description"] = str(entry.get("locked_copy", tr("newrun.eye_unopened")))
		entries.append(entry)
	return entries

func _select_default_character_if_needed() -> void:
	if not selected_character_object_id.is_empty() and Global.get_character_data(selected_character_object_id) != null:
		return
	for entry in _build_gallery_entries():
		if not bool(entry.get("locked", true)):
			var character_id: String = str(entry.get("character_id", ""))
			if not character_id.is_empty():
				Signals.character_selected.emit(character_id)
				return
	_on_character_selected("")

func _portrait_file_for(character_object_id: String) -> String:
	for shelf_entry in _character_shelf:
		if str(shelf_entry.get("character_id", "")) == character_object_id:
			return str(shelf_entry.get("portrait_file", ""))
	return ""

func _tags_for_character(character_object_id: String) -> Array:
	for shelf_entry in _character_shelf:
		if str(shelf_entry.get("character_id", "")) == character_object_id:
			return shelf_entry.get("tags", [])
	return []

func _load_character_shelf() -> Array:
	if not FileAccess.file_exists(CHARACTER_SHELF_PATH):
		push_error("NewRunMenu: missing character shelf data: " + CHARACTER_SHELF_PATH)
		return _fallback_character_shelf_from_global()
	var file := FileAccess.open(CHARACTER_SHELF_PATH, FileAccess.READ)
	if file == null:
		push_error("NewRunMenu: cannot open character shelf data: " + CHARACTER_SHELF_PATH)
		return _fallback_character_shelf_from_global()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("NewRunMenu: character shelf JSON must be an array")
		return _fallback_character_shelf_from_global()
	var shelf: Array = []
	for item in parsed:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = (item as Dictionary).duplicate(true)
		if not entry.has("tags") or typeof(entry["tags"]) != TYPE_ARRAY:
			entry["tags"] = []
		shelf.append(entry)
	if shelf.is_empty():
		return _fallback_character_shelf_from_global()
	return shelf

func _fallback_character_shelf_from_global() -> Array:
	var shelf: Array = []
	for character_id: String in Global._id_to_character_data.keys():
		var character_data: CharacterData = Global.get_character_data(character_id)
		if character_data == null:
			continue
		shelf.append({
			"character_id": character_id,
			"label": character_data.character_name,
			"portrait_file": "",
			"locked_copy": character_data.character_description,
			"tags": [],
			"build_hint": "",
		})
	return shelf

func _start_run_button_state(can_start: bool) -> void:
	start_run_button.disabled = not can_start

## 護壇 / 法器選擇器（OptionButton；留空 = 角色預設班底）
func _build_loadout_pickers() -> void:
	if _guardian_picker != null:
		return
	_guardian_picker = _make_loadout_picker(RitualLoadout.list_guardian_ids(), tr("newrun.guardian"), true)
	_guardian_picker.item_selected.connect(_on_guardian_picked)
	add_child(_guardian_picker)
	_tool_picker = _make_loadout_picker(RitualLoadout.list_tool_ids_unlocked(Global.profile_data), tr("newrun.tool"), false)
	_tool_picker.item_selected.connect(_on_tool_picked)
	add_child(_tool_picker)

func _make_loadout_picker(ids: Array, prefix: String, is_guardian: bool) -> OptionButton:
	var ob: OptionButton = OptionButton.new()
	ob.name = prefix + "Picker"
	ob.clip_text = true
	ob.fit_to_longest_item = false
	ob.add_item(tr("newrun.default_pick") % prefix)
	ob.set_item_metadata(0, "")
	for id: String in ids:
		var disp: String = id
		if is_guardian:
			var g: GuardianData = RitualLoadout.load_guardian(id)
			if g != null and g.guardian_name != "":
				disp = g.guardian_name
		else:
			var t: RitualToolData = RitualLoadout.load_tool(id)
			if t != null and t.tool_name != "":
				disp = t.tool_name
		ob.add_item("%s：%s" % [prefix, disp])
		ob.set_item_metadata(ob.item_count - 1, id)
	_apply_picker_icons(ob, ids)
	return ob

func _on_guardian_picked(idx: int) -> void:
	selected_guardian_id = str(_guardian_picker.get_item_metadata(idx))

func _on_tool_picked(idx: int) -> void:
	selected_ritual_tool_id = str(_tool_picker.get_item_metadata(idx))

func _on_start_run_button_up() -> void:
	if selected_character_object_id.is_empty():
		return
	var run_seed: int = seed_input.text.to_int()
	Global.start_run(selected_character_object_id, run_seed, selected_difficulty_level, _collect_run_modifiers(), selected_guardian_id, selected_ritual_tool_id)

func _on_back_button_up() -> void:
	title_screen.show_main_menu()

func _on_run_ended() -> void:
	var has_save_file: bool = FileLoader.has_save_file()
	visible = not has_save_file
	selected_character_object_id = ""
	populate_new_run_menu()

func _apply_picker_icons(picker: OptionButton, ids: Array) -> void:
	for i: int in mini(picker.item_count, ids.size()):
		var icon_path: String = "res://assets/generated/icons_v2/loadout_%s.svg" % str(ids[i])
		if not ResourceLoader.exists(icon_path):
			continue
		var tex: Texture2D = load(icon_path)
		var img: Image = tex.get_image()
		if img == null:
			continue
		img.resize(28, 28, Image.INTERPOLATE_LANCZOS)
		picker.set_item_icon(i, ImageTexture.create_from_image(img))
