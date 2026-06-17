# 鎮島錄 v0.3 — 緣分合祀（FC-6）回歸防線。
# 驗鄰接圖（中營樞紐+方位環）、緣分啟用（全成員佈陣 + 連通）、未佈陣/不連通則不啟用、讀檔。
extends "res://tests/test_case.gd"

const AffinityCls := preload("res://scripts/systems/ritual/AffinitySystem.gd")

# 五營（中+東南西北）最小 camps 結構（id + lane）
func _camps() -> Array:
	return [
		{"id": "camp_center", "lane": ""},
		{"id": "camp_north", "lane": "north"},
		{"id": "camp_east", "lane": "east"},
		{"id": "camp_south", "lane": "south"},
		{"id": "camp_west", "lane": "west"},
	]

func test_load_affinities() -> void:
	var affs: Array = AffinityCls.load_affinities()
	assert_true(affs.size() >= 2, "至少 2 條緣分（媽祖三聖 + 城隍土地）")
	var ids: Array = []
	for a: Dictionary in affs:
		ids.append(str(a.get("object_id")))
	assert_true(ids.has("affinity_mazu_eyes_ears"), "含媽祖緣分")

func test_adjacency_center_hub_and_ring() -> void:
	var adj: Dictionary = AffinityCls.adjacency_map(_camps())
	# 中營與四方位皆鄰
	assert_true(adj["camp_center"].has("camp_north"), "中營鄰北")
	assert_true(adj["camp_center"].has("camp_east"), "中營鄰東")
	# 方位環：北鄰東、北鄰西；北不鄰南
	assert_true(adj["camp_north"].has("camp_east"), "北鄰東（環）")
	assert_true(adj["camp_north"].has("camp_west"), "北鄰西（環）")
	assert_false(adj["camp_north"].has("camp_south"), "北不直接鄰南")

func test_affinity_active_when_adjacent() -> void:
	# 媽祖三聖：中+北+東（經中營樞紐連通）→ 啟用
	var deploy: Dictionary = {
		"unit_mazu": "camp_center", "unit_qianliyan": "camp_north", "unit_shunfenger": "camp_east",
	}
	var active: Array = AffinityCls.active_affinities(deploy, _camps())
	var effs: Array = AffinityCls.active_combo_effects(deploy, _camps())
	assert_eq(active.size(), 1, "三聖相鄰合祀 → 1 條緣分啟用")
	assert_true(effs.has("combo_sea_watch"), "啟用媽祖合擊效果")

func test_affinity_inactive_when_member_missing() -> void:
	# 缺順風耳 → 不啟用
	var deploy: Dictionary = {"unit_mazu": "camp_center", "unit_qianliyan": "camp_north"}
	assert_eq(AffinityCls.active_affinities(deploy, _camps()).size(), 0, "成員不全 → 不啟用")

func test_affinity_inactive_when_not_connected() -> void:
	# 城隍土地：北 + 南（無中營、北南不鄰）→ 不連通 → 不啟用
	var deploy: Dictionary = {"unit_chenghuang": "camp_north", "unit_tudigong": "camp_south"}
	assert_eq(AffinityCls.active_affinities(deploy, _camps()).size(), 0, "不相鄰 → 不啟用")
	# 城隍土地：北 + 東（環相鄰）→ 啟用
	var deploy2: Dictionary = {"unit_chenghuang": "camp_north", "unit_tudigong": "camp_east"}
	var effs: Array = AffinityCls.active_combo_effects(deploy2, _camps())
	assert_true(effs.has("combo_earth_ward"), "北東環相鄰 → 城隍土地合祀啟用")
