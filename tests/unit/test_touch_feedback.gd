extends "res://tests/test_case.gd"

const TOUCH := preload("res://scripts/ui/theme/TouchFeedback.gd")
const MAP := preload("res://scripts/ui/Map.gd")

func test_touch_feedback_exposes_required_four_states() -> void:
	assert_true(TOUCH.new().has_method("apply_state"), "TouchFeedback 必須提供 apply_state，統一 normal/pressed/selected/disabled")
	assert_eq(TOUCH.TouchState.NORMAL, 0, "normal state 必須存在")
	assert_eq(TOUCH.TouchState.PRESSED, 1, "pressed state 必須存在")
	assert_eq(TOUCH.TouchState.SELECTED, 2, "selected state 必須存在")
	assert_eq(TOUCH.TouchState.DISABLED, 3, "disabled state 必須存在")

func test_touch_feedback_pressed_selected_disabled_are_visibly_distinct() -> void:
	var c := Control.new()
	TOUCH.apply_state(c, TOUCH.TouchState.NORMAL)
	var normal_scale: Vector2 = c.scale
	var normal_modulate: Color = c.self_modulate
	TOUCH.apply_state(c, TOUCH.TouchState.PRESSED)
	assert_true(c.scale.x < normal_scale.x, "pressed 必須有微縮放，手機玩家才感覺按下去了")
	TOUCH.apply_state(c, TOUCH.TouchState.SELECTED)
	assert_true(c.self_modulate != normal_modulate, "selected 必須有亮度/色彩差異")
	assert_true(c.has_meta("touch_feedback_particle_hook"), "selected/pressed 至少要提供粒子或符紙光 hook")
	TOUCH.apply_state(c, TOUCH.TouchState.DISABLED)
	assert_true(c.self_modulate.a < 1.0, "disabled 整張卡/商品必須明顯降權，不只價格變色")
	c.queue_free()

func test_touch_feedback_can_install_long_press_detail_overlay_hook() -> void:
	var b := Button.new()
	TOUCH.install_long_press_detail(b, "detail://reward")
	assert_true(b.has_meta("long_press_detail_payload"), "卡牌/商品/reward 必須有長按 detail overlay payload，不可依賴 hover")
	assert_eq(str(b.get_meta("long_press_detail_payload")), "detail://reward", "長按 payload 應被保存在互動元件上")
	b.queue_free()

func test_map_reachable_flow_line_connects_current_to_reachable_node() -> void:
	var line: Line2D = MAP.make_reachable_flow_line(Vector2(10, 20), Vector2(110, 120))
	assert_not_null(line, "Map 必須能建立可前往節點的連線流光")
	assert_eq(line.name, "ReachableFlowLine", "流光節點名稱需穩定，方便除錯")
	assert_true(line.points.size() >= 3, "可前往流光應有彎折與方向感，不該只是死直線")
	assert_true(line.default_color.a > 0.5, "流光 alpha 必須足夠明顯，不能只是 flash")
	assert_true(line.has_meta("is_reachable_flow"), "流光需標記為 reachable flow")
	assert_eq(str(line.get_meta("route_state")), MAP.ROUTE_STATE_REACHABLE, "reachable 流光必須帶 route_state metadata")
	line.queue_free()

func test_map_path_line_supports_dim_and_visited_story_states() -> void:
	var dim_line: Line2D = MAP.make_map_path_line(Vector2(0, 0), Vector2(0, 120), MAP.ROUTE_STATE_DIM)
	var visited_line: Line2D = MAP.make_map_path_line(Vector2(0, 0), Vector2(120, 120), MAP.ROUTE_STATE_VISITED)
	assert_not_null(dim_line.gradient, "未走暗線必須有陰影漸層，不能是裸色線")
	assert_not_null(visited_line.gradient, "已走路線必須有餘燼漸層")
	assert_true(dim_line.width < visited_line.width, "已走餘燼路線要比未走暗線更有存在感")
	assert_eq(str(visited_line.get_meta("route_state")), MAP.ROUTE_STATE_VISITED, "已走路線 metadata 必須穩定")
	dim_line.queue_free()
	visited_line.queue_free()

func test_touch_feedback_routes_real_ui_sfx_to_sfx_bus() -> void:
	var root := Control.new()
	Engine.get_main_loop().root.add_child(root)
	TOUCH.mount_feedback_layer(root)
	var player: AudioStreamPlayer = TOUCH.play_sfx(root, "ui/touch_selected")
	assert_not_null(player, "TouchFeedback 必須真正建立 AudioStreamPlayer，而不是只塞 metadata")
	assert_eq(player.bus, "SFX", "UI touch 音效必須走 SFX bus")
	assert_true(player.playing, "play_sfx 應立即播放短觸控聲")
	root.queue_free()

func test_touch_feedback_spawns_fu_light_particles_from_hook() -> void:
	var root := Control.new()
	TOUCH.mount_feedback_layer(root)
	var particles: CPUParticles2D = TOUCH.spawn_particle_hook(root, "fu_light_selected", Vector2(88, 66))
	assert_not_null(particles, "TouchFeedback 必須把 particle hook 轉成實際粒子")
	assert_eq(particles.name, "TouchFuLightFX", "符紙光節點名稱需穩定")
	assert_true(particles.emitting, "符紙光粒子必須立即 emitting")
	assert_true(particles.amount >= 18, "selected 符紙光不能寒酸")
	root.queue_free()

func test_reward_rarity_style_has_distinct_hierarchy() -> void:
	var common := TOUCH.get_reward_style("card", CardData.CARD_RARITIES.COMMON)
	var uncommon := TOUCH.get_reward_style("card", CardData.CARD_RARITIES.UNCOMMON)
	var rare := TOUCH.get_reward_style("card", CardData.CARD_RARITIES.RARE)
	var money := TOUCH.get_reward_style("money", 0)
	assert_ne(common["rim_color"], uncommon["rim_color"], "common / uncommon reward 邊框色必須不同")
	assert_ne(uncommon["rim_color"], rare["rim_color"], "uncommon / rare reward 邊框色必須不同")
	assert_true(int(rare["border_width"]) > int(common["border_width"]), "rare reward 必須比 common 更有層級")
	assert_eq(money["glyph"], "金", "money reward 應有穩定 glyph")

func test_detail_overlay_is_styled_exhibit_not_plain_panel() -> void:
	var overlay: Panel = TOUCH.make_detail_overlay({"type": "card", "name": "測試卡", "description": "細節"})
	assert_eq(overlay.name, "TouchDetailOverlay", "detail overlay 名稱需穩定")
	assert_true(overlay.has_theme_stylebox_override("panel"), "detail overlay 必須有面板 stylebox，不可裸 Panel")
	assert_not_null(overlay.get_node_or_null("Title"), "detail overlay 必須有標題層級")
	assert_not_null(overlay.get_node_or_null("FuSeal"), "detail overlay 必須有符紙/印記視覺，而不是純文字")
	assert_true(overlay.size.x >= 460 and overlay.size.y >= 240, "detail overlay 尺寸要足以作為手機詳情展品")
	overlay.queue_free()
