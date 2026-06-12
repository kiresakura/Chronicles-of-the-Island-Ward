## Maintains data for the player
extends SerializableData
class_name ProfileData

@export var profile_name: String = ""

@export var profile_total_wins: int = 0
@export var profile_total_losses: int = 0
@export var profile_total_runs: int = 0
@export var profile_character_object_id_to_wins: Dictionary[String, int] = {}
@export var profile_character_object_id_to_losses: Dictionary[String, int] = {}

@export var profile_character_object_id_to_highest_difficulty: Dictionary[String, int] = {}

## 看板娘：玩家選定的展示角色（在 MainMenu 中央 idle 動畫顯示）。
## 預設 character_tongji（首次啟動時）。
@export var profile_mascot_character_id: String = "character_tongji"

## 鎮島錄 2D — 修廟 meta：香火餘額 + 各建築等級（永久進度，隨 profile 序列化存檔）
@export var profile_incense_balance: int = 0
@export var profile_building_id_to_level: Dictionary[String, int] = {}

## Q4-C IAP：元寶（付費貨幣）。紅線：元寶只買外觀/角色解鎖 —
## 香火與戰力不可販售，授與路由在 IAPManager 以白名單強制。
@export var profile_yuanbao: int = 0
## 已購非消耗性商品 sku（防重複授與 + restore 還原依據）
@export var profile_owned_iap_skus: Array[String] = []
## IAP 授與的解鎖 token（如 character_daoshi / skin_xxx — 遊戲端查詢用）
@export var profile_iap_unlock_ids: Array[String] = []

## 香火加成（戰後結算 / 土地公被動等）。
func add_incense(amount: int) -> void:
	profile_incense_balance = maxi(0, profile_incense_balance + amount)

func add_yuanbao(amount: int) -> void:
	profile_yuanbao = maxi(0, profile_yuanbao + amount)

func has_iap_unlock(unlock_id: String) -> bool:
	return unlock_id in profile_iap_unlock_ids

func grant_iap_unlock(unlock_id: String) -> void:
	if unlock_id != "" and unlock_id not in profile_iap_unlock_ids:
		profile_iap_unlock_ids.append(unlock_id)

func get_building_level(building_id: String) -> int:
	return profile_building_id_to_level.get(building_id, 0)

func win_run(character_object_id: String) -> void:
	profile_total_wins += 1
	var character_wins: int = profile_character_object_id_to_wins.get(character_object_id, 0)
	character_wins += 1
	profile_character_object_id_to_wins[character_object_id] = character_wins

func lose_run(character_object_id: String) -> void:
	profile_total_losses += 1
	var character_losses: int = profile_character_object_id_to_losses.get(character_object_id, 0)
	character_losses += 1
	profile_character_object_id_to_losses[character_object_id] = character_losses
