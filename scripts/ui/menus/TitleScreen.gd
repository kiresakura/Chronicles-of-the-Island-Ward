# title screen of game
# composed of sub menus with their own logic
# does nothing except control sub menu display logic
extends Control

const CharacterPanelScript := preload("res://scripts/ui/menus/CharacterPanel.gd")
const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

# ── P0 載入體驗優化（2026-06-02）────────────────────────────────
# 舊版用 1.6 秒「假進度條」（_process 計時跑 ProgressBar），問題：
#   1. 進度條不對應任何真實資源載入 → 誤導玩家
#   2. 固定等 1.6 秒，拉長「點 APP → 可互動主畫面」的時間
# 改為「短品牌過場」：
#   - 不再固定等待、不再顯示假進度條
#   - 僅保留「鎮島錄」標題 + 一句氛圍文案，營造儀式感
#   - 過場停留約 0.35 秒、淡出約 0.15 秒（總長 ~0.5 秒內）
#   - 支援 tap-to-skip：點擊／觸控立即進主選單
# 注意：本階段刻意不拆 Root.tscn、不動 MainMenu 版面。
const BRAND_HOLD_SEC: float = 0.35      # 品牌過場停留時間（儀式感）
const OVERLAY_FADE_SEC: float = 0.15    # 過場淡出時間
# 氛圍文案：用「已完成」語氣，避免「…中」讓玩家誤以為仍在載入
const BRAND_PHRASES: Array[String] = [
	"香火已燃",
	"聖筊已應",
	"鎮島降乩",
]

@onready var main_menu = $MainMenu
@onready var new_run_menu = $NewRunMenu
@onready var codex_menu = $CodexMenu
@onready var _background: ColorRect = $Background if has_node("Background") else null

var _character_panel: Control
var _loading_overlay: Control
var _loading_card: Panel
var _loading_title: Label
var _loading_status: Label
var _transition_tween: Tween
var _loading_active: bool = false
var _loading_finished: bool = false
var _loading_bg_color: Color = Color(0.788, 0.125, 0.125, 1)


func _ready():
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)

	# 自適應地基：TitleScreen 與底色撐滿整個 viewport（expand 下不留空白）
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _background:
		_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_loading_bg_color = COTIW_UI_THEME.get_color("boot_splash_red", _loading_bg_color)

	# MainMenu 自己做完整自適應；NewRunMenu/CodexMenu 為固定 1200×700 版面，
	# 用 SafeFit 等比置中塞進安全區（Phase 1；戰鬥/地圖等留 Phase 2）
	SafeFit.bind(new_run_menu)
	SafeFit.bind(codex_menu)

	# 角色面板：程序化建構，動態 add_child（不需要 .tscn 節點）
	_character_panel = Control.new()
	_character_panel.set_script(CharacterPanelScript)
	_character_panel.name = "CharacterPanel"
	_character_panel.visible = false
	add_child(_character_panel)

	# 啟動日誌（沿用 DebugLogger.log_line，非正式 telemetry）
	DebugLogger.log_line("[啟動] TitleScreen ready", Color(0.96, 0.82, 0.48))

	_build_root_loading_overlay()
	Responsive.changed.connect(_relayout_root_loading_overlay)
	_begin_root_transition()


func hide_menus():
	main_menu.visible = false
	new_run_menu.visible = false
	codex_menu.visible = false
	if is_instance_valid(_character_panel):
		_character_panel.visible = false


func show_main_menu():
	hide_menus()
	main_menu.visible = true


func show_new_run_menu():
	hide_menus()
	main_menu.visible = true
	new_run_menu.visible = true
	new_run_menu.populate_new_run_menu()


func show_codex_menu():
	hide_menus()
	main_menu.visible = true
	codex_menu.visible = true
	codex_menu.populate_codex_menu()


func show_character_panel():
	hide_menus()
	main_menu.visible = true
	if is_instance_valid(_character_panel):
		_character_panel.visible = true


## 建構品牌過場 overlay：底色 + 卡片 + 標題 +氛圍文案（已移除進度條／hint）
func _build_root_loading_overlay() -> void:
	_loading_overlay = Control.new()
	_loading_overlay.name = "RootLoadingOverlay"
	_loading_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# tap-to-skip：子節點皆為 IGNORE，點擊會冒泡到 overlay 的 gui_input
	_loading_overlay.gui_input.connect(_on_overlay_input)
	add_child(_loading_overlay)

	var fill := ColorRect.new()
	fill.name = "BackgroundFill"
	fill.color = _loading_bg_color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loading_overlay.add_child(fill)

	_loading_card = Panel.new()
	_loading_card.name = "LoadingCard"
	_loading_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.11, 0.05, 0.04, 0.88)
	card_style.border_width_left = 3
	card_style.border_width_top = 3
	card_style.border_width_right = 3
	card_style.border_width_bottom = 3
	card_style.border_color = Color(0.957, 0.839, 0.498, 0.92)
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.shadow_color = Color(0, 0, 0, 0.45)
	card_style.shadow_size = 12
	card_style.shadow_offset = Vector2(0, 4)
	_loading_card.add_theme_stylebox_override("panel", card_style)
	_loading_overlay.add_child(_loading_card)

	_loading_title = Label.new()
	_loading_title.name = "Title"
	_loading_title.text = "鎮島錄"
	_loading_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_title.add_theme_color_override("font_color", Color(1, 0.953, 0.498, 1))
	_loading_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	_loading_title.add_theme_constant_override("shadow_offset_x", 3)
	_loading_title.add_theme_constant_override("shadow_offset_y", 3)
	_loading_card.add_child(_loading_title)

	# 氛圍文案（取代舊的「假進度狀態列」；不再有點點動畫與進度暗示）
	_loading_status = Label.new()
	_loading_status.name = "Status"
	_loading_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_status.add_theme_color_override("font_color", Color(0.957, 0.839, 0.498, 1))
	_loading_status.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	_loading_status.add_theme_constant_override("shadow_offset_x", 2)
	_loading_status.add_theme_constant_override("shadow_offset_y", 2)
	_loading_card.add_child(_loading_status)

	_relayout_root_loading_overlay()


## 啟動品牌過場：顯示 overlay → 停留 BRAND_HOLD_SEC → 收尾進主選單
func _begin_root_transition() -> void:
	_loading_active = true
	_loading_finished = false
	# 隨機挑一句氛圍文案（用 ticks 當種子，避免每次都同一句）
	var phrase: String = BRAND_PHRASES[int(Time.get_ticks_msec()) % BRAND_PHRASES.size()]
	_loading_status.text = phrase
	visible = true
	hide_menus()
	_loading_overlay.visible = true
	_loading_overlay.modulate = Color(1, 1, 1, 1)

	DebugLogger.log_line("[啟動] splash transition begin（%s）" % phrase, Color(0.831, 0.686, 0.216))

	# 用 Tween 取代舊的 _process 假進度：停留結束後自動收尾
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_transition_tween = create_tween()
	_transition_tween.tween_interval(BRAND_HOLD_SEC)
	_transition_tween.tween_callback(_finish_root_transition)


## 過場收尾：顯示主選單 + 淡出 overlay
func _finish_root_transition() -> void:
	if not _loading_active or _loading_finished:
		return
	_loading_active = false
	_loading_finished = true
	show_main_menu()

	DebugLogger.log_line("[啟動] main menu shown", Color(0.55, 0.86, 0.45))

	var tween: Tween = create_tween()
	tween.tween_property(_loading_overlay, "modulate:a", 0.0, OVERLAY_FADE_SEC)
	tween.tween_callback(func() -> void:
		_loading_overlay.visible = false
	)


## tap-to-skip：略過停留，立刻收尾（仍會走一次短淡出）
func _skip_root_transition() -> void:
	if not _loading_active or _loading_finished:
		return
	if _transition_tween != null and _transition_tween.is_valid():
		_transition_tween.kill()
	_finish_root_transition()


## overlay 的輸入處理：滑鼠點擊或螢幕觸控皆視為 skip
func _on_overlay_input(event: InputEvent) -> void:
	if not _loading_active or _loading_finished:
		return
	var tapped: bool = false
	if event is InputEventMouseButton and event.pressed:
		tapped = true
	elif event is InputEventScreenTouch and event.pressed:
		tapped = true
	if tapped:
		_skip_root_transition()


func _relayout_root_loading_overlay() -> void:
	if not is_instance_valid(_loading_overlay):
		return
	_loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe: Rect2 = Responsive.safe_rect
	var scale: float = 1.12 if Responsive.is_tablet() else 1.0
	var card_width: float = clampf(safe.size.x * 0.52, 420.0, 760.0)
	# 移除進度條／hint 後卡片變矮：只容納標題 + 一句文案
	var card_height: float = roundf(150.0 * scale)
	_loading_card.position = Vector2(
		safe.position.x + (safe.size.x - card_width) * 0.5,
		safe.position.y + (safe.size.y - card_height) * 0.5
	)
	_loading_card.size = Vector2(card_width, card_height)

	_loading_title.position = Vector2(24, 26 * scale)
	_loading_title.size = Vector2(card_width - 48, 60 * scale)
	_loading_title.add_theme_font_size_override("font_size", int(44 * scale))

	_loading_status.position = Vector2(24, 94 * scale)
	_loading_status.size = Vector2(card_width - 48, 34 * scale)
	_loading_status.add_theme_font_size_override("font_size", int(22 * scale))


func _on_run_started():
	visible = false
	if is_instance_valid(_loading_overlay):
		_loading_overlay.visible = false


func _on_run_ended():
	visible = true
	show_main_menu()
	if is_instance_valid(_loading_overlay):
		_loading_overlay.visible = false
