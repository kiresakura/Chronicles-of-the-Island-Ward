extends Button
class_name BaseRewardButton

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const TOUCH_FEEDBACK := preload("res://scripts/ui/theme/TouchFeedback.gd")

var action_on_click: BaseAction = null
var reward_group: int = 0
var reward_kind: String = "reward"
var reward_rarity: int = CardData.CARD_RARITIES.COMMON

@onready var panel_background: TextureRect = $PanelBackground if has_node("PanelBackground") else null

func _ready():
	button_up.connect(_on_button_up)
	button_down.connect(func(): TOUCH_FEEDBACK.apply_state(self, TOUCH_FEEDBACK.TouchState.PRESSED))
	_apply_visual_style()
	TOUCH_FEEDBACK.install_long_press_detail(self, _make_reward_detail_payload())

func init(_action_on_click: BaseAction, _reward_group: int) -> void:
	action_on_click = _action_on_click
	reward_group = _reward_group
	_apply_visual_style()
	set_meta("long_press_detail_payload", _make_reward_detail_payload())

func _apply_visual_style() -> void:
	COTIW_UI_THEME.style_reward_button(self, reward_kind, reward_rarity)
	TOUCH_FEEDBACK.mark_disabled(self, disabled)

func _make_reward_detail_payload() -> Dictionary:
	var payload := {
		"type": "reward",
		"label": text,
		"reward_group": reward_group,
	}
	if action_on_click != null:
		payload["action"] = action_on_click.get_script().resource_path if action_on_click.get_script() != null else str(action_on_click)
		var action_values: Variant = action_on_click.get("values")
		payload["values"] = action_values if action_values != null else {}
	return payload

func _on_button_up():
	if action_on_click != null:
		ActionHandler.add_action(action_on_click)
	queue_free()
