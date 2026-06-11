extends BaseAction

func perform_action():
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
	
	for action_interceptor_processor in action_interceptor_processors:
		var money_amount: int = action_interceptor_processor.get_shadowed_action_values("money_amount", 0)
		if money_amount > 0 and Global.run_fortune_money_gain_mult != 1.0:
			money_amount = maxi(1, roundi(money_amount * Global.run_fortune_money_gain_mult))	# Q3-E 籤詩
		Global.player_data.add_money(money_amount)

func _to_string():
	var money_amount: int = get_action_value("money_amount", 0)
	return "Add Money Action: " + str(money_amount)
