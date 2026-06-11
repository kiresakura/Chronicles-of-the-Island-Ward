## 鎮島錄 Q1-A — 戰鬥 HUD 三層閱讀秩序（DELEGATION §5 Q1／QA 2026-06-11 P1-2）。
##
## 層 1 每回合必讀（元神/敵意圖/神力/結束回合）：恆亮，不經本系統。
## 層 2 本回合操作（手牌/消耗品/可降乩）：恆亮；「可操作」時才允許發光效果。
## 層 3 低頻資訊（銀兩/牌堆四鈕/請神進度/地圖/暫停）：idle 降權至 IDLE_ALPHA，
##       數值變化時 pulse() 打一拍亮起再回落 —「吵不等於熱鬧；熱鬧要有鼓點」。
##
## 純靜態工具：additive，不動 STR 節點結構；接線在 Combat/CombatHudOverlay。
extends Object

const IDLE_ALPHA := 0.55
const FULL_ALPHA := 1.0
const PULSE_IN := 0.12
const PULSE_HOLD := 0.45
const PULSE_OUT := 0.35
const GROUP := "hud_low_freq"
const META_TWEEN := "hud_focus_tween"
const META_OPERATIONAL := "hud_focus_operational"

## 註冊為層 3 低頻元素：入 group + 立即降權。
static func mark_low_freq(item: CanvasItem) -> void:
	if item == null:
		return
	item.add_to_group(GROUP)
	item.modulate.a = IDLE_ALPHA

## 數值變化鼓點：亮一拍（PULSE_IN→HOLD→OUT 回 idle）。
## 僅對已註冊低頻元素生效；operational 狀態（恆亮）下不打拍。
static func pulse(item: CanvasItem) -> void:
	if item == null or not item.is_inside_tree() or not item.is_in_group(GROUP):
		return
	if item.get_meta(META_OPERATIONAL, false):
		return
	_kill_tween(item)
	var tw: Tween = item.create_tween()
	tw.tween_property(item, "modulate:a", FULL_ALPHA, PULSE_IN)
	tw.tween_interval(PULSE_HOLD)
	tw.tween_property(item, "modulate:a", IDLE_ALPHA, PULSE_OUT)
	item.set_meta(META_TWEEN, tw)

## 進出「可操作」狀態：可操作＝恆亮（層 2 待遇）；否則回低頻 idle。
static func set_operational(item: CanvasItem, operational: bool) -> void:
	if item == null:
		return
	item.set_meta(META_OPERATIONAL, operational)
	_kill_tween(item)
	item.modulate.a = FULL_ALPHA if operational else IDLE_ALPHA

static func _kill_tween(item: CanvasItem) -> void:
	# get_meta(key, null) 的 null 預設等同未給預設、缺 key 照樣報錯 → has_meta 前置
	if not item.has_meta(META_TWEEN):
		return
	var prev: Variant = item.get_meta(META_TWEEN)
	if prev is Tween and (prev as Tween).is_valid():
		(prev as Tween).kill()
