extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

const ROUTE_STATE_DIM := "dim"
const ROUTE_STATE_REACHABLE := "reachable"
const ROUTE_STATE_VISITED := "visited"
const MAP_NODE_ANCHOR := Vector2(44, 44)

# Q2-A 遶境地圖二輪 — 蜿蜒重映射（DELEGATION §5 Q2「節點嵌入島嶼路徑」）。
# 生成器的 location_position 是格陣（存檔資料，動它要遷移存檔且違反 fork-first）；
# 這裡只做「表現層」重映射：格陣 → 蜿蜒進香路。資料不動，存檔/測試/生成全不受影響。
const SERPENT_AMP := 84.0			# 蜿蜒振幅（px；整排同移，不改鄰距）
const SERPENT_WAVELEN := 430.0		# 蜿蜒波長（px，沿 y 軸）
const JITTER_X := 13.0				# 節點手繪感抖動（由 location_id 決定，確定性）
const JITTER_Y := 9.0
const TRAIL_GRID_MIN_X := 200.0		# 生成器格陣 x 範圍（MIDDLE=400 ± 2×100）
const TRAIL_GRID_MAX_X := 600.0
# 逐欄縱向錯位：打散「水平成排」的格陣感。同欄整欄同移 → 同欄上下鄰距不變（不互撞）；
# 橫向鄰欄高低參差 → 視覺成「五條山徑並行交織」而非表格。
const COL_STAGGER: Array[float] = [0.0, -18.0, 12.0, -12.0, 20.0]

const PAPER_SCROLL_PATH := "res://assets/generated/map_v7/talisman_scroll_v1.png"
const BOSS_AURA_PATH := "res://assets/generated/map_v7/boss_sha_aura_v1.png"
const BOSS_GATE_PATH := "res://assets/generated/map_v7/boss_gate_v1.png"

@onready var scroll_container = $ScrollContainer
@onready var location_container = $ScrollContainer/LocationContainer
@onready var back_button: Button = $BackButton

@onready var map_button = %MapButton

var can_travel: bool = false	# if clicking on a location brings you to the next location
var _route_line_layer: Control
var _route_marker_layer: Control
var _boss_omen_layer: Control

## Adds a margin to the bottom of the map display
const MAP_Y_MARGIN: float = 150

func _ready():
	map_button.button_up.connect(_on_map_button_up)
	back_button.button_up.connect(_on_back_button_up)
	
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)
	
	Signals.dialogue_ended.connect(_on_dialogue_ended)
	
	Signals.chest_opened.connect(_on_chest_opened)
	Signals.shop_opened.connect(_on_shop_opened)
	
	Signals.map_location_selected.connect(_on_map_location_selected)
	# P0-2 遶境地圖 v6：島嶼進香路背景。以 Map 自身子節點承載（避免多畫面共用 CanvasLayer -10
	# 疊序導致別的畫面背景滲入），並把不透明灰板降為薄暗角，露出遶境背景。
	_apply_pilgrimage_backdrop()
	_ensure_map_story_layers()

## P0-2：露出遶境地圖背景。原 Background2 為不透明灰板蓋住背景 → 改全透明；Background 降為薄暗角；
## 並把 map_bg_v6 加為 Map 自身最底層子節點（隨地圖顯隱正確、不與其他畫面背景搶層）。保留節點，不刪。
func _apply_pilgrimage_backdrop() -> void:
	var bg2: Node = get_node_or_null("Background2")
	if bg2 is ColorRect:
		(bg2 as ColorRect).color = Color(0.0, 0.0, 0.0, 0.0)	# 不透明灰板 → 全透明
	var bg1: Node = get_node_or_null("Background")
	if bg1 is ColorRect:
		(bg1 as ColorRect).color = Color(0.05, 0.04, 0.06, 0.30)	# 薄暗角，維持節點/連線對比
		# Q2-A z 層修正：暗角壓到 -9，否則蓋住 LocationContainer 內負 z 的符紙/路線層
		#（z_index 跨手足比 tree order 優先 — 路線一直偏暗的根因）
		(bg1 as ColorRect).z_index = -9
	const MAP_BG := "res://assets/generated/pixellab/map_bg_v6.png"
	if get_node_or_null("PilgrimageBackdrop") == null and ResourceLoader.exists(MAP_BG):
		var bg := TextureRect.new()
		bg.name = "PilgrimageBackdrop"
		bg.texture = load(MAP_BG)
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.add_to_group("fullbleed_mask")	# UIQA P2-5：寬螢幕側帶也覆蓋（COVERED 自裁切）
		bg.z_index = -10	# Q2-A：最底（< 暗角 -9 < 符紙 -5 < 山門 -4 < 路線 -3 < 節點 0）
		add_child(bg)
		move_child(bg, 0)	# 置最底：在暗角/節點之下

func populate_locations(locations: Array[LocationData] = Global.get_all_act_locations()):
	clear_locations()
	_ensure_map_story_layers()
	
	var next_locations: Array[LocationData] = Global.get_next_locations()
	var max_y: float = 0.0 # the highest location position, used to determine container size
	
	var current_map_location: MapLocation = null
	var reachable_map_locations: Array[MapLocation] = []
	var location_by_id: Dictionary = {}
	var boss_map_location: MapLocation = null

	for location_data in locations:
		if location_data.location_type == LocationData.LOCATION_TYPES.STARTING:
			continue	# starting area not displayed

		var map_location: MapLocation = Scenes.MAP_LOCATION.instantiate()
		location_container.add_child(map_location)

		var is_reachable: bool = can_travel and next_locations.has(location_data)
		var is_current: bool = location_data == Global.get_player_location_data()
		map_location.init(location_data, is_reachable, is_current, can_travel)
		# 表現層重映射：init 內以格陣資料定位，這裡覆寫為蜿蜒進香路顯示位（資料不動）
		map_location.position = display_position(location_data, _trail_x_shift())
		map_location.map_location_button_up.connect(_on_map_location_button_up)

		max_y = max(max_y, map_location.position.y)
		location_by_id[location_data.location_id] = map_location
		
		if is_reachable:
			map_location.flash_location()
			reachable_map_locations.append(map_location)
		if is_current:
			current_map_location = map_location
		elif current_map_location == null and is_reachable:
			current_map_location = map_location
		if location_data.location_type == LocationData.LOCATION_TYPES.BOSS:
			boss_map_location = map_location
	
	# set the size of the container to make scrolling posible
	location_container.custom_minimum_size.y = max_y + MAP_Y_MARGIN
	location_container.size.y = max_y + MAP_Y_MARGIN
	
	# 地圖不是 icon 清單，而是路線敘事：符紙路引、連線狀態、引路感、Boss 壓迫一起補上。
	_rebuild_paper_scroll(locations)
	_rebuild_map_story_layers(locations, location_by_id, current_map_location, reachable_map_locations, next_locations, boss_map_location)
	_dress_boss_node(boss_map_location)

	# wait a frame to ensure container is properly resized
	await Global.get_tree().process_frame
	# set the scroll
	if current_map_location != null:
		current_map_location.grab_focus()
	else:
		# presumably the invisible starting location, set to bottom
		scroll_container.scroll_vertical = max_y
	

func clear_locations() -> void:
	# Q2-A 修既有潛伏 bug：原本連故事層一起 free，但 _ensure 的 null 檢查在
	# 「queue_free pending、尚未真正釋放」狀態下不重建 → 路線/Boss 層整層死在當幀
	# （地圖連線「有時消失」的隨機根因 — 取決於 show_map 呼叫節奏）。
	# 故事層持久化：本體保留，內容物由 _rebuild_map_story_layers 自清。
	for child in location_container.get_children():
		if child == _boss_omen_layer or child == _route_line_layer or child == _route_marker_layer:
			continue
		child.queue_free()

func _ensure_map_story_layers() -> void:
	if _boss_omen_layer != null and not is_instance_valid(_boss_omen_layer):
		_boss_omen_layer = null
	if _route_line_layer != null and not is_instance_valid(_route_line_layer):
		_route_line_layer = null
	if _route_marker_layer != null and not is_instance_valid(_route_marker_layer):
		_route_marker_layer = null
	if _boss_omen_layer == null:
		_boss_omen_layer = Control.new()
		_boss_omen_layer.name = "BossOmenLayer"
		_boss_omen_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_boss_omen_layer.z_index = -4
		location_container.add_child(_boss_omen_layer)
	if _route_line_layer == null:
		_route_line_layer = Control.new()
		_route_line_layer.name = "RouteLineLayer"
		_route_line_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_route_line_layer.z_index = -3
		location_container.add_child(_route_line_layer)
	if _route_marker_layer == null:
		_route_marker_layer = Control.new()
		_route_marker_layer.name = "RouteMarkerLayer"
		_route_marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_route_marker_layer.z_index = -2
		location_container.add_child(_route_marker_layer)

static func _map_anchor_from_position(position: Vector2) -> Vector2:
	return position + MAP_NODE_ANCHOR

# ---------- Q2-A 蜿蜒重映射（表現層，資料不動）----------

## 格陣 → 蜿蜒進香路。確定性：同一 location 永遠映到同一點（jitter 由 id hash 決定）。
static func display_position(location_data: LocationData, x_shift: float) -> Vector2:
	var grid: Vector2 = location_data.location_position
	var serpent: float = SERPENT_AMP * sin(grid.y * TAU / SERPENT_WAVELEN + 0.7)
	var h: int = location_data.location_id.hash()
	var jx: float = float(h % 1000) / 1000.0 * 2.0 - 1.0			# -1..1
	var jy: float = float((h / 1000) % 1000) / 1000.0 * 2.0 - 1.0
	var col: int = clampi(int(roundf((grid.x - TRAIL_GRID_MIN_X) / 100.0)), 0, COL_STAGGER.size() - 1)
	var stagger: float = COL_STAGGER[col]
	# Boss 走中軸不抖不錯位：壓迫感來自端點的穩，蜿蜒留給途中
	if location_data.location_type == LocationData.LOCATION_TYPES.BOSS:
		jx = 0.0
		jy = 0.0
		stagger = 0.0
	return Vector2(grid.x + serpent + jx * JITTER_X + x_shift, grid.y + jy * JITTER_Y + stagger)

## 蜿蜒帶置中：格陣帶（200..600 + 節點 88）置中到實際視口寬。
func _trail_x_shift() -> float:
	var view_w: float = get_viewport_rect().size.x
	var resp: Node = get_node_or_null("/root/Responsive")
	if resp != null:
		view_w = resp.screen_rect.size.x
	var band_center: float = (TRAIL_GRID_MIN_X + TRAIL_GRID_MAX_X + MAP_NODE_ANCHOR.x * 2.0) * 0.5
	return view_w * 0.5 - band_center

## 半透明符紙路卷：墊在節點/路線之下、島嶼背景之上 —「遶境路引是一張開出來的符紙」。
## 有正式材質用材質；否則程序化符紙（暖紙底 + 硃砂內框 + 印章角）— 設計性 matting，非佔位。
func _rebuild_paper_scroll(locations: Array[LocationData]) -> void:
	var old: Node = location_container.get_node_or_null("TalismanScroll")
	if old != null:
		old.queue_free()
	var min_y: float = INF
	var max_y: float = -INF
	for location_data: LocationData in locations:
		if location_data.location_type == LocationData.LOCATION_TYPES.STARTING:
			continue
		min_y = minf(min_y, location_data.location_position.y)
		max_y = maxf(max_y, location_data.location_position.y)
	if min_y == INF:
		return
	var shift: float = _trail_x_shift()
	var band_left: float = TRAIL_GRID_MIN_X + shift - SERPENT_AMP - 76.0
	var band_right: float = TRAIL_GRID_MAX_X + MAP_NODE_ANCHOR.x * 2.0 + shift + SERPENT_AMP + 76.0
	var band_top: float = maxf(0.0, min_y - 132.0)
	var band_size := Vector2(band_right - band_left, max_y + 124.0 - band_top)

	var scroll: Control
	if ResourceLoader.exists(PAPER_SCROLL_PATH):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(PAPER_SCROLL_PATH)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		tex_rect.modulate = Color(1, 1, 1, 0.86)
		scroll = tex_rect
	else:
		scroll = _make_procedural_talisman_panel(band_size)
	scroll.name = "TalismanScroll"
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.position = Vector2(band_left, band_top)
	scroll.size = band_size
	scroll.z_index = -5	# BossOmen(-4)/路線(-3)/節點(0) 之下
	location_container.add_child(scroll)

## 程序化符紙：半透明暖紙 + 硃砂雙框 + 四角印章方。零素材依賴的設計面板。
static func _make_procedural_talisman_panel(panel_size: Vector2) -> Control:
	var panel := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.91, 0.82, 0.60, 0.30)			# 暖符紙，透島嶼
	sb.border_color = Color(0.62, 0.13, 0.09, 0.62)		# 硃砂框
	sb.set_border_width_all(3)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.anti_aliasing = true
	panel.add_theme_stylebox_override("panel", sb)
	# 內框（細線，雙框出「符」的版式感）
	var inner := Panel.new()
	inner.name = "InnerFrame"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sbi := StyleBoxFlat.new()
	sbi.bg_color = Color.TRANSPARENT
	sbi.border_color = Color(0.62, 0.13, 0.09, 0.34)
	sbi.set_border_width_all(1)
	sbi.anti_aliasing = true
	inner.add_theme_stylebox_override("panel", sbi)
	inner.position = Vector2(9, 9)
	inner.size = panel_size - Vector2(18, 18)
	panel.add_child(inner)
	# 四角硃砂印章方（45° 菱形）
	for corner: int in 4:
		var seal := ColorRect.new()
		seal.name = "CornerSeal%d" % corner
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.color = Color(0.62, 0.13, 0.09, 0.55)
		seal.size = Vector2(16, 16)
		seal.pivot_offset = seal.size * 0.5
		seal.rotation_degrees = 45.0
		var sx: float = 22.0 if corner % 2 == 0 else panel_size.x - 38.0
		var sy: float = 24.0 if corner < 2 else panel_size.y - 40.0
		seal.position = Vector2(sx, sy)
		panel.add_child(seal)
	return panel

## Boss 節點壓迫感：煞氣光暈（緩旋脈動）+ 不動按鈕幾何（觸控/連線錨點不受影響）。
func _dress_boss_node(boss_map_location: MapLocation) -> void:
	if boss_map_location == null or _boss_omen_layer == null:
		return
	if not ResourceLoader.exists(BOSS_AURA_PATH):
		return
	var center: Vector2 = boss_map_location.position + MAP_NODE_ANCHOR
	var aura := TextureRect.new()
	aura.name = "BossShaAura"
	aura.texture = load(BOSS_AURA_PATH)
	aura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	aura.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.size = Vector2(196, 196)
	aura.pivot_offset = aura.size * 0.5
	aura.position = center - aura.size * 0.5
	_boss_omen_layer.add_child(aura)
	var tw := aura.create_tween().set_loops()
	tw.tween_property(aura, "rotation_degrees", 360.0, 14.0).from(0.0)
	var pulse := aura.create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(aura, "modulate", Color(1.0, 0.86, 0.86, 0.92), 1.1)
	pulse.tween_property(aura, "modulate", Color(1, 1, 1, 0.66), 1.1)

static func _make_path_midpoint(from_position: Vector2, to_position: Vector2) -> Vector2:
	var midpoint := from_position.lerp(to_position, 0.5)
	var horizontal_delta: float = to_position.x - from_position.x
	var vertical_delta: float = to_position.y - from_position.y
	var arc_direction: float = -1.0 if horizontal_delta >= 0.0 else 1.0
	return midpoint + Vector2(horizontal_delta * 0.08, vertical_delta * -0.10 + arc_direction * 12.0)

static func make_map_path_line(from_position: Vector2, to_position: Vector2, route_state: String = ROUTE_STATE_DIM) -> Line2D:
	var start := _map_anchor_from_position(from_position)
	var finish := _map_anchor_from_position(to_position)
	var line := Line2D.new()
	line.name = "MapPathLine"
	line.points = PackedVector2Array([start, _make_path_midpoint(start, finish), finish])
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.antialiased = true
	line.z_index = -1
	line.set_meta("route_state", route_state)
	line.set_meta("route_story", "pilgrimage_route")
	line.set_meta("path_from", from_position)
	line.set_meta("path_to", to_position)
	match route_state:
		ROUTE_STATE_REACHABLE:
			line.width = 7.0
			line.default_color = COTIW_UI_THEME.get_color("neon_cyan", Color(0.31, 0.78, 0.90, 0.86))
			var guide_gradient := Gradient.new()
			guide_gradient.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
			guide_gradient.colors = PackedColorArray([
				Color(0.16, 0.34, 0.40, 0.16),
				COTIW_UI_THEME.get_color("neon_cyan", Color(0.31, 0.78, 0.90, 0.72)),
				Color(0.98, 0.90, 0.62, 0.96),
			])
			line.gradient = guide_gradient
			line.set_meta("is_reachable_flow", true)
			line.set_meta("direction_cue", "incense_guidance")
		ROUTE_STATE_VISITED:
			line.width = 6.0
			line.default_color = Color(0.86, 0.42, 0.16, 0.80)
			var ember_gradient := Gradient.new()
			ember_gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
			ember_gradient.colors = PackedColorArray([
				Color(0.42, 0.08, 0.05, 0.76),
				Color(0.80, 0.30, 0.10, 0.84),
				Color(0.96, 0.72, 0.26, 0.90),
			])
			line.gradient = ember_gradient
		_:
			# Q2-A：z 層修正後 dim 線不再被暗角壓暗 → 自身降透明度，未知路保持「隱約」
			line.width = 3.5
			line.default_color = Color(0.18, 0.14, 0.14, 0.30)
			var dim_gradient := Gradient.new()
			dim_gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
			dim_gradient.colors = PackedColorArray([
				Color(0.12, 0.10, 0.10, 0.13),
				Color(0.24, 0.18, 0.18, 0.24),
				Color(0.14, 0.10, 0.10, 0.12),
			])
			line.gradient = dim_gradient
	return line

static func make_reachable_flow_line(from_position: Vector2, to_position: Vector2) -> Line2D:
	var line := make_map_path_line(from_position, to_position, ROUTE_STATE_REACHABLE)
	line.name = "ReachableFlowLine"
	return line

## 路基線：與狀態線同路徑、更寬、暗土色，墊底（z -2 < 狀態線 -1）。
static func make_road_bed_line(from_position: Vector2, to_position: Vector2) -> Line2D:
	var start := _map_anchor_from_position(from_position)
	var finish := _map_anchor_from_position(to_position)
	var bed := Line2D.new()
	bed.name = "RoadBedLine"
	bed.points = PackedVector2Array([start, _make_path_midpoint(start, finish), finish])
	bed.joint_mode = Line2D.LINE_JOINT_ROUND
	bed.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bed.end_cap_mode = Line2D.LINE_CAP_ROUND
	bed.antialiased = true
	bed.width = 16.0
	bed.default_color = Color(0.20, 0.13, 0.09, 0.50)
	bed.z_index = -2
	bed.set_meta("route_story", "road_bed")
	return bed

static func make_boss_omen_marker(boss_center: Vector2) -> Control:
	var holder := Control.new()
	holder.name = "BossOmenMarker"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = Vector2(boss_center.x - 210.0, maxf(0.0, boss_center.y - 202.0))
	holder.size = Vector2(420.0, 232.0)
	holder.set_meta("route_story", "boss_omen")
	holder.set_meta("omen_subject", "tiger_lord_gate")

	# 煞氣壓頂：Boss 區上方紅黑漸層帶（無素材依賴，程序化漸層）
	var sha_band := TextureRect.new()
	sha_band.name = "BossShaBand"
	sha_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 1.0])
	grad.colors = PackedColorArray([Color(0.22, 0.02, 0.03, 0.46), Color(0.22, 0.02, 0.03, 0.0)])
	var grad_tex := GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill_from = Vector2(0.5, 0.0)
	grad_tex.fill_to = Vector2(0.5, 1.0)
	sha_band.texture = grad_tex
	sha_band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sha_band.stretch_mode = TextureRect.STRETCH_SCALE
	sha_band.position = Vector2(-320.0, -36.0)
	sha_band.size = Vector2(1060.0, 250.0)
	holder.add_child(sha_band)

	if ResourceLoader.exists(BOSS_GATE_PATH):
		# 正式素材：紅黑山門（虎爺關牌樓），Boss 節點背後拔地而起
		var gate := TextureRect.new()
		gate.name = "BossGateArt"
		gate.texture = load(BOSS_GATE_PATH)
		gate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		gate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		gate.position = Vector2(60.0, 8.0)
		gate.size = Vector2(300.0, 188.0)
		holder.add_child(gate)
	else:
		# 佔位（明顯醜，等素材）：色塊山門
		var shadow := ColorRect.new()
		shadow.name = "BossMountainShadow"
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.position = Vector2(0.0, 12.0)
		shadow.size = Vector2(420.0, 220.0)
		shadow.color = Color(0.09, 0.04, 0.04, 0.34)
		holder.add_child(shadow)
		for x_offset in [92.0, 302.0]:
			var pillar := ColorRect.new()
			pillar.name = "BossGatePillar"
			pillar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pillar.position = Vector2(x_offset, 46.0)
			pillar.size = Vector2(24.0, 110.0)
			pillar.color = Color(0.16, 0.06, 0.06, 0.52)
			holder.add_child(pillar)
		var lintel := ColorRect.new()
		lintel.name = "BossGateLintel"
		lintel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lintel.position = Vector2(70.0, 34.0)
		lintel.size = Vector2(280.0, 22.0)
		lintel.color = Color(0.26, 0.08, 0.06, 0.62)
		holder.add_child(lintel)

	var omen_label := Label.new()
	omen_label.name = "BossOmenLabel"
	omen_label.text = "虎爺關"
	omen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	omen_label.position = Vector2(122.0, 0.0)
	omen_label.size = Vector2(176.0, 30.0)
	omen_label.add_theme_font_size_override("font_size", 16)
	omen_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.54, 0.78))
	omen_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.01, 0.88))
	omen_label.add_theme_constant_override("shadow_offset_x", 1)
	omen_label.add_theme_constant_override("shadow_offset_y", 2)
	holder.add_child(omen_label)

	return holder

func _rebuild_map_story_layers(locations: Array[LocationData], location_by_id: Dictionary, current_map_location: MapLocation, reachable_map_locations: Array[MapLocation], next_locations: Array[LocationData], boss_map_location: MapLocation) -> void:
	if _route_line_layer == null or _route_marker_layer == null or _boss_omen_layer == null:
		return
	for child in _route_line_layer.get_children():
		child.queue_free()
	for child in _route_marker_layer.get_children():
		child.queue_free()
	for child in _boss_omen_layer.get_children():
		child.queue_free()

	var reachable_ids: Dictionary = {}
	for reachable_location: LocationData in next_locations:
		reachable_ids[reachable_location.location_id] = true

	for from_location: LocationData in locations:
		if from_location.location_type == LocationData.LOCATION_TYPES.STARTING:
			continue
		var from_map_location: MapLocation = location_by_id.get(from_location.location_id)
		if from_map_location == null:
			continue
		for next_location_id: String in from_location.location_next_location_ids:
			var to_map_location: MapLocation = location_by_id.get(next_location_id)
			if to_map_location == null:
				continue
			var route_state := _classify_route_state(from_location, to_map_location.location_data, reachable_ids)
			# 路基（土路底）墊在彩色狀態線下：路線讀成「進香路」而非線框；未知路基更淡
			var road_bed := make_road_bed_line(from_map_location.position, to_map_location.position)
			if route_state == ROUTE_STATE_DIM:
				road_bed.default_color.a = 0.26
			_route_line_layer.add_child(road_bed)
			var line := make_map_path_line(from_map_location.position, to_map_location.position, route_state)
			_route_line_layer.add_child(line)
			if route_state == ROUTE_STATE_REACHABLE and current_map_location != null:
				_spawn_reachable_route_marker(from_map_location.position, to_map_location.position)

	_build_boss_omen(boss_map_location)

func _classify_route_state(from_location: LocationData, to_location: LocationData, reachable_ids: Dictionary) -> String:
	if bool(reachable_ids.get(to_location.location_id, false)):
		return ROUTE_STATE_REACHABLE
	if from_location.location_visited and to_location.location_visited:
		return ROUTE_STATE_VISITED
	return ROUTE_STATE_DIM

func _spawn_reachable_route_marker(from_position: Vector2, to_position: Vector2) -> void:
	var marker := ColorRect.new()
	marker.name = "ReachableGuideMarker"
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.size = Vector2(12, 12)
	marker.position = _map_anchor_from_position(from_position) - marker.size * 0.5
	marker.color = Color(0.98, 0.92, 0.70, 0.94)
	marker.set_meta("guide_route", true)
	_route_marker_layer.add_child(marker)
	var origin := _map_anchor_from_position(from_position) - marker.size * 0.5
	var destination := _map_anchor_from_position(to_position) - marker.size * 0.5
	var tween := marker.create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(marker, "position", destination, 0.95)
	tween.parallel().tween_property(marker, "modulate", Color(0.38, 0.86, 0.94, 0.30), 0.95)
	tween.tween_property(marker, "position", origin, 0.0)
	tween.parallel().tween_property(marker, "modulate", Color(1.0, 0.96, 0.76, 0.94), 0.0)

func _build_boss_omen(boss_map_location: MapLocation) -> void:
	if boss_map_location == null or _boss_omen_layer == null:
		return
	var boss_center := boss_map_location.position + MAP_NODE_ANCHOR
	_boss_omen_layer.add_child(make_boss_omen_marker(boss_center))

func show_map():
	populate_locations()
	visible = true

func hide_map():
	visible = false

func _on_map_button_up():
	show_map()

func _on_map_location_button_up(map_location: MapLocation):
	# map must be in travel mode
	if can_travel:
		# must be adjacent to player location
		if Global.get_next_locations().has(map_location.location_data):
			# visit the location
			ActionGenerator.generate_visit_location(map_location.location_data.location_id)
	
func _on_map_location_selected(location_data: LocationData):
	# disable travel mode
	can_travel = false
	hide_map()

func _on_combat_started(_event_id: String):
	can_travel = false

func _on_combat_ended():
	can_travel = true

func _on_chest_opened():
	can_travel = true

func _on_shop_opened():
	can_travel = true

func _on_dialogue_ended():
	var player: Player = Global.get_player()
	if player.is_alive():
		can_travel = true
		show_map()
	else:
		hide_map()

func _on_back_button_up():
	hide_map()
	get_combined_minimum_size()
