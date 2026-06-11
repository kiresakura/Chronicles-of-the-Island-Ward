# 鎮島錄 Q2-A — 遶境地圖蜿蜒重映射守門（DELEGATION §5 Q2「節點嵌入島嶼路徑」）。
# 表現層契約：確定性（同 location 永遠同點）、偏移有界（蜿蜒+抖動不破壞欄距可讀性）、
# Boss 端點穩定（壓迫感來自不抖）。資料層 location_position 不得被改動。
extends "res://tests/test_case.gd"

const MAP_SCRIPT := preload("res://scripts/ui/Map.gd")

func _loc(id: String, grid: Vector2, type: int = LocationData.LOCATION_TYPES.COMBAT) -> LocationData:
	var l: LocationData = LocationData.new()
	l.location_id = id
	l.location_position = grid
	l.location_type = type
	return l

func test_display_position_deterministic() -> void:
	var l := _loc("location_1_7", Vector2(300, 600))
	var a: Vector2 = MAP_SCRIPT.display_position(l, 0.0)
	var b: Vector2 = MAP_SCRIPT.display_position(l, 0.0)
	assert_eq(a, b, "同一 location 必須永遠映到同一顯示點（確定性）")

func test_display_position_bounded_offsets() -> void:
	# 蜿蜒 + 抖動 + 欄錯位的總偏移必須有界：x ≤ AMP+JITTER_X、y ≤ JITTER_Y+max|COL_STAGGER|。
	var max_stagger: float = 0.0
	for s: float in MAP_SCRIPT.COL_STAGGER:
		max_stagger = maxf(max_stagger, absf(s))
	for i: int in 12:
		var l := _loc("location_1_%d" % i, Vector2(200 + 100 * (i % 5), 100 + 100 * i))
		var p: Vector2 = MAP_SCRIPT.display_position(l, 0.0)
		assert_true(absf(p.x - l.location_position.x) <= MAP_SCRIPT.SERPENT_AMP + MAP_SCRIPT.JITTER_X + 0.001,
			"x 偏移超界：%s" % str(p))
		assert_true(absf(p.y - l.location_position.y) <= MAP_SCRIPT.JITTER_Y + max_stagger + 0.001,
			"y 偏移超界：%s" % str(p))
	assert_true((MAP_SCRIPT.JITTER_Y + max_stagger) * 2.0 < 100.0,
		"y 總偏移必須遠小於樓層距（垂直順序不可顛倒）")

func test_same_column_vertical_spacing_preserved() -> void:
	# 欄錯位是「整欄同移」：同欄上下鄰節點的距離只受 jitter 影響（±2×JITTER_Y），
	# 不受 stagger 影響 — 同欄縱向絕不互撞。
	var a := _loc("location_1_20", Vector2(300, 500))
	var b := _loc("location_1_21", Vector2(300, 600))
	var pa: Vector2 = MAP_SCRIPT.display_position(a, 0.0)
	var pb: Vector2 = MAP_SCRIPT.display_position(b, 0.0)
	assert_true(absf((pb.y - pa.y) - 100.0) <= MAP_SCRIPT.JITTER_Y * 2.0 + 0.001,
		"同欄縱距應 ≈ 100（僅 jitter 浮動），實得 %f" % (pb.y - pa.y))

func test_display_position_does_not_mutate_data() -> void:
	var l := _loc("location_1_3", Vector2(400, 500))
	var before: Vector2 = l.location_position
	MAP_SCRIPT.display_position(l, 123.0)
	assert_eq(l.location_position, before, "重映射是表現層：不得改動 location_position 資料")

func test_boss_rides_centerline_without_jitter() -> void:
	# Boss 不抖：x 偏移應正好等於該 y 的蜿蜒值、y 不動。
	var grid := Vector2(400, 100)
	var l := _loc("location_1_99", grid, LocationData.LOCATION_TYPES.BOSS)
	var p: Vector2 = MAP_SCRIPT.display_position(l, 0.0)
	var serpent: float = MAP_SCRIPT.SERPENT_AMP * sin(grid.y * TAU / MAP_SCRIPT.SERPENT_WAVELEN + 0.7)
	assert_true(absf(p.x - (grid.x + serpent)) < 0.001, "Boss x 應正好 = 格點 + 蜿蜒（無抖動）")
	assert_eq(p.y, grid.y, "Boss y 不抖")

func test_shift_translates_x_only() -> void:
	var l := _loc("location_1_5", Vector2(300, 700))
	var p0: Vector2 = MAP_SCRIPT.display_position(l, 0.0)
	var p1: Vector2 = MAP_SCRIPT.display_position(l, 80.0)
	assert_true(absf((p1.x - p0.x) - 80.0) < 0.001, "x_shift 應為純平移")
	assert_eq(p1.y, p0.y, "x_shift 不影響 y")
