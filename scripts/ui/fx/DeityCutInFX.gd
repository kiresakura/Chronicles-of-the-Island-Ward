# 鎮島錄 Q1-D — 降乩 cut-in（DELEGATION §5 Q1 / 基準 Q-2 情緒峰值）。
# 構圖：全幅降亮 45% → 斜切紅布橫帶掃入（金邊）→ 神明立繪右側掃入（過衝定格）
#       → 金光射線 → 「神名・降乩」牌匾字左側對位 → 整體淡出。
# 素材走 DeityData.deity_texture_path（資料驅動，4 神自動各得其像；鐵律 1）。
# 總長 1.25s（≤1.5s 演出鐵律免跳過條款）；全程 MOUSE_FILTER_IGNORE 零輸入阻塞；
# 效果結算不等演出 — cut-in 純 overlay，不拖慢操作。
class_name DeityCutInFX
extends Object

const CARD_ART_REGISTRY := preload("res://scripts/ui/theme/CardArtRegistry.gd")
const THROTTLE_MSEC: int = 400
const LAYER_CUTIN: int = 88	# 破煞(85) 之上、合符(90) 之下
const DIM_ALPHA: float = 0.45
const TOTAL_LIFE: float = 1.25
const BAND_COLOR := Color(0.42, 0.06, 0.05, 0.96)	# 紅布
const BAND_EDGE := Color(0.95, 0.78, 0.32)			# 金邊
const BAND_TILT_DEG: float = -7.0

static var _last_msec: int = -100000

## 播放降乩 cut-in。host 提供樹；deity 提供名與立繪路徑。
static func play(host: Node, deity: DeityData) -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree() or deity == null:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_msec < THROTTLE_MSEC:
		return
	_last_msec = now
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return

	var screen: Rect2 = Rect2(Vector2.ZERO, Vector2(1200, 700))
	var resp: Node = host.get_node_or_null("/root/Responsive")
	if resp != null:
		screen = resp.screen_rect
	var cx: float = screen.position.x + screen.size.x * 0.5
	var cy: float = screen.position.y + screen.size.y * 0.46

	var layer := CanvasLayer.new()
	layer.name = "DeityCutInLayer"
	layer.layer = LAYER_CUTIN
	tree.root.add_child(layer)

	# 1) 全幅降亮
	var dim := ColorRect.new()
	dim.name = "CutInDim"
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.position = screen.position
	dim.size = screen.size
	layer.add_child(dim)

	# 2) 斜切紅布橫帶（含上下金邊），自左掃入
	var band := Control.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.rotation_degrees = BAND_TILT_DEG
	band.position = Vector2(screen.position.x - screen.size.x, cy - 60.0)	# 起點：整幅在畫面左外（終位讓牌匾字坐在布上）
	layer.add_child(band)
	var band_w: float = screen.size.x * 2.2
	var cloth := ColorRect.new()
	cloth.color = BAND_COLOR
	cloth.size = Vector2(band_w, 240.0)
	cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(cloth)
	for edge_y: float in [-6.0, 240.0]:
		var edge := ColorRect.new()
		edge.color = BAND_EDGE
		edge.size = Vector2(band_w, 6.0)
		edge.position = Vector2(0, edge_y)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		band.add_child(edge)

	# 3) 金光射線（立繪後方扇形）
	var rays := Control.new()
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays.position = Vector2(cx + screen.size.x * 0.18, cy)
	rays.modulate = Color(1, 1, 1, 0)
	layer.add_child(rays)
	for i: int in 7:
		var ray := ColorRect.new()
		ray.color = Color(1.0, 0.88, 0.45, 0.55)
		ray.size = Vector2(screen.size.x * 0.55, 5.0)
		ray.pivot_offset = Vector2(0, 2.5)
		ray.rotation_degrees = -42.0 + 14.0 * i
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rays.add_child(ray)

	# 4) 神明立繪（資料驅動路徑 → registry 反查 preload → FileLoader fallback）
	var tex: Texture2D = CARD_ART_REGISTRY.get_by_texture_path(deity.deity_texture_path)
	if tex == null and str(deity.deity_texture_path) != "":
		var p: String = str(deity.deity_texture_path)
		tex = load(p) if p.begins_with("res://") else FileLoader.load_texture(p)
	var portrait := TextureRect.new()
	if tex != null:
		portrait.texture = tex
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size = Vector2(300, 300)
	portrait.pivot_offset = portrait.size * 0.5
	portrait.position = Vector2(screen.position.x + screen.size.x + 80.0, cy - 150.0)	# 右外起點
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(portrait)
	var portrait_to_x: float = cx + screen.size.x * 0.18 - 150.0

	# 5) 「神名・降乩」牌匾字（左側對位）
	var title := Label.new()
	title.text = TranslationServer.translate("fx.invoke_title") % deity.deity_name
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	title.add_theme_color_override("font_shadow_color", Color(0.25, 0.03, 0.03, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.position = Vector2(screen.position.x - 420.0, cy - 36.0)	# 左外起點
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(title)
	var title_to_x: float = cx - screen.size.x * 0.30

	# 6) 時間軸
	var tw := layer.create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "color:a", DIM_ALPHA, 0.10)
	tw.tween_property(band, "position:x", screen.position.x - screen.size.x * 0.55, 0.16).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property(portrait, "position:x", portrait_to_x, 0.22).set_delay(0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(title, "position:x", title_to_x, 0.22).set_delay(0.10).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property(rays, "modulate:a", 1.0, 0.18).set_delay(0.16)
	tw.tween_property(rays, "rotation_degrees", 9.0, 0.9).set_delay(0.16)
	# 淡出段（0.85s 起全體退場）
	for fading: CanvasItem in [band, portrait, title, rays]:
		tw.tween_property(fading, "modulate:a", 0.0, 0.28).set_delay(0.90)
	tw.tween_property(dim, "color:a", 0.0, 0.30).set_delay(0.90)
	tw.tween_callback(_free_layer.bind(layer)).set_delay(TOTAL_LIFE)

static func _free_layer(layer: CanvasLayer) -> void:
	if is_instance_valid(layer):
		layer.queue_free()
