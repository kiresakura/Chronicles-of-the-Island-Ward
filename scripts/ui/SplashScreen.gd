## 載入畫面 — 廟會主題大圖 + 進度條 + 預載資料，完成後切換主選單
##
## 自適應：背景圖/底襯為 anchors 全屏（expand 下自動填滿）；
## 進度條與文字改由 Responsive.safe_rect 即時定位，避免固定 1200 座標
## 在真機（含瀏海安全區）跑位。launch storyboard → Godot boot_splash →
## 本畫面三者同圖同紅底 → 啟動連貫，進度組以淡入承接（不再「不連貫」）。
extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

@onready var bg_fill: ColorRect = $BgFill
@onready var title_glow: Label = $TitleGlow
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Label = $ProgressLabel
@onready var loading_dots: Label = $LoadingDots
@onready var tap_hint: Label = $TapHint

const ROOT_SCENE: String = "res://scenes/Root.tscn"
const TOTAL_LOAD_DURATION: float = 2.4
const MIN_DURATION_BEFORE_TAP_ALLOWED: float = 1.0
# 與 Godot boot_splash / launch storyboard 一致的廟會紅，銜接無跳色
# （由 design_tokens.boot_splash_red 提供；project.godot boot_splash bg 須同步維護）
var SPLASH_BG: Color = Color(0.788, 0.125, 0.125, 1)

var _elapsed: float = 0.0
var _can_tap_to_start: bool = false
var _transitioning: bool = false
var _dot_timer: float = 0.0
var _dot_phase: int = 0
var _tip: String = ""
const LOADING_TIPS: Array[String] = [
	"召喚乩童中",
	"擲筊問神中",
	"焚香淨壇中",
	"開光點睛中",
	"鎮島降乩中",
]


func _ready() -> void:
	SPLASH_BG = COTIW_UI_THEME.get_color("boot_splash_red", SPLASH_BG)
	# 與 boot_splash 同紅底，避免影像載入前的暗色閃跳
	bg_fill.color = SPLASH_BG
	loading_dots.visible = false  # 點點併入 ProgressLabel

	_tip = LOADING_TIPS[randi() % LOADING_TIPS.size()]
	progress_bar.value = 0
	progress_label.text = _tip
	tap_hint.modulate.a = 0.0

	_relayout()
	Responsive.changed.connect(_relayout)
	# v2 pixel skin（蓋在 bg_fill 之上）
	const PixelSkinCls = preload("res://scripts/ui/theme/PixelSkin.gd")
	PixelSkinCls.apply_background(self, "splash_bg.png")

	# 進度組從一開始就出現（用戶反饋：載入動畫應一開始就有）
	# 標題與文字仍淡入；進度條立即可見並開始動
	progress_bar.modulate.a = 1.0
	progress_bar.value = 1  # 起始 1% 給視覺提示「正在載入」
	title_glow.modulate.a = 0.0
	progress_label.modulate.a = 0.0
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(title_glow, "modulate:a", 1.0, 0.45)
	t.tween_property(progress_label, "modulate:a", 1.0, 0.45)

	await get_tree().process_frame
	_relayout()


## 依安全區重新定位進度條與文字（背景圖 anchors 全屏，不需處理）
func _relayout() -> void:
	var safe: Rect2 = Responsive.safe_rect
	var ts: float = 1.15 if Responsive.is_tablet() else 1.0
	var cx: float = safe.position.x + safe.size.x * 0.5

	# 標題：安全區頂部置中
	title_glow.size = Vector2(safe.size.x, roundf(74 * ts))
	title_glow.position = Vector2(safe.position.x, safe.position.y + roundf(36 * ts))
	title_glow.add_theme_font_size_override("font_size", int(60 * ts))

	# 進度條：安全區底部置中，寬度隨螢幕
	var bar_w: float = clampf(safe.size.x * 0.6, 480.0, 820.0)
	var bar_h: float = roundf(34 * ts)
	var bar_y: float = safe.position.y + safe.size.y - roundf(120 * ts)
	progress_bar.position = Vector2(cx - bar_w * 0.5, bar_y)
	progress_bar.size = Vector2(bar_w, bar_h)

	# 提示文字：進度條上方置中
	progress_label.size = Vector2(safe.size.x, roundf(40 * ts))
	progress_label.position = Vector2(safe.position.x, bar_y - roundf(50 * ts))
	progress_label.add_theme_font_size_override("font_size", int(26 * ts))

	# 點擊提示：進度條下方置中
	tap_hint.size = Vector2(safe.size.x, roundf(32 * ts))
	tap_hint.position = Vector2(safe.position.x, bar_y + bar_h + roundf(14 * ts))
	tap_hint.add_theme_font_size_override("font_size", int(20 * ts))


func _process(delta: float) -> void:
	if _transitioning:
		return

	_elapsed += delta
	var raw: float = clamp(_elapsed / TOTAL_LOAD_DURATION, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - raw, 2.4)
	progress_bar.value = eased * 100.0

	_dot_timer += delta
	if _dot_timer > 0.35:
		_dot_timer = 0.0
		_dot_phase = (_dot_phase + 1) % 4
		progress_label.text = _tip + ".".repeat(_dot_phase)

	if _elapsed >= MIN_DURATION_BEFORE_TAP_ALLOWED and not _can_tap_to_start:
		_can_tap_to_start = true
		_fade_in_tap_hint()

	if _elapsed >= TOTAL_LOAD_DURATION:
		_transition_to_main()


func _fade_in_tap_hint() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(tap_hint, "modulate:a", 1.0, 0.8)
	tween.tween_property(tap_hint, "modulate:a", 0.4, 0.8)


func _input(event: InputEvent) -> void:
	if _transitioning or not _can_tap_to_start:
		return
	if event is InputEventMouseButton and event.pressed:
		_transition_to_main()
	elif event is InputEventScreenTouch and event.pressed:
		_transition_to_main()


func _transition_to_main() -> void:
	if _transitioning:
		return
	_transitioning = true
	progress_bar.value = 100.0

	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(ROOT_SCENE))
