# Combat FX overlay — 接通技能特效 sprite 到戰鬥事件
#
# Combat._ready 結尾呼叫 `CombatFxOverlay.apply(self)`；
# additive 加 1 CanvasLayer 用來播 FX；自動連 Signals.combatant_damaged /
# combatant_blocked / status_added 等事件，於對應位置短暫顯示 FX sprite。
# 不動 STR 既有邏輯，鐵律 3 友善。
extends Object
class_name CombatFxOverlay

const FX_DURATION: float = 0.6
const FX_COOLDOWN_SEC: float = 0.16
const FX_MERGE_WINDOW_SEC: float = 0.42

# 事件 → fx texture mapping。用 preload 直接持資源參照：
# (1) 保證 export 一定打包進 APK（字串引用會被 export 掃漏，cards_v3 已踩過坑）
# (2) runtime 直拿，不必 ResourceLoader.exists / load by path
const FX_BY_EVENT: Dictionary = {
	"damage": preload("res://assets/generated/fx_v3/fx_slash_red.png"),
	"block": preload("res://assets/generated/fx_v3/fx_shield.png"),
	"heal": preload("res://assets/generated/fx_v3/fx_heal_green.png"),
	"holy": preload("res://assets/generated/fx_v3/fx_holy_burst.png"),
	"curse": preload("res://assets/generated/fx_v3/fx_curse_black.png"),
	"lightning": preload("res://assets/generated/fx_v3/fx_lightning.png"),
}

static var _layer: CanvasLayer = null
static var _last_fx_time_by_bucket: Dictionary = {}
static var _active_fx_by_bucket: Dictionary = {}


static func apply(host: Control) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "CombatFxOverlay"
	layer.layer = 30  # 在 HUD 之上、scene transition 之下
	host.add_child(layer)
	# CanvasLayer 不會自動吃到 RunScreen 等祖先 Control 的 visible 狀態；
	# FX 層也要跟 host 的實際樹上可見性同步，避免主畫面漏出戰鬥特效。
	var sync_visibility := func() -> void:
		if is_instance_valid(layer) and is_instance_valid(host):
			layer.visible = host.is_visible_in_tree()
	_connect_visibility_sync(host, sync_visibility)
	sync_visibility.call()
	_layer = layer

	# 連 STR signals — 嘗試 autoload Signals
	var signals_node: Node = host.get_node_or_null("/root/Signals")
	if signals_node != null:
		_connect_signals()
	return layer


static func reset_fx_throttle_state() -> void:
	# 測試與切換戰鬥時可清掉限流狀態；不影響任何戰鬥核心數值。
	_last_fx_time_by_bucket.clear()
	_active_fx_by_bucket.clear()


static func get_fx_throttle_snapshot() -> Dictionary:
	return {
		"cooldown_sec": FX_COOLDOWN_SEC,
		"merge_window_sec": FX_MERGE_WINDOW_SEC,
		"last_fx_count": _last_fx_time_by_bucket.size(),
		"active_fx_count": _active_fx_by_bucket.size(),
	}


static func _connect_visibility_sync(host: Control, sync_visibility: Callable) -> void:
	var current: Node = host
	while current != null:
		if current is CanvasItem:
			(current as CanvasItem).visibility_changed.connect(sync_visibility)
		current = current.get_parent()


static func _connect_signals() -> void:
	# 透過 autoload Signals 連事件
	var signals: Node = null
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop == null or not (main_loop is SceneTree):
		return
	var scene_root: Node = (main_loop as SceneTree).root
	for c in scene_root.get_children():
		if c.name == "Signals":
			signals = c
			break
	if signals == null:
		return
	if signals.has_signal("combatant_damaged"):
		if not signals.combatant_damaged.is_connected(_on_damage):
			signals.combatant_damaged.connect(_on_damage)
	if signals.has_signal("combatant_blocked"):
		if not signals.combatant_blocked.is_connected(_on_block):
			signals.combatant_blocked.connect(_on_block)
	if signals.has_signal("combatant_healed"):
		if not signals.combatant_healed.is_connected(_on_heal):
			signals.combatant_healed.connect(_on_heal)


static func _on_damage(target: Node, _amount: int) -> void:
	if not is_instance_valid(_layer):
		return
	_spawn_fx_for_target("damage", target)


static func _on_block(target: Node, _amount: int) -> void:
	if not is_instance_valid(_layer):
		return
	_spawn_fx_for_target("block", target)


static func _on_heal(target: Node, _amount: int) -> void:
	if not is_instance_valid(_layer):
		return
	_spawn_fx_for_target("heal", target)


static func _spawn_fx_for_target(event_kind: String, target: Node) -> bool:
	var now_sec := float(Time.get_ticks_msec()) / 1000.0
	var bucket := _make_fx_bucket_key(event_kind, target)
	if not _should_emit_fx(bucket, now_sec):
		_merge_active_fx(bucket, now_sec)
		return false
	_last_fx_time_by_bucket[bucket] = now_sec
	var fx := _spawn_fx(event_kind, _get_target_pos(target))
	if fx != null:
		fx.set_meta("fx_bucket", bucket)
		fx.set_meta("fx_event_kind", event_kind)
		fx.set_meta("merged_count", 1)
		fx.set_meta("last_merged_at", now_sec)
		_active_fx_by_bucket[bucket] = fx
	return fx != null


static func _make_fx_bucket_key(event_kind: String, target: Node) -> String:
	var target_key := "screen"
	if is_instance_valid(target):
		target_key = str(target.get_instance_id())
	return "%s:%s" % [event_kind, target_key]


static func _should_emit_fx(bucket: String, now_sec: float) -> bool:
	if not _last_fx_time_by_bucket.has(bucket):
		return true
	return now_sec - float(_last_fx_time_by_bucket[bucket]) >= FX_COOLDOWN_SEC


static func _merge_active_fx(bucket: String, now_sec: float) -> void:
	var fx: Variant = _active_fx_by_bucket.get(bucket)
	if not is_instance_valid(fx):
		_active_fx_by_bucket.erase(bucket)
		return
	var fx_node := fx as Node
	var last_merged_at := float(fx_node.get_meta("last_merged_at", now_sec))
	if now_sec - last_merged_at > FX_MERGE_WINDOW_SEC:
		return
	var merged_count := int(fx_node.get_meta("merged_count", 1)) + 1
	fx_node.set_meta("merged_count", merged_count)
	fx_node.set_meta("last_merged_at", now_sec)
	if fx is CanvasItem:
		# 疊段事件只做輕微亮度回饋，不額外生新節點，避免 mobile 戰鬥畫面爆量。
		(fx as CanvasItem).modulate.a = minf(1.0, (fx as CanvasItem).modulate.a + 0.12)


static func _get_target_pos(target: Node) -> Vector2:
	if target is Control:
		return target.global_position + target.size * 0.5
	if target is Node2D:
		return target.global_position
	# fallback：螢幕中央
	var vp: Viewport = (target as Node).get_viewport() if target else null
	if vp:
		return vp.get_visible_rect().size * 0.5
	return Vector2(600, 400)


static func _spawn_fx(event_kind: String, world_pos: Vector2) -> TextureRect:
	if not is_instance_valid(_layer):
		return null
	var fx_texture: Texture2D = FX_BY_EVENT.get(event_kind, FX_BY_EVENT["damage"])
	if fx_texture == null:
		return null

	var fx := TextureRect.new()
	fx.texture = fx_texture
	fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fx.size = Vector2(140, 140)
	fx.position = world_pos - fx.size * 0.5
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.modulate = Color(1, 1, 1, 0.92)
	_layer.add_child(fx)

	# Tween：縮放彈出 + 淡出
	fx.scale = Vector2(0.5, 0.5)
	fx.pivot_offset = fx.size * 0.5
	var t: Tween = fx.create_tween().set_parallel(true)
	t.tween_property(fx, "scale", Vector2(1.4, 1.4), FX_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(fx, "modulate:a", 0.0, FX_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(fx.queue_free)
	return fx
