class_name CdxDetailSheet
extends Control
## 圖鑑詳情底卡（bottom sheet）。scrim 點擊關閉、ui_cancel 關閉、開啟時 focus 移到關閉鈕。
## 純自動佈局：panel 底錨 + MarginContainer 內距 + VBox 內容；slide 只動 modulate/offset（過場非佈局）。
const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

signal closed()

var _panel: PanelContainer
var _title: Label
var _rar: Label
var _body: Label
var _meta: Label
var _close_btn: Button
var _last_focus: Control = null

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	visible = false
	_build()

func _build() -> void:
	var scrim := ColorRect.new()
	scrim.color = Color(0.07, 0.04, 0.04, 0.74)
	scrim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	scrim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(scrim)

	_panel = PanelContainer.new()
	# 底錨：寬滿、貼底；高由內容撐（grow up）。零硬高度。
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.grow_vertical = GROW_DIRECTION_BEGIN
	_panel.add_theme_stylebox_override("panel",
		THEME.make_stylebox(THEME.get_color("lacquer_black"), THEME.get_color("hot_gold"), 0, 3, 0.0))
	add_child(_panel)

	var pad := MarginContainer.new()
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(m, THEME.get_spacing("lg", 24))
	_panel.add_child(pad)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", THEME.get_spacing("md", 16))
	pad.add_child(v)

	# 標題列：名（左）＋ 稀有度（中）＋ 關閉（右，拇指可達）
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", THEME.get_spacing("md", 16))
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", THEME.get_typography_size("h1", 36))
	_title.add_theme_color_override("font_color", THEME.get_color("hot_gold"))
	head.add_child(_title)
	_rar = Label.new()
	_rar.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
	_rar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_rar)
	var hsp := Control.new(); hsp.size_flags_horizontal = SIZE_EXPAND_FILL; head.add_child(hsp)
	_close_btn = Button.new()
	_close_btn.text = "關閉 ✕"
	_close_btn.custom_minimum_size = Vector2(0, THEME._get_touch_target_value("minimum", 88) * 0.6)
	THEME.apply_secondary_button_style(_close_btn)
	_close_btn.focus_mode = FOCUS_ALL
	_close_btn.pressed.connect(close)
	head.add_child(_close_btn)
	v.add_child(head)

	v.add_child(_rule())

	_body = Label.new()
	_body.add_theme_font_size_override("font_size", THEME.get_typography_size("body", 22))
	_body.add_theme_color_override("font_color", THEME.get_color("paper_warm"))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_body)

	_meta = Label.new()
	_meta.add_theme_font_size_override("font_size", THEME.get_typography_size("caption", 18))
	_meta.add_theme_color_override("font_color", THEME.get_color("ash_beige"))
	v.add_child(_meta)

func _rule() -> Control:
	var line := ColorRect.new()
	line.color = Color(THEME.get_color("old_gold").r, THEME.get_color("old_gold").g, THEME.get_color("old_gold").b, 0.5)
	line.custom_minimum_size = Vector2(0, 2)
	return line

func open(data: Dictionary) -> void:
	_last_focus = get_viewport().gui_get_focus_owner()
	_title.text = str(data.get("name", "？"))
	var rar_name := str(data.get("rar", "common"))
	_rar.text = {"common": "常見", "uncommon": "良品", "rare": "稀有", "epic": "神話"}.get(rar_name, "常見")
	_rar.add_theme_color_override("font_color",
		THEME.get_color(CdxCardSlot.RAR_COLOR.get(rar_name, "old_gold")))
	_body.text = str(data.get("desc", "（暫無敘述）"))
	var bits := PackedStringArray()
	if int(data.get("cost", -1)) >= 0: bits.append("費 %d" % int(data.get("cost")))
	if data.has("type"): bits.append("型 %s" % str(data.get("type")))
	if data.has("got"): bits.append("收編於：%s" % str(data.get("got")))
	_meta.text = "　·　".join(bits)
	_apply_safe()
	visible = true
	_close_btn.grab_focus.call_deferred()
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, THEME.get_motion_duration("reward_reveal", 260) / 1000.0)

func close() -> void:
	if not visible:
		return
	visible = false
	if is_instance_valid(_last_focus):
		_last_focus.grab_focus.call_deferred()
	closed.emit()

func _apply_safe() -> void:
	# sheet 底部讓出底安全區（瀏海/小白條），寬度讓出左右安全區
	var vp := get_viewport().get_visible_rect().size
	var safe := THEME.get_safe_content_rect(get_viewport())
	_panel.offset_left = maxi(0, int(safe.position.x))
	_panel.offset_right = -maxi(0, int(vp.x - safe.end.x))
	_panel.offset_bottom = -maxi(0, int(vp.y - safe.end.y))

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
