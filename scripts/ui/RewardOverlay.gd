# Overlay for acceptable rewards
extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

@onready var reward_container: VBoxContainer = $RewardContainer
@onready var continue_button: Button = $ContinueButton
@onready var backdrop: ColorRect = $Background
@onready var panel_fill: ColorRect = $Background2

@onready var map = $%Map

var _offering_table_panel: Panel

# reward values; These are sorted into mutually exclusive groups
# they can be added to via ActionGrantRewards to allow things to affect them
# call populate_rewards() to actually generate RewardButtons UI elements
var reward_data: Dictionary = {
	#0:
		#{
		#"reward_money": 0,
		#"reward_artifact_ids": [],
		#"reward_card_drafts": [],
		#"reward_custom_action_data": [],
		#}
}

func _ready():
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_ended.connect(_on_combat_ended)
	
	Signals.map_location_selected.connect(_on_map_location_selected)
	Signals.chest_opened.connect(_on_chest_opened)
	
	Signals.reward_grant_requested.connect(_on_reward_grant_requested)
	Signals.reward_clear_requested.connect(_on_reward_clear_requested)
	
	continue_button.button_up.connect(_on_continue_button_up)
	COTIW_UI_THEME.apply_primary_button_style(continue_button)
	COTIW_UI_THEME.style_overlay_backdrop(backdrop, panel_fill)
	_build_offering_table_chrome()

static func make_offering_table_panel(panel_size: Vector2 = Vector2(640, 360)) -> Panel:
	var table := Panel.new()
	table.name = "OfferingTablePanel"
	table.size = panel_size
	table.custom_minimum_size = panel_size
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	table.set_meta("reward_language", "offering_table")
	table.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
		Color(0.10, 0.04, 0.03, 0.92),
		COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.82, 0.45)),
		20,
		3,
		0.22
	))

	var cloth := ColorRect.new()
	cloth.name = "OfferingCloth"
	cloth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloth.position = Vector2(18.0, 62.0)
	cloth.size = Vector2(maxf(0.0, panel_size.x - 36.0), maxf(0.0, panel_size.y - 92.0))
	cloth.color = Color(0.46, 0.04, 0.03, 0.54)
	table.add_child(cloth)

	var title := Label.new()
	title.name = "OfferingTitle"
	title.text = "神示供桌"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(20.0, 14.0)
	title.size = Vector2(maxf(0.0, panel_size.x - 40.0), 28.0)
	title.add_theme_font_size_override("font_size", COTIW_UI_THEME.get_typography_size("h2", 28))
	title.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color.GOLD))
	title.add_theme_color_override("font_shadow_color", COTIW_UI_THEME.get_color("text_shadow_strong", Color(0, 0, 0, 0.9)))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 2)
	table.add_child(title)

	var rule := Label.new()
	rule.name = "ChoiceRuleLabel"
	rule.text = "三份神示只能領一份；長按可看細節。"
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule.position = Vector2(20.0, 42.0)
	rule.size = Vector2(maxf(0.0, panel_size.x - 40.0), 22.0)
	rule.add_theme_font_size_override("font_size", COTIW_UI_THEME.get_typography_size("caption", 18))
	rule.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	table.add_child(rule)

	return table

func _build_offering_table_chrome() -> void:
	if _offering_table_panel != null:
		return
	_offering_table_panel = make_offering_table_panel(panel_fill.size if panel_fill != null and panel_fill.size.x > 0 else Vector2(640, 360))
	_offering_table_panel.z_index = -1
	add_child(_offering_table_panel)
	move_child(_offering_table_panel, max(0, reward_container.get_index()))
	_sync_offering_table_layout()
	if not resized.is_connected(_sync_offering_table_layout):
		resized.connect(_sync_offering_table_layout)
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_sync_offering_table_layout):
		viewport.size_changed.connect(_sync_offering_table_layout)

func _sync_offering_table_layout() -> void:
	if _offering_table_panel == null or reward_container == null:
		return
	var margin := Vector2(26.0, 42.0)
	_offering_table_panel.position = reward_container.position - margin
	_offering_table_panel.size = reward_container.size + margin * 2.0
	var cloth := _offering_table_panel.get_node_or_null("OfferingCloth") as ColorRect
	if cloth != null:
		cloth.position = Vector2(18.0, 62.0)
		cloth.size = Vector2(maxf(0.0, _offering_table_panel.size.x - 36.0), maxf(0.0, _offering_table_panel.size.y - 92.0))
	var title := _offering_table_panel.get_node_or_null("OfferingTitle") as Label
	if title != null:
		title.size.x = maxf(0.0, _offering_table_panel.size.x - 40.0)
	var rule := _offering_table_panel.get_node_or_null("ChoiceRuleLabel") as Label
	if rule != null:
		rule.size.x = maxf(0.0, _offering_table_panel.size.x - 40.0)

#region Reward Display
func populate_reward_display() -> void:
	# generate reward buttons from reward data
	clear_reward_display()
	
	for reward_group: int in reward_data.keys():
		var reward_group_data: Dictionary = reward_data[reward_group]
		
		# money reward
		var money_reward_amount: int = reward_group_data.get("reward_money")
		if money_reward_amount > 0:
			var add_money_action_data: Array[Dictionary] = [
					{
					Scripts.ACTION_ADD_MONEY: {"money_amount": money_reward_amount}
					}
				]
			
			var add_money_action: BaseAction = ActionGenerator.create_actions(null, null, [], add_money_action_data, null)[0]
			
			var money_reward_button: BaseRewardButton = Scenes.MONEY_REWARD_BUTTON.instantiate()
			money_reward_button.init(add_money_action, reward_group)
			reward_container.add_child(money_reward_button)
			# make reward group mutually exclusive
			money_reward_button.button_up.connect(_on_reward_group_selected.bind(reward_group))
		
		# card draft rewards
		var card_draft_rewards: Array[Array] = []
		card_draft_rewards.assign(reward_group_data.get("reward_card_drafts", []))
		for card_draft in card_draft_rewards:
			var draft_card_action_data: Array[Dictionary] = [
				{
				Scripts.ACTION_PICK_CARDS: {
					"card_pick_type": ActionBasePickCards.CARD_PICK_TYPES.DRAFT,
					"pick_draft_cards": true,
					"draft_cards": card_draft,
					"action_data": [{Scripts.ACTION_ADD_CARDS_TO_DECK: {}}]
					}
				}
			]
			
			var draft_card_action: BaseAction = ActionGenerator.create_actions(null, null, [], draft_card_action_data, null)[0]
			
			var card_reward_button: BaseRewardButton = Scenes.CARD_REWARD_BUTTON.instantiate()
			card_reward_button.init(draft_card_action, reward_group)
			reward_container.add_child(card_reward_button)
			# make reward group mutually exclusive
			card_reward_button.button_up.connect(_on_reward_group_selected.bind(reward_group))
		
		# artifact rewards
		var artifact_reward_ids: Array[String] = []
		artifact_reward_ids.assign(reward_group_data.get("reward_artifact_ids", []))
		
		for artifact_id in artifact_reward_ids:
			var draft_artifact_action_data: Array[Dictionary] = [
				{
				Scripts.ACTION_ADD_ARTIFACT: {
					"artifact_id": artifact_id
					}
				}
			]
			
			var draft_artifact_action: BaseAction = ActionGenerator.create_actions(null, null, [], draft_artifact_action_data, null)[0]
			
			var artifact_reward_button: BaseRewardButton = Scenes.ARTIFACT_REWARD_BUTTON.instantiate()
			artifact_reward_button.init(draft_artifact_action, reward_group)
			reward_container.add_child(artifact_reward_button)
			# make reward group mutually exclusive
			artifact_reward_button.button_up.connect(_on_reward_group_selected.bind(reward_group))
	
	# clear reward data
	clear_rewards()
	
func clear_reward_display() -> void:
	for child in reward_container.get_children():
		child.queue_free()
		
func _on_reward_group_selected(reward_group: int):
	# rewards groups are mutually exclusive
	for reward_button: BaseRewardButton in reward_container.get_children():
		if reward_button.reward_group != reward_group:
			reward_button.queue_free()
	
#endregion

#region Reward Data
func add_location_rewards() -> void:
	# adds rewards from the location to the end of combat rewards
	var player: Player = Global.get_player()
	var action_data: Array[Dictionary] = [{
	Scripts.ACTION_GRANT_REWARDS: {
		"reward_group": 0,
		"money_amount": Random.get_location_money_reward(),
		"card_drafts": Random.get_location_card_rewards(),
		"artifact_ids": Random.get_location_artifact_rewards(),
		}
	}]
	var grant_reward_action: BaseAction = ActionGenerator.create_actions(player, null, [player], action_data, null)[0]
	grant_reward_action.perform_action()

func add_rewards(reward_group: int, money_amount: int, card_drafts: Array[Array], artifact_ids: Array[String], custom_action_data: Array[Array]):
	# adds rewards which can be populated into the display
	
	# get existing reward data generate new reward data
	var reward_group_data: Dictionary = {}
	if reward_data.has(reward_group):
		reward_group_data = reward_data[reward_group]
	else:
		reward_group_data = {
			"reward_money": 0,
			"reward_card_drafts": [],
			"reward_artifact_ids": [],
			"reward_custom_action_data": [],
			}
	
	# money
	reward_group_data["reward_money"] = reward_group_data["reward_money"] + money_amount
	
	# card drafts
	var reward_card_drafts: Array = reward_group_data["reward_card_drafts"]
	reward_card_drafts.assign(card_drafts)
	reward_group_data["reward_card_drafts"] = reward_card_drafts
	
	# artifacts
	var reward_artifact_ids: Array = reward_group_data["reward_artifact_ids"]
	reward_artifact_ids.assign(artifact_ids)
	reward_group_data["reward_artifact_ids"] = reward_artifact_ids

	# custom actions
	var reward_custom_action_data: Array = reward_group_data["reward_custom_action_data"]
	reward_custom_action_data.assign(custom_action_data)
	reward_group_data["reward_custom_action_data"] = reward_custom_action_data
	
	# negative reward groups will assign to a new group
	var assigned_reward_group: int = reward_group
	if reward_group < 0:
		assigned_reward_group = 1
		while reward_data.has(assigned_reward_group):
			assigned_reward_group += 1
		
	# assign the data to the group	
	reward_data[assigned_reward_group] = reward_group_data

func clear_rewards(reward_group: int = -1) -> void:
	if reward_group < 0:
		reward_data.clear()	# -1 means clear all rewards
	else:
		reward_data.erase(reward_group)	# clear a specific reward group

func _on_reward_grant_requested(reward_group: int, money_amount: int, card_drafts: Array[Array], artifact_ids: Array[String], custom_action_data: Array[Array]):
	add_rewards(reward_group, money_amount, card_drafts, artifact_ids, custom_action_data)

func _on_reward_clear_requested(reward_group: int):
	clear_rewards(reward_group)

#endregion

func _on_combat_started(_event_id: String):
	visible = false
	add_location_rewards()

func _on_combat_ended():
	if not Global.is_end_of_run():
		visible = true
		populate_reward_display()

func _on_chest_opened():
	visible = true
	# rewards will have been populated elsewhere, display them
	populate_reward_display()

func _on_continue_button_up():
	# increment the act and potentially generate a new one
	if Global.is_end_of_act():
		if not Global.is_end_of_run():
			ActionGenerator.generate_next_act()
	
	if not Global.is_end_of_run():
		map.show_map()
	else:
		visible = false
		Signals.run_victory.emit()

func _on_map_location_selected(_location_data: LocationData):
	visible = false
