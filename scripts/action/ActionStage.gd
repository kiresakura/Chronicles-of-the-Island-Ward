## P1 2D 橫向動作原型 — 關卡控制器
##
## 接玩家血量到 HUD、把觸控按鈕綁到 input action、敵人全清時顯示提示。
extends Node2D

@onready var player: ActionPlayer = $Player
@onready var hp_label: Label = $HUD/PlayerHP
@onready var hint_label: Label = $HUD/HintLabel
@onready var enemy_container: Node2D = $Enemies


func _ready() -> void:
	player.health_changed.connect(_on_player_hp)
	_on_player_hp(player.health, player.max_health)

	# 觸控按鈕 → input action（按下 press、放開 release，tap/hold 通用）
	_bind_touch($HUD/Touch/BtnLeft, "act_left")
	_bind_touch($HUD/Touch/BtnRight, "act_right")
	_bind_touch($HUD/Touch/BtnJump, "act_jump")
	_bind_touch($HUD/Touch/BtnAttack, "act_attack")

	hint_label.text = "← → 移動    跳    攻擊"


func _bind_touch(btn: BaseButton, action: String) -> void:
	btn.button_down.connect(func() -> void: Input.action_press(action))
	btn.button_up.connect(func() -> void: Input.action_release(action))


func _on_player_hp(hp: int, max_hp: int) -> void:
	hp_label.text = "乩童  HP  %d / %d" % [hp, max_hp]


func _process(_delta: float) -> void:
	if is_instance_valid(enemy_container) and enemy_container.get_child_count() == 0:
		hint_label.text = "全部清除！(P1 prototype)"
