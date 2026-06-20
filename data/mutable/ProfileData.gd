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
# v0.3 敕封（FC-5）：神明/家將跨局位階 deity_id → 0..3（將/帥/神/帝）。預設空＝皆為「將」（向後相容）。
@export var profile_deity_rank: Dictionary[String, int] = {}

## Q4-D 雲端存檔：最後寫入時戳（unix 秒）— 開機對帳 last-writer-wins 依據。
## FileLoader.save_profile() 落地時蓋章。
@export var profile_updated_at_unix: int = 0

## Q4-C IAP：元寶（付費貨幣）。紅線：元寶只買外觀/角色解鎖 —
## 香火與戰力不可販售，授與路由在 IAPManager 以白名單強制。
@export var profile_yuanbao: int = 0
## 已購非消耗性商品 sku（防重複授與 + restore 還原依據）
@export var profile_owned_iap_skus: Array[String] = []
## IAP 授與的解鎖 token（如 character_daoshi / skin_xxx — 遊戲端查詢用）
@export var profile_iap_unlock_ids: Array[String] = []

## 每日上香（留存）：最後上香日（ISO YYYY-MM-DD，OS 本地日）+ 連簽天數。
## 紅線安全：獎勵給香火（thematic 免費 meta 進度）；每 7 日里程碑加碼元寶（外觀幣，
## 免費獲取無妨 — 元寶只能換外觀，不碰戰力）。
@export var profile_last_incense_day: String = ""
@export var profile_incense_streak: int = 0

## 外觀變現（設計稿 捌 外觀四階）：已購外觀 id 清單 + 當前裝備的外觀框階。
## 紅線：外觀只賣視覺、零戰力；以元寶購買（免費獲取的元寶亦只能換外觀）。
@export var profile_owned_cosmetics: Array[String] = []
@export var profile_equipped_frame: String = ""	# ""＝素（預設）；其餘為外觀 id

## c-3 FTUE：首局 90 秒導引是否已完成（完成或略過後置 true，不再觸發）。
@export var profile_ftue_done: bool = false

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

# ───────────────── 每日上香（c-1 留存）─────────────────
## 上香獎勵階梯（7 日循環）：香火逐日遞增，循環末日（第 7 日）里程碑加碼元寶。
## 階梯不寫死於 UI；ProfileData 為唯一真相（鐵律 1）。
const DAILY_INCENSE_LADDER: Array[int] = [20, 25, 30, 35, 40, 50, 80]
const DAILY_YUANBAO_MILESTONE: int = 10

## 今日是否可上香（OS 本地日；同日只 1 次）。
func can_offer_incense_today() -> bool:
	return profile_last_incense_day != _today_date()

## 上香 → 算連簽（昨日續簽 +1、斷簽歸 1）、發獎（香火 + 里程碑元寶）、回報明細。
## 呼叫端負責 FileLoader.save_profile() 落地 + 刷新 UI。
func offer_daily_incense() -> Dictionary:
	var today: String = _today_date()
	return _offer_on(today, _yesterday_of(today))

## 連簽於循環中的日序（1..7；UI 階梯高亮用）。
func incense_cycle_day() -> int:
	if profile_incense_streak <= 0:
		return 1
	return ((profile_incense_streak - 1) % DAILY_INCENSE_LADDER.size()) + 1

## 純邏輯（可單元測試）：給定 today/yesterday 日字串，更新連簽 + 發獎。
func _offer_on(today: String, yesterday: String) -> Dictionary:
	if profile_last_incense_day == today:
		return {"claimed": false, "streak": profile_incense_streak, "incense": 0, "yuanbao": 0}
	if profile_last_incense_day == yesterday and profile_incense_streak > 0:
		profile_incense_streak += 1
	else:
		profile_incense_streak = 1
	profile_last_incense_day = today
	var cycle_idx: int = (profile_incense_streak - 1) % DAILY_INCENSE_LADDER.size()
	var incense: int = DAILY_INCENSE_LADDER[cycle_idx]
	var yuanbao: int = DAILY_YUANBAO_MILESTONE if cycle_idx == DAILY_INCENSE_LADDER.size() - 1 else 0
	add_incense(incense)
	if yuanbao > 0:
		add_yuanbao(yuanbao)
	return {"claimed": true, "streak": profile_incense_streak, "incense": incense, "yuanbao": yuanbao}

func _today_date() -> String:
	var t: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [t["year"], t["month"], t["day"]]

## date_str（YYYY-MM-DD）的前一日；以中午建 unix 退 86400 再轉回，避開 DST/午夜邊界。
static func _yesterday_of(date_str: String) -> String:
	var parts: PackedStringArray = date_str.split("-")
	if parts.size() != 3:
		return ""
	var dict: Dictionary = {"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
		"hour": 12, "minute": 0, "second": 0}
	var unix: int = int(Time.get_unix_time_from_datetime_dict(dict)) - 86400
	var y: Dictionary = Time.get_datetime_dict_from_unix_time(unix)
	return "%04d-%02d-%02d" % [y["year"], y["month"], y["day"]]

# ───────────────── 外觀變現（c-2）─────────────────
func own_cosmetic(cosmetic_id: String) -> void:
	if cosmetic_id != "" and cosmetic_id not in profile_owned_cosmetics:
		profile_owned_cosmetics.append(cosmetic_id)

func has_cosmetic(cosmetic_id: String) -> bool:
	return cosmetic_id in profile_owned_cosmetics

## 以元寶購買外觀（紅線：只扣元寶、只給外觀，永不碰香火/戰力）。餘額足才扣，成功回 true。
func spend_yuanbao(amount: int) -> bool:
	if amount <= 0 or profile_yuanbao < amount:
		return false
	profile_yuanbao -= amount
	return true
