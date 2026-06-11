# 鎮島錄 Q1-B — 破煞演出（DELEGATION §5 Q1 / 基準 Q-2 情緒峰值）。
# 煞盾碎裂：八卦護環放大碎散 + 像素碎片噴飛 + 全幅降亮 ≥30% + 畫面震。
# 純 CanvasLayer + Tween（FuheFX 同款慣例）；總長 ~0.72s（≤1.5s，符合演出鐵律免跳過條款）；
# 降亮層 mouse_filter=IGNORE — 演出零輸入阻塞，不拖慢操作。
# 演出層只讀事件與座標，數值邏輯留在 WardBreakSystem/JSON（鐵律 1）。
class_name WardBreakFX
extends Object

const RING_PATH: String = "res://assets/generated/icons_v2/status/block_bagua.svg"
const THROTTLE_MSEC: int = 90
const LAYER_BREAK: int = 85	# toast(80) 之上、合符(90) 之下
const DIM_ALPHA: float = 0.35	# 背景降亮 35%（基準 Q-2 要求 ≥30%）
const SHARD_COUNT: int = 12
const SHARD_COLOR := Color(0.55, 0.95, 0.95)	# 煞盾青色系
const SHARD_CORE := Color(1.0, 1.0, 1.0)
const SHAKE_AMPLITUDE: float = 7.0
const SHAKE_STEPS: int = 5
const TOTAL_LIFE: float = 0.72

static var _last_msec: int = -100000

## 在 at_global（畫面座標）播放一次破煞演出。host = Combat（兼作畫面震對象）。
static func play(host: Control, at_global: Vector2) -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_msec < THROTTLE_MSEC:
		return	# AoE 連破節流：同拍不疊爆
	_last_msec = now
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return

	var layer := CanvasLayer.new()
	layer.name = "WardBreakFXLayer"
	layer.layer = LAYER_BREAK
	tree.root.add_child(layer)

	# 1) 全幅降亮（IGNORE：不擋任何輸入）
	var dim := ColorRect.new()
	dim.name = "BreakDim"
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var screen: Rect2 = Rect2(Vector2.ZERO, Vector2(1200, 700))
	var resp: Node = host.get_node_or_null("/root/Responsive")
	if resp != null:
		screen = resp.screen_rect
	dim.position = screen.position
	dim.size = screen.size
	layer.add_child(dim)

	# 2) 八卦護環碎裂主體（放大 + 瞬白 + 淡出）
	var ring := TextureRect.new()
	ring.texture = load(RING_PATH)
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ring.size = Vector2(150, 150)
	ring.position = at_global - ring.size * 0.5
	ring.pivot_offset = ring.size * 0.5
	ring.modulate = Color(1.6, 1.6, 1.6, 0.95)	# 過曝瞬白
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ring)

	# 3) 像素碎片（噴飛 + 重力下墜 + 旋轉淡出）
	var rng := RandomNumberGenerator.new()
	rng.seed = now	# 演出層隨機只影響視覺，不進遊戲邏輯
	for i: int in SHARD_COUNT:
		var shard := ColorRect.new()
		var s: float = rng.randf_range(6.0, 14.0)
		shard.size = Vector2(s, s)
		shard.color = SHARD_CORE if i % 4 == 0 else SHARD_COLOR
		shard.position = at_global - shard.size * 0.5
		shard.pivot_offset = shard.size * 0.5
		shard.rotation = rng.randf_range(0.0, TAU)
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(shard)
		var ang: float = rng.randf_range(0.0, TAU)
		var dist: float = rng.randf_range(90.0, 190.0)
		var burst_to: Vector2 = shard.position + Vector2(cos(ang), sin(ang)) * dist + Vector2(0, -rng.randf_range(10.0, 50.0))
		var stw := layer.create_tween()
		stw.set_parallel(true)
		stw.tween_property(shard, "position", burst_to, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		stw.tween_property(shard, "position:y", burst_to.y + rng.randf_range(60.0, 130.0), 0.40).set_delay(0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		stw.tween_property(shard, "rotation", shard.rotation + rng.randf_range(-3.0, 3.0), 0.62)
		stw.tween_property(shard, "modulate:a", 0.0, 0.30).set_delay(0.34)

	# 4) 主時間軸：dim 進出 + 環放大淡出
	var tw := layer.create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "color:a", DIM_ALPHA, 0.08)
	tw.tween_property(dim, "color:a", 0.0, 0.30).set_delay(0.34)
	tw.tween_property(ring, "scale", Vector2(1.7, 1.7), 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "modulate", Color(0.55, 0.95, 0.95, 0.0), 0.34).set_delay(0.10)
	tw.tween_callback(_free_layer.bind(layer)).set_delay(TOTAL_LIFE)

	# 5) 畫面震（host 位移衰減；結束精確歸位）
	_shake(host)

static func _shake(host: Control) -> void:
	var orig: Vector2 = host.position
	var rng := RandomNumberGenerator.new()
	rng.seed = Time.get_ticks_msec() + 7
	var tw := host.create_tween()
	for i: int in SHAKE_STEPS:
		var damp: float = 1.0 - float(i) / float(SHAKE_STEPS)
		var off := Vector2(
			rng.randf_range(-SHAKE_AMPLITUDE, SHAKE_AMPLITUDE) * damp,
			rng.randf_range(-SHAKE_AMPLITUDE, SHAKE_AMPLITUDE) * damp
		)
		tw.tween_property(host, "position", orig + off, 0.05)
	tw.tween_property(host, "position", orig, 0.06)

static func _free_layer(layer: CanvasLayer) -> void:
	if is_instance_valid(layer):
		layer.queue_free()
