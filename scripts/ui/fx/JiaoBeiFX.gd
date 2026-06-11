# 鎮島錄 Q2-B — 擲筊演出（DELEGATION §5 Q2「供桌四選一 + 筊杯演出」／基準 Q-2）。
# 構圖：兩枚筊杯自供桌中央拋起（拋物線+翻滾、空中凸/平面交替＝翻面錯覺）
#       → 落桌定面「聖筊」（一凸一平）→ 塵土圈 + 金光暈 + 「聖筊」漫畫字 punch → 整體淡出。
# 總長 1.35s（≤1.5s 演出鐵律）；全程 MOUSE_FILTER_IGNORE 零輸入阻塞；
# 效果結算不等演出 — 選項 actions 即刻生效，本演出純 overlay。
class_name JiaoBeiFX
extends Object

const TEX_ROUND := "res://assets/ui/fx/jiaobei_round.svg"
const TEX_FLAT := "res://assets/ui/fx/jiaobei_flat.svg"
const THROTTLE_MSEC: int = 500
const LAYER_JIAOBEI: int = 86	# 破煞(85) 之上、降乩(88) 之下
const TOTAL_LIFE: float = 1.35
const TOSS_TIME: float = 0.55	# 拋起到落定
const FLIP_INTERVAL: float = 0.11	# 空中翻面節奏

static var _last_msec: int = -100000

## 在 center（畫面座標）擲筊。host 提供樹。
static func play(host: Node, center: Vector2) -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_msec < THROTTLE_MSEC:
		return
	_last_msec = now
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return
	if not ResourceLoader.exists(TEX_ROUND) or not ResourceLoader.exists(TEX_FLAT):
		return
	var tex_round: Texture2D = load(TEX_ROUND)
	var tex_flat: Texture2D = load(TEX_FLAT)

	var layer := CanvasLayer.new()
	layer.name = "JiaoBeiLayer"
	layer.layer = LAYER_JIAOBEI
	tree.root.add_child(layer)

	# 兩枚筊杯：左右分拋（鏡像參數），空中翻面，落地一凸一平＝聖筊
	var land_faces: Array[Texture2D] = [tex_flat, tex_round]
	for i: int in 2:
		var cup := TextureRect.new()
		cup.texture = tex_round if i == 0 else tex_flat
		cup.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cup.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cup.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cup.size = Vector2(86, 62)
		cup.pivot_offset = cup.size * 0.5
		var dir: float = -1.0 if i == 0 else 1.0
		var start := center + Vector2(dir * 8.0, 10.0)
		var land := center + Vector2(dir * 64.0, 26.0 + 6.0 * float(i))
		cup.position = start - cup.size * 0.5
		cup.rotation_degrees = dir * 8.0
		layer.add_child(cup)

		var tw := layer.create_tween()
		tw.set_parallel(true)
		# 拋物線：x 線性、y 先上後下（兩段 chain 模擬）
		tw.tween_property(cup, "position:x", land.x - cup.size.x * 0.5, TOSS_TIME)
		var rise := layer.create_tween()
		rise.tween_property(cup, "position:y", center.y - 128.0 - 18.0 * float(i) - cup.size.y * 0.5, TOSS_TIME * 0.46) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		rise.tween_property(cup, "position:y", land.y - cup.size.y * 0.5, TOSS_TIME * 0.54) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# 翻滾 + 翻面錯覺
		tw.tween_property(cup, "rotation_degrees", dir * (300.0 + 80.0 * float(i)), TOSS_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var flips: int = int(TOSS_TIME / FLIP_INTERVAL)
		for f: int in flips:
			var face: Texture2D = tex_flat if (f % 2 == (0 if i == 0 else 1)) else tex_round
			var ft := layer.create_tween()
			ft.tween_interval(FLIP_INTERVAL * float(f + 1))
			ft.tween_callback(_set_cup_texture.bind(cup, face))
		# 落定面 + 著地小彈跳
		var settle := layer.create_tween()
		settle.tween_interval(TOSS_TIME)
		settle.tween_callback(_set_cup_texture.bind(cup, land_faces[i]))
		settle.tween_callback(_land_bounce.bind(cup, dir))

	# 落定後：塵土圈 + 金暈 + 「聖筊」punch
	var beat := layer.create_tween()
	beat.tween_interval(TOSS_TIME + 0.04)
	beat.tween_callback(_play_verdict.bind(layer, center))

	var cleanup := layer.create_tween()
	cleanup.tween_interval(TOTAL_LIFE)
	cleanup.tween_callback(_free_layer.bind(layer))

static func _set_cup_texture(cup: TextureRect, tex: Texture2D) -> void:
	if is_instance_valid(cup):
		cup.texture = tex

static func _land_bounce(cup: TextureRect, dir: float) -> void:
	if not is_instance_valid(cup):
		return
	cup.rotation_degrees = dir * 6.0
	var tw := cup.create_tween()
	tw.tween_property(cup, "scale", Vector2(1.14, 0.84), 0.07)
	tw.tween_property(cup, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## 聖筊判定演出：擴散圈 + 「聖筊」金字 punch（漫畫節奏）。
static func _play_verdict(layer: CanvasLayer, center: Vector2) -> void:
	if not is_instance_valid(layer):
		return
	var ring := Panel.new()
	ring.name = "VerdictRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.border_color = Color(1.0, 0.86, 0.45, 0.9)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(90)
	sb.anti_aliasing = true
	ring.add_theme_stylebox_override("panel", sb)
	ring.size = Vector2(60, 60)
	ring.pivot_offset = ring.size * 0.5
	ring.position = center + Vector2(0, 22) - ring.size * 0.5
	ring.scale = Vector2(0.4, 0.4)
	layer.add_child(ring)
	var rt := layer.create_tween()
	rt.set_parallel(true)
	rt.tween_property(ring, "scale", Vector2(3.4, 2.1), 0.42).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	rt.tween_property(ring, "modulate:a", 0.0, 0.42)

	var label := Label.new()
	label.name = "VerdictLabel"
	label.text = "聖筊！"
	label.add_theme_font_size_override("font_size", 46)
	label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	label.add_theme_color_override("font_shadow_color", Color(0.3, 0.05, 0.04, 0.95))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = center + Vector2(-86.0, -118.0)
	label.pivot_offset = Vector2(86.0, 30.0)
	label.scale = Vector2(0.2, 0.2)
	label.modulate = Color(1, 1, 1, 0)
	layer.add_child(label)
	var lt := layer.create_tween()
	lt.set_parallel(true)
	lt.tween_property(label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lt.tween_property(label, "modulate:a", 1.0, 0.12)
	lt.tween_property(label, "modulate:a", 0.0, 0.26).set_delay(0.48)

static func _free_layer(layer: CanvasLayer) -> void:
	if is_instance_valid(layer):
		layer.queue_free()
