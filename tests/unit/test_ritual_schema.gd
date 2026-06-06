# 鎮島錄 — 儀式系統資料 schema 驗證
#
# 對應 PRD §戰鬥系統 與 docs/design/{ward_break,talisman_merge,deity_invocation}_system.md。
# 直接從 res://external/data/ 讀 JSON 驗證欄位與格式（不經 Global 載入器），
# 是「資料驅動鐵律」的回歸防線：新卡/敵/神明資料一旦欄位不合法即測試失敗。
extends "res://tests/test_case.gd"

const DATA_ROOT: String = "res://external/data/"

const VALID_TAGS: Array[String] = ["fist", "talisman", "fire", "bell", "array", "curse"]
const VALID_BREAK_EFFECTS: Array[String] = [
	"break_stun", "break_vulnerable", "break_weak", "break_stun_vulnerable", "break_invoke_window",
]
const VALID_DEITY_TRIGGERS: Array[String] = [
	"on_enemy_broken", "on_debuff_applied", "on_block_gained", "on_self_damage", "on_merge_tier3", "manual",
]
const VALID_TOOL_DOMAINS: Array[String] = ["ward_break", "deity", "economy", "draw", "merge"]
const VALID_RITUAL_CARD_TYPES: Array[String] = [
	"wu_jue", "hu_tan", "kai_tan", "fu_ling", "shen_yu", "gong_pin", "jin_ji",
]

# ---------- 收集工具 ----------

func _collect_props(subdir: String) -> Array:
	# 回傳 [{ "_path": String, ...properties }] 陣列
	var out: Array = []
	var files: Array[String] = []
	_collect_json_files(DATA_ROOT + subdir + "/", files)
	for path: String in files:
		var f: FileAccess = FileAccess.open(path, FileAccess.READ)
		if f == null:
			continue
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY:
			continue
		var props: Dictionary = (parsed as Dictionary).get("properties", {})
		props = props.duplicate()
		props["_path"] = path.get_file()
		out.append(props)
	return out

func _all_card_ids() -> Dictionary:
	var ids: Dictionary = {}
	for props: Dictionary in _collect_props("cards"):
		if props.has("object_id"):
			ids[props["object_id"]] = props
	return ids

func _all_ids(subdir: String) -> Dictionary:
	var ids: Dictionary = {}
	for props: Dictionary in _collect_props(subdir):
		if props.has("object_id"):
			ids[props["object_id"]] = props
	return ids

# ---------- 卡牌：儀法標籤 + 分類 ----------

func test_card_ritual_tags_and_type_valid() -> void:
	for props: Dictionary in _collect_props("cards"):
		var name: String = props.get("_path", "?")
		for tag: Variant in props.get("card_ritual_tags", []):
			assert_true(VALID_TAGS.has(tag),
				"%s 的 ritual_tag「%s」不在合法六道儀法內" % [name, str(tag)])
		var rct: String = props.get("card_ritual_card_type", "")
		if rct != "":
			assert_true(VALID_RITUAL_CARD_TYPES.has(rct),
				"%s 的 ritual_card_type「%s」非合法分類" % [name, rct])
		var bd: int = int(props.get("card_break_damage", 0))
		assert_true(bd >= 0, "%s break_damage 不可為負" % name)

# ---------- 卡牌：符階合成圖完整性 ----------

func test_card_merge_graph_consistent() -> void:
	var cards: Dictionary = _all_card_ids()
	for cid: String in cards:
		var props: Dictionary = cards[cid]
		var name: String = props.get("_path", cid)
		var tier: int = int(props.get("card_merge_tier", 0))
		var group: String = props.get("card_merge_group", "")
		var result_id: String = props.get("card_merge_result_id", "")
		assert_true(tier >= 0 and tier <= 3, "%s merge_tier 必須在 0..3" % name)
		if group != "":
			assert_true(tier >= 1, "%s 有 merge_group 卻 merge_tier=0" % name)
		if result_id != "":
			assert_has(cards, result_id,
				"%s 的 merge_result_id「%s」指向不存在的卡" % [name, result_id])
			if cards.has(result_id):
				var target: Dictionary = cards[result_id]
				assert_eq(target.get("card_merge_group", ""), group,
					"%s 合成產物族群不一致" % name)
				assert_eq(int(target.get("card_merge_tier", 0)), tier + 1,
					"%s 合成產物階級應為 %d" % [name, tier + 1])

# ---------- 敵人：煞盾 / 弱點 / 破煞效果 ----------

func test_enemy_ward_schema_valid() -> void:
	for props: Dictionary in _collect_props("enemies"):
		var name: String = props.get("_path", "?")
		var max_ward: int = int(props.get("enemy_max_ward_shield", 0))
		var ward: int = int(props.get("enemy_ward_shield", 0))
		assert_true(max_ward >= 0, "%s max_ward_shield 不可為負" % name)
		assert_true(ward <= max_ward or max_ward == 0,
			"%s ward_shield(%d) 不可大於 max(%d)" % [name, ward, max_ward])
		if max_ward > 0:
			var weaknesses: Array = props.get("enemy_weaknesses", [])
			assert_true(weaknesses.size() > 0,
				"%s 有煞盾卻無弱點（玩家將無法破煞）" % name)
			for w: Variant in weaknesses:
				assert_true(VALID_TAGS.has(w),
					"%s 弱點「%s」非合法儀法標籤" % [name, str(w)])
			var be: String = props.get("enemy_break_effect", "")
			assert_true(VALID_BREAK_EFFECTS.has(be),
				"%s 破煞效果「%s」未定義" % [name, be])
			assert_true(int(props.get("enemy_broken_turns", 1)) >= 1,
				"%s broken_turns 必須 >= 1" % name)

# ---------- 神明 deities ----------

func test_deity_schema_valid() -> void:
	var deities: Dictionary = _all_ids("deities")
	assert_true(deities.size() >= 3, "至少需設計 3 位神明（虎爺/城隍/媽祖）")
	for did: String in deities:
		var props: Dictionary = deities[did]
		var name: String = props.get("_path", did)
		assert_ne(props.get("deity_name", ""), "", "%s 缺 deity_name" % name)
		var tags: Array = props.get("deity_charge_tags", [])
		assert_true(tags.size() > 0, "%s 缺 charge_tags" % name)
		for t: Variant in tags:
			assert_true(VALID_TAGS.has(t), "%s charge_tag「%s」非法" % [name, str(t)])
		assert_true(int(props.get("deity_max_charge", 0)) > 0, "%s max_charge 必須 > 0" % name)
		assert_true(VALID_DEITY_TRIGGERS.has(props.get("deity_trigger_condition", "manual")),
			"%s trigger_condition 未定義" % name)

# ---------- 護壇 guardians ----------

func test_guardian_schema_valid() -> void:
	var cards: Dictionary = _all_card_ids()
	var deities: Dictionary = _all_ids("deities")
	for gid: String in _all_ids("guardians"):
		var props: Dictionary = _all_ids("guardians")[gid]
		var name: String = props.get("_path", gid)
		assert_ne(props.get("guardian_name", ""), "", "%s 缺 guardian_name" % name)
		for cid: Variant in props.get("guardian_support_card_ids", []):
			assert_has(cards, cid, "%s 支援卡「%s」不存在" % [name, str(cid)])
		var deity_id: String = props.get("guardian_affinity_deity_id", "")
		if deity_id != "":
			assert_has(deities, deity_id, "%s 契合神明「%s」不存在" % [name, deity_id])

# ---------- 法器 ritual_tools ----------

func test_ritual_tool_schema_valid() -> void:
	var deities: Dictionary = _all_ids("deities")
	for tid: String in _all_ids("ritual_tools"):
		var props: Dictionary = _all_ids("ritual_tools")[tid]
		var name: String = props.get("_path", tid)
		assert_ne(props.get("tool_name", ""), "", "%s 缺 tool_name" % name)
		assert_true(VALID_TOOL_DOMAINS.has(props.get("tool_rule_domain", "")),
			"%s rule_domain 未定義" % name)
		var deity_id: String = props.get("tool_affinity_deity_id", "")
		if deity_id != "":
			assert_has(deities, deity_id, "%s 契合神明「%s」不存在" % [name, deity_id])

# ---------- 遶境路線 + 修廟建築 ----------

func test_route_and_building_schema_valid() -> void:
	for props: Dictionary in _collect_props("route_traits"):
		var name: String = props.get("_path", "?")
		assert_ne(props.get("route_name", ""), "", "%s 缺 route_name" % name)
		assert_true(int(props.get("danger_rating", -1)) >= 0, "%s danger_rating 不合法" % name)
		assert_true(int(props.get("pollution_level", -1)) >= 0, "%s pollution_level 不合法" % name)
	for props2: Dictionary in _collect_props("meta_buildings"):
		var bname: String = props2.get("_path", "?")
		assert_ne(props2.get("building_name", ""), "", "%s 缺 building_name" % bname)
		assert_true(int(props2.get("repair_cost_incense", 0)) > 0,
			"%s 修復成本（香火）必須 > 0" % bname)

# ---------- 落地證明：新欄位確實經 Global 載入器灌進活物件（非僅存在於磁碟）----------

func test_ritual_fields_roundtrip_through_loader() -> void:
	# 卡牌：攻拳應帶 fist 標籤、破煞數值、與指向重擊的合成鏈
	var punch: CardData = Global._id_to_card_data.get("card_tongji_punch")
	assert_not_null(punch, "card_tongji_punch 未載入")
	if punch != null:
		assert_true(punch.card_ritual_tags.has("fist"), "攻拳 ritual_tags 未灌入 fist")
		assert_eq(punch.card_break_damage, 2, "攻拳 break_damage 未灌入")
		assert_eq(punch.card_merge_result_id, "card_tongji_heavy_strike",
			"攻拳 merge_result_id 未灌入")
	# 敵人：樹靈應帶火弱點與煞盾
	var tree: EnemyData = Global._id_to_enemy_data.get("enemy_tree_spirit")
	assert_not_null(tree, "enemy_tree_spirit 未載入")
	if tree != null:
		assert_eq(tree.enemy_max_ward_shield, 6, "樹靈 max_ward_shield 未灌入")
		assert_true(tree.enemy_weaknesses.has("fire"), "樹靈 fire 弱點未灌入")
		assert_eq(tree.enemy_break_effect, "break_vulnerable", "樹靈 break_effect 未灌入")

# ---------- 共用：遞迴收集 JSON ----------

func _collect_json_files(dir_path: String, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full: String = dir_path + entry
		if dir.current_is_dir():
			_collect_json_files(full + "/", out)
		elif entry.ends_with(".json"):
			out.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
