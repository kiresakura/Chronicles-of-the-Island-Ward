extends BaseRewardButton

func init(_action_on_click: BaseAction, _reward_group: int) -> void:
	reward_kind = "card"
	reward_rarity = _resolve_highest_draft_rarity(_action_on_click)
	super(_action_on_click, _reward_group)
	
	text = tr("reward.card")
	_apply_visual_style()

func _resolve_highest_draft_rarity(action: BaseAction) -> int:
	if action == null:
		return CardData.CARD_RARITIES.COMMON
	var cards: Array = action.values.get("draft_cards", [])
	var highest := CardData.CARD_RARITIES.COMMON
	for card in cards:
		if card is CardData:
			highest = maxi(highest, (card as CardData).card_rarity)
	return highest

func _on_button_up():
	if action_on_click != null:
		# request the player pick a card
		var pick_action: ActionBasePickCards = action_on_click # typecast
		ActionHandler.add_action(pick_action)
		
		# wait until selection made
		await pick_action.action_async_finished
		if len(pick_action.picked_cards) > 0:
			# user picked a card, remove the reward
			queue_free()
	else:
		breakpoint
		queue_free()
