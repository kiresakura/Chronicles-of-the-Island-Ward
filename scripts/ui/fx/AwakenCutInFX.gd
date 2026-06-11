# 鎮島錄 Q3-A — Boss 覺醒 cut-in（多階段轉場演出；基準 Q-2 情緒峰值）。
# 構圖：全幅壓暗 50% → 黑底煞紅斜帶自右掃入（與降乩紅金帶鏡像 — 敵我語彙對立）
#       → Boss 立繪左側掃入（資料驅動 enemy_texture_path）→ 裂紋紅光 → 覺醒標題 → 退場。
# 總長 1.4s（≤1.5s 演出鐵律）；全程 MOUSE_FILTER_IGNORE 零輸入阻塞；效果結算不等演出。
class_name AwakenCutInFX
extends Object

const THROTTLE_MSEC: int = 600
const LAYER_AWAKEN: int = 87	# 擲筊(86) 之上、降乩(88) 之下
const DIM_ALPHA: float = 0.50
const TOTAL_LIFE: float = 1.4
const BAND_COLOR := Color(0.10, 0.04, 0.06, 0.97)	# 煞黑
const BAND_EDGE := Color(0.82, 0.16, 0.12)			# 煞紅緣
const BAND_TILT_DEG: float = 6.0					# 與降乩 -7° 鏡像

static var _last_msec: int = -100000

## 播放覺醒 cut-in。host 提供樹；enemy_data 提供名/立繪/覺醒標題。
static func play(host: Node, enemy_data: EnemyData) -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree() or enemy_data == null:
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
	layer.name = "AwakenCutInLayer"
	layer.layer = LAYER_AWAKEN
	tree.root.add_child(layer)

	# 1) 全幅壓暗（覺醒比降乩更沉）
	var dim := ColorRect.new()
	dim.name = "AwakenDim"
	dim.color = Color(0, 0, 0, 0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.position = screen.position
	dim.size = screen.size
	layer.add_child(dim)

	# 2) 煞黑斜帶（紅緣），自「右」掃入（降乩自左 — 敵我鏡像）
	var band := Control.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.rotation_degrees = BAND_TILT_DEG
	band.position = Vector2(screen.position.x + screen.size.x, cy - 64.0)
	layer.add_child(band)
	var band_w: float = screen.size.x * 2.2
	var cloth := ColorRect.new()
	cloth.color = BAND_COLOR
	cloth.size = Vector2(band_w, 248.0)
	cloth.position = Vector2(-band_w, 0)	# 帶體向左展開
	cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(cloth)
	for edge_y: float in [-6.0, 248.0]:
		var edge := ColorRect.new()
		edge.color = BAND_EDGE
		edge.size = Vector2(band_w, 6.0)
		edge.position = Vector2(-band_w, edge_y)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		band.add_child(edge)

	# 3) 裂紋紅光（立繪後方放射 — 比降乩金扇更銳利的窄角）
	var rays := Control.new()
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays.position = Vector2(cx - screen.size.x * 0.18, cy)
	rays.modulate = Color(1, 1, 1, 0)
	layer.add_child(rays)
	for i: int in 6:
		var ray := ColorRect.new()
		ray.color = Color(0.92, 0.20, 0.14, 0.6)
		ray.size = Vector2(screen.size.x * 0.5, 4.0)
		ray.pivot_offset = Vector2(0, 2.0)
		ray.rotation_degrees = 150.0 + 12.0 * i
		ray.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rays.add_child(ray)

	# 4) Boss 立繪（資料驅動）：左側掃入（與降乩右側鏡像）
	var tex: Texture2D = null
	var tex_path: String = str(enemy_data.enemy_texture_path)
	if tex_path != "":
		tex = load(tex_path) if tex_path.begins_with("res://") else FileLoader.load_texture(tex_path)
	var portrait := TextureRect.new()
	if tex != null:
		portrait.texture = tex
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size = Vector2(300, 300)
	portrait.pivot_offset = portrait.size * 0.5
	portrait.position = Vector2(screen.position.x - portrait.size.x - 80.0, cy - 150.0)
	portrait.modulate = Color(1.15, 0.85, 0.8)	# 煞紅染
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(portrait)
	var portrait_to_x: float = cx - screen.size.x * 0.18 - 150.0

	# 5) 覺醒標題（右側對位；JSON enemy_awaken_title，缺省「{名}・煞變」）
	var title_text: String = str(enemy_data.enemy_awaken_title)
	if title_text == "":
		title_text = "%s・煞變" % enemy_data.enemy_name
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 54)
	title.add_theme_color_override("font_color", Color(1.0, 0.42, 0.34))
	title.add_theme_color_override("font_shadow_color", Color(0.05, 0.0, 0.0, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.position = Vector2(screen.position.x + screen.size.x + 60.0, cy - 36.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(title)
	var title_to_x: float = cx + screen.size.x * 0.06

	# 6) 時間軸（含 6 步畫面震）
	var tw := layer.create_tween()
	tw.set_parallel(true)
	tw.tween_property(dim, "color:a", DIM_ALPHA, 0.10)
	tw.tween_property(band, "position:x", screen.position.x + screen.size.x * 1.55, 0.16) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property(portrait, "position:x", portrait_to_x, 0.22).set_delay(0.08) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(title, "position:x", title_to_x, 0.22).set_delay(0.10) \
		.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.tween_property(rays, "modulate:a", 1.0, 0.18).set_delay(0.16)
	tw.tween_property(rays, "rotation_degrees", -8.0, 0.95).set_delay(0.16)
	for fading: CanvasItem in [band, portrait, title, rays]:
		tw.tween_property(fading, "modulate:a", 0.0, 0.28).set_delay(1.02)
	tw.tween_property(dim, "color:a", 0.0, 0.30).set_delay(1.02)
	tw.tween_callback(_free_layer.bind(layer)).set_delay(TOTAL_LIFE)
	_shake(tree)

## 畫面震（借破煞節奏，幅度更大 — 覺醒是 Boss 戰最重一拍）。精確還原原位。
static func _shake(tree: SceneTree) -> void:
	var cam_holder: Node = tree.root
	if cam_holder == null or not cam_holder is Window:
		return
	var window: Window = cam_holder as Window
	var base: Vector2i = window.position
	var shake_tw := window.get_tree().create_tween()
	for i: int in 6:
		var off := Vector2i((6 - i) * (1 if i % 2 == 0 else -1), (5 - i) * (1 if i % 3 == 0 else -1))
		shake_tw.tween_callback(func() -> void: window.position = base + off).set_delay(0.035 * i)
	shake_tw.tween_callback(func() -> void: window.position = base).set_delay(0.24)

static func _free_layer(layer: CanvasLayer) -> void:
	if is_instance_valid(layer):
		layer.queue_free()
