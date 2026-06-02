extends BaseShopButton

@onready var card: Card = $Card

func _ready():
	card.card_selected.connect(_on_card_selected)
	COTIW_UI_THEME.style_shop_button(self, is_unaffordable)

func init(_action_on_click: BaseAction) -> void:
	super(_action_on_click)
	
	var card_data: CardData = _action_on_click.values.get("card_data", null)
	if card_data != null:
		card.init(card_data, 0, false, true)
		TOUCH_FEEDBACK.install_long_press_detail(card, _make_shop_detail_payload())
		if card.card_button != null:
			TOUCH_FEEDBACK.install_long_press_detail(card.card_button, _make_shop_detail_payload())

func _on_card_selected(_card: Card):
	_on_button_up()
