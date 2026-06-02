extends BaseRewardButton

func init(_action_on_click: BaseAction, _reward_group: int) -> void:
	reward_kind = "money"
	reward_rarity = 0
	super(_action_on_click, _reward_group)
	
	text = "Money %s" % _action_on_click.values.get("money_amount", 0)
	_apply_visual_style()
