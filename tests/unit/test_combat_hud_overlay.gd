extends "res://tests/test_case.gd"

const COMBAT_HUD := preload("res://scripts/ui/theme/CombatHudOverlay.gd")

class MockHudProvider:
	extends RefCounted
	func get_combat_hud_state() -> Dictionary:
		return {
			"energy": 5,
			"energy_max": 7,
			"health": 42,
			"health_max": 60,
			"block": 9,
			"incoming_damage": 13,
			"deity_affinity": [
				{"key": "mazu", "label": "媽", "value": 88},
				{"key": "guanyin", "label": "觀", "value": 44},
			]
		}

class MutableHudProvider:
	extends RefCounted
	var energy: int = 1
	func get_combat_hud_state() -> Dictionary:
		return {
			"energy": energy,
			"energy_max": 6,
			"health": 42,
			"health_max": 60,
			"block": 0,
			"incoming_damage": 0,
			"deity_affinity": []
		}

func test_combat_hud_status_strip_uses_stable_l1_metadata_and_semantics() -> void:
	var strip: Control = COMBAT_HUD._make_status_strip(MockHudProvider.new().get_combat_hud_state())
	assert_eq(strip.name, "CombatPriorityStrip", "status strip 節點名稱應穩定，方便 Root 拆分後 smoke test 定位")
	assert_eq(strip.get_meta("hud_priority_layer", ""), "L1", "status strip 應明確標示為戰鬥 L1 資訊層")
	assert_eq(strip.get_meta("layout_role", ""), "combat_status_priority_strip", "status strip 應有穩定 layout_role，避免拆 Root 時改壞層級")
	assert_eq(strip.get_meta("avoids_anchor", ""), "BaguaRing", "status strip 必須宣告避開 energy ring anchor，不可遮擋核心神力資訊")
	var hp := strip.get_node_or_null("PriorityPill_HP")
	var block := strip.get_node_or_null("PriorityPill_護")
	var incoming := strip.get_node_or_null("PriorityPill_預兆")
	assert_not_null(hp, "L1 應包含 HP pill")
	assert_not_null(block, "L1 應包含護身/block pill")
	assert_not_null(incoming, "L1 應包含預兆/incoming intent pill，不可叫敵意造成誤解")
	if incoming != null:
		assert_eq(incoming.get_meta("status_key", ""), "incoming_damage", "預兆 pill 應保留 incoming_damage semantic key")
		assert_eq(incoming.get_meta("status_role", ""), "incoming_intent", "預兆 pill 應標示為 incoming intent")
	strip.queue_free()

func test_combat_hud_state_uses_provider_instead_of_hardcoded_values() -> void:
	var state: Dictionary = COMBAT_HUD.get_hud_state_from_provider(MockHudProvider.new())
	assert_eq(state.get("energy"), 5, "Energy ring 必須能從 provider 讀取實際 energy，不可硬碼 3")
	assert_eq(state.get("energy_max"), 7, "Energy max 必須由 provider 提供")
	assert_eq(state.get("block"), 9, "HUD state 應包含玩家 block，供資訊層級使用")
	assert_eq(state.get("incoming_damage"), 13, "HUD state 應包含 incoming intent，供資訊層級使用")
	var affinity: Array = state.get("deity_affinity", [])
	assert_eq(affinity.size(), 2, "神明 affinity 應由 provider 提供，而非固定三筆假數字")
	assert_eq(affinity[0].get("value"), 88, "媽祖 affinity value 應讀 provider")

func test_combat_hud_safe_anchor_uses_safe_rect_not_fixed_canvas_coordinates() -> void:
	var safe := Rect2(Vector2(40, 24), Vector2(1000, 620))
	var energy_pos: Vector2 = COMBAT_HUD.get_safe_anchor_position(safe, COMBAT_HUD.Anchor.BOTTOM_LEFT, Vector2(128, 128), Vector2(16, 18))
	var deity_pos: Vector2 = COMBAT_HUD.get_safe_anchor_position(safe, COMBAT_HUD.Anchor.TOP_RIGHT, Vector2(210, 54), Vector2(16, 18))
	assert_eq(energy_pos, Vector2(56, 498), "Energy ring 應錨在 safe_rect 左下，不可固定 Vector2(20, 460)")
	assert_eq(deity_pos, Vector2(814, 42), "神明 badges 應錨在 safe_rect 右上，避開 HP/Block/Energy 主資訊")

func test_combat_hud_builds_circular_bagua_ring_with_value_label() -> void:
	var ring: Control = COMBAT_HUD.make_bagua_ring(4, 6)
	assert_not_null(ring, "make_bagua_ring 應回傳 Control")
	assert_eq(ring.name, "BaguaRing", "Energy ring 節點名稱應穩定，方便測試與除錯")
	assert_eq(ring.size, Vector2(128, 128), "八卦 ring 應是 128×128 圓形構圖，不是舊方形 120×120")
	assert_true(ring.has_meta("is_circular_bagua"), "八卦 ring 應標記為圓形符印構圖")
	var energy_num := ring.get_node_or_null("EnergyNum") as Label
	assert_not_null(energy_num, "ring 中央必須只有核心 energy 數字 Label")
	if energy_num != null:
		assert_eq(energy_num.text, "4", "EnergyNum 應顯示傳入的實際 energy")
	ring.queue_free()

func test_combat_hud_refreshes_when_energy_signal_emits_with_arguments() -> void:
	var provider := MutableHudProvider.new()
	var host := Control.new()
	Engine.get_main_loop().root.add_child(host)
	var layer: CanvasLayer = COMBAT_HUD.apply(host, provider)
	var ring := layer.get_node_or_null("BaguaRing")
	var energy_num := ring.get_node_or_null("EnergyNum") as Label
	assert_eq(energy_num.text, "1", "初始 energy 應由 provider 決定")
	provider.energy = 4
	Signals.energy_added.emit(3)
	assert_eq(energy_num.text, "4", "energy_added 帶參數 emit 時，HUD refresh 不應因 callback arity 失敗")
	host.queue_free()

func test_combat_hud_layer_tracks_ancestor_visibility() -> void:
	var parent := Control.new()
	var host := Control.new()
	parent.name = "HiddenRunScreen"
	host.name = "Combat"
	parent.visible = false
	Engine.get_main_loop().root.add_child(parent)
	parent.add_child(host)

	var layer: CanvasLayer = COMBAT_HUD.apply(host, MockHudProvider.new())
	assert_false(layer.visible, "RunScreen 類祖先隱藏時，CanvasLayer HUD 不可只因 Combat.visible=true 而漏到主畫面")

	parent.visible = true
	assert_true(layer.visible, "祖先顯示後，HUD layer 應跟著 host.is_visible_in_tree() 顯示")

	parent.visible = false
	assert_false(layer.visible, "祖先再次隱藏時，HUD layer 必須同步關閉")
	parent.queue_free()
