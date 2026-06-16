# 鎮島錄 v0.3 — 五營/單位/五行 schema 驗證（formation_progression_v0.3 §4 回歸防線）。
# 新資料一旦欄位不合法即紅燈；文案超長即 fail（源頭杜絕 UI 截斷，呼應新一局批判）。
extends "res://tests/test_case.gd"

const FiveElementsCls := preload("res://scripts/systems/ritual/FiveElements.gd")
const VALID_ELEMENTS: Array[String] = ["wood", "fire", "earth", "metal", "water"]
const VALID_DIRECTIONS: Array[String] = ["east", "south", "west", "north", "center"]
const MAX_DESC_LEN: int = 60
const VALID_UNIT_KINDS: Array[String] = ["deity", "general", "vanguard"]

func test_formation_camp_schema_valid() -> void:
	var camps: Dictionary = Global._id_to_formation_camp_data
	assert_eq(camps.size(), 5, "五營必須恰 5 筆（東南西北中）")
	var seen_dir: Dictionary = {}
	for cid: String in camps:
		var c: FormationCampData = camps[cid]
		assert_true(VALID_DIRECTIONS.has(c.camp_direction), "%s 方位非法：%s" % [cid, c.camp_direction])
		assert_true(VALID_ELEMENTS.has(c.camp_element), "%s 五行非法：%s" % [cid, c.camp_element])
		assert_false(seen_dir.has(c.camp_direction), "方位重複：%s" % c.camp_direction)
		seen_dir[c.camp_direction] = true
		assert_ne(c.camp_unlock_feature, "", "%s 缺 camp_unlock_feature（漸進揭露需要）" % cid)
		assert_ne(c.camp_name, "", "%s 缺 camp_name" % cid)
	# 五方位齊全
	for d: String in VALID_DIRECTIONS:
		assert_true(seen_dir.has(d), "缺方位：%s" % d)
	# 唯一中營（lane 空 = 調度中樞）
	var center_count: int = 0
	for cid: String in camps:
		if camps[cid].camp_lane == "":
			center_count += 1
	assert_eq(center_count, 1, "恰一個中營（lane 空）")

func test_formation_unit_schema_valid() -> void:
	var units: Dictionary = Global._id_to_formation_unit_data
	assert_true(units.size() >= 5, "可佈陣單位至少 5（五營主將）")
	for uid: String in units:
		var u: FormationUnitData = units[uid]
		assert_true(VALID_ELEMENTS.has(u.unit_element), "%s 五行非法：%s" % [uid, u.unit_element])
		assert_true(VALID_UNIT_KINDS.has(u.unit_kind), "%s 單位類別非法：%s" % [uid, u.unit_kind])
		assert_true(u.unit_power >= 0, "%s 削煞值不可為負" % uid)
		# unit_source_id 若非空，必須是既有 deity/guardian（複用降乩管線）
		if u.unit_source_id != "":
			var in_deity: bool = Global._id_to_deity_data.has(u.unit_source_id) if "_id_to_deity_data" in Global else false
			assert_true(in_deity or FileAccess.file_exists("res://external/data/deities/%s.json" % u.unit_source_id)
				or FileAccess.file_exists("res://external/data/guardians/%s.json" % u.unit_source_id),
				"%s unit_source_id 不存在：%s" % [uid, u.unit_source_id])

func test_formation_descriptions_within_length() -> void:
	for cid: String in Global._id_to_formation_camp_data:
		var d: String = Global._id_to_formation_camp_data[cid].camp_description
		assert_true(d.length() <= MAX_DESC_LEN, "%s 描述 %d 字超上限 %d（會截斷）" % [cid, d.length(), MAX_DESC_LEN])
	for uid: String in Global._id_to_formation_unit_data:
		var d: String = Global._id_to_formation_unit_data[uid].unit_description
		assert_true(d.length() <= MAX_DESC_LEN, "%s 描述 %d 字超上限 %d" % [uid, d.length(), MAX_DESC_LEN])

# ---- 五行相生相剋系統正確性 ----

func test_five_elements_generating_cycle() -> void:
	# 相生環：木→火→土→金→水→木，每元素恰生一、被一生
	var gen_targets: Dictionary = {}
	for el: String in FiveElementsCls.ELEMENTS:
		var t: String = FiveElementsCls.GENERATES[el]
		assert_true(VALID_ELEMENTS.has(t), "%s 生的目標非法" % el)
		assert_false(gen_targets.has(t), "相生非單射（%s 被多元素生）" % t)
		gen_targets[t] = true
	assert_eq(gen_targets.size(), 5, "相生須形成 5 元素環")

func test_five_elements_overcoming_cycle() -> void:
	# 相剋環：木→土→水→火→金→木
	var ov_targets: Dictionary = {}
	for el: String in FiveElementsCls.ELEMENTS:
		var t: String = FiveElementsCls.OVERCOMES[el]
		assert_true(VALID_ELEMENTS.has(t), "%s 剋的目標非法" % el)
		assert_ne(t, el, "%s 不能剋自己" % el)
		assert_ne(FiveElementsCls.GENERATES[el], t, "%s 不能同時生又剋同一元素" % el)
		ov_targets[t] = true
	assert_eq(ov_targets.size(), 5, "相剋須形成 5 元素環")

func test_five_elements_relationship_semantics() -> void:
	assert_eq(FiveElementsCls.relationship("fire", "fire"), "same", "同行=same")
	assert_eq(FiveElementsCls.relationship("fire", "wood"), "generated_by", "木生火 → 火在木營=受扶持")
	assert_eq(FiveElementsCls.relationship("wood", "earth"), "overcomes", "木剋土 → 木在土營=制")
	assert_eq(FiveElementsCls.relationship("earth", "wood"), "overcome_by", "木剋土 → 土在木營=失位")
	assert_eq(FiveElementsCls.relationship("fire", ""), "neutral", "空 element=中性")
	assert_true(FiveElementsCls.is_wei_position("fire", "fire"), "同行=得位")
	assert_true(FiveElementsCls.is_wei_position("fire", "wood"), "受生=得位")
	assert_false(FiveElementsCls.is_wei_position("earth", "wood"), "失位≠得位")

func test_five_elements_damage_multiplier_data_driven() -> void:
	var mult: Dictionary = {"same": 1.5, "generated_by": 1.3, "overcomes": 1.2, "generates": 0.9, "overcome_by": 0.6}
	assert_eq(FiveElementsCls.damage_multiplier("fire", "fire", mult), 1.5, "同行倍率讀資料")
	assert_eq(FiveElementsCls.damage_multiplier("earth", "wood", mult), 0.6, "失位倍率讀資料")
	assert_eq(FiveElementsCls.damage_multiplier("fire", "wood", {}), 1.0, "缺倍率表 → 1.0（向後相容）")
