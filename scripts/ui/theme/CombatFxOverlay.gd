# Combat FX overlay — 接通技能特效 sprite 到戰鬥事件
#
# Combat._ready 結尾呼叫 `CombatFxOverlay.apply(self)`；
# additive 加 1 CanvasLayer 用來播 FX；自動連 Signals.combatant_damaged /
# combatant_blocked / status_added 等事件，於對應位置短暫顯示 FX sprite。
# 不動 STR 既有邏輯，鐵律 3 友善。
extends Object
class_name CombatFxOverlay

const FX_DIR := "res://assets/generated/fx_v3/"
const FX_DURATION: float = 0.6

# 簡 sprite 容器：事件 → fx 檔名 mapping
const FX_BY_EVENT: Dictionary = {
	"damage": "fx_slash_red.png",
	"block": "fx_shield.png",
	"heal": "fx_heal_green.png",
	"holy": "fx_holy_burst.png",
	"curse": "fx_curse_black.png",
	"lightning": "fx_lightning.png",
}

static var _layer: CanvasLayer = null


static func apply(host: Control) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "CombatFxOverlay"
	layer.layer = 30  # 在 HUD 之上、scene transition 之下
	host.add_child(layer)
	host.visibility_changed.connect(func(): layer.visible = host.visible)
	layer.visible = host.visible
	_layer = layer

	# 連 STR signals — 嘗試 autoload Signals
	var signals_node: Node = host.get_node_or_null("/root/Signals")
	if signals_node != null:
		_connect_signals()
	return layer


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
	var pos: Vector2 = _get_target_pos(target)
	_spawn_fx("damage", pos)


static func _on_block(target: Node, _amount: int) -> void:
	if not is_instance_valid(_layer):
		return
	_spawn_fx("block", _get_target_pos(target))


static func _on_heal(target: Node, _amount: int) -> void:
	if not is_instance_valid(_layer):
		return
	_spawn_fx("heal", _get_target_pos(target))


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


static func _spawn_fx(event_kind: String, world_pos: Vector2) -> void:
	if not is_instance_valid(_layer):
		return
	var path: String = FX_DIR + FX_BY_EVENT.get(event_kind, "fx_slash_red.png")
	if not ResourceLoader.exists(path):
		return

	var fx := TextureRect.new()
	fx.texture = load(path)
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
