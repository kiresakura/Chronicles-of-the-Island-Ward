# 鎮島錄 — 看板娘選擇面板
# 點 MainMenu 看板娘觸發。展示所有 unlocked 角色（idle anim cycling），
# 點一個 → 設為 mascot + 關閉。
# 參考 CharacterPanel 設計但專注 mascot 選擇。
extends Control
class_name MascotSelector

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const CHARS_V2_DIR: String = "res://assets/generated/characters_v2/"
const ACTOR_TO_FILE: Dictionary = {
	"character_tongji": "tongji",
	"character_luannu": "luannu",
}

var GOLD:           Color = Color(0.95, 0.82, 0.45)
var GOLD_DIM:       Color = Color(0.62, 0.49, 0.24)
var PANEL_BG:       Color = Color(0.14, 0.05, 0.04, 0.94)
var PANEL_BG_LOCK:  Color = Color(0.10, 0.08, 0.08, 0.80)
var PANEL_BG_ACTIVE: Color = Color(0.36, 0.10, 0.08, 0.96)

# 候選清單：有 anim 條的 unlocked 角色 + 鎖定角色
const CHOICES: Array = [
	{"id": "character_tongji", "label": "乩童",  "locked": false},
	{"id": "character_luannu", "label": "鸞女",  "locked": false},
	{"id": "",                 "label": "道士",  "locked": true},
	{"id": "",                 "label": "家將",  "locked": true},
]

var _back_btn: Button
var _title_lbl: Label
var _cards: Array = []   # {panel, sprite, name_lbl, frames, frame_idx, time, button, id, locked, highlight}

signal mascot_picked(character_id: String)

func _ready() -> void:
	GOLD     = COTIW_UI_THEME.get_color("incense_gold", GOLD)
	GOLD_DIM = COTIW_UI_THEME.get_color("old_gold",     GOLD_DIM)

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_build_backdrop()
	_build_title()
	_build_cards()
	_build_back_button()

	await get_tree().process_frame
	_relayout()
	Responsive.changed.connect(_relayout)

func _process(_delta: float) -> void:
	# 立繪靜態，不切幀。保留 _process hook 給未來呼吸效果。
	pass

func _build_backdrop() -> void:
	var bg := ColorRect.new()
	bg.name  = "Backdrop"
	bg.color = Color(0.05, 0.02, 0.02, 0.95)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

func _build_title() -> void:
	_title_lbl = Label.new()
	_title_lbl.text = "選看板娘"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_font(_title_lbl, 38)
	add_child(_title_lbl)

func _build_cards() -> void:
	var current_id: String = Global.get_mascot_character_id()
	for choice in CHOICES:
		var c_id: String = choice["id"]
		var locked: bool = choice["locked"]
		var label: String = choice["label"]

		var panel := Panel.new()
		panel.name = "Card_" + label
		var is_active: bool = (not locked) and (c_id == current_id)
		var bg_col: Color = PANEL_BG_LOCK if locked else (PANEL_BG_ACTIVE if is_active else PANEL_BG)
		var border_col: Color = GOLD if (not locked) else GOLD_DIM
		panel.add_theme_stylebox_override("panel",
			_sb(bg_col, border_col, 3 if is_active else 2, 12))
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(panel)

		# Sprite (animated)
		var sprite := TextureRect.new()
		sprite.name = "Sprite"
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if locked:
			sprite.modulate = Color(0.45, 0.45, 0.45, 0.75)
		panel.add_child(sprite)

		# 載入 Recraft anime 動漫立繪
		if not locked and c_id != "":
			var tex: Texture2D = _load_anime_portrait(c_id)
			if tex != null:
				sprite.texture = tex

		# 名稱
		var name_lbl := Label.new()
		name_lbl.text = label + ("（鎖）" if locked else "")
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_gold_font(name_lbl, 22)
		if locked:
			name_lbl.add_theme_color_override("font_color", GOLD_DIM)
		panel.add_child(name_lbl)

		# "目前" 標籤（如果是當前 mascot）
		var active_lbl: Label = null
		if is_active:
			active_lbl = Label.new()
			active_lbl.text = "★ 目前"
			active_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_gold_font(active_lbl, 16)
			active_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42))
			panel.add_child(active_lbl)

		# 透明 button 接點擊
		var btn: Button = null
		if not locked and c_id != "":
			btn = Button.new()
			btn.flat = true
			btn.focus_mode = Control.FOCUS_NONE
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.self_modulate = Color(1, 1, 1, 0)
			panel.add_child(btn)
			var pick_id: String = c_id
			btn.button_up.connect(func(): _on_card_picked(pick_id))

		_cards.append({
			"panel": panel, "sprite": sprite, "name_lbl": name_lbl,
			"active_lbl": active_lbl, "button": btn,
			"id": c_id, "locked": locked,
		})

func _build_back_button() -> void:
	_back_btn = Button.new()
	_back_btn.text = "← 返回"
	_back_btn.flat = false
	_back_btn.focus_mode = Control.FOCUS_NONE
	_back_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_back_btn.add_theme_stylebox_override("normal",
		_sb(Color(0.12, 0.04, 0.04, 0.90), GOLD, 2, 8))
	_back_btn.add_theme_stylebox_override("hover",
		_sb(Color(0.28, 0.10, 0.08, 0.96), GOLD, 3, 8))
	_back_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_gold_font(_back_btn, 18)
	_back_btn.button_up.connect(_on_back_pressed)
	add_child(_back_btn)

func _on_card_picked(character_id: String) -> void:
	Global.set_mascot_character_id(character_id)
	mascot_picked.emit(character_id)
	_dismiss()

func _on_back_pressed() -> void:
	_dismiss()

func _dismiss() -> void:
	visible = false

# ── 排版 ──────────────────────────────────────────────────────────────

func _relayout() -> void:
	var safe: Rect2 = Responsive.safe_rect
	var ts: float = 1.15 if Responsive.is_tablet() else 1.0
	var pad: float = roundf(20.0 * ts)

	if is_instance_valid(_title_lbl):
		_title_lbl.size = Vector2(safe.size.x, roundf(52.0 * ts))
		_title_lbl.position = Vector2(safe.position.x, safe.position.y + roundf(pad * 0.4))

	if is_instance_valid(_back_btn):
		var bw: float = roundf(148.0 * ts)
		var bh: float = roundf(44.0 * ts)
		_back_btn.size = Vector2(bw, bh)
		_back_btn.position = Vector2(safe.position.x + pad,
									 safe.position.y + roundf(pad * 0.5))

	var n: int = _cards.size()
	var gap: float = safe.size.x * 0.018
	var card_w: float = safe.size.x * 0.19
	var header_h: float = roundf(60.0 * ts)
	var avail_h: float = safe.size.y - header_h - pad
	var card_h: float = clampf(avail_h * 0.86, 320.0, 520.0)
	var total_w: float = card_w * n + gap * (n - 1)
	var start_x: float = safe.position.x + (safe.size.x - total_w) * 0.5
	var card_y: float = safe.position.y + header_h + (avail_h - card_h) * 0.5

	for i in n:
		var c: Dictionary = _cards[i]
		var p: Panel = c["panel"]
		p.position = Vector2(start_x + i * (card_w + gap), card_y)
		p.size = Vector2(card_w, card_h)

		# 動畫 sprite：占上方 68%
		var sh: float = card_h * 0.68
		c["sprite"].position = Vector2(0, 0)
		c["sprite"].size = Vector2(card_w, sh)

		var info_y: float = sh + 8.0
		c["name_lbl"].position = Vector2(4, info_y)
		c["name_lbl"].size = Vector2(card_w - 8, 34)

		if c["active_lbl"] != null and is_instance_valid(c["active_lbl"]):
			c["active_lbl"].position = Vector2(4, info_y + 36)
			c["active_lbl"].size = Vector2(card_w - 8, 26)

		if c["button"] != null and is_instance_valid(c["button"]):
			c["button"].position = Vector2(0, 0)
			c["button"].size = p.size

# ── helpers ──────────────────────────────────────────────────────────

## 載入 Recraft anime 動漫立繪（優先 idle，fallback standee → card）
func _load_anime_portrait(actor_id: String) -> Texture2D:
	var base_name: String = ACTOR_TO_FILE.get(actor_id, "")
	if base_name.is_empty():
		return null
	for suffix in ["_anim_idle.png", "_standee.png", "_card.png"]:
		var p: String = CHARS_V2_DIR + base_name + suffix
		if ResourceLoader.exists(p):
			var tex: Texture2D = load(p)
			if tex != null:
				return tex
	return null

func _sb(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	return COTIW_UI_THEME.make_stylebox(bg, border, radius, bw)

func _gold_font(c: Control, sz: int) -> void:
	c.add_theme_font_size_override("font_size", sz)
	c.add_theme_color_override("font_color", GOLD)
	c.add_theme_constant_override("shadow_offset_x", 2)
	c.add_theme_constant_override("shadow_offset_y", 2)
	c.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
