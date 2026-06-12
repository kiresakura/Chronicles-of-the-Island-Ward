# provides a general interface for a button like object in a shop
# given a PurchaseItemAction which it populates data from
extends Control
class_name BaseShopButton

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const TOUCH_FEEDBACK := preload("res://scripts/ui/theme/TouchFeedback.gd")

@onready var price_label: Label = $PriceLabel
@onready var panel_background: TextureRect = $PanelBackground if has_node("PanelBackground") else null

var action_on_click: BaseAction = null
var is_unaffordable: bool = false

func _ready() -> void:
	TOUCH_FEEDBACK.install_long_press_detail(self, _make_shop_detail_payload())

func init(_action_on_click: BaseAction) -> void:
	action_on_click = _action_on_click
	
	var price: int = action_on_click.get_action_value("money_amount", 0)
	is_unaffordable = price > Global.player_data.player_money
	price_label.text = tr("shop.buy_gold") + str(price)
	_apply_shop_visual_style(is_unaffordable)
	TOUCH_FEEDBACK.install_long_press_detail(self, _make_shop_detail_payload())

func _apply_shop_visual_style(is_unaffordable: bool = false) -> void:
	COTIW_UI_THEME.style_shop_button(self, is_unaffordable)
	TOUCH_FEEDBACK.apply_state(self, TOUCH_FEEDBACK.TouchState.DISABLED if is_unaffordable else TOUCH_FEEDBACK.TouchState.NORMAL)
	set_meta("shop_affordance", "disabled" if is_unaffordable else "normal")

func _make_shop_detail_payload() -> Dictionary:
	var payload := {
		"type": "shop_item",
		"price": action_on_click.get_action_value("money_amount", 0) if action_on_click != null else 0,
		"unaffordable": is_unaffordable,
	}
	if action_on_click != null:
		var action_values: Variant = action_on_click.get("values")
		payload["values"] = action_values if action_values != null else {}
	return payload

func _on_button_up():
	if is_unaffordable:
		TOUCH_FEEDBACK.apply_state(self, TOUCH_FEEDBACK.TouchState.DISABLED)
		return
	if action_on_click != null:
		ActionHandler.add_action(action_on_click)
