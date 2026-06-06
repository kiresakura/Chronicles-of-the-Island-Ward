extends PrototypeData
class_name DeityData

# 鎮島錄 — 神明 / 守護靈資料（請神系統）。
# 對應 PRD §請神系統、docs/design/deity_invocation_system.md。
# 目前為 schema + 資料驅動樣本（external/data/deities/*.json）；
# 戰鬥端 wiring（請神槽累積、降乩釋放）屬 PRD Phase 1D，本類先把欄位定義落地。

@export var deity_name: String = ""
@export var deity_description: String = ""
@export var deity_texture_path: String = ""

## 可為此神明累積請神值的儀法標籤（與卡牌 ritual_tags 交集；鍵見 RitualTags.gd）
@export var deity_charge_tags: Array[String] = []
@export var deity_max_charge: int = 100			# 請神槽滿值
@export var deity_starting_charge: int = 0

## 觸發 / 解放條件鍵（資料驅動，引擎據此判斷請神來源）：
##   on_enemy_broken / on_debuff_applied / on_block_gained / on_self_damage / on_merge_tier3 / manual
@export var deity_trigger_condition: String = "manual"
@export var deity_auto_release: bool = false	# false = 滿槽後由玩家擇時降乩

@export var deity_invocation_effect: String = ""	# 降乩（大招）效果鍵
@export var deity_invocation_description: String = ""
@export var deity_passive_effect: String = ""		# 常駐被動效果鍵
@export var deity_passive_description: String = ""

## 自損換請神（乩童專屬節奏）：每失去 1 點元神累積的請神值
@export var deity_charge_per_self_loss: int = 0
