# 鎮島錄 ─ 角色總覽面板
# 從主畫面「角色」鈕進入；展示 4 名角色（2 開放 + 2 鎖定）。
# 程序化建構，由 TitleScreen 動態 add_child；無需 .tscn。
extends Control
class_name CharacterPanel

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const PORTRAIT_DIR    := "res://assets/generated/portraits_v3/"
const BG_IMG          := "res://assets/generated/pixellab/mainmenu_temple_v5.png"

var GOLD:          Color = Color(0.95, 0.82, 0.45)
var GOLD_DIM:      Color = Color(0.62, 0.49, 0.24)
var PANEL_BG:      Color = Color(0.14, 0.05, 0.04, 0.93)
var PANEL_BG_LOCK: Color = Color(0.10, 0.08, 0.08, 0.80)

# 角色清單：已解鎖者有 id；鎖定者 id 為空
const CHARS: Array = [
	{"id": "character_tongji",  "file": "tongji.png",  "locked": false},
	{"id": "character_luannu",  "file": "luannu.png",  "locked": false},
	{"id": "",                  "file": "daoshi.png",  "locked": true,
	 "name": "道士", "desc": "（尚未解鎖）"},
	{"id": "",                  "file": "jiajiang.png","locked": true,
	 "name": "家將", "desc": "（尚未解鎖）"},
]

var _title_lbl: Label
var _back_btn:  Button
var _cards:     Array = []   # Array of Dictionaries: {panel, portrait, name_lbl, hp_lbl, desc_lbl}

func _ready() -> void:
	GOLD     = COTIW_UI_THEME.get_color("incense_gold", GOLD)
	GOLD_DIM = COTIW_UI_THEME.get_color("old_gold",     GOLD_DIM)

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP   # 吃掉所有點擊，不讓事件穿透

	_build_backdrop()
	_build_title()
	_build_cards()
	_build_back_button()

	await get_tree().process_frame
	_relayout()
	Responsive.changed.connect(_relayout)

# ── 背景 ──────────────────────────────────────────────────────────────

func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.name  = "Backdrop"
	bg.color = Color(0.05, 0.02, 0.02, 0.94)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	if ResourceLoader.exists(BG_IMG):
		var tr := TextureRect.new()
		tr.texture      = load(BG_IMG)
		tr.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.modulate     = Color(1.0, 1.0, 1.0, 0.22)
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)

# ── 標題 ──────────────────────────────────────────────────────────────

func _build_title() -> void:
	_title_lbl = Label.new()
	_title_lbl.name = "TitleLabel"
	_title_lbl.text = "角色"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_font(_title_lbl, 38)
	add_child(_title_lbl)

# ── 角色卡片 ──────────────────────────────────────────────────────────

func _build_cards() -> void:
	for c in CHARS:
		var locked: bool = c["locked"]

		# 取得角色資料（只有已解鎖且有 id 才查）
		var cd = null
		if not locked and c["id"] != "":
			cd = Global.get_character_data(c["id"])

		var char_name: String
		var char_desc: String
		var char_hp: int
		if cd != null:
			char_name = cd.character_name
			char_desc = cd.character_description
			char_hp   = cd.character_starting_health
		else:
			char_name = c.get("name", "???")
			char_desc = c.get("desc", "")
			char_hp   = 0

		# 外框 Panel
		var panel := Panel.new()
		panel.name = "Card_" + c["file"].get_basename()
		panel.add_theme_stylebox_override("panel",
			_sb(PANEL_BG_LOCK if locked else PANEL_BG,
				GOLD_DIM if locked else GOLD, 2, 12))
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(panel)

		# 立繪
		var portrait := TextureRect.new()
		portrait.name        = "Portrait"
		var p_path: String   = PORTRAIT_DIR + c["file"]
		if ResourceLoader.exists(p_path):
			portrait.texture = load(p_path)
		portrait.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.modulate     = Color(0.45, 0.45, 0.45, 0.70) if locked else Color(1, 1, 1, 1)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(portrait)

		# 名稱（鎖定者附上「（鎖）」）
		var name_lbl := Label.new()
		name_lbl.name = "NameLabel"
		name_lbl.text = char_name + ("（鎖）" if locked else "")
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_gold_font(name_lbl, 20)
		if locked:
			name_lbl.add_theme_color_override("font_color", GOLD_DIM)
		panel.add_child(name_lbl)

		# HP
		var hp_lbl := Label.new()
		hp_lbl.name = "HpLabel"
		hp_lbl.text = ("HP  %d" % char_hp) if not locked else "——"
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_gold_font(hp_lbl, 16)
		hp_lbl.add_theme_color_override("font_color",
			Color(0.68, 0.92, 0.62) if not locked else GOLD_DIM)
		panel.add_child(hp_lbl)

		# 描述文字
		var desc_lbl := Label.new()
		desc_lbl.name      = "DescLabel"
		desc_lbl.text      = char_desc
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_TOP
		desc_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
		_gold_font(desc_lbl, 14)
		desc_lbl.add_theme_color_override("font_color",
			Color(0.88, 0.80, 0.64) if not locked else Color(0.52, 0.48, 0.42))
		panel.add_child(desc_lbl)

		_cards.append({
			"panel":    panel,
			"portrait": portrait,
			"name_lbl": name_lbl,
			"hp_lbl":   hp_lbl,
			"desc_lbl": desc_lbl,
		})

# ── 返回按鈕 ─────────────────────────────────────────────────────────

func _build_back_button() -> void:
	_back_btn = Button.new()
	_back_btn.name  = "BackButton"
	_back_btn.text  = "← 返回"
	_back_btn.flat  = false
	_back_btn.focus_mode = Control.FOCUS_NONE
	_back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_back_btn.add_theme_stylebox_override("normal",
		_sb(Color(0.12, 0.04, 0.04, 0.90), GOLD, 2, 8))
	_back_btn.add_theme_stylebox_override("hover",
		_sb(Color(0.28, 0.10, 0.08, 0.96), GOLD, 3, 8))
	_back_btn.add_theme_stylebox_override("pressed",
		_sb(Color(0.08, 0.03, 0.03, 0.90), GOLD, 2, 8))
	_back_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_gold_font(_back_btn, 18)
	_back_btn.button_up.connect(_on_back_pressed)
	add_child(_back_btn)

func _on_back_pressed() -> void:
	var ts: Node = get_parent()
	if ts != null and ts.has_method("show_main_menu"):
		ts.show_main_menu()
	else:
		visible = false

# ── 排版（響應式） ────────────────────────────────────────────────────

func _relayout() -> void:
	var safe: Rect2      = Responsive.safe_rect
	var ts_scale: float  = 1.15 if Responsive.is_tablet() else 1.0
	var pad: float       = roundf(20.0 * ts_scale)

	# 標題：安全區頂部橫跨全寬
	if is_instance_valid(_title_lbl):
		var th: float = roundf(52.0 * ts_scale)
		_title_lbl.size     = Vector2(safe.size.x, th)
		_title_lbl.position = Vector2(safe.position.x, safe.position.y + roundf(pad * 0.4))

	# 返回按鈕：左上角
	if is_instance_valid(_back_btn):
		var bw: float = roundf(148.0 * ts_scale)
		var bh: float = roundf(44.0 * ts_scale)
		_back_btn.size     = Vector2(bw, bh)
		_back_btn.position = Vector2(safe.position.x + pad,
								   safe.position.y + roundf(pad * 0.5))

	# 4 張卡：水平排列，在安全區中段置中
	var n: int          = _cards.size()
	var card_gap: float = safe.size.x * 0.018
	var card_w: float   = safe.size.x * 0.19
	var header_h: float = roundf(60.0 * ts_scale)
	var avail_h: float  = safe.size.y - header_h - pad
	var card_h: float   = clampf(avail_h * 0.88, 320.0, 520.0)
	var total_w: float  = card_w * n + card_gap * (n - 1)
	var start_x: float  = safe.position.x + (safe.size.x - total_w) * 0.5
	var card_y: float   = safe.position.y + header_h + (avail_h - card_h) * 0.5

	for i: int in n:
		var cd_dict: Dictionary = _cards[i]
		var panel: Panel        = cd_dict["panel"]
		if not is_instance_valid(panel):
			continue
		panel.position = Vector2(start_x + i * (card_w + card_gap), card_y)
		panel.size     = Vector2(card_w, card_h)

		# 立繪：佔上方 56%
		var portrait: TextureRect = cd_dict["portrait"]
		var ph: float = card_h * 0.56
		portrait.position = Vector2(0, 0)
		portrait.size     = Vector2(card_w, ph)

		# info 區（立繪下方）
		var info_start: float = ph + 8.0
		var info_h: float     = card_h - ph - 16.0

		var name_lbl: Label = cd_dict["name_lbl"]
		name_lbl.position = Vector2(4, info_start)
		name_lbl.size     = Vector2(card_w - 8, roundf(info_h * 0.22))

		var hp_lbl: Label = cd_dict["hp_lbl"]
		hp_lbl.position = Vector2(4, info_start + info_h * 0.24)
		hp_lbl.size     = Vector2(card_w - 8, roundf(info_h * 0.18))

		var desc_lbl: Label = cd_dict["desc_lbl"]
		desc_lbl.position = Vector2(6, info_start + info_h * 0.44)
		desc_lbl.size     = Vector2(card_w - 12, info_h * 0.54)

# ── Helpers ──────────────────────────────────────────────────────────

func _sb(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	return COTIW_UI_THEME.make_stylebox(bg, border, radius, bw)

func _gold_font(c: Control, sz: int) -> void:
	c.add_theme_font_size_override("font_size", sz)
	c.add_theme_color_override("font_color", GOLD)
	c.add_theme_constant_override("shadow_offset_x", 2)
	c.add_theme_constant_override("shadow_offset_y", 2)
	c.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
