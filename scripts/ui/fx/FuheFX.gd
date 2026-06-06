# 鎮島錄 — 合符 FX（P0-4）。
# 核心差異化動作「合符」的演出：兩張符飛合的金光爆 + 漫畫擬聲字「合符！」。
# 純 CanvasLayer + TextureRect + Tween（無粒子系統）；含節流避免連觸爆炸；
# 總時長 ~0.6s、~0.3s 後開始淡出，不長時間遮擋手牌核心資訊。
class_name FuheFX
extends Object

const BURST_PATH: String = "res://assets/generated/fx/fuhe_burst_v1.png"
const TEXT_PATH: String = "res://assets/generated/fx/fuhe_manga_text_v1.png"
const THROTTLE_MSEC: int = 260
const LAYER_FUHE: int = 90	# 在 toast(80) 之上

static var _last_msec: int = -100000

## 在 at_global（畫面座標）播放一次合符演出。host 提供 SceneTree。
static func play(host: Node, at_global: Vector2) -> void:
	if host == null or not is_instance_valid(host):
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_msec < THROTTLE_MSEC:
		return	# 節流：連續合符不疊爆
	_last_msec = now
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return

	var layer := CanvasLayer.new()
	layer.name = "FuheFXLayer"
	layer.layer = LAYER_FUHE
	tree.root.add_child(layer)

	var burst: TextureRect = _make_rect(BURST_PATH, Vector2(236, 236), at_global)
	if burst != null:
		burst.modulate = Color(1, 1, 1, 0)
		burst.scale = Vector2(0.45, 0.45)
		layer.add_child(burst)
	var glyph: TextureRect = _make_rect(TEXT_PATH, Vector2(300, 150), at_global + Vector2(0, -94))
	if glyph != null:
		glyph.modulate = Color(1, 1, 1, 0)
		glyph.scale = Vector2(0.6, 0.6)
		layer.add_child(glyph)

	var tw := layer.create_tween()
	tw.set_parallel(true)
	if burst != null:
		tw.tween_property(burst, "modulate:a", 1.0, 0.12)
		tw.tween_property(burst, "scale", Vector2(1.15, 1.15), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(burst, "modulate:a", 0.0, 0.30).set_delay(0.24)
		tw.tween_property(burst, "scale", Vector2(1.45, 1.45), 0.32).set_delay(0.24)
	if glyph != null:
		tw.tween_property(glyph, "modulate:a", 1.0, 0.14)
		tw.tween_property(glyph, "scale", Vector2(1.0, 1.0), 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(glyph, "modulate:a", 0.0, 0.30).set_delay(0.30)
		tw.tween_property(glyph, "position:y", glyph.position.y - 26.0, 0.34).set_delay(0.18)
	tw.tween_callback(_free_layer.bind(layer)).set_delay(0.64)

static func _free_layer(layer: CanvasLayer) -> void:
	if is_instance_valid(layer):
		layer.queue_free()

static func _make_rect(path: String, display_size: Vector2, center_global: Vector2) -> TextureRect:
	if not ResourceLoader.exists(path):
		return null
	var tr := TextureRect.new()
	tr.texture = load(path)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.size = display_size
	tr.pivot_offset = display_size * 0.5
	tr.position = center_global - display_size * 0.5
	return tr
