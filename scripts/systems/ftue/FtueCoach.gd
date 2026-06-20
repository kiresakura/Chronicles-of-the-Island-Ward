# 鎮島錄 c-3 — FTUE 首局導引（coach-mark）。
#
# 設計取向：不腳本化、不強迫戰鬥流程（脆弱易卡關），改「標註玩家真實首局」：
# 在 供桌(擲筊) / 五營(煞臨·布營·破煞) / 結算(領禮) 三個可靠全域訊號點各顯一張
# 情境提示卡（dim + 文字 + 知道了/略過），把設計稿 5 拍之精神涵蓋在流程脈絡裡。
# 鐵則：全程可略過；任一 hook 不觸發也不卡關（防呆）；只首局觸發（profile_ftue_done）。
# 文案全走 tr()（i18n 安全）。掛載：autoload（全域監聽 + 最上層覆蓋）。
extends CanvasLayer

const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

var _active: bool = false
var _shown: Dictionary = {}	# beat_key → true（每拍只顯一次，防重複）
var _dim: ColorRect
var _panel: Panel
var _title_lbl: Label
var _body_lbl: Label

## 是否該為此 profile 啟用首局導引（純函式，可測）。
static func should_activate(profile: ProfileData) -> bool:
	return profile != null and not profile.profile_ftue_done

func _ready() -> void:
	layer = 100	# 最上層：蓋住所有 run UI
	visible = false
	_build()
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	Signals.map_location_selected.connect(_on_map_location_selected)
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)

func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.03, 0.02, 0.025, 0.46)	# 輕 dim：玩家仍看得見上方畫面脈絡
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim)

	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.add_theme_stylebox_override("panel", THEME.make_stylebox(
		THEME.get_color("lacquer_black", Color(0.10, 0.06, 0.05)), THEME.get_color("incense_gold"), 0, 4, 0.0))
	add_child(_panel)

	_title_lbl = Label.new()
	_title_lbl.name = "Title"
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 24)
	_title_lbl.add_theme_color_override("font_color", THEME.get_color("incense_gold"))
	_panel.add_child(_title_lbl)

	_body_lbl = Label.new()
	_body_lbl.name = "Body"
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.add_theme_font_size_override("font_size", 17)
	_body_lbl.add_theme_color_override("font_color", THEME.get_color("paper_cream"))
	_panel.add_child(_body_lbl)

	var next_btn := Button.new()
	next_btn.name = "NextBtn"
	next_btn.text = tr("ftue.next")
	next_btn.focus_mode = Control.FOCUS_NONE
	THEME.apply_primary_button_style(next_btn)
	next_btn.button_up.connect(_advance)
	_panel.add_child(next_btn)

	var skip_btn := Button.new()
	skip_btn.name = "SkipBtn"
	skip_btn.text = tr("ftue.skip")
	skip_btn.focus_mode = Control.FOCUS_NONE
	skip_btn.flat = true
	THEME.apply_secondary_button_style(skip_btn)
	skip_btn.button_up.connect(_skip)
	_panel.add_child(skip_btn)
	_layout()

func _layout() -> void:
	if _panel == null:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size if get_viewport() != null else Vector2(1200, 700)
	var pw: float = minf(620.0, vp.x - 80.0)
	var ph: float = 232.0
	_panel.size = Vector2(pw, ph)
	_panel.position = Vector2((vp.x - pw) * 0.5, vp.y - ph - 40.0)	# 底部置中：不全擋上方戰局
	_panel.pivot_offset = Vector2(pw, ph) * 0.5
	(_panel.get_node("Title") as Control).position = Vector2(0, 18)
	(_panel.get_node("Title") as Control).size = Vector2(pw, 30)
	_body_lbl.position = Vector2(28, 58)
	_body_lbl.size = Vector2(pw - 56, 86)
	var next_btn := _panel.get_node("NextBtn") as Button
	next_btn.size = Vector2(200, 50)
	next_btn.position = Vector2((pw - 200) * 0.5, ph - 64)
	var skip_btn := _panel.get_node("SkipBtn") as Button
	skip_btn.size = Vector2(120, 32)
	skip_btn.position = Vector2(pw - 132, 12)

# ── 觸發點（可靠全域訊號）──
func _on_run_started() -> void:
	if should_activate(Global.profile_data):
		_active = true
		_shown.clear()

func _on_run_ended() -> void:
	_active = false
	_hide()

func _on_map_location_selected(location_data: LocationData) -> void:
	if not _active or location_data == null:
		return
	if location_data.location_type != LocationData.LOCATION_TYPES.STARTING:
		return
	_show_beat("oracle", tr("ftue.oracle_title"), tr("ftue.oracle_body"))

func _on_combat_started(_event_id: String) -> void:
	if not _active:
		return
	_show_beat("combat", tr("ftue.combat_title"), tr("ftue.combat_body"))

func _on_combat_ended() -> void:
	if not _active:
		return
	_show_beat("reward", tr("ftue.reward_title"), tr("ftue.reward_body"))
	_mark_done()	# 走到結算＝首局核心拍走完，標記完成（reward 卡仍可讀）

# ── 顯示/收起 ──
func _show_beat(key: String, title: String, body: String) -> void:
	if _shown.get(key, false):
		return
	_shown[key] = true
	if _title_lbl != null:
		_title_lbl.text = title
	if _body_lbl != null:
		_body_lbl.text = body
	_layout()
	visible = true
	if _panel != null:
		_panel.scale = Vector2(0.95, 0.95)
		create_tween().tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _advance() -> void:
	_hide()	# 收起本拍；下一拍由下個訊號觸發（流程脈絡驅動）

func _skip() -> void:
	_mark_done()
	_active = false
	_hide()

func _hide() -> void:
	visible = false

func _mark_done() -> void:
	if Global.profile_data != null and not Global.profile_data.profile_ftue_done:
		Global.profile_data.profile_ftue_done = true
		FileLoader.save_profile()
