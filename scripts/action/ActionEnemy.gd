## P1 2D 橫向動作原型 — 測試敵人（小鬼）
##
## 簡單 AI：朝玩家緩慢逼近 → 接觸時撞擊傷害。受擊會被擊退 + 閃紅，
## 血量歸零淡出消失。P2 會換成 PixelLab 動畫 + 較完整 AI。
extends CharacterBody2D
class_name ActionEnemy

const GRAVITY: float = 1900.0
const MOVE_SPEED: float = 70.0
const TOUCH_DAMAGE: int = 6
const TOUCH_COOLDOWN: float = 1.5

@onready var sprite: Sprite2D = $Sprite2D

var health: int = 40
var _player: Node2D = null
var _touch_timer: float = 0.0
var _stunned: float = 0.0


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("action_player")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	_touch_timer = maxf(0.0, _touch_timer - delta)
	_stunned = maxf(0.0, _stunned - delta)

	if _stunned <= 0.0 and is_instance_valid(_player):
		var dx: float = _player.global_position.x - global_position.x
		if absf(dx) > 40.0:
			velocity.x = signf(dx) * MOVE_SPEED
			sprite.flip_h = dx < 0.0
		else:
			velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED)
			_try_touch_damage(dx)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)

	move_and_slide()


func _try_touch_damage(dx: float) -> void:
	if _touch_timer > 0.0:
		return
	if is_instance_valid(_player) and _player.has_method("take_damage"):
		_player.take_damage(TOUCH_DAMAGE, signf(dx) * -1.0)
		_touch_timer = TOUCH_COOLDOWN


func take_damage(amount: int, from_dir: int = 0) -> void:
	health -= amount
	_stunned = 0.35
	sprite.modulate = Color(1, 0.3, 0.3)
	velocity.x = from_dir * 360.0
	velocity.y = -240.0
	await get_tree().create_timer(0.14).timeout
	if not is_instance_valid(self):
		return
	sprite.modulate = Color.WHITE
	if health <= 0:
		_die()


func _die() -> void:
	set_physics_process(false)
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	t.tween_property(self, "rotation", deg_to_rad(80.0), 0.35)
	t.chain().tween_callback(queue_free)
