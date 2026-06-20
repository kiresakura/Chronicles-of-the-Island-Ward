# 鎮島錄 c-1 — 每日上香 overlay（留存系統）。
#
# 點正殿香爐 → 開此面板：7 日連簽階梯 + 上香領香火（循環末日里程碑加碼元寶）。
# 變現紅線：獎勵走香火（thematic 免費 meta 進度）+ 里程碑元寶（外觀幣）；絕不販售戰力。
# 階梯為 ProfileData.DAILY_INCENSE_LADDER 唯一真相（鐵律1）；顯示文案全走 tr()（i18n 安全）。
extends Control

const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

var _panel: Panel
var _offer_btn: Button
var _streak_label: Label
var _ladder_row: HBoxContainer
var _msg_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Color(0.04, 0.025, 0.03, 0.80)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP	# 全幅 modal：擋穿透；點空白關閉
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
	title.text = tr("daily.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", THEME.get_color("incense_gold"))
	_panel.add_child(title)

	_streak_label = Label.new()
	_streak_label.name = "Streak"
	_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_streak_label.add_theme_font_size_override("font_size", 18)
	_streak_label.add_theme_color_override("font_color", THEME.get_color("paper_cream"))
	_panel.add_child(_streak_label)

	_ladder_row = HBoxContainer.new()
	_ladder_row.name = "Ladder"
	_ladder_row.add_theme_constant_override("separation", 8)
	_ladder_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_ladder_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_ladder_row)

	_msg_label = Label.new()
	_msg_label.name = "Msg"
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.add_theme_font_size_override("font_size", 15)
	_msg_label.add_theme_color_override("font_color", THEME.get_color("ash_beige"))
	_panel.add_child(_msg_label)

	_offer_btn = Button.new()
	_offer_btn.name = "OfferBtn"
	_offer_btn.focus_mode = Control.FOCUS_NONE
	THEME.apply_primary_button_style(_offer_btn)
	_offer_btn.button_up.connect(_on_offer)
	_panel.add_child(_offer_btn)

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
	var pw: float = minf(640.0, vp.x - 80.0)
	var ph: float = 372.0
	_panel.size = Vector2(pw, ph)
	_panel.position = Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	_panel.pivot_offset = Vector2(pw, ph) * 0.5
	(_panel.get_node("Title") as Control).position = Vector2(0, 22)
	(_panel.get_node("Title") as Control).size = Vector2(pw, 36)
	_streak_label.position = Vector2(0, 66)
	_streak_label.size = Vector2(pw, 24)
	_ladder_row.position = Vector2(20, 108)
	_ladder_row.size = Vector2(pw - 40, 116)
	_msg_label.position = Vector2(0, 238)
	_msg_label.size = Vector2(pw, 22)
	_offer_btn.size = Vector2(248, 56)
	_offer_btn.position = Vector2((pw - 248) * 0.5, ph - 76)
	var close_btn := _panel.get_node("CloseBtn") as Button
	close_btn.size = Vector2(40, 40)
	close_btn.position = Vector2(pw - 50, 10)

func open() -> void:
	_layout()
	_refresh()
	visible = true
	_panel.scale = Vector2(0.94, 0.94)
	var tw := create_tween()
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	visible = false

func _refresh() -> void:
	var p: ProfileData = Global.profile_data
	if p == null:
		return
	_streak_label.text = tr("daily.streak") % p.profile_incense_streak
	_build_ladder(p)
	if p.can_offer_incense_today():
		_offer_btn.disabled = false
		_offer_btn.text = tr("daily.offer")
		_msg_label.text = tr("daily.prompt")
	else:
		_offer_btn.disabled = true
		_offer_btn.text = tr("daily.claimed")
		_msg_label.text = tr("daily.come_back")

func _build_ladder(p: ProfileData) -> void:
	for c in _ladder_row.get_children():
		c.queue_free()
	var ladder: Array = ProfileData.DAILY_INCENSE_LADDER
	var claimed_today: bool = not p.can_offer_incense_today()
	# 高亮日序：已領→當前循環日；未領→即將領的日序（streak%7 + 1，含跨週重置）。
	var display_day: int = p.incense_cycle_day() if claimed_today else (p.profile_incense_streak % ladder.size()) + 1
	for i in ladder.size():
		_ladder_row.add_child(_make_ladder_cell(i + 1, int(ladder[i]), i == ladder.size() - 1, display_day, claimed_today))

func _make_ladder_cell(day_n: int, incense: int, is_milestone: bool, display_day: int, claimed_today: bool) -> Control:
	var is_claimed: bool = day_n < display_day or (claimed_today and day_n == display_day)
	var is_today: bool = (not claimed_today) and day_n == display_day
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(74, 100)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border: Color = THEME.get_color("incense_gold") if is_today else (THEME.get_color("spirit_jade") if is_claimed else THEME.get_color("smoke_gray"))
	var bg: Color = Color(0.10, 0.16, 0.12, 0.96) if is_claimed else Color(0.16, 0.10, 0.07, 0.96)
	panel.add_theme_stylebox_override("panel", THEME.make_stylebox(bg, border, 0, 3 if is_today else 2, 0.0))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 3)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var d := Label.new()
	d.text = tr("daily.day") % day_n
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.add_theme_font_size_override("font_size", 13)
	d.add_theme_color_override("font_color", THEME.get_color("ash_beige"))
	v.add_child(d)
	var amt := Label.new()
	amt.text = "✓" if is_claimed else str(incense)
	amt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amt.add_theme_font_size_override("font_size", 26 if is_claimed else 22)
	amt.add_theme_color_override("font_color", THEME.get_color("spirit_jade") if is_claimed else THEME.get_color("incense_gold"))
	v.add_child(amt)
	var tag := Label.new()
	tag.text = tr("daily.milestone") if is_milestone else tr("daily.incense_unit")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", THEME.get_color("incense_gold") if is_milestone else THEME.get_color("smoke_gray"))
	v.add_child(tag)
	return panel

func _on_offer() -> void:
	var p: ProfileData = Global.profile_data
	if p == null or not p.can_offer_incense_today():
		return
	var r: Dictionary = p.offer_daily_incense()
	if not bool(r.get("claimed", false)):
		return
	FileLoader.save_profile()	# 加密落地 + 雲端時戳
	Signals.daily_incense_claimed.emit(int(r.get("streak", 1)), r)
	AudioManager.play_sfx("turn_end")
	_play_offer_juice(r)
	_refresh()

## 上香 juice：香火 +N 上飄（里程碑日加飄元寶）。自我清理。
func _play_offer_juice(r: Dictionary) -> void:
	var cx: float = _panel.position.x + _panel.size.x * 0.5
	var cy: float = _panel.position.y + _panel.size.y * 0.42
	_float_gain("+%d %s" % [int(r.get("incense", 0)), tr("daily.incense_unit")], Vector2(cx - 60, cy), THEME.get_color("incense_gold"), 30, 0.0)
	if int(r.get("yuanbao", 0)) > 0:
		_float_gain("+%d %s" % [int(r.get("yuanbao", 0)), tr("daily.yuanbao_unit")], Vector2(cx - 50, cy + 38), THEME.get_color("neon_cyan"), 24, 0.18)

func _float_gain(text: String, pos: Vector2, col: Color, font_size: int, delay: float) -> void:
	var fly := Label.new()
	fly.text = text
	fly.add_theme_font_size_override("font_size", font_size)
	fly.add_theme_color_override("font_color", col)
	fly.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	fly.add_theme_constant_override("shadow_offset_y", 2)
	fly.position = pos
	fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fly)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(fly, "position:y", pos.y - 82.0, 0.95).set_delay(delay).set_trans(Tween.TRANS_SINE)
	tw.tween_property(fly, "modulate:a", 0.0, 0.95).set_delay(delay + 0.3)
	tw.chain().tween_callback(fly.queue_free)
