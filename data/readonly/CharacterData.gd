## read only data for a playable character.
## see PlayerData for mutabale parts.
## NOTE: If you wish to add a new character, you must provide both a CharacterData AND a PlayerData prototype
## and hook them up via CharacterData.character_player_id and PlayerData.player_character_object_id
extends SerializableData
class_name CharacterData

@export var character_name: String = "Character 1"
@export var character_description: String = "Description of Character 1"	# blurb of character on select screen
@export var character_color_id: String = "" # color id ascociated with this character

# textures
@export var character_texture_path: String = ""	# the sprite to use for this character during a run
@export var character_icon_texture_path: String = ""	# the button for selecting this character on run start screen
@export var character_background_texture_path: String = ""	# the background for selecting this character on run start screen
@export var character_text_energy_texture_path: String = "" # the energy icon used when [energy_icon] is used in a card description

# data used for initializing runs
@export var character_player_id: String = ""	# the corresponding player data prototype id to use
@export var character_starting_artifact_ids: Array[String] = []	# added to player on run start
## Determines what kinds of artifacts are available to the player at start of run. Should generally be
## [color_white, character_color_id]
@export var character_starting_artifact_pack_ids: Array[String] = []
@export var character_starting_card_object_ids: Array[String] = [] # cards added to player on run start
# v0.3 五營：本局起始符令牌庫（FC-2b.3-3）。預設空＝回退 formation_fu.json 通用起始（向後相容）。
@export var character_starting_fu_ids: Array[String] = []
@export var character_starting_money: int = 999	# money added to player on start
@export var character_starting_health: int = 50
@export var character_starting_card_draft_card_pack_ids: Array[String] = [] # the cards this character can draft. Usually the same as the character color.

## 鎮島錄 — 預設班底（開局未由 loadout UI 指定時採用）。出戰神明由 RitualLoadout 依 affinity 解析。
@export var character_default_guardian_id: String = ""		# 護壇（GuardianData）
@export var character_default_ritual_tool_id: String = ""	# 法器（RitualToolData）
