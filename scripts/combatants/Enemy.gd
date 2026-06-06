extends BaseCombatant
class_name Enemy

@onready var enemy_intent: Control = $Visible/Intent
@onready var enemy_intent_amount_text: Label = $Visible/Intent/IntentAmount

@onready var name_label = $Visible/Sprite/NameLabel

var enemy_data: EnemyData
var enemy_slot: int = 0 # the spawn slot the enemy is in

var enemy_intent_attack_damage: int = 0
var enemy_intent_number_of_attacks: int = 0

# 鎮島錄 — 破煞系統：頭頂煞盾指示（僅在有煞盾機制的敵人上建立）
var _ward_label: Label = null

func init(_enemy_data: EnemyData):
	enemy_data = _enemy_data
	
	selection_button.mouse_entered.connect(_on_mouse_entered)
	selection_button.mouse_exited.connect(_on_mouse_exited)
	
	set_combatant_sprite(enemy_data.enemy_texture_path)
	
	# apply initial effects
	for status_effect_object_id in enemy_data.enemy_initial_status_effects.keys():
		var charge_amount: int = enemy_data.enemy_initial_status_effects[status_effect_object_id]
		add_status_effect_charges(status_effect_object_id, charge_amount)
	
	name_label.text = enemy_data.enemy_name
	
	# update_health_bar()
	layered_health_bar.init(enemy_data.enemy_health, enemy_data.enemy_health_max)

	# 鎮島錄 — 破煞系統：初始化煞盾（current=max）、建立頭頂煞盾指示、監聽出牌結算破煞
	WardBreakSystem.init_ward(enemy_data)
	_setup_ward_ui()
	if not Signals.card_played.is_connected(_on_card_played_ward):
		Signals.card_played.connect(_on_card_played_ward)

## Does damage to combatant and returns [unblocked damage dealt, damage to 0 (if enemy dies), overkill damage (if enemy dies)]
## eg 15 damage on 10 remaining health and 3 block will return [12, 10, 2].
## bypass_block = true will do damage directly to health.
func damage(_damage: int, bypass_block: bool = false) -> Array[int]:
	# 鎮島錄 — 破煞爆發窗口：對已破煞敵人傷害 ×1.5（未破煞不進此分支，對既有數值零影響）
	if enemy_data != null and enemy_data.enemy_is_broken:
		_damage = roundi(_damage * WardBreakSystem.damage_multiplier_for(enemy_data))
	var bypassed_damage: int = _damage # raw unblocked damage
	var bypassed_damage_capped: int = 0 # damage done that does not factor in overkill damage
	var overkill_damage: int = 0 # damage done past 0

	if enemy_data.enemy_block > 0 and not bypass_block:
		if enemy_data.enemy_block > _damage:
			# damage less than block
			enemy_data.enemy_block -= _damage
			bypassed_damage = 0
			create_block_text()
			Signals.combatant_blocked.emit(self, _damage)
		else:
			# damage exceeds block
			bypassed_damage = _damage - enemy_data.enemy_block
			enemy_data.enemy_block = 0
			Signals.combatant_block_broken.emit(self)
	
	block.visible = enemy_data.enemy_block > 0
	block_amount.text = str(enemy_data.enemy_block)
	
	if bypassed_damage <= 0:
		return [0,0,0]
	
	create_damage_text(bypassed_damage)
	
	overkill_damage = max(0, bypassed_damage - enemy_data.enemy_health)
	bypassed_damage_capped = bypassed_damage - overkill_damage
	
	if enemy_data.enemy_health > 0:
		enemy_data.enemy_health = max(0, enemy_data.enemy_health - bypassed_damage)
		Signals.combatant_damaged.emit(self, bypassed_damage)
		update_health_bar(true)
		if enemy_data.enemy_health <= 0:
			if not animation_player.is_playing():
				animation_player.play("death")
				remove_from_group("enemies")
				Signals.enemy_killed.emit(self)
	
	return [bypassed_damage, bypassed_damage_capped, overkill_damage]

func set_block(amount: int) -> void:
	enemy_data.enemy_block = amount
	enemy_data.enemy_block = max(0, enemy_data.enemy_block)
	
	block.visible = enemy_data.enemy_block > 0
	block_amount.text = str(enemy_data.enemy_block)

func get_block() -> int:
	return enemy_data.enemy_block

func add_block(amount: int) -> void:
	set_block(enemy_data.enemy_block + amount)
	if amount > 0:
		Signals.combatant_block_added.emit(self)

func update_health_bar(as_damage: bool = false) -> void:
	if as_damage:
		layered_health_bar.apply_damage(enemy_data.enemy_health, enemy_data.enemy_health_max, status_id_to_status_effects)
	else:
		layered_health_bar.update_health_layers(enemy_data.enemy_health, enemy_data.enemy_health_max, status_id_to_status_effects)

func cycle_enemy_intent():
	enemy_data.cycle_next_attack_state()
	update_enemy_intent()
	Signals.enemy_intent_changed.emit()

func update_enemy_intent():
	# displays the enemy's attack
	
	
	# get current intent's attack
	var attack_damages: Array = enemy_data.get_current_attack_damages()
	var attack_damage: int = attack_damages[0]
	var number_of_attacks: int = attack_damages[1]
	
	var player: Player = Global.get_player()
	
	### damage
	# intercept an attack action in preview mode
	var action_data: Array[Dictionary] = [{
			Scripts.ACTION_ATTACK: 
				{
				"damage": attack_damage,
				"target_override": BaseAction.TARGET_OVERRIDES.PLAYER
				}}]
	var generated_action: BaseAction = ActionGenerator.create_actions(self, null, [player], action_data, null)[0]
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = generated_action._intercept_action([player], true)
	
	if len(action_interceptor_processors) == 1:
		var action_interceptor_processor: ActionInterceptorProcessor = action_interceptor_processors[0]
		# get intercepted attack values
		enemy_intent_attack_damage = max(0, action_interceptor_processor.get_shadowed_action_values("damage", 0))

	
	### number of attacks
	# intercept an attack action generator in preview mode
	action_data = [{
		Scripts.ACTION_ATTACK_GENERATOR: 
			{
			"damage": attack_damage,
			"number_of_attacks": number_of_attacks,
			"target_override": BaseAction.TARGET_OVERRIDES.PLAYER
			}}]
	generated_action = ActionGenerator.create_actions(self, null, [player], action_data, null)[0]
	action_interceptor_processors = generated_action._intercept_action([player], true)
	
	if len(action_interceptor_processors) == 1:
		var action_interceptor_processor: ActionInterceptorProcessor = action_interceptor_processors[0]
		# get intercepted attack values
		enemy_intent_number_of_attacks = max(0, action_interceptor_processor.get_shadowed_action_values("number_of_attacks", 0))
	
	### Display intent
	enemy_intent.visible = false
	if enemy_intent_attack_damage * enemy_intent_number_of_attacks > 0:
		enemy_intent.visible = true
		enemy_intent_amount_text.text = str(enemy_intent_attack_damage)
		if enemy_intent_number_of_attacks > 1:
			enemy_intent_amount_text.text += " x " + str(enemy_intent_number_of_attacks)

func is_alive() -> bool:
	return enemy_data.enemy_health > 0

func is_attacking() -> bool:
	return enemy_intent_number_of_attacks > 0

func _on_combat_started(_event_id: String):
	pass

func _on_combat_ended():
	queue_free()

func _on_player_turn_started():
	cycle_enemy_intent()

func _on_player_turn_ended():
	# 破煞爆發窗口在玩家回合結束遞減；歸零 → 煞盾回滿、解除破煞
	if enemy_data != null and enemy_data.enemy_is_broken:
		WardBreakSystem.tick_broken_state(enemy_data)
		_refresh_ward_ui()

func _on_selection_button_up():
	if is_alive():
		Signals.enemy_clicked.emit(self)

func _on_mouse_entered():
	Signals.enemy_hovered.emit(self)
	name_label.visible = true

func _on_mouse_exited():
	Signals.enemy_hovered.emit(null)
	name_label.visible = false

func _on_death_animtation_finished():
	# called from animation player
	Signals.enemy_death_animation_finished.emit(self)

#region 鎮島錄 — 破煞 / 煞盾（Ward Break）戰鬥接線
## 破煞效果鍵 → 套用的 status（驚嚇=status_effect_vulnerable / 怯戰=status_effect_weak）。
## 目前無「暈眩」status，break_stun 暫以驚嚇表示頓挫（見 ward_break_system.md 開放問題 / QUESTIONS Q-R3）。
const BREAK_EFFECT_STATUSES: Dictionary = {
	"break_stun": [["status_effect_vulnerable", 1]],
	"break_vulnerable": [["status_effect_vulnerable", 2]],
	"break_weak": [["status_effect_weak", 2]],
	"break_stun_vulnerable": [["status_effect_vulnerable", 2], ["status_effect_weak", 1]],
	"break_invoke_window": [["status_effect_vulnerable", 2]],
}

## 出牌結束時（ActionCardPlayEnd → Signals.card_played）對「本敵」結算破煞削盾。
## 註：card_played 在卡牌動作（含該卡傷害）結算「之後」才發，故破煞的 ×1.5 獎勵
## 套用在「後續出牌」，不會讓觸發破煞的那張卡自身翻倍——節奏明確、無重複計算。
func _on_card_played_ward(request: CardPlayRequest) -> void:
	if request == null or request.card_data == null:
		return
	if request.selected_target != self:
		return
	if not is_alive() or enemy_data == null or enemy_data.enemy_max_ward_shield <= 0:
		return
	var amount: int = WardBreakSystem.compute_ward_damage(request.card_data, enemy_data)
	if amount > 0:
		if WardBreakSystem.apply_ward_damage(enemy_data, amount):
			_on_ward_broken()
	_refresh_ward_ui()

## 破煞瞬間：套用 break_effect 對應 status + 「破煞！」飄字 + 受擊抖動。
func _on_ward_broken() -> void:
	var effects: Array = BREAK_EFFECT_STATUSES.get(enemy_data.enemy_break_effect, [])
	for pair: Array in effects:
		add_status_effect_charges(str(pair[0]), int(pair[1]))
	if _proc_anim != null:
		_proc_anim.trigger_hurt()
	var text_fade: TextFade = Scenes.TEXT_FADE.instantiate()
	fade_container.add_child(text_fade)
	text_fade.init("破煞！")
	# 連通請神（1D）：破煞為 on_enemy_broken 神明（虎爺）累積請神值
	Signals.enemy_broken.emit(self)

## 建立敵人頭頂煞盾指示（僅有煞盾機制的敵人）。文字版：煞盾值 + 弱點字 + 破煞態。
func _setup_ward_ui() -> void:
	if enemy_data == null or enemy_data.enemy_max_ward_shield <= 0 or _ward_label != null:
		return
	_ward_label = Label.new()
	_ward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ward_label.add_theme_font_size_override("font_size", 13)
	_ward_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_ward_label.add_theme_constant_override("outline_size", 4)
	_ward_label.offset_left = -82.0
	_ward_label.offset_right = 84.0
	_ward_label.offset_top = -98.0
	_ward_label.offset_bottom = -68.0
	sprite.add_child(_ward_label)
	_refresh_ward_ui()

## 重繪煞盾指示：破煞態顯示「破煞！(剩餘窗口)」橘字，否則顯示「煞盾 N/M｜弱 〔弱點字〕」藍字。
func _refresh_ward_ui() -> void:
	if _ward_label == null or enemy_data == null:
		return
	if enemy_data.enemy_is_broken:
		_ward_label.text = "破煞！(%d)" % enemy_data.enemy_broken_turns_remaining
		_ward_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
	else:
		var wk: String = ""
		for t: String in enemy_data.enemy_weaknesses:
			wk += str(RitualTags.DISPLAY.get(t, ""))
		_ward_label.text = "煞盾 %d/%d｜弱 %s" % [enemy_data.enemy_ward_shield, enemy_data.enemy_max_ward_shield, wk]
		_ward_label.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0))
#endregion
