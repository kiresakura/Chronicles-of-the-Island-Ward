# provides a general interface for a button like object in a shop
# given a PurchaseItemAction which it populates data from
extends Control
class_name BaseShopButton

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

@onready var price_label: Label = $PriceLabel
@onready var panel_background: TextureRect = $PanelBackground if has_node("PanelBackground") else null

var action_on_click: BaseAction = null

func init(_action_on_click: BaseAction) -> void:
	action_on_click = _action_on_click
	
	var price: int = action_on_click.get_action_value("money_amount", 0)
	price_label.text = "購買  金" + str(price)
	_apply_shop_visual_style(price > Global.player_data.player_money)

func _apply_shop_visual_style(is_unaffordable: bool = false) -> void:
	if panel_background != null:
		COTIW_UI_THEME.apply_panel_texture(panel_background, "shop")
		panel_background.modulate = Color.WHITE if not is_unaffordable else Color(0.72, 0.72, 0.72, 0.9)
	price_label.add_theme_color_override("font_color",
		COTIW_UI_THEME.get_color("warning_orange", Color.ORANGE) if is_unaffordable
		else COTIW_UI_THEME.get_color("incense_gold", Color.GOLD))
	price_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	price_label.add_theme_constant_override("shadow_offset_x", 1)
	price_label.add_theme_constant_override("shadow_offset_y", 1)
	price_label.add_theme_font_size_override("font_size", 18)

func _on_button_up():
	if action_on_click != null:
		ActionHandler.add_action(action_on_click)
