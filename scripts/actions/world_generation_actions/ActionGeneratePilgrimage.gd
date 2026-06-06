## 鎮島錄 — 遶境地圖生成器（2E）。
##
## 取代 STS 分支圖：沿用「網格 + 鄰接連線 + 末端 Boss」的有效圖結構（保證連通、可通關，
## 與 ActionGenerateAct 同），疊加「遶境路線」——依樓層深度指派 山路→夜市路→廟路→荒宅路，
## 把 污染度 / 香火回報 / 危險度 標記到每個 LocationData，並以危險度決定巡境遇煞的難度池。
## 節點語意轉為遶境：遇煞(COMBAT)/惡煞據點(MINIBOSS)/夜市香鋪(SHOP)/入廟安神(REST)/民俗問事(EVENT)/鎮煞大醮(BOSS)。
## 透過 ActData.act_action_script_path 切入（框架支援的多生成演算法擴充點，見 ActionGenerateAct 註解）。
extends BaseAction

var _route_cache: Dictionary = {}

func perform_action() -> void:
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	for action_interceptor_processor: ActionInterceptorProcessor in action_interceptor_processors:
		var rng_name: String = action_interceptor_processor.get_shadowed_action_values("rng_name", "rng_world_generation")
		var rng: RandomNumberGenerator = Global.player_data.get_player_rng(rng_name)

		var act_id: String = get_action_value("act_id", "")
		var act_data: ActData = Global.get_act_data(act_id)
		var act_number: int = get_action_value("act_number", Global.player_data.player_act)

		Global.player_data.player_act_id = act_id
		Global.player_data.player_act = act_number

		var floors_per_act: int = action_interceptor_processor.get_shadowed_action_values("floors_per_act", 10)
		var locations_per_floor: int = action_interceptor_processor.get_shadowed_action_values("locations_per_floor", 5)
		var obfuscation_rate: float = action_interceptor_processor.get_shadowed_action_values("location_obfuscation_rate", 0.5)
		var non_combat_event_rate: float = action_interceptor_processor.get_shadowed_action_values("location_non_combat_event_rate", 0.3)

		var generate_start_node: bool = act_number == 1
		const MIDDLE: int = 400
		const GRID_SPACING: int = 100
		var bottom: int = (floors_per_act + 1) * GRID_SPACING
		var middle_index: int = (locations_per_floor - 1) / 2
		var bottom_left: Vector2 = Vector2(MIDDLE - (GRID_SPACING * middle_index), bottom)

		var floors: Array[Array] = []
		var location_id_counter: int = 0
		var floor_counter: int = 0

		# 出巡起壇（起點）
		if generate_start_node:
			Global.clear_locations()
			var starting_location: LocationData = LocationData.new()
			starting_location.location_id = "location_0"
			Global.player_data.location_id_to_location_data["location_0"] = starting_location
			Global.player_data.player_location_id = starting_location.location_id
			starting_location.location_act = 1
			starting_location.location_index = Vector2(middle_index, -1)
			starting_location.location_position = bottom_left + (starting_location.location_index * GRID_SPACING)
			starting_location.location_floor = floor_counter
			starting_location.location_type = LocationData.LOCATION_TYPES.STARTING
			starting_location.location_event_object_id = "event_act_1_easy_combat_1"
			_apply_route(starting_location, 0, floors_per_act)
			var starting_floor: Array[LocationData] = [starting_location]
			floors.append(starting_floor)
		else:
			var current_location_data: LocationData = Global.get_player_location_data()
			Global.clear_locations()
			Global.player_data.location_id_to_location_data[current_location_data.location_id] = current_location_data
			var current_floor: Array[LocationData] = [current_location_data]
			floors.append(current_floor)

		# 各樓層的遶境節點
		var location_id: String = ""
		for k: int in floors_per_act:
			var current_floor: Array[LocationData] = []
			floor_counter += 1
			var route_props: Dictionary = _route_props(k + 1, floors_per_act)
			var danger: int = int(route_props.get("danger_rating", 2))
			for i: int in locations_per_floor:
				var location: LocationData = LocationData.new()
				location_id_counter += 1
				location_id = "location_" + str(act_number) + "_" + str(location_id_counter)
				location.location_id = location_id
				Global.player_data.location_id_to_location_data[location_id] = location
				location.location_act = act_number
				location.location_index = Vector2(i, k)
				location.location_position = bottom_left + (Vector2(i, -k) * GRID_SPACING)
				location.location_floor = floor_counter

				# 遶境節點型別（沿用平衡過的樓層分佈；難度池改由路線危險度決定）
				if k == 4:
					location.location_type = LocationData.LOCATION_TYPES.MINIBOSS	# 惡煞據點
					location.location_event_pool_object_id = act_data.act_miniboss_event_pool_object_id
				elif k == 6:
					location.location_type = LocationData.LOCATION_TYPES.REST_SITE	# 入廟安神
				elif k == 5:
					location.location_type = LocationData.LOCATION_TYPES.TREASURE
					location.location_event_pool_object_id = act_data.act_easy_combat_event_pool_object_id
				elif k == 3:
					location.location_type = LocationData.LOCATION_TYPES.SHOP	# 夜市香鋪
				else:
					# 巡境遇煞：荒宅路（danger>=3）走硬池，其餘易池
					location.location_type = LocationData.LOCATION_TYPES.COMBAT
					if danger >= 3:
						location.location_event_pool_object_id = act_data.act_hard_combat_event_pool_object_id
					else:
						location.location_event_pool_object_id = act_data.act_easy_combat_event_pool_object_id

				if [LocationData.LOCATION_TYPES.TREASURE, LocationData.LOCATION_TYPES.COMBAT].has(location.location_type):
					if rng.randf() < obfuscation_rate:
						location.location_obfuscated = true
				# 民俗問事 / 禁忌遭遇（部分遇煞轉事件）
				if location.location_type == LocationData.LOCATION_TYPES.COMBAT:
					if rng.randf() < non_combat_event_rate:
						location.location_obfuscated = true
						location.location_type = LocationData.LOCATION_TYPES.EVENT
						location.location_event_pool_object_id = act_data.act_non_combat_event_pool_object_id

				_apply_route_props(location, route_props)
				current_floor.append(location)

				# 鄰接連線（與 STS 相同：連到上層 i, i-1, i+1，保證連通可通關）
				if k > 0:
					var previous_floor: Array[LocationData] = floors[-1]
					previous_floor[i].location_next_location_ids.append(location_id)
					if (i - 1) >= 0:
						previous_floor[i - 1].location_next_location_ids.append(location_id)
					if (i + 1) < locations_per_floor:
						previous_floor[i + 1].location_next_location_ids.append(location_id)
				else:
					var previous_floor: Array[LocationData] = floors[-1]
					for previous_location: LocationData in previous_floor:
						previous_location.location_next_location_ids.append(location_id)
			floors.append(current_floor)

		# 鎮煞大醮（Boss，末端）
		floor_counter += 1
		var boss_location: LocationData = LocationData.new()
		location_id_counter += 1
		location_id = "location_" + str(act_number) + "_" + str(location_id_counter)
		boss_location.location_id = location_id
		Global.player_data.location_id_to_location_data[location_id] = boss_location
		boss_location.location_act = act_number
		boss_location.location_index = Vector2(middle_index, floors_per_act)
		boss_location.location_position = bottom_left + (Vector2(middle_index, -floors_per_act) * GRID_SPACING)
		boss_location.location_floor = floor_counter
		boss_location.location_type = LocationData.LOCATION_TYPES.BOSS
		boss_location.location_event_pool_object_id = act_data.act_boss_event_pool_object_id
		_apply_route(boss_location, floors_per_act, floors_per_act)
		if len(floors):
			var previous_floor: Array[LocationData] = floors[-1]
			for previous_location: LocationData in previous_floor:
				previous_location.location_next_location_ids.append(location_id)
		floors.append([boss_location] as Array[LocationData])

## 樓層 → 路線特徵（含快取，避免每節點重讀檔）。
func _route_props(floor_k: int, total_floors: int) -> Dictionary:
	var rid: String = PilgrimageRoutes.route_id_for_floor(floor_k, total_floors)
	if not _route_cache.has(rid):
		_route_cache[rid] = PilgrimageRoutes.load_route(rid)
	return _route_cache[rid]

func _apply_route(location: LocationData, floor_k: int, total_floors: int) -> void:
	_apply_route_props(location, _route_props(floor_k, total_floors))

## 把遶境路線特徵標記到 location（route_flavor / pollution / incense / danger）。
func _apply_route_props(location: LocationData, props: Dictionary) -> void:
	if props.is_empty():
		return
	location.location_route_flavor = str(props.get("route_flavor", ""))
	location.location_pollution_level = int(props.get("pollution_level", 0))
	location.location_incense_modifier = float(props.get("incense_reward_modifier", 1.0))
	location.location_danger_rating = int(props.get("danger_rating", 0))
