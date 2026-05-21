## P1 2D 橫向動作原型 — 玩家控制器（乩童）
##
## 移動 / 跳躍 / 近戰攻擊。輸入走 act_left / act_right / act_jump / act_attack
## input action（鍵盤 + 觸控按鈕共用）。攻擊用 AttackArea(Area2D) 命中框。
## P1 用 PixelLab 生的靜態 sprite；P2 會換成 PixelLab 動畫（呼吸/走/攻擊）。
extends CharacterBody2D
class_name ActionPlayer

const SPEED: float = 340.0
const JUMP_VELOCITY: float = -820.0
const GRAVITY: float = 1900.0
const ATTACK_DAMAGE: int = 25
const ATTACK_REACH: float = 130.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/AttackShape

var facing: int = 1            # 1 = 右, -1 = 左
var is_attacking: bool = false
var is_dead: bool = false
var max_health: int = 120
var health: int = 120
var _spawn_pos: Vector2

signal health_changed(hp: int, max_hp: int)


func _ready() -> void:
	attack_shape.disabled = true
	_spawn_pos = global_position
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	# 重力
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# 水平移動（攻擊中鎖腳步）
	var dir: float = Input.get_axis("act_left", "act_right")
	if dir != 0.0 and not is_attacking:
		velocity.x = dir * SPEED
		facing = -1 if dir < 0.0 else 1
		sprite.flip_h = facing < 0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	# 跳躍
	if Input.is_action_just_pressed("act_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 攻擊
	if Input.is_action_just_pressed("act_attack") and not is_attacking:
		_do_attack()

	move_and_slide()


func _do_attack() -> void:
	is_attacking = true
	attack_area.position.x = ATTACK_REACH * facing
	attack_shape.disabled = false
	sprite.modulate = Color(1.25, 1.15, 0.8)   # 出手亮一下

	# 命中判定窗
	await get_tree().create_timer(0.10).timeout
	if is_instance_valid(self):
		for body in attack_area.get_overlapping_bodies():
			if body != self and body.has_method("take_damage"):
				body.take_damage(ATTACK_DAMAGE, facing)

	await get_tree().create_timer(0.16).timeout
	if is_instance_valid(self):
		attack_shape.disabled = true
		sprite.modulate = Color.WHITE
		is_attacking = false


func take_damage(amount: int, from_dir: int = 0) -> void:
	if is_dead:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	sprite.modulate = Color(1, 0.35, 0.35)
	velocity.x = from_dir * 240.0
	velocity.y = -260.0
	if health <= 0:
		_die()
		return
	await get_tree().create_timer(0.16).timeout
	if is_instance_valid(self):
		sprite.modulate = Color.WHITE


## 死亡 → 1.5 秒後在出生點滿血復活（P1 prototype 簡易處理）
func _die() -> void:
	is_dead = true
	is_attacking = false
	attack_shape.disabled = true
	velocity = Vector2.ZERO
	sprite.modulate = Color(0.45, 0.45, 0.5)
	sprite.rotation_degrees = 90.0
	await get_tree().create_timer(1.5).timeout
	if not is_instance_valid(self):
		return
	global_position = _spawn_pos
	velocity = Vector2.ZERO
	sprite.rotation_degrees = 0.0
	sprite.modulate = Color.WHITE
	health = max_health
	health_changed.emit(health, max_health)
	is_dead = false
