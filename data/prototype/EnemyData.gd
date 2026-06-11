extends PrototypeData
class_name EnemyData

@export var enemy_object_id: String = ""	# prototype id for this enemy type
@export var enemy_name: String = ""
@export var enemy_texture_path: String = "external/sprites/enemies/enemy_blue_small.png"

@export var enemy_health: int = 20
@export var enemy_health_max: int = 20

@export var enemy_block: int = 0

@export var enemy_actions_on_death: Array[Dictionary] = []

enum ENEMY_TYPES {STANDARD, MINIBOSS, BOSS}
@export var enemy_type: int = ENEMY_TYPES.STANDARD
@export var enemy_is_minion: bool = false	# minion enemies do not need to be killed for combat to end

### 鎮島錄 — 破煞 / 煞盾系統（資料驅動；max_ward_shield = 0 時等同無煞盾，戰鬥行為不變）
## 設計來源：docs/design/ward_break_system.md。運算見 WardBreakSystem.gd。
@export var enemy_ward_shield: int = 0			# 當前煞盾值
@export var enemy_max_ward_shield: int = 0		# 最大煞盾；0 表示此敵無破煞機制
@export var enemy_weaknesses: Array[String] = []	# 弱點儀法標籤，如 ["fist","fire"]（鍵見 RitualTags.gd）
@export var enemy_break_effect: String = ""		# 破煞後效果鍵：break_stun / break_vulnerable / break_weak / break_stun_vulnerable / break_invoke_window
@export var enemy_broken_turns: int = 1			# 破煞後爆發窗口持續回合數

# Q3-A Boss 覺醒（多階段轉場；數值在敵人 JSON — 鐵律 1）。threshold 0 = 無覺醒機制。
@export var enemy_awaken_threshold: float = 0.0			# 血量比例 ≤ 此值觸發覺醒（如 0.5）
@export var enemy_awaken_status_effects: Dictionary[String, int] = {}	# 覺醒套用 status → 層數
@export var enemy_awaken_restore_ward: bool = false		# 覺醒時煞盾重灌（第二輪破煞循環）
@export var enemy_awaken_title: String = ""				# 覺醒 cut-in 標題（如「百年虎爺・煞變」）
var enemy_is_awakened: bool = false						# runtime 狀態（單次觸發守門）
# ── 執行期破煞狀態（非序列化；由 WardBreakSystem 維護）──
var enemy_is_broken: bool = false
var enemy_broken_turns_remaining: int = 0

### Attack States

var enemy_current_attack_state: String = "initial"	# 0 is initial state which it will iterate from on combat start

const ENEMY_ATTACK_DELAY: float = 0.5

@export var enemy_attack_states: Dictionary[String, Dictionary] = {
	"initial":	# dummy state used for random attacks at start of combat
	{
	"attack_damage": 0,
	"number_of_attacks": 0,
	"block": 0,
	"custom_actions": [],
	"next_attack_weights": 
		{
		"1": 1,
		"2": 1,
		}
	},
	"1":
	{
	"attack_damage": 5,
	"number_of_attacks": 1,
	"block": 5,
	"custom_actions": [],
	"next_attack_weights": 
		{
		"1": 1,
		"2": 1,
		}
	},
	"2":
	{
	"attack_damage": 3,
	"number_of_attacks": 2,
	"block": 7,
	"custom_actions": [],
	"next_attack_weights": 
		{
		"1": 1,
		"2": 1,
		}
	}
}

### Statuses
@export var enemy_initial_status_effects: Dictionary[String, int] = {}	# maps status effect ids to charge count at start of combat

#region Difficulty
@export var enemy_difficulty_to_enemy_modfiers: Dictionary[String, Dictionary] = {
	#"2": {
		### difficulty that increases enemy health
		#"enemy_health": 30,
		#"enemy_health_max": 30,
	#},
	#"3": {
		### difficulty that changes attack patterns
		#"enemy_attack_states": {
			#"initial":
			#{
			#"attack_damage": 0,
			#"number_of_attacks": 0,
			#"block": 0,
			#"custom_actions": [],
			#"next_attack_weights": 
				#{
				#"1": 1,
				#"2": 1,
				#}
			#},
			#"1":
			#{
			#"attack_damage": 8,
			#"number_of_attacks": 1,
			#"block": 8,
			#"custom_actions": [],
			#"next_attack_weights": 
				#{
				#"1": 1,
				#"2": 1,
				#}
			#},
			#"2":
			#{
			#"attack_damage": 4,
			#"number_of_attacks": 2,
			#"block": 7,
			#"custom_actions": [],
			#"next_attack_weights": 
				#{
				#"1": 1,
				#"2": 1,
				#}
			#}
		#}
	#}
}	# maps a difficulty level to a set of properties and their values

func apply_enemy_difficulty_modifiers():
	# apply all modifiers acrosss all difficulties up to the player's difficulty for this enemy
	var player_run_difficulty_level: int = Global.player_data.player_run_difficulty_level
	for difficulty_level: int in (player_run_difficulty_level + 1):
		# get modifiers for each difficulty level and apply them
		var enemy_difficulty_modifiers: Dictionary = enemy_difficulty_to_enemy_modfiers.get(str(difficulty_level), {})
		for property_name: String in enemy_difficulty_modifiers.keys():
			set(property_name, enemy_difficulty_modifiers[property_name])

#endregion

### Attack States
func cycle_next_attack_state():
	# makes the enemy cycle to next attack in attack graph
	var current_attack_state: Dictionary = enemy_attack_states.get(enemy_current_attack_state, {})
	var next_attack_weights: Dictionary[Variant, int] = {}
	next_attack_weights.assign(current_attack_state.get("next_attack_weights", {"1":1}))
	
	var rng_enemy_attack_patterns: RandomNumberGenerator = Global.player_data.get_player_rng("rng_enemy_attack_patterns")
	
	enemy_current_attack_state = Random.get_weighted_selection(rng_enemy_attack_patterns, next_attack_weights)

func get_current_attack_damages() -> Array:
	# return tuple of damage and number of attacks
	var current_attack_state: Dictionary = enemy_attack_states.get(enemy_current_attack_state, {})
	return [
		current_attack_state.get("attack_damage", 1),
		current_attack_state.get("number_of_attacks", 1),
	]

func get_current_attack_block() -> int:
	var current_attack_state: Dictionary = enemy_attack_states.get(enemy_current_attack_state, {})
	return current_attack_state.get("block", 0)

func get_current_attack_custom_actions() -> Array[Dictionary]:
	var current_attack_state: Dictionary = enemy_attack_states.get(enemy_current_attack_state, {})
	var attack_actions: Array[Dictionary] = []
	attack_actions.assign(current_attack_state.get("custom_actions", []))
	return attack_actions
