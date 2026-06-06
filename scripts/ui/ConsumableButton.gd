# represents a consumable slot
# can be empty
extends TextureButton
class_name ConsumableButton

var consumable_slot_index: int = 0	# which consumable slot this button corresponds to

signal consumable_slot_button_up(slot_index: int)

func _ready():
	button_up.connect(_on_button_up)

func init(_consumable_slot_index: int):
	consumable_slot_index = _consumable_slot_index
	
	var consumable_data: ConsumableData = Global.get_player_consumable_in_slot_index(consumable_slot_index)
	if consumable_data != null:
		# 有消耗品 → 套用主題 SVG icon，取代場景預設的 res://icon.svg placeholder
		const CONSUMABLE_ICON := "res://assets/generated/icons_v2/icon_consumable.svg"
		if ResourceLoader.exists(CONSUMABLE_ICON):
			texture_normal = load(CONSUMABLE_ICON)
		self_modulate.a = 1.0
		# set tooltip
		tooltip_text = consumable_data.consumable_name
		if consumable_data.consumable_description != "":
			tooltip_text += "\n" + consumable_data.consumable_description
	else:
		# empty consumable slot
		self_modulate.a = 0.3
		tooltip_text = ""
	


func _on_button_up():
	consumable_slot_button_up.emit(consumable_slot_index)
