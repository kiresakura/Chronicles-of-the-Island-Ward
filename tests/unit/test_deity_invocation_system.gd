# 鎮島錄 — 請神運算 + 神明載入單元測試（DeityInvocationSystem）。
# 純函式 + disk 載入器；同步、無場景。對應 docs/design/deity_invocation_system.md。
extends "res://tests/test_case.gd"

func _card(tags: Array[String], charge: int) -> CardData:
	var c: CardData = CardData.new()
	c.card_ritual_tags = tags
	c.card_deity_charge = charge
	return c

# ---------- charge_from_card ----------

func test_charge_from_card_on_tag_hit() -> void:
	# 虎爺 charge_tags [fist]；fist 卡 charge 8 → 8
	assert_eq(DeityInvocationSystem.charge_from_card(["fist"], _card(["fist"], 8)), 8,
		"標籤命中應回 card_deity_charge")

func test_charge_from_card_on_miss() -> void:
	assert_eq(DeityInvocationSystem.charge_from_card(["fist"], _card(["fire"], 8)), 0,
		"標籤未命中應為 0")

# ---------- add_charge / is_ready ----------

func test_add_charge_clamps_to_max_and_zero() -> void:
	assert_eq(DeityInvocationSystem.add_charge(90, 20, 100), 100, "上限夾在 max")
	assert_eq(DeityInvocationSystem.add_charge(0, -5, 100), 0, "下限夾在 0")
	assert_eq(DeityInvocationSystem.add_charge(40, 12, 100), 52, "一般累加")

func test_is_ready() -> void:
	assert_true(DeityInvocationSystem.is_ready(100, 100), "滿槽可降乩")
	assert_false(DeityInvocationSystem.is_ready(99, 100), "未滿不可")
	assert_false(DeityInvocationSystem.is_ready(0, 0), "max 0 不可")

# ---------- 神明載入（disk）----------

func test_load_tiger_god_from_disk() -> void:
	var d: DeityData = DeityInvocationSystem.load_deity("deity_tiger_god")
	assert_not_null(d, "虎爺資料應從 external/data/deities 載入")
	if d == null:
		return
	assert_eq(d.deity_name, "虎爺", "名稱")
	assert_true(d.deity_charge_tags.has("fist"), "charge_tags 應含 fist")
	assert_eq(d.deity_max_charge, 100, "max_charge")
	assert_eq(d.deity_trigger_condition, "on_enemy_broken", "觸發條件")
	assert_eq(d.deity_invocation_effect, "tiger_roar", "降乩效果鍵")

func test_real_punch_charges_tiger_god() -> void:
	var tiger: DeityData = DeityInvocationSystem.load_deity("deity_tiger_god")
	var punch: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
	if tiger == null or punch == null:
		return
	assert_eq(DeityInvocationSystem.charge_from_card(tiger.deity_charge_tags, punch), 8,
		"攻拳（fist, deity_charge 8）應為虎爺累積 8")

func test_load_missing_deity_returns_null() -> void:
	assert_true(DeityInvocationSystem.load_deity("deity_nonexistent") == null,
		"不存在的神明應回 null")
