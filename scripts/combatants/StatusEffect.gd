# UI element for a status effect
extends TextureRect
class_name StatusEffect

var status_effect_script: BaseStatusEffect

@onready var status_charge_label: Label = $StatusChargeLabel
@onready var status_secondary_charge_label = $StatusSecondaryChargeLabel

# ── 狀態效果 icon registry（取代場景預設 res://icon.svg placeholder）──
# 對應每個 status object_id → icon 檔名（部分重用既有，部分新生成）。
const STATUS_ICON_DIR := "res://assets/generated/icons_v2/status/"
const STATUS_ICON := {
	"status_effect_damage_increase":      "strength.svg",            # 神威
	"status_effect_vulnerable":           "vulnerable.svg",          # 驚嚇
	"status_effect_bomb":                 "bomb.svg",                # 炸彈
	"status_effect_attached_card":        "attached_card.svg",       # 附身卡
	"status_effect_duplicate_attacks":    "duplicate_attacks.svg",   # 重複攻擊
	"status_effect_duplicate_card_plays": "duplicate_card_plays.svg",# 重複出牌
	"status_effect_negate_debuffs":       "negate_debuffs.svg",      # 無視 debuff
	"status_effect_weak":                 "weak.svg",                # 怯戰
	"status_effect_weaken":               "weak.svg",                # 怯戰
	"status_effect_corrosion":            "curse.svg",               # 邪氣
	"status_effect_preserve_block":       "block_bagua.svg",         # 保留護身符
	"status_effect_negate_damage":        "block_bagua.svg",         # 無視傷害
}
# 未對應到具體 icon 時，依 buff/debuff 給通用圖，避免露出 res://icon.svg
const STATUS_FALLBACK_BUFF := "talisman_buff.svg"
const STATUS_FALLBACK_DEBUFF := "curse.svg"

## 依 status 套用主題 icon：資料明確指定 > registry by object_id > buff/debuff 通用
func _apply_status_icon() -> void:
	var data: StatusEffectData = status_effect_script.status_effect_data
	if data == null:
		return
	# 1) 資料明確指定的 texture 優先
	if data.status_effect_texture_path != "" and ResourceLoader.exists(data.status_effect_texture_path):
		texture = load(data.status_effect_texture_path)
		return
	# 2) registry by object_id
	var oid: String = str(data.object_id) if ("object_id" in data) else ""
	var icon_file: String = STATUS_ICON.get(oid, "")
	# 3) buff/debuff 通用 fallback
	if icon_file == "":
		icon_file = STATUS_FALLBACK_DEBUFF if data.status_effect_type == StatusEffectData.STATUS_EFFECT_TYPES.DEBUFF else STATUS_FALLBACK_BUFF
	var p: String = STATUS_ICON_DIR + icon_file
	if ResourceLoader.exists(p):
		texture = load(p)

func update_status_charge_display() -> void:
	visible = status_effect_script.status_effect_data.status_effect_is_visible
	_apply_status_icon()
	
	if status_effect_script.status_charges == 1 and not status_effect_script.status_effect_data.status_effect_stacks:
		status_charge_label.text = ""
	else:
		status_charge_label.text = str(status_effect_script.status_charges)
	
	if status_effect_script.status_secondary_charges == 0:
		status_secondary_charge_label.text = ""
	else:
		status_secondary_charge_label.text = str(status_effect_script.status_secondary_charges)
	
	
	tooltip_text = status_effect_script.status_effect_data.status_effect_name
