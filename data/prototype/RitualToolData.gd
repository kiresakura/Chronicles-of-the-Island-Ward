extends PrototypeData
class_name RitualToolData

# 鎮島錄 — 法器資料（開局「主祭 / 護壇 / 法器」配置中的法器位）。
# 對應 PRD §主祭／護壇／法器。法器改變破煞、請神或資源規則（類 STS 起始遺物的職業變體）。
# schema + 樣本（external/data/ritual_tools/*.json）；規則 wiring 屬 PRD Phase 1B/1D。

@export var tool_name: String = ""
@export var tool_description: String = ""
@export var tool_texture_path: String = ""

## 法器影響的規則領域鍵：ward_break / deity / economy / draw / merge
@export var tool_rule_domain: String = ""

## 破煞相關修正（rule_domain = ward_break 時生效）
@export var tool_bonus_break_damage: int = 0		# 全卡破煞削減 +N
@export var tool_extra_broken_turns: int = 0		# 破煞窗口 +N 回合

## 請神相關修正（rule_domain = deity 時生效）
@export var tool_bonus_deity_charge: int = 0		# 每張命中卡請神值 +N
@export var tool_affinity_deity_id: String = ""

## 資源 / 抽牌修正
@export var tool_bonus_incense_money: int = 0		# 戰後香火 / 銀兩加成
@export var tool_bonus_draw: int = 0				# 開局多抽 N

## 可選：法器附帶的起始卡或被動效果鍵
@export var tool_granted_card_ids: Array[String] = []
@export var tool_passive_effect: String = ""
