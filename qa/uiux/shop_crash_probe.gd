extends Node
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	await get_tree().process_frame
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	for i in 80: await get_tree().process_frame
	Global.start_run("character_tongji", 20260613)
	for i in 30: await get_tree().process_frame
	var shop_data: ShopData = Global.generate_shop_at_player_location()
	var rng = Global.player_data.get_player_rng("rng_shop")
	var cards: Array[CardData] = Random.generate_rarity_weighted_card_draft(rng, ShopData.GENERATED_CARD_COUNT + 3, Random.CARD_DRAFT_TABLE_TYPES.SHOP, false)
	for c in cards:
		print("[PROBE] %s rarity=%d in_table=%s" % [c.object_id, c.card_rarity, str(ShopData.CARD_RARITY_TO_PRICE_RANGE.has(c.card_rarity))])
	get_tree().quit(0)
