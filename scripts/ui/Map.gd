extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

const ROUTE_STATE_DIM := "dim"
const ROUTE_STATE_REACHABLE := "reachable"
const ROUTE_STATE_VISITED := "visited"
const MAP_NODE_ANCHOR := Vector2(44, 44)

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
	# v4 Recraft pixel_art 背景 + PixelFX 動畫（山間薄霧 + Ken Burns）
	const PixelSkinCls = preload("res://scripts/ui/theme/PixelSkin.gd")
	const PixelFXCls   = preload("res://scripts/ui/fx/PixelFX.gd")
	var _map_layer = PixelSkinCls.apply_background(self, "map_bg_v5.png")
	if _map_layer:
		PixelFXCls.apply(_map_layer, PixelFXCls.Preset.MIST)
	_ensure_map_story_layers()

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
		map_location.map_location_button_up.connect(_on_map_location_button_up)
		
		max_y = max(max_y, location_data.location_position.y)
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
	
	# 地圖不是 icon 清單，而是路線敘事：把所有連線狀態、引路感、Boss 壓迫一起補上。
	_rebuild_map_story_layers(locations, location_by_id, current_map_location, reachable_map_locations, next_locations, boss_map_location)

	# wait a frame to ensure container is properly resized
	await Global.get_tree().process_frame
	# set the scroll
	if current_map_location != null:
		current_map_location.grab_focus()
	else:
		# presumably the invisible starting location, set to bottom
		scroll_container.scroll_vertical = max_y
	

func clear_locations() -> void:
	for child in location_container.get_children():
		child.queue_free()

func _ensure_map_story_layers() -> void:
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
			line.width = 4.0
			line.default_color = Color(0.18, 0.14, 0.14, 0.42)
			var dim_gradient := Gradient.new()
			dim_gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
			dim_gradient.colors = PackedColorArray([
				Color(0.12, 0.10, 0.10, 0.20),
				Color(0.24, 0.18, 0.18, 0.34),
				Color(0.14, 0.10, 0.10, 0.18),
			])
			line.gradient = dim_gradient
	return line

static func make_reachable_flow_line(from_position: Vector2, to_position: Vector2) -> Line2D:
	var line := make_map_path_line(from_position, to_position, ROUTE_STATE_REACHABLE)
	line.name = "ReachableFlowLine"
	return line

static func make_boss_omen_marker(boss_center: Vector2) -> Control:
	var holder := Control.new()
	holder.name = "BossOmenMarker"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.position = Vector2(boss_center.x - 210.0, maxf(0.0, boss_center.y - 202.0))
	holder.size = Vector2(420.0, 232.0)
	holder.set_meta("route_story", "boss_omen")
	holder.set_meta("omen_subject", "tiger_lord_gate")

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
