extends PrototypeData
class_name GuardianData

# 鎮島錄 — 護壇資料（開局「主祭 / 護壇 / 法器」配置中的護壇位）。
# 對應 PRD §主祭／護壇／法器、docs/design/ritual_combat_system.md。
# 護壇提供被動與少量支援卡池，與主祭（main_ritualist，沿用 CharacterData）搭配。
# schema + 樣本（external/data/guardians/*.json）；隊伍 wiring 屬 PRD Phase 2。

@export var guardian_name: String = ""
@export var guardian_description: String = ""
@export var guardian_texture_path: String = ""

## 連結到既有角色原型（可選）：護壇可由某 CharacterData 兼任
@export var guardian_character_id: String = ""

@export var guardian_passive_effect: String = ""		# 常駐被動效果鍵
@export var guardian_passive_description: String = ""

## 護壇額外注入主祭牌庫的支援卡（object_id）
@export var guardian_support_card_ids: Array[String] = []

## 護壇與哪位神明特別契合（請神值加成的鉤點，可選）
@export var guardian_affinity_deity_id: String = ""
