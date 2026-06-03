extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

@onready var button_samples: VBoxContainer = $ButtonSamples
@onready var panel_samples: VBoxContainer = $PanelSamples
@onready var badge_samples: HBoxContainer = $BadgeSamples  # scene 內 BadgeSamples 為橫排 HBoxContainer，型別需與 scene 一致
@onready var tooltip_sample: Panel = $TooltipSample
@onready var reward_samples: VBoxContainer = $RewardSamples
@onready var shop_item_samples: VBoxContainer = $ShopItemSamples
@onready var map_node_samples: HBoxContainer = $MapNodeSamples

func _ready() -> void:
	_apply_button_samples()
	_apply_panel_samples()
	_apply_badge_samples()
	_apply_reward_samples()
	_apply_shop_samples()
	_apply_map_node_samples()

func _apply_button_samples() -> void:
	var primary := button_samples.get_node_or_null("PrimaryButton") as Button
	if primary != null:
		primary.text = "Primary / 開始祭典"
		COTIW_UI_THEME.apply_primary_button_style(primary)
	var secondary := button_samples.get_node_or_null("SecondaryButton") as Button
	if secondary != null:
		secondary.text = "Secondary / 返回廟埕"
		COTIW_UI_THEME.apply_secondary_button_style(secondary)

func _apply_panel_samples() -> void:
	var stylebox_panel := panel_samples.get_node_or_null("StyleBoxPanel") as Panel
	if stylebox_panel != null:
		COTIW_UI_THEME.apply_panel_style(stylebox_panel)
	var texture_panel := panel_samples.get_node_or_null("SvgTexturePanel") as TextureRect
	if texture_panel != null:
		COTIW_UI_THEME.apply_panel_texture(texture_panel, "reward")
	COTIW_UI_THEME.apply_tooltip_style(tooltip_sample)

func _apply_badge_samples() -> void:
	for child in badge_samples.get_children():
		if child is Panel:
			COTIW_UI_THEME.style_hud_badge(child, str(child.get_meta("accent_token", "incense_gold")))

func _apply_reward_samples() -> void:
	var common := reward_samples.get_node_or_null("RewardCommon") as Button
	if common != null:
		common.text = "常｜添香卡牌"
		COTIW_UI_THEME.style_reward_button(common, "card", CardData.CARD_RARITIES.COMMON)
	var rare := reward_samples.get_node_or_null("RewardRare") as Button
	if rare != null:
		rare.text = "稀｜神明敕令"
		COTIW_UI_THEME.style_reward_button(rare, "card", CardData.CARD_RARITIES.RARE)

func _apply_shop_samples() -> void:
	for child in shop_item_samples.get_children():
		COTIW_UI_THEME.style_shop_button(child, bool(child.get_meta("unaffordable", false)))

func _apply_map_node_samples() -> void:
	var types := [
		LocationData.LOCATION_TYPES.COMBAT,
		LocationData.LOCATION_TYPES.EVENT,
		LocationData.LOCATION_TYPES.SHOP,
		LocationData.LOCATION_TYPES.BOSS,
	]
	for i in mini(types.size(), map_node_samples.get_child_count()):
		var node := map_node_samples.get_child(i) as TextureButton
		if node == null:
			continue
		var label := node.get_node_or_null("MapLabel") as Label
		var glow := node.get_node_or_null("StateGlow") as ColorRect
		COTIW_UI_THEME.style_map_node(node, int(types[i]), label, glow, i == 1, i == 0, false, i == 2)
		if label != null:
			label.text = COTIW_UI_THEME.get_location_short_label(int(types[i]))
