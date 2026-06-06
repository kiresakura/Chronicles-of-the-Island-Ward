# 鎮島錄 — 開局班底（主祭 / 護壇 / 法器）載入 + 出戰神明解析。
#
# 護壇 / 法器資料目前不入 Global SCHEMA，由此就地讀取（同 DeityInvocationSystem）。
# 對應 PRD §主祭/護壇/法器、docs/design/ritual_combat_system.md。loadout 套用在 Global.start_run。
class_name RitualLoadout
extends RefCounted

const GUARDIAN_DIR: String = "res://external/data/guardians/"
const TOOL_DIR: String = "res://external/data/ritual_tools/"
const DEFAULT_DEITY_ID: String = "deity_tiger_god"

static func _read_props(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return (parsed as Dictionary).get("properties", {})

static func load_guardian(guardian_id: String) -> GuardianData:
	if guardian_id == "":
		return null
	var props: Dictionary = _read_props(GUARDIAN_DIR + guardian_id + ".json")
	if props.is_empty():
		return null
	var g: GuardianData = GuardianData.new()
	g.object_id = str(props.get("object_id", guardian_id))
	g.guardian_name = str(props.get("guardian_name", ""))
	g.guardian_passive_effect = str(props.get("guardian_passive_effect", ""))
	var cards: Array[String] = []
	for c: Variant in props.get("guardian_support_card_ids", []):
		cards.append(str(c))
	g.guardian_support_card_ids = cards
	g.guardian_affinity_deity_id = str(props.get("guardian_affinity_deity_id", ""))
	return g

static func load_tool(tool_id: String) -> RitualToolData:
	if tool_id == "":
		return null
	var props: Dictionary = _read_props(TOOL_DIR + tool_id + ".json")
	if props.is_empty():
		return null
	var t: RitualToolData = RitualToolData.new()
	t.object_id = str(props.get("object_id", tool_id))
	t.tool_name = str(props.get("tool_name", ""))
	t.tool_rule_domain = str(props.get("tool_rule_domain", ""))
	t.tool_bonus_break_damage = int(props.get("tool_bonus_break_damage", 0))
	t.tool_extra_broken_turns = int(props.get("tool_extra_broken_turns", 0))
	t.tool_bonus_deity_charge = int(props.get("tool_bonus_deity_charge", 0))
	t.tool_affinity_deity_id = str(props.get("tool_affinity_deity_id", ""))
	return t

## 出戰神明解析：法器 affinity > 護壇 affinity > 預設虎爺。
static func resolve_active_deity(guardian: GuardianData, tool: RitualToolData) -> String:
	if tool != null and tool.tool_affinity_deity_id != "":
		return tool.tool_affinity_deity_id
	if guardian != null and guardian.guardian_affinity_deity_id != "":
		return guardian.guardian_affinity_deity_id
	return DEFAULT_DEITY_ID
