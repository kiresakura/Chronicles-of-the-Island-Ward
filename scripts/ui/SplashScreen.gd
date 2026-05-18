## 載入畫面 — 顯示廟會主題大圖 + 進度條 + 預載資料，完成後切換主選單
extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var progress_label: Label = $ProgressLabel
@onready var loading_dots: Label = $LoadingDots
@onready var tap_hint: Label = $TapHint

const ROOT_SCENE: String = "res://scenes/Root.tscn"
const TOTAL_LOAD_DURATION: float = 2.4
const MIN_DURATION_BEFORE_TAP_ALLOWED: float = 1.0

var _elapsed: float = 0.0
var _can_tap_to_start: bool = false
var _transitioning: bool = false
var _dot_timer: float = 0.0
var _dot_phase: int = 0
const LOADING_TIPS: Array[String] = [
	"召喚乩童中…",
	"擲筊問神中…",
	"焚香淨壇中…",
	"開光點睛中…",
	"鎮島降乩中…",
]


func _ready() -> void:
	progress_bar.value = 0
	progress_label.text = LOADING_TIPS[randi() % LOADING_TIPS.size()]
	tap_hint.modulate.a = 0.0


func _process(delta: float) -> void:
	if _transitioning:
		return

	_elapsed += delta
	var raw: float = clamp(_elapsed / TOTAL_LOAD_DURATION, 0.0, 1.0)
	# 用 ease-out 讓進度條前段快、後段稍慢，模擬真實載入感
	var eased: float = 1.0 - pow(1.0 - raw, 2.4)
	progress_bar.value = eased * 100.0

	# 跳動「點點點」省力動畫
	_dot_timer += delta
	if _dot_timer > 0.35:
		_dot_timer = 0.0
		_dot_phase = (_dot_phase + 1) % 4
		loading_dots.text = ".".repeat(_dot_phase)

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
