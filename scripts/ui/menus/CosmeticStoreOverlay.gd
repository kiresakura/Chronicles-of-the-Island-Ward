# 鎮島錄 c-2 — 外觀商店 overlay（設計稿 捌 外觀四階）。
#
# 從正殿元寶「+」開啟：4 階立繪外框（素/燙金/玉青/神話），以元寶購買 + 裝備。
# 變現紅線：只賣外觀、零戰力（CosmeticCatalog.purchase 單點強制只扣元寶）。文案全走 tr()。
extends Control

const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const CAT := preload("res://scripts/systems/cosmetics/CosmeticCatalog.gd")
const CFRAME := preload("res://scripts/ui/fx/CosmeticFrame.gd")
const PREVIEW_PORTRAIT := "res://assets/generated/portraits_v3/tongji.png"

var _panel: Panel
var _balance_label: Label
var _cards_row: HBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.04, 0.025, 0.03, 0.80)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			close())
	add_child(dim)

	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.add_theme_stylebox_override("panel", THEME.make_stylebox(
		THEME.get_color("lacquer_black", Color(0.10, 0.06, 0.05)), THEME.get_color("incense_gold"), 0, 3, 0.0))
	add_child(_panel)

	var title := Label.new()
	title.name = "Title"
	title.text = tr("cosmetic.store_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", THEME.get_color("incense_gold"))
	_panel.add_child(title)

	_balance_label = Label.new()
	_balance_label.name = "Balance"
	_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_balance_label.add_theme_font_size_override("font_size", 18)
	_balance_label.add_theme_color_override("font_color", THEME.get_color("neon_cyan"))
	_panel.add_child(_balance_label)

	_cards_row = HBoxContainer.new()
	_cards_row.name = "Cards"
	_cards_row.add_theme_constant_override("separation", 14)
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_cards_row)

	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = "✕"
	close_btn.focus_mode = Control.FOCUS_NONE
	THEME.apply_secondary_button_style(close_btn)
	close_btn.button_up.connect(close)
	_panel.add_child(close_btn)
	_layout()

func _layout() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var pw: float = minf(780.0, vp.x - 60.0)
	var ph: float = 426.0
	_panel.size = Vector2(pw, ph)
	_panel.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	_panel.pivot_offset = Vector2(pw, ph) * 0.5
	(_panel.get_node("Title") as Control).position = Vector2(0, 20)
	(_panel.get_node("Title") as Control).size = Vector2(pw, 36)
	_balance_label.position = Vector2(0, 62)
	_balance_label.size = Vector2(pw, 24)
	_cards_row.position = Vector2(20, 102)
	_cards_row.size = Vector2(pw - 40, ph - 124)
	var close_btn := _panel.get_node("CloseBtn") as Button
	close_btn.size = Vector2(40, 40)
	close_btn.position = Vector2(pw - 50, 10)

func open() -> void:
	_layout()
	_refresh()
	visible = true
	_panel.scale = Vector2(0.95, 0.95)
	create_tween().tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	visible = false

func _refresh() -> void:
	var p: ProfileData = Global.profile_data
	if p == null:
		return
	_balance_label.text = tr("cosmetic.balance") % p.profile_yuanbao
	for c in _cards_row.get_children():
		c.queue_free()
	for fr: Variant in CAT.frames():
		if typeof(fr) == TYPE_DICTIONARY:
			_cards_row.add_child(_make_card(fr as Dictionary, p))

func _make_card(d: Dictionary, p: ProfileData) -> Control:
	var frame_id: String = str(d.get("id", ""))
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(170, 0)
	card.add_theme_constant_override("separation", 8)
	card.alignment = BoxContainer.ALIGNMENT_CENTER

	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(150, 178)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.clip_contents = true
	CFRAME.apply(preview, frame_id)	# 真實外觀樣式套上預覽
	if ResourceLoader.exists(PREVIEW_PORTRAIT):
		var port := TextureRect.new()
		port.texture = load(PREVIEW_PORTRAIT)
		port.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		port.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		port.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		port.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.add_child(port)
		preview.move_child(port, 0)	# 立繪在框內、框繪其上
	card.add_child(preview)

	var name_lbl := Label.new()
	name_lbl.text = tr(str(d.get("name_key", "")))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 17)
	name_lbl.add_theme_color_override("font_color", THEME.get_color(str(d.get("border_token", "incense_gold"))))
	card.add_child(name_lbl)

	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0, 48)
	var owned: bool = CAT.owns(p, frame_id)
	var equipped: bool = CAT.equipped_id(p) == frame_id
	var cost: int = CAT.price(frame_id)
	if equipped:
		btn.text = tr("cosmetic.equipped")
		btn.disabled = true
		THEME.apply_secondary_button_style(btn)
	elif owned:
		btn.text = tr("cosmetic.equip")
		THEME.apply_primary_button_style(btn)
		btn.button_up.connect(_on_equip.bind(frame_id))
	elif p.profile_yuanbao >= cost:
		btn.text = tr("cosmetic.buy") % cost
		THEME.apply_primary_button_style(btn)
		btn.button_up.connect(_on_buy.bind(frame_id))
	else:
		btn.text = tr("cosmetic.insufficient")
		btn.disabled = true
		THEME.apply_secondary_button_style(btn)
	card.add_child(btn)
	return card

func _on_buy(frame_id: String) -> void:
	var p: ProfileData = Global.profile_data
	if p == null:
		return
	if CAT.purchase(p, frame_id):
		CAT.equip(p, frame_id)	# 購買即裝備（即時回饋）
		FileLoader.save_profile()
		Signals.cosmetic_equipped.emit(CAT.equipped_id(p))
		AudioManager.play_sfx("turn_end")
		_refresh()

func _on_equip(frame_id: String) -> void:
	var p: ProfileData = Global.profile_data
	if p == null:
		return
	if CAT.equip(p, frame_id):
		FileLoader.save_profile()
		Signals.cosmetic_equipped.emit(CAT.equipped_id(p))
		AudioManager.play_sfx("turn_end")
		_refresh()
