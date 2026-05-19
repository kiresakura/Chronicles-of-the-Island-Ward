extends BaseShopButton

@onready var card: Card = $Card

func _ready():
	card.card_selected.connect(_on_card_selected)
	price_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color.GOLD))
	price_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	price_label.add_theme_constant_override("shadow_offset_x", 1)
	price_label.add_theme_constant_override("shadow_offset_y", 1)
	price_label.add_theme_font_size_override("font_size", 18)
	if panel_background != null:
		COTIW_UI_THEME.apply_panel_texture(panel_background, "shop")

func init(_action_on_click: BaseAction) -> void:
	super(_action_on_click)
	
	var card_data: CardData = _action_on_click.values.get("card_data", null)
	if card_data != null:
		card.init(card_data, 0, false, true)

func _on_card_selected(_card: Card):
	_on_button_up()
