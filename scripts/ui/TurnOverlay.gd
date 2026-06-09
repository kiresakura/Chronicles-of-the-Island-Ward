extends Control

@onready var turn_label: Label = $TurnLabel

func update_turn_label() -> void:
	# called from animation player
	turn_label.text = tr("battle.turn_count") % Global.get_combat_stats().turn_count
