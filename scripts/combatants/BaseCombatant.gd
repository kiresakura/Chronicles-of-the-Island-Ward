# Base abstract class for shared interface of player and enemies
extends Control
class_name BaseCombatant

const CARD_ART_REGISTRY := preload("res://scripts/ui/theme/CardArtRegistry.gd")
## v3 NBP 戰鬥員立繪是 1024px+ 大圖；Sprite2D 無 scale 會以原生尺寸繪製、
## 爆版蓋住整個戰鬥畫面。set_combatant_sprite() 載圖後把「圖」縮到此高度
## （Sprite2D scale 維持 1，子節點 LayeredHealthBar / SelectionButton 不受影響）。
const COMBATANT_SPRITE_MAX_HEIGHT: int = 200

@onready var block: Sprite2D = $Visible/Block
@onready var block_amount: Label = $Visible/Block/BlockAmount

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var sprite: Sprite2D = $Visible/Sprite
@onready var layered_health_bar: LayeredHealthBar = $Visible/Sprite/LayeredHealthBar

@onready var fade_container = $Visible/FadeContainer
@onready var selection_button: Button = $Visible/Sprite/SelectionButton

@onready var status_container: GridContainer = $Visible/StatusContainer
@onready var custom_ui_container = $Visible/CustomUIContainer

var status_id_to_status_effects: Dictionary = {}	# maps status id to the array of ui element(s) it matches
var custom_ui_object_id_to_custom_ui: Dictionary = {} # maps a custom ui id to the ui component it matches. Duplicate registrations will be ignored

## 程序化精靈動畫 — 待機呼吸 / 出手前刺 / 受擊抖動（squash & stretch）。
## 只寫 sprite 的 position / scale / rotation，與 AnimationPlayer 走的
## offset / modulate 互不衝突。
var _proc_anim: SpriteProcAnim
var _facing: int = 1	# 1 = 朝右（玩家）, -1 = 朝左（敵人）

## PixelLab 戰鬥動畫條（idle/attack/defend/hit/death，4 幀/條）。
## set_combatant_sprite() 收到 texture_path 時若能映射到 actor_id 就載入
## anim sheet 並啟動 idle 迴圈；找不到 anim 則退回靜態貼圖。
const ANIM_DIR: String = "res://assets/generated/pixellab/anim/"
## texture_path basename → actor_id 對應表
const ANIM_LOOKUP: Dictionary = {
	"tongji.png":              "character_tongji",
	"luannu.png":              "character_luannu",
	"enemy_mountain_boar.png": "enemy_mountain_boar",
	"enemy_tree_spirit.png":   "enemy_tree_spirit",
	"enemy_lost_soul.png":     "enemy_wandering_soul",
	"enemy_chair_girl.png":    "enemy_chair_girl",
	"enemy_tiger_god.png":     "enemy_tiger_god",
	"enemy_makanai_v1.png":    "enemy_makanai",
	"enemy_tiger_aunt_v1.png": "enemy_tiger_aunt",
	"enemy_hungry_ghost.png":  "enemy_hungry_ghost",
	"enemy_paper_soldier.png": "enemy_paper_soldier",
}
const ANIM_FRAME_COUNT: int = 4
const ANIM_IDLE_FPS: float = 4.0     # idle 慢循環
const ANIM_ACTION_FPS: float = 8.0   # attack/hit/death 較快
var _anim_frames: Array[Texture2D] = []
var _anim_actor_id: String = ""
var _anim_state: String = ""
var _anim_frame_idx: int = 0
var _anim_time: float = 0.0
var _anim_one_shot: bool = false  # death/attack/hit 播完不循環

func _ready():
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)
	Signals.player_turn_started.connect(_on_player_turn_started)
	Signals.player_turn_ended.connect(_on_player_turn_ended)
	Signals.combatant_damaged.connect(_on_combatant_damaged)
	# 死亡 signals — 跟 AnimationPlayer 的 "death" 平行觸發 anim 條 death 狀態
	Signals.enemy_killed.connect(_on_combatant_killed)
	Signals.player_killed.connect(_on_combatant_killed)

	selection_button.button_up.connect(_on_selection_button_up)

	# 程序化動畫：戰鬥員待機呼吸 + 出手 / 受擊變形
	_facing = -1 if is_in_group("enemies") else 1
	_proc_anim = SpriteProcAnim.new()
	_proc_anim.setup(sprite)

## 每幀推進程序化動畫 — 呼吸持續、出手 / 受擊殘量衰減。
func _process(delta: float) -> void:
	if _proc_anim != null:
		_proc_anim.update(delta, false, false, _facing)
	_advance_anim_frames(delta)

## 推進 anim 條的當前幀（state 機）。one-shot state 結束時自動回 idle，
## 但 death 例外 — 停在最後一幀（屍體姿態）。
func _advance_anim_frames(delta: float) -> void:
	if _anim_frames.is_empty():
		return
	var fps: float = ANIM_ACTION_FPS if _anim_one_shot else ANIM_IDLE_FPS
	_anim_time += delta
	var step: float = 1.0 / fps
	if _anim_time < step:
		return
	_anim_time -= step
	var next_idx: int = _anim_frame_idx + 1
	if next_idx >= _anim_frames.size():
		if _anim_state == "death":
			# 死亡播完 → 停在最後一幀（屍體姿態，等待 AnimationPlayer 的 fade）
			_anim_frames.clear()
			return
		if _anim_one_shot:
			# 動作條播完 → 回 idle 條
			_play_anim_state("idle", false)
			return
		next_idx = 0
	_anim_frame_idx = next_idx
	sprite.texture = _anim_frames[_anim_frame_idx]

## 此戰鬥員受到血量傷害時抖一下（格擋不觸發）。
func _on_combatant_damaged(base_combatant: BaseCombatant, _unblocked_damage: int) -> void:
	if base_combatant != self:
		return
	if _proc_anim != null:
		_proc_anim.trigger_hurt()
	# 如果有 anim 條，播 hit 動作（one-shot，播完自動回 idle）
	if not _anim_actor_id.is_empty():
		_play_anim_state("hit", true)

## 死亡 signal handler — 跟 Player.gd / Enemy.gd 的 animation_player.play("death")
## 同步觸發 anim 條 death 狀態（fallback：anim 條沒 death 條時無動作）。
## one_shot=true 但 death 不回 idle（is_dead 後 _advance_anim_frames 不再切幀）。
func _on_combatant_killed(killed: BaseCombatant) -> void:
	if killed != self:
		return
	if not _anim_actor_id.is_empty():
		_play_anim_state("death", true)

func _on_selection_button_up():
	pass

## 設定戰鬥員 sprite — 解析 texture（res:// 打包資源走 load()，外部圖走 FileLoader），
## 大圖縮到 COMBATANT_SPRITE_MAX_HEIGHT 後指派。Player / Enemy 共用。
## 同名 actor 若有 PixelLab anim 條會優先載入 idle 循環，否則退回靜態貼圖。
func set_combatant_sprite(texture_path: String) -> void:
	# 先試 anim 條（PixelLab 4-幀條）
	if _try_load_anim_from_texture_path(texture_path):
		return
	# fallback 靜態貼圖
	_anim_frames.clear()
	_anim_actor_id = ""
	_anim_state = ""
	var tex: Texture2D = _resolve_combatant_texture(texture_path)
	if tex != null:
		sprite.texture = tex
		if _proc_anim != null:
			_proc_anim.refresh_texture()	# 貼圖換新 → 重算踏地補正半高


## 嘗試由 texture_path basename 映射 actor_id，找到就載入 idle 動畫條。
## 返回是否成功（成功時 sprite 已套第一幀，後續 _process 推進循環）。
func _try_load_anim_from_texture_path(texture_path: String) -> bool:
	if texture_path == null or texture_path.is_empty():
		return false
	var basename: String = texture_path.get_file()
	var actor_id: String = ANIM_LOOKUP.get(basename, "")
	if actor_id == "":
		return false
	_anim_actor_id = actor_id
	return _play_anim_state("idle", false)


## 載入指定 actor + state 的動畫條到 _anim_frames，立即套第一幀。
## one_shot=true：death/attack/hit 播完自動回 idle；one_shot=false：循環。
func _play_anim_state(state: String, one_shot: bool) -> bool:
	if _anim_actor_id.is_empty():
		return false
	var sheet_path: String = ANIM_DIR + _anim_actor_id + "/" + state + ".png"
	if not ResourceLoader.exists(sheet_path):
		return false
	var sheet_tex: Texture2D = load(sheet_path)
	if sheet_tex == null:
		return false
	var frame_w: int = int(sheet_tex.get_width() / ANIM_FRAME_COUNT)
	var frame_h: int = sheet_tex.get_height()
	_anim_frames.clear()
	for i in ANIM_FRAME_COUNT:
		var at: AtlasTexture = AtlasTexture.new()
		at.atlas = sheet_tex
		at.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		_anim_frames.append(at)
	_anim_state = state
	_anim_one_shot = one_shot
	_anim_frame_idx = 0
	_anim_time = 0.0
	sprite.texture = _anim_frames[0]
	# anim 條一律朝右畫，敵人 _facing=-1 時水平鏡像
	sprite.flip_h = (_facing == -1)
	if _proc_anim != null:
		_proc_anim.refresh_texture()
	return true


func _resolve_combatant_texture(texture_path: String) -> Texture2D:
	if texture_path == null or texture_path.is_empty():
		return null
	# 先走 CardArtRegistry（preload 保證打包進 APK）
	var tex: Texture2D = CARD_ART_REGISTRY.get_by_texture_path(texture_path)
	if tex == null:
		# res:// 打包資源直載
		var res_path: String = texture_path
		if not res_path.begins_with("res://"):
			res_path = "res://" + res_path.trim_prefix("/")
		if ResourceLoader.exists(res_path):
			var packed: Resource = load(res_path)
			if packed is Texture2D:
				tex = packed
	if tex == null:
		# fallback：外部 external/ 圖經 FileLoader
		tex = FileLoader.load_texture(texture_path)
	if tex == null:
		return null
	# 大圖縮到合理戰鬥尺寸（避免 1024px 原生繪製爆版）
	if tex.get_height() > COMBATANT_SPRITE_MAX_HEIGHT:
		var img: Image = tex.get_image()
		if img != null:
			if img.is_compressed():
				img.decompress()
			var scale_f: float = float(COMBATANT_SPRITE_MAX_HEIGHT) / float(tex.get_height())
			var new_w: int = maxi(1, int(round(tex.get_width() * scale_f)))
			img.resize(new_w, COMBATANT_SPRITE_MAX_HEIGHT, Image.INTERPOLATE_LANCZOS)
			tex = ImageTexture.create_from_image(img)
	return tex


## 出手動畫 — 改走程序化前刺（拉後 → 衝刺 → 收，含旋轉與拉伸），
## 比舊版 AnimationPlayer offset 平移更有勁。_proc_anim 未就緒時退回舊動畫。
## 同時若有 anim 條會播 attack 動作條（one-shot，播完自動回 idle）。
func play_attack_animation() -> void:
	if _proc_anim != null:
		_proc_anim.trigger_attack()
	else:
		animation_player.play("attack")
	if not _anim_actor_id.is_empty():
		_play_anim_state("attack", true)

#region Block
func set_block(_amount: int) -> void:
	# override
	breakpoint

func get_block() -> int:
	# override
	breakpoint
	return 0

func add_block(_amount: int) -> void:
	# override
	breakpoint

func generate_reset_block_action() -> void:
	# generates a reset block action for this combatant and adds it to the action stack
	var actions_data: Array[Dictionary] = [
		{
		Scripts.ACTION_RESET_BLOCK:  {
			"target_override": BaseAction.TARGET_OVERRIDES.PARENT,
			"time_delay": 0.0
			}
		}
	]
	
	var generated_actions: Array = ActionGenerator.create_actions(self, null, [self], actions_data, null)
	ActionHandler.add_actions(generated_actions)

func reset_block() -> void:
	set_block(0)
#endregion

#region Health
func update_health_bar(as_damage: bool = false) -> void:
	# as_damage will tell the healthbar to update as though the combatant took some kind of damage
	pass

func is_alive() -> bool:
	# override this
	return true

## Does damage to combatant and returns [unblocked damage dealt, overkill damage (if combatant dies)]
func damage(_damage: int, _bypass_block: bool = false) -> Array[int]:
	breakpoint
	return [0,0,0]
#endregion

#region Custom UI
func register_custom_ui(custom_ui_object_id: String) -> void:
	# generates a custom ui element and attaches it to the combatant if it doesn't already exist
	if not custom_ui_object_id_to_custom_ui.has(custom_ui_object_id):
		var custom_ui_data: CustomUIData = Global.get_custom_ui_data(custom_ui_object_id)
		if custom_ui_data != null:
			if custom_ui_data.custom_ui_asset_path != "":
				var custom_ui_asset: PackedScene = load(custom_ui_data.custom_ui_asset_path)
				var custom_ui: BaseCustomUI = custom_ui_asset.instantiate()
				custom_ui_container.add_child(custom_ui)
				custom_ui_object_id_to_custom_ui[custom_ui_object_id] = custom_ui
				custom_ui.init(custom_ui_object_id, self)

func unregister_custom_ui(custom_ui_object_id: String) -> void:
	var custom_ui: BaseCustomUI = custom_ui_object_id_to_custom_ui.get(custom_ui_object_id, null)
	if custom_ui != null:
		custom_ui.queue_free()
		custom_ui_object_id_to_custom_ui.erase(custom_ui_object_id)
		
func unregister_all_custom_ui() -> void:
	for custom_ui_object_id: String in custom_ui_object_id_to_custom_ui.keys().duplicate():
		unregister_custom_ui(custom_ui_object_id)
#endregion

#region Fades

func create_block_text() -> void:
	var text_fade: TextFade = Scenes.TEXT_FADE.instantiate()
	fade_container.add_child(text_fade)
	text_fade.init("Blocked")

func create_damage_text(damage_amount: int) -> void:
	var text_fade: TextFade = Scenes.TEXT_FADE.instantiate()
	fade_container.add_child(text_fade)
	text_fade.init(str(damage_amount))

#endregion

#region Statuses

func add_status_effect_charges(status_effect_object_id: String, charge_amount: int, secondary_charge_amount: int = 0) -> void:
	# general method for adding status effects and charge amounts
	# adds charges and secondary charges to ALL instances of a given status
	# if no status exists, create one and apply charges
	# will remove statuses that become zero'd out
	
	if charge_amount == 0 and secondary_charge_amount == 0:
		return # charge applications of zero have no effect
	
	# get status data
	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	if status_effect_data == null:
		# status effect of given id does not exist
		push_error("Status effect \"", status_effect_object_id,"\" does not exist")
		return
	
	#  get status effect ui elements corresponding to the status
	var status_effects: Array[StatusEffect] = []
	if status_id_to_status_effects.has(status_effect_object_id):
		status_effects = status_id_to_status_effects[status_effect_object_id]
	
	# create a new status if none exists
	if len(status_effects) == 0:
		var _status_effect: StatusEffect = _create_status_effect(status_effect_object_id)
		status_effects = status_id_to_status_effects[status_effect_object_id]
	
	# iterate over all statuses and apply charges
	for status_effect in status_effects.duplicate():
		var status_effect_script: BaseStatusEffect = status_effect.status_effect_script
		
		# apply charges and secondary charges
		status_effect_script.add_status_charges(charge_amount)
		status_effect_script.status_secondary_charges += secondary_charge_amount
		
		# delete the effect if zero charges
		if (status_effect_script.status_charges == 0):
			_remove_status_effect(status_effect)
		else:
			# update ui with charge count
			status_effect.update_status_charge_display()
	
	update_health_bar(false)
	
	Signals.enemy_intent_changed.emit()	# update enemy intent in case statuses affect them

func add_new_status_effect(status_effect_object_id: String, charge_amount: int, secondary_charge_amount: int = 0, custom_values: Dictionary = {}) -> void:
	# attempts to add an entirely new status effect with given charges
	# this is mainly useful for statuses that allow multiples
	# will fail if status does not allow multiples and one already exists
	# see add_status_effect_charges()
	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	if charge_amount == 0:
		return # charges of zero have no effect
	elif status_effect_data.status_effect_can_be_negative and charge_amount < 0:
		return
	
	var status_effect: StatusEffect = _create_status_effect(status_effect_object_id)
	if status_effect != null:
		var status_effect_script: BaseStatusEffect = status_effect.status_effect_script
		
		# apply charges and secondary charges
		status_effect_script.add_status_charges(charge_amount)
		status_effect_script.status_secondary_charges += secondary_charge_amount
		
		# apply unique values beyond charges
		status_effect_script.status_custom_values = custom_values
		
		# delete the effect if zero charges
		if (status_effect_script.status_charges == 0):
			_remove_status_effect(status_effect)
		else:
			# update ui with charge count
			status_effect.update_status_charge_display()
	
	update_health_bar(false)
	
	Signals.enemy_intent_changed.emit()	# update enemy intent in case statuses affect them

func clear_all_status_effects():
	for status_effect_object_id in status_id_to_status_effects.keys().duplicate():
		var status_effects: Array[StatusEffect] = status_id_to_status_effects[status_effect_object_id] 
		for status_effect in status_effects.duplicate():
			_remove_status_effect(status_effect)
	
	status_id_to_status_effects.clear()
	update_health_bar(false)

## Decrements statuses by the decay rate and potentially removes them.
func _decay_status_effect(status_effect_object_id: String) -> void:
	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	if status_effect_data != null:
		# get the first status effect of the given type
		# and use it to determine the decay ratw of all the statuses
		var status_effects: Array[StatusEffect] = []
		if status_id_to_status_effects.has(status_effect_object_id):
			status_effects = status_id_to_status_effects[status_effect_object_id]
		if len(status_effects) > 0:
			var status_effect: StatusEffect = status_effects[0]
			var status_effect_script: BaseStatusEffect = status_effect.status_effect_script
			var decay_amount: int = status_effect_script.get_status_decay_amount()
			
			# generate an instant intercepted action to decay the status
			ActionGenerator.generate_decay_status_effect(self, status_effect_object_id, decay_amount)
			# 
			# add_status_effect_charges(status_effect_object_id, decay_amount, 0)

## DEPRECATED Left in for being potentially useful, but not used anywhere
func _decay_all_status_effects():
	for status_effect_object_id in status_id_to_status_effects.keys().duplicate():
		_decay_status_effect(status_effect_object_id)

func get_status_charges(status_effect_object_id: String) -> int:
	# returns the amount of status effect charges of a given effect
	# zero if no status applied, if multiple statuses returns absolute maximum
	var status_effects: Array = status_id_to_status_effects.get(status_effect_object_id, [])
	var absolute_maximum: int = 0
	for s_e in status_effects:
		var status_effect: StatusEffect = s_e
		if abs(status_effect.status_effect_script.status_charges) > abs(absolute_maximum):
			absolute_maximum = status_effect.status_effect_script.status_charges
	return absolute_maximum

func _remove_status_effect(status_effect: StatusEffect) -> void:
	var status_effect_data: StatusEffectData = status_effect.status_effect_script.status_effect_data
	var status_effect_object_id: String = status_effect_data.object_id
	
	# get status list
	var status_effects: Array[StatusEffect] = status_id_to_status_effects[status_effect_object_id]
	# remove from lists
	status_effects.erase(status_effect)
	
	if len(status_effects) == 0:
		# remove the status keys if no other effects of that type
		status_id_to_status_effects.erase(status_effect_object_id)	
		# unregister action interceptors
		for interceptor_id in status_effect_data.status_effect_interceptor_ids:
			ActionHandler.unregister_action_interceptor(self, interceptor_id)
	
	status_effect.queue_free()

func _create_status_effect(status_effect_object_id: String) -> StatusEffect:
	# creates a status on the combatant and creates bindings and back references for it
	# does not allow duplicate statuses that do not allow multiples
	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	# check if existing status and if duplicates aren't allowed
	var status_exists: bool = len(status_id_to_status_effects.get(status_effect_object_id, [])) > 0
	if (not status_exists) or status_effect_data.status_effect_allows_multiples:
		# create the status
		var status_effect: StatusEffect = Scenes.STATUS_EFFECT.instantiate()
		var status_effect_script_asset: Resource = load(status_effect_data.status_effect_script_path)
		var status_effect_script: BaseStatusEffect = status_effect_script_asset.new()
		
		# set bindings for ui elements
		if status_id_to_status_effects.has(status_effect_object_id):
			status_id_to_status_effects[status_effect_object_id].append(status_effect)
		else:
			var statuses: Array[StatusEffect] = [status_effect] # ensures typed array passed in
			status_id_to_status_effects[status_effect_object_id] = statuses
		
		# initialize status effect
		status_effect.status_effect_script = status_effect_script
		status_container.add_child(status_effect)
		# initialize status effect script
		status_effect_script.init(status_effect_data, self)
		
		# register interceptors when creating first instance of effect
		if not status_exists:
			for interceptor_id in status_effect_data.status_effect_interceptor_ids:
				ActionHandler.register_action_interceptor(self, interceptor_id)
		
		return status_effect
	return null
#endregion

#region Turns/Combat

func _on_combat_started(_event_id: String):
	pass

func _on_combat_ended():
	pass

func _on_player_turn_started():
	pass

func _on_player_turn_ended():
	pass


## Processes and then decays all status effects belonging to a given process type (turn phase)
func perform_status_effect_actions(status_effect_process_time: int = StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.PRE_DRAW_PLAYER_START_TURN):
	var status_effect_ids: Array = _get_status_effects_with_process_time(status_id_to_status_effects.keys(), status_effect_process_time)
	
	# sort the statuses by their process priority
	status_effect_ids.sort_custom(_sort_status_effect_priorities)
	
	for status_effect_object_id in status_effect_ids:
		var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)	
		# perform the status effect
		var status_effects: Array[StatusEffect] = status_id_to_status_effects[status_effect_object_id]
		for status_effect in status_effects:
			status_effect.status_effect_script.perform_status_effect_actions()
		
		# NOTE: Uncommenting this will make status related code more stable by forcing
		# all actions to process before decaying, but
		# doesn't look as good as statuses decaying instantly.
		#if ActionHandler.actions_being_performed:
			#await ActionHandler.actions_ended
		
		# decay all status effects of given type
		_decay_status_effect(status_effect_object_id)


## Helper method. Gets all status effects with a given status_effect_process_time.
func _get_status_effects_with_process_time(status_effect_object_ids: Array, status_effect_process_time: int = StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.PRE_DRAW_PLAYER_START_TURN) -> Array[String]:
	var returned_status_effect_ids: Array[String] = []
	for status_effect_object_id: String in status_effect_object_ids:
		var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
		if status_effect_data == null:
			continue
		if not status_effect_data.status_effect_action_process_times.has(status_effect_process_time):
			continue
		returned_status_effect_ids.append(status_effect_object_id)
		
	return returned_status_effect_ids

## Helper method. Custom sort method for sorting the priorities of a given list of status effects.
## Used to ensure status effects fire in a consistent order.
func _sort_status_effect_priorities(status_effect_object_id_1: String, status_effect_object_id_2: String) -> bool:
	var status_effect_data_1: StatusEffectData = Global.get_status_effect_data(status_effect_object_id_1)
	var status_effect_data_2: StatusEffectData = Global.get_status_effect_data(status_effect_object_id_2)
	if status_effect_data_1.status_effect_priority == status_effect_data_2.status_effect_priority:
		return status_effect_data_1.object_id > status_effect_data_2.object_id
	else:
		return status_effect_data_1.status_effect_priority > status_effect_data_2.status_effect_priority


#endregion
