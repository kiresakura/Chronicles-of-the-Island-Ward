extends BaseShopButton

@onready var button: Button = $Button

func _ready():
	button.button_down.connect(func(): TOUCH_FEEDBACK.apply_state(button, TOUCH_FEEDBACK.TouchState.PRESSED))
	button.button_up.connect(_on_button_up)
	COTIW_UI_THEME.apply_secondary_button_style(button)
	button.flat = false
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.clip_text = true
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", COTIW_UI_THEME.get_typography_size("caption", 18))

func init(_action_on_click: BaseAction) -> void:
	super(_action_on_click)
	
	var consumable_object_id: String = _action_on_click.values.get("consumable_object_id", "")
	var consumable_data: ConsumableData = Global.get_consumable_data(consumable_object_id)
	if consumable_data != null:
		button.text = consumable_data.consumable_name
		button.icon = load(consumable_data.consumable_texture_path)
		TOUCH_FEEDBACK.install(button)
		TOUCH_FEEDBACK.mark_disabled(button, is_unaffordable)
		TOUCH_FEEDBACK.install_long_press_detail(button, _make_shop_detail_payload())
