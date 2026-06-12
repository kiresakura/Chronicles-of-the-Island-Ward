## UI menu to display all content in the game such as all cards, 8家將 portraits, and 神明 deity portraits.
##
## Tab buttons in sidebar swap codex_card_container content:
##  - 卡牌: all CardData (6 cols, uses Card.tscn)
##  - 家將: 8 jiajiang generals (4 cols, portrait + 中文 label)
##  - 神明: 6 deities (3 cols, portrait + 中文 label)
##
## 友善鐵律 3: 加 logic 不動 STR existing flow; sidebar buttons connect on _ready.
extends Control

const JIAJIANG_DIR := "res://assets/generated/jiajiang_v3/"
const DEITY_DIR := "res://assets/generated/deities_v3/"
const CARD_ART_REGISTRY := preload("res://scripts/ui/theme/CardArtRegistry.gd")

# (sid, 中文標題, 副標)
const JIAJIANG_LIST: Array = [
	["gan_general", "codex.gan_general.name", "codex.gan_general.title"],
	["liu_general", "codex.liu_general.name", "codex.liu_general.title"],
	["xie_general", "codex.xie_general.name", "codex.xie_general.title"],
	["fan_general", "codex.fan_general.name", "codex.fan_general.title"],
	["spring_god", "codex.spring_god.name", "codex.spring_god.title"],
	["summer_god", "codex.summer_god.name", "codex.summer_god.title"],
	["autumn_god", "codex.autumn_god.name", "codex.autumn_god.title"],
	["winter_god", "codex.winter_god.name", "codex.winter_god.title"],
]

const DEITY_LIST: Array = [
	["mazu", "codex.mazu.name", "codex.mazu.title"],
	["guanyin", "codex.guanyin.name", "codex.guanyin.title"],
	["wangye", "codex.wangye.name", "codex.wangye.title"],
	["chenghuang", "codex.chenghuang.name", "codex.chenghuang.title"],
	["tudi", "codex.tudi.name", "codex.tudi.title"],
	["huye", "codex.huye.name", "codex.huye.title"],
]

@onready var title_screen: Control = $%TitleScreen
@onready var back_button: Button = $BackButton
@onready var codex_card_container: GridContainer = $ScrollContainer/MarginContainer/CodexCardContainer
@onready var tab_cards: Button = %TabCards
@onready var tab_jiajiang: Button = %TabJiajiang
@onready var tab_deities: Button = %TabDeities

enum TAB { CARDS, JIAJIANG, DEITIES }
var _current_tab: int = TAB.CARDS


func _ready() -> void:
	back_button.button_up.connect(_on_back_button_up)
	if is_instance_valid(tab_cards):
		tab_cards.button_up.connect(_on_tab_cards)
	if is_instance_valid(tab_jiajiang):
		tab_jiajiang.button_up.connect(_on_tab_jiajiang)
	if is_instance_valid(tab_deities):
		tab_deities.button_up.connect(_on_tab_deities)


func populate_codex_menu() -> void:
	_show_tab(TAB.CARDS)


func _show_tab(tab: int) -> void:
	_current_tab = tab
	_clear_container()
	codex_card_container.columns = 6 if tab == TAB.CARDS else (4 if tab == TAB.JIAJIANG else 3)
	match tab:
		TAB.CARDS:
			_populate_cards()
		TAB.JIAJIANG:
			_populate_portraits(JIAJIANG_LIST, JIAJIANG_DIR)
		TAB.DEITIES:
			_populate_portraits(DEITY_LIST, DEITY_DIR)


## 收藏卡牌過濾：只顯示 active COTIW 角色卡（乩童/鸞女/道士/家將），
## 不公開 external/data/cards/str 的 legacy/debug 卡（最大污染源）。
const ACTIVE_CARD_PREFIXES: Array = [
	"card_tongji_", "card_luannu_", "card_daoshi_", "card_jiajiang_",
]

func _is_active_cotiw_card(card_object_id: String) -> bool:
	for prefix: String in ACTIVE_CARD_PREFIXES:
		if card_object_id.begins_with(prefix):
			return true
	return false

func _populate_cards() -> void:
	var card_object_ids: Array = Global._id_to_card_data.keys()
	card_object_ids.sort()	# 依 id 排序 → 角色卡群聚（tongji/luannu/daoshi/jiajiang）
	var shown: int = 0
	for card_object_id: String in card_object_ids:
		if not _is_active_cotiw_card(card_object_id):
			continue	# 過濾 STR legacy/debug 卡
		var card_data: CardData = Global.get_card_data(card_object_id)
		var card: Card = Scenes.CARD.instantiate()
		codex_card_container.add_child(card)
		card.init(card_data, 0, false, false)
		shown += 1


func _populate_portraits(spec_list: Array, base_dir: String) -> void:
	for entry in spec_list:
		var sid: String = entry[0]
		var title: String = tr(entry[1])
		var subtitle: String = tr(entry[2])
		var portrait: Control = _make_portrait_card(sid, title, subtitle, base_dir)
		codex_card_container.add_child(portrait)


func _make_portrait_card(sid: String, title: String, subtitle: String, base_dir: String) -> Control:
	var card_size := Vector2(184, 256)
	var root := PanelContainer.new()
	root.custom_minimum_size = card_size

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.094, 0.071, 0.063, 0.82)
	sb.border_color = Color(0.831, 0.686, 0.216, 0.86)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	root.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	root.add_child(vbox)

	var img := TextureRect.new()
	img.custom_minimum_size = Vector2(168, 196)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# 先走 CardArtRegistry（已 preload 保證 ship），fallback path-based 載入
	var tex: Texture2D = null
	if base_dir.contains("jiajiang"):
		tex = CARD_ART_REGISTRY.get_jiajiang(sid)
	elif base_dir.contains("deities"):
		tex = CARD_ART_REGISTRY.get_deity(sid)
	if tex == null:
		var png_path: String = base_dir + sid + ".png"
		if ResourceLoader.exists(png_path):
			tex = load(png_path)
	img.texture = tex
	vbox.add_child(img)

	var name_label := Label.new()
	name_label.text = title
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1, 0.953, 0.498))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	vbox.add_child(name_label)

	var subtitle_label := Label.new()
	subtitle_label.text = subtitle
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 11)
	subtitle_label.add_theme_color_override("font_color", Color(0.957, 0.839, 0.498, 0.86))
	vbox.add_child(subtitle_label)

	return root


func _clear_container() -> void:
	for child in codex_card_container.get_children():
		child.queue_free()


# Legacy public API kept for backwards compatibility
func populate_codex_card_container() -> void:
	_show_tab(TAB.CARDS)


func clear_codex_card_container() -> void:
	_clear_container()


func _on_tab_cards() -> void:
	_show_tab(TAB.CARDS)


func _on_tab_jiajiang() -> void:
	_show_tab(TAB.JIAJIANG)


func _on_tab_deities() -> void:
	_show_tab(TAB.DEITIES)


func _on_back_button_up() -> void:
	_clear_container()
	title_screen.show_main_menu()
