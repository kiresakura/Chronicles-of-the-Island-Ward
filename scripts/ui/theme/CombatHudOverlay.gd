# Combat HUD overlay — 真資料綁定 + safe-area 八卦 energy + 神明 affinity badges
#
# Combat._ready 結尾呼叫 `CombatHudOverlay.apply(self)`；additive CanvasLayer(layer=20)
# 浮在 Combat 之上。此檔只疊 UI，不破壞 STR 既有戰鬥節點（鐵律 3 友善）。
extends Object
class_name CombatHudOverlay

const HUD_FOCUS := preload("res://scripts/ui/theme/HudFocus.gd")

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const DEITY_DIR := "res://assets/generated/icons/deities/"
const RING_SIZE := Vector2(128, 128)
const DEITY_BADGE_SIZE := Vector2(210, 54)
const SAFE_MARGIN := Vector2(16, 18)

# 真 affinity 系統尚未完成前的 provider fallback。
# 注意：這是「mock provider 預設值」，不是 UI 內硬碼真資料。正式系統接上後只需讓
# provider 實作 get_combat_hud_state() 或 get_deity_affinity() 即可替換。
const DEFAULT_DEITY_AFFINITY := [
	{"key": "mazu", "label": "媽", "value": 0},
	{"key": "guanyin", "label": "觀", "value": 0},
	{"key": "wangye", "label": "爺", "value": 0},
]

enum Anchor { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }

# 真正的圓形八卦符印底盤。用 _draw() 畫，不再拿方形 ColorRect 假裝 ring。
class BaguaRing extends Control:
	var energy: int = 0
	var energy_max: int = 0
	var ring_color: Color = Color(0.31, 0.78, 0.90, 0.82)
	var gold_color: Color = Color(0.95, 0.82, 0.45, 0.82)
	var bg_color: Color = Color(0.06, 0.03, 0.03, 0.82)

	func _init() -> void:
		name = "BaguaRing"
		size = RING_SIZE
		custom_minimum_size = RING_SIZE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_meta("is_circular_bagua", true)

	func set_energy(value: int, max_value: int) -> void:
		energy = maxi(0, value)
		energy_max = maxi(0, max_value)
		queue_redraw()

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.46
		draw_circle(center, radius, bg_color)
		# 外圈 / 內圈：符印層級，而不是粗糙方框。
		draw_arc(center, radius, 0.0, TAU, 96, gold_color, 3.0, true)
		draw_arc(center, radius - 9.0, 0.0, TAU, 96, Color(ring_color.r, ring_color.g, ring_color.b, 0.52), 2.0, true)

		# 八向卦位短線。避免蓋住中央數字，所以只在外圈繪製。
		for i in 8:
			var a := -PI * 0.5 + float(i) * TAU / 8.0
			var inner := center + Vector2(cos(a), sin(a)) * (radius - 22.0)
			var outer := center + Vector2(cos(a), sin(a)) * (radius - 8.0)
			draw_line(inner, outer, ring_color, 3.0, true)

		# energy 比例弧：玩家第一眼看中心數字，第二眼才看弧線餘量。
		if energy_max > 0:
			var ratio := clampf(float(energy) / float(energy_max), 0.0, 1.0)
			draw_arc(center, radius + 4.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 96, ring_color, 5.0, true)

static func apply(host: Control, provider: Object = null) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "CombatHudOverlay"
	layer.layer = 20
	host.add_child(layer)
	# CanvasLayer 不會自動繼承 Control 祖先層的實際可見狀態；
	# 必須看 is_visible_in_tree()，否則 RunScreen 隱藏時 Combat HUD 仍會漏到主畫面。
	var sync_visibility := func() -> void:
		if is_instance_valid(layer) and is_instance_valid(host):
			layer.visible = host.is_visible_in_tree()
	_connect_visibility_sync(host, sync_visibility)
	sync_visibility.call()

	var state := get_hud_state_from_provider(provider, host)

	var bagua := make_bagua_ring(int(state.get("energy", 0)), int(state.get("energy_max", 0)))
	layer.add_child(bagua)

	var deity_holder := _make_deity_badges(state.get("deity_affinity", DEFAULT_DEITY_AFFINITY))
	layer.add_child(deity_holder)
	HUD_FOCUS.mark_low_freq(deity_holder)	# Q1-A：神祇好感徽章屬層 3 低頻

	var status_strip := _make_status_strip(state)
	layer.add_child(status_strip)

	var layout := func() -> void:
		if not is_instance_valid(host) or not is_instance_valid(layer):
			return
		var safe := get_safe_rect(host)
		bagua.position = get_safe_anchor_position(safe, Anchor.BOTTOM_LEFT, bagua.size, SAFE_MARGIN)
		deity_holder.position = get_safe_anchor_position(safe, Anchor.TOP_RIGHT, deity_holder.size, SAFE_MARGIN)
		# HP/護/預兆 資源 strip：原本錨在 bottom-left 會壓到手牌（Hand x≥168）。
		# 改錨 top-left、置於頂部資源 bar 下方一列，清出整個底部給卡牌（HP 頂部已顯示一次，不重複佔底部）。
		status_strip.position = get_safe_anchor_position(safe, Anchor.TOP_LEFT, status_strip.size, Vector2(SAFE_MARGIN.x, SAFE_MARGIN.y + 88.0))	# 80px 頂列讓位（UIQA W1）

	var refresh := func(_arg1: Variant = null, _arg2: Variant = null, _arg3: Variant = null) -> void:
		if not is_instance_valid(layer):
			return
		var next_state := get_hud_state_from_provider(provider, host)
		_update_bagua_ring(bagua, int(next_state.get("energy", 0)), int(next_state.get("energy_max", 0)))
		_update_deity_badges(deity_holder, next_state.get("deity_affinity", DEFAULT_DEITY_AFFINITY))
		_update_status_strip(status_strip, next_state)
		layout.call()

	_connect_refresh_signals(host, refresh)
	_connect_layout_signals(host, layout)
	layer.tree_exiting.connect(func() -> void:
		_disconnect_visibility_sync(host, sync_visibility)
		_disconnect_refresh_signals(host, refresh)
		_disconnect_layout_signals(host, layout)
	)
	refresh.call()
	return layer

static func _connect_visibility_sync(host: Control, sync_visibility: Callable) -> void:
	var current: Node = host
	while current != null:
		if current is CanvasItem:
			(current as CanvasItem).visibility_changed.connect(sync_visibility)
		current = current.get_parent()

static func _disconnect_visibility_sync(host: Control, sync_visibility: Callable) -> void:
	if not is_instance_valid(host):
		return
	var current: Node = host
	while current != null:
		if current is CanvasItem:
			var visibility_signal: Signal = (current as CanvasItem).visibility_changed
			if visibility_signal.is_connected(sync_visibility):
				visibility_signal.disconnect(sync_visibility)
		current = current.get_parent()

static func get_hud_state_from_provider(provider: Object = null, host: Control = null) -> Dictionary:
	if provider != null and provider.has_method("get_combat_hud_state"):
		var provided: Variant = provider.call("get_combat_hud_state")
		if provided is Dictionary:
			return _normalize_hud_state(provided as Dictionary)

	var state := {
		"energy": 0,
		"energy_max": 0,
		"health": 0,
		"health_max": 0,
		"block": 0,
		"incoming_damage": 0,
		"deity_affinity": DEFAULT_DEITY_AFFINITY.duplicate(true),
	}

	# Global 是 autoload；測試與 headless 場景皆可讀。這裡把舊 HUD 的真 player_data
	# 拉成 overlay state，避免 energy ring 再硬碼。
	if Engine.get_main_loop() is SceneTree and Global != null and Global.player_data != null:
		state["energy"] = int(Global.player_data.player_energy)
		state["energy_max"] = int(Global.player_data.player_energy_max)
		state["health"] = int(Global.player_data.player_health)
		state["health_max"] = int(Global.player_data.player_health_max)
		state["block"] = int(Global.player_data.player_block)

	if host != null:
		state["incoming_damage"] = _read_incoming_damage_from_host(host)
		if provider == null and host.has_method("get_deity_affinity"):
			var affinity: Variant = host.call("get_deity_affinity")
			if affinity is Array:
				state["deity_affinity"] = affinity
	elif provider != null and provider.has_method("get_deity_affinity"):
		var affinity_from_provider: Variant = provider.call("get_deity_affinity")
		if affinity_from_provider is Array:
			state["deity_affinity"] = affinity_from_provider

	return _normalize_hud_state(state)

static func get_safe_rect(host: Control) -> Rect2:
	var viewport_size := Vector2(1200, 700)
	if host != null and host.get_viewport() != null:
		viewport_size = host.get_viewport().get_visible_rect().size
	var fallback := Rect2(Vector2.ZERO, viewport_size)
	if host == null or host.get_tree() == null:
		return fallback
	var responsive := host.get_node_or_null("/root/Responsive")
	if responsive != null:
		var safe: Variant = responsive.get("safe_rect")
		if safe is Rect2 and (safe as Rect2).size.x > 0.0 and (safe as Rect2).size.y > 0.0:
			return safe as Rect2
	return fallback

static func get_safe_anchor_position(safe_rect: Rect2, anchor: Anchor, node_size: Vector2, margin: Vector2 = SAFE_MARGIN) -> Vector2:
	match anchor:
		Anchor.TOP_LEFT:
			return safe_rect.position + margin
		Anchor.TOP_RIGHT:
			return Vector2(safe_rect.position.x + safe_rect.size.x - node_size.x - margin.x, safe_rect.position.y + margin.y)
		Anchor.BOTTOM_LEFT:
			return Vector2(safe_rect.position.x + margin.x, safe_rect.position.y + safe_rect.size.y - node_size.y - margin.y)
		Anchor.BOTTOM_RIGHT:
			return safe_rect.position + safe_rect.size - node_size - margin
		_:
			return safe_rect.position + margin

static func make_bagua_ring(energy: int, energy_max: int = 0) -> Control:
	var holder := BaguaRing.new()
	holder.ring_color = COTIW_UI_THEME.get_color("energy_cyan", Color(0.31, 0.78, 0.9, 1.0))
	holder.gold_color = COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.82, 0.45, 1.0))
	holder.bg_color = Color(0.06, 0.03, 0.03, 0.82)
	holder.set_energy(energy, energy_max)

	var energy_num := Label.new()
	energy_num.name = "EnergyNum"
	energy_num.position = Vector2(0, 24)
	energy_num.size = Vector2(RING_SIZE.x, 60)
	energy_num.text = str(energy)
	energy_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_num.add_theme_font_size_override("font_size", 52)
	energy_num.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("energy_cyan", Color(0.31, 0.78, 0.9)))
	energy_num.add_theme_color_override("font_shadow_color", COTIW_UI_THEME.get_color("text_shadow_strong", Color(0, 0, 0, 0.9)))
	energy_num.add_theme_constant_override("shadow_offset_x", 2)
	energy_num.add_theme_constant_override("shadow_offset_y", 2)
	holder.add_child(energy_num)

	var energy_sub := Label.new()
	energy_sub.name = "EnergySub"
	energy_sub.position = Vector2(0, 80)
	energy_sub.size = Vector2(RING_SIZE.x, 20)
	energy_sub.text = "神力"
	energy_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_sub.add_theme_font_size_override("font_size", 15)
	energy_sub.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("paper_warm", Color(0.96, 0.91, 0.81)))
	holder.add_child(energy_sub)

	var energy_max_label := Label.new()
	energy_max_label.name = "EnergyMax"
	energy_max_label.position = Vector2(0, 98)
	energy_max_label.size = Vector2(RING_SIZE.x, 18)
	energy_max_label.text = "/%d" % energy_max if energy_max > 0 else ""
	energy_max_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_max_label.add_theme_font_size_override("font_size", 12)
	energy_max_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("ash_beige", Color(0.84, 0.77, 0.64)))
	holder.add_child(energy_max_label)

	return holder

static func _normalize_hud_state(raw: Dictionary) -> Dictionary:
	var normalized := raw.duplicate(true)
	for key in ["energy", "energy_max", "health", "health_max", "block", "incoming_damage"]:
		normalized[key] = int(normalized.get(key, 0))
	var affinity: Array = []
	affinity.assign(normalized.get("deity_affinity", DEFAULT_DEITY_AFFINITY))
	normalized["deity_affinity"] = affinity
	return normalized

static func _read_incoming_damage_from_host(host: Control) -> int:
	var player := host.get_node_or_null("Player")
	if player == null:
		return 0
	var label := player.get_node_or_null("Visible/IncomingDamage/IncomingDamageAmount") as Label
	if label == null:
		return 0
	return label.text.to_int()

static func _make_deity_badges(affinity: Array) -> Control:
	var holder := Control.new()
	holder.name = "DeityAffinityBadges"
	holder.size = DEITY_BADGE_SIZE
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_deity_badges(holder, affinity)
	return holder

static func _update_deity_badges(holder: Control, affinity: Array) -> void:
	for child in holder.get_children():
		child.queue_free()

	var x := 0.0
	var max_badges := mini(3, affinity.size())
	for i in max_badges:
		var d: Dictionary = affinity[i]
		var key := str(d.get("key", ""))
		var label := str(d.get("label", "?"))
		var value := int(d.get("value", 0))
		var slot := _make_single_deity_badge(key, label, value)
		slot.position = Vector2(x, 0)
		holder.add_child(slot)
		x += 68.0
	holder.size = Vector2(maxf(1.0, x - 8.0), 54.0)

static func _make_single_deity_badge(key: String, label: String, value: int) -> Control:
	var slot := Control.new()
	slot.name = "DeityBadgeSlot_" + key
	slot.size = Vector2(60, 54)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := Panel.new()
	bg.name = "BadgePanel"
	bg.size = Vector2(60, 54)
	COTIW_UI_THEME.style_hud_badge(bg, "incense_gold")
	bg.modulate = Color(1, 1, 1, 0.82)
	slot.add_child(bg)

	var path := DEITY_DIR + "deity_" + key + ".svg"
	if ResourceLoader.exists(path):
		var icon := TextureRect.new()
		icon.name = "DeityIcon"
		icon.texture = load(path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(3, 2)
		icon.size = Vector2(38, 38)
		icon.modulate = COTIW_UI_THEME.get_color("incense_gold", Color(1, 0.85, 0.45))
		slot.add_child(icon)
	else:
		var fallback := Label.new()
		fallback.name = "DeityFallbackLabel"
		fallback.text = label
		fallback.position = Vector2(3, 2)
		fallback.size = Vector2(38, 38)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", 22)
		fallback.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color.GOLD))
		slot.add_child(fallback)

	var value_label := Label.new()
	value_label.name = "AffinityValue"
	value_label.text = str(value)
	value_label.position = Vector2(38, 8)
	value_label.size = Vector2(20, 36)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 15)
	value_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color.GOLD))
	value_label.add_theme_color_override("font_shadow_color", COTIW_UI_THEME.get_color("text_shadow_strong", Color(0, 0, 0, 0.9)))
	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)
	slot.add_child(value_label)
	return slot

static func _make_status_strip(state: Dictionary) -> Control:
	var strip := Control.new()
	strip.name = "CombatPriorityStrip"
	strip.size = Vector2(270, 44)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.set_meta("hud_priority_layer", "L1")
	strip.set_meta("layout_role", "combat_status_priority_strip")
	strip.set_meta("avoids_anchor", "BaguaRing")
	_update_status_strip(strip, state)
	return strip

static func _update_status_strip(strip: Control, state: Dictionary) -> void:
	for child in strip.get_children():
		child.queue_free()
	var entries := [
		{"key": "health", "name": "HP", "display": TranslationServer.translate("keyword.hp_short"), "value": "%d/%d" % [int(state.get("health", 0)), int(state.get("health_max", 0))], "color": "hp_red", "role": "life_total"},
		{"key": "block", "name": "護", "value": str(int(state.get("block", 0))), "color": "armor_gold", "role": "protection"},
		{"key": "incoming_damage", "name": "預兆", "value": str(int(state.get("incoming_damage", 0))), "color": "warning_orange", "role": "incoming_intent"},
	]
	var x := 0.0
	for e: Dictionary in entries:
		var pill := _make_status_pill(str(e.get("name", "")), str(e.get("value", "")), str(e.get("color", "paper_warm")), str(e.get("key", "")), str(e.get("role", "")), str(e.get("display", "")))
		pill.position = Vector2(x, 0)
		strip.add_child(pill)
		x += pill.size.x + 8.0
	strip.size = Vector2(x, 44.0)

static func _make_status_pill(title: String, value: String, color_token: String, semantic_key: String = "", semantic_role: String = "", display_title: String = "") -> Control:
	var pill := Panel.new()
	pill.name = "PriorityPill_" + title
	pill.size = Vector2(82, 40)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.set_meta("status_key", semantic_key)
	pill.set_meta("status_role", semantic_role)
	pill.set_meta("hud_priority_layer", "L1")
	COTIW_UI_THEME.style_hud_badge(pill, color_token)

	var title_label := Label.new()
	title_label.text = display_title if display_title != "" else title
	title_label.position = Vector2(8, 2)
	title_label.size = Vector2(66, 14)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("ash_beige", Color(0.84, 0.77, 0.64)))
	pill.add_child(title_label)

	var value_label := Label.new()
	value_label.name = "Value"
	value_label.text = value
	value_label.position = Vector2(6, 14)
	value_label.size = Vector2(70, 22)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 17)
	value_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color(color_token, Color.WHITE))
	value_label.add_theme_color_override("font_shadow_color", COTIW_UI_THEME.get_color("text_shadow_strong", Color(0, 0, 0, 0.9)))
	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)
	pill.add_child(value_label)
	return pill

static func _update_bagua_ring(ring: Control, energy: int, energy_max: int) -> void:
	if ring == null:
		return
	if ring.has_method("set_energy"):
		ring.call("set_energy", energy, energy_max)
	var energy_num := ring.get_node_or_null("EnergyNum") as Label
	if energy_num != null:
		energy_num.text = str(energy)
	var energy_max_label := ring.get_node_or_null("EnergyMax") as Label
	if energy_max_label != null:
		energy_max_label.text = "/%d" % energy_max if energy_max > 0 else ""

static func _connect_refresh_signals(host: Control, refresh: Callable) -> void:
	var signals := host.get_node_or_null("/root/Signals")
	if signals == null:
		return
	for signal_name in [
		"energy_added", "card_queue_refunded", "card_played", "card_drawn",
		"player_health_changed", "combatant_blocked", "combatant_block_added",
		"combat_started", "combat_ended", "player_turn_started", "enemy_intent_changed",
	]:
		if signals.has_signal(signal_name):
			var sig: Signal = signals.get(signal_name)
			if not sig.is_connected(refresh):
				sig.connect(refresh)

static func _disconnect_refresh_signals(host: Control, refresh: Callable) -> void:
	if not is_instance_valid(host):
		return
	var signals := host.get_node_or_null("/root/Signals")
	if signals == null:
		return
	for signal_name in [
		"energy_added", "card_queue_refunded", "card_played", "card_drawn",
		"player_health_changed", "combatant_blocked", "combatant_block_added",
		"combat_started", "combat_ended", "player_turn_started", "enemy_intent_changed",
	]:
		if signals.has_signal(signal_name):
			var sig: Signal = signals.get(signal_name)
			if sig.is_connected(refresh):
				sig.disconnect(refresh)

static func _connect_layout_signals(host: Control, layout: Callable) -> void:
	var responsive := host.get_node_or_null("/root/Responsive")
	if responsive != null and responsive.has_signal("changed"):
		var changed_signal: Signal = responsive.get("changed")
		if not changed_signal.is_connected(layout):
			changed_signal.connect(layout)
	var vp := host.get_viewport()
	if vp != null and not vp.size_changed.is_connected(layout):
		vp.size_changed.connect(layout)

static func _disconnect_layout_signals(host: Control, layout: Callable) -> void:
	if not is_instance_valid(host):
		return
	var responsive := host.get_node_or_null("/root/Responsive")
	if responsive != null and responsive.has_signal("changed"):
		var changed_signal: Signal = responsive.get("changed")
		if changed_signal.is_connected(layout):
			changed_signal.disconnect(layout)
	var vp := host.get_viewport()
	if vp != null and vp.size_changed.is_connected(layout):
		vp.size_changed.disconnect(layout)
