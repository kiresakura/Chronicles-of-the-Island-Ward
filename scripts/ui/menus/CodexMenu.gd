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
const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const FC := preload("res://scripts/systems/ritual/FormationCombat.gd")	# FP-3 符令圖鑑來源

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
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var tab_sidebar: VBoxContainer = $VBoxContainer
@onready var codex_card_container: GridContainer = $ScrollContainer/MarginContainer/CodexCardContainer
@onready var tab_cards: Button = %TabCards
@onready var tab_jiajiang: Button = %TabJiajiang
@onready var tab_deities: Button = %TabDeities

enum TAB { CARDS, JIAJIANG, DEITIES, FU }
var _current_tab: int = TAB.CARDS
var _tab_fu: Button		# FP-3 符令分頁（runtime 建，沿用卡牌分頁樣式）


func _ready() -> void:
	back_button.button_up.connect(_on_back_button_up)
	if is_instance_valid(tab_cards):
		tab_cards.button_up.connect(_on_tab_cards)
		_build_fu_tab_button()	# 在「卡圖收藏」之後插入「符令」分頁
	if is_instance_valid(tab_jiajiang):
		tab_jiajiang.button_up.connect(_on_tab_jiajiang)
	if is_instance_valid(tab_deities):
		tab_deities.button_up.connect(_on_tab_deities)
	# 佈局契約：自管安全區內縮 + 響應式欄數（取代 TitleScreen 的 SafeFit 等比縮放）。
	# 純從 viewport + Responsive.safe_rect 推導區塊（無寫死 1200×700 座標），resize 自動重排。
	scale = Vector2.ONE
	position = Vector2.ZERO
	_apply_safe()
	var resp: Node = get_node_or_null("/root/Responsive")
	if resp != null and resp.has_signal("changed") and not resp.changed.is_connected(_apply_safe):
		resp.changed.connect(_apply_safe)
	# 焦點導航：分頁 + 返回可達（卡位於 _populate_cards 設 FOCUS_ALL）
	for b: Button in [tab_cards, tab_jiajiang, tab_deities, back_button]:
		if is_instance_valid(b):
			b.focus_mode = Control.FOCUS_ALL

## 符令分頁鈕：複製卡牌分頁鈕（沿用主題樣式）、改文案、插在其後、接 _on_tab_fu。
func _build_fu_tab_button() -> void:
	if _tab_fu != null:
		return
	_tab_fu = tab_cards.duplicate()
	_tab_fu.name = "TabFu"
	_tab_fu.text = tr("codex.tab_fu")
	tab_cards.get_parent().add_child(_tab_fu)
	tab_cards.get_parent().move_child(_tab_fu, tab_cards.get_index() + 1)
	_tab_fu.button_up.connect(_on_tab_fu)


func populate_codex_menu() -> void:
	_apply_safe()	# 開啟時 viewport 可能已變 → 重排一次
	_show_tab(TAB.CARDS)
	if is_instance_valid(tab_cards):
		tab_cards.grab_focus.call_deferred()	# 初始焦點落首分頁（手把/鍵盤入口）


func _show_tab(tab: int) -> void:
	_current_tab = tab
	_clear_container()
	_recompute_columns(tab)	# 響應式欄數（取代寫死 6/4/3）
	match tab:
		TAB.CARDS:
			_populate_cards()
		TAB.FU:
			_populate_fu()
		TAB.JIAJIANG:
			_populate_portraits(JIAJIANG_LIST, JIAJIANG_DIR)
		TAB.DEITIES:
			_populate_portraits(DEITY_LIST, DEITY_DIR)
	# 邊界態：分類為空 → 置中提示（防呆；active 分頁恆有資料，停用分頁不可點）
	if codex_card_container.get_child_count() == 0:
		codex_card_container.columns = 1
		var hint := Label.new()
		hint.text = tr("codex.empty_category")
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", COTIW_UI_THEME.get_typography_size("body", 22))
		hint.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("smoke_gray", Color(0.55, 0.49, 0.45)))
		codex_card_container.add_child(hint)


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
		card.focus_mode = Control.FOCUS_ALL	# 焦點導航：D-pad 可進卡牌格（ScrollContainer follow_focus 自動捲）
		shown += 1


## FP-3 符令圖鑑：列出 formation_fu.json 全符（名/稀有星/述/可合提示），稀有度配色。
func _populate_fu() -> void:
	var ids: Array = FC.fu_library().keys()
	ids.sort()
	for fu_id: String in ids:
		codex_card_container.add_child(_make_fu_card(str(fu_id)))

func _make_fu_card(fu_id: String) -> Control:
	var d: Dictionary = FC.fu_def(fu_id)
	var rarity: String = str(d.get("rarity", "common"))
	var col: Color = _fu_rarity_color(rarity)
	var root := PanelContainer.new()
	root.custom_minimum_size = Vector2(184, 210)
	root.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(Color(0.12, 0.08, 0.06, 0.96), col, 0, 3, 0.0))
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	root.add_child(vbox)
	var name_label := Label.new()
	name_label.text = str(d.get("name", fu_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", col)
	vbox.add_child(name_label)
	var stars := Label.new()
	stars.text = "★".repeat(_rarity_stars(rarity))
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_font_size_override("font_size", 14)
	stars.add_theme_color_override("font_color", col)
	vbox.add_child(stars)
	var desc := Label.new()
	desc.text = str(d.get("desc", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.custom_minimum_size = Vector2(160, 64)
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.92, 0.86, 0.74))
	vbox.add_child(desc)
	if FC.fu_can_merge(fu_id):
		var mh := Label.new()
		mh.text = tr("codex.fu_mergeable")
		mh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mh.add_theme_font_size_override("font_size", 12)
		mh.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("spirit_jade", Color(0.42, 0.80, 0.60)))
		vbox.add_child(mh)
	return root

func _fu_rarity_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return COTIW_UI_THEME.get_color("festival_red", Color(0.90, 0.40, 0.28))
		"uncommon":
			return COTIW_UI_THEME.get_color("spirit_jade", Color(0.42, 0.80, 0.60))
		_:
			return COTIW_UI_THEME.get_color("incense_gold", Color(0.85, 0.72, 0.42))

func _rarity_stars(rarity: String) -> int:
	match rarity:
		"rare":
			return 3
		"uncommon":
			return 2
		_:
			return 1


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


## 佈局契約核心：從 viewport + safe_rect 推導三區塊（側欄／返回／內容捲動），
## 全出血底由 UiMaskFitter 管 DimBackground。零寫死 1200×700，resize 經 Responsive.changed 重排。
func _apply_safe() -> void:
	if not is_instance_valid(scroll_container):
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var safe: Rect2 = COTIW_UI_THEME.get_safe_content_rect(get_viewport())
	var base: float = float(COTIW_UI_THEME.get_spacing("lg", 24))
	var gap: float = float(COTIW_UI_THEME.get_spacing("md", 16))
	var l: float = base + maxf(0.0, safe.position.x)
	var t: float = base + maxf(0.0, safe.position.y)
	var r: float = base + maxf(0.0, vp.x - safe.end.x)
	var b: float = base + maxf(0.0, vp.y - safe.end.y)
	# 響應式：窄寬比（平板 4:3）側欄收窄讓位給內容
	var ar: float = vp.x / maxf(vp.y, 1.0)
	var side_w: float = 150.0 if ar < 1.6 else 172.0
	var back_h: float = 64.0
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	# 側欄分頁：左欄，置於返回鈕之上
	_place(tab_sidebar, l, t, side_w, maxf(120.0, vp.y - t - b - back_h - gap))
	# 返回：左下（拇指可達；原置中改靠左以讓出內容高度）
	_place(back_button, l, vp.y - b - back_h, side_w, back_h)
	# 內容捲動：填右側剩餘、內縮安全區
	var sx: float = l + side_w + gap
	_place(scroll_container, sx, t, maxf(200.0, vp.x - sx - r), maxf(160.0, vp.y - t - b))
	_recompute_columns(_current_tab)


## 置入區塊（anchor 左上 + 由安全區推導的 offset）；resize 時整批重算 → 響應式無寫死座標。
func _place(c: Control, x: float, y: float, w: float, h: float) -> void:
	if not is_instance_valid(c):
		return
	c.set_anchors_preset(PRESET_TOP_LEFT)
	c.offset_left = x
	c.offset_top = y
	c.offset_right = x + w
	c.offset_bottom = y + h


## 響應式欄數：由內容捲動區可用寬推導（不寫死 6/4/3），各分頁 cell 目標寬不同。
func _recompute_columns(tab: int) -> void:
	if not is_instance_valid(scroll_container) or not is_instance_valid(codex_card_container):
		return
	# 用 offset 推導寬（剛由 _apply_safe 設定，比可能 stale 的 .size 可靠），扣 MarginContainer 10+10
	var inner: float = (scroll_container.offset_right - scroll_container.offset_left) - 20.0
	var target: float = 168.0
	var lo: int = 3
	var hi: int = 6
	match tab:
		TAB.JIAJIANG, TAB.FU:
			target = 196.0; lo = 2; hi = 4
		TAB.DEITIES:
			target = 240.0; lo = 2; hi = 3
		_:
			target = 168.0; lo = 3; hi = 6
	codex_card_container.columns = clampi(int(inner / target), lo, hi)


# Legacy public API kept for backwards compatibility
func populate_codex_card_container() -> void:
	_show_tab(TAB.CARDS)


func clear_codex_card_container() -> void:
	_clear_container()


func _on_tab_cards() -> void:
	_show_tab(TAB.CARDS)


func _on_tab_fu() -> void:
	_show_tab(TAB.FU)


func _on_tab_jiajiang() -> void:
	_show_tab(TAB.JIAJIANG)


func _on_tab_deities() -> void:
	_show_tab(TAB.DEITIES)


func _on_back_button_up() -> void:
	_clear_container()
	title_screen.show_main_menu()
