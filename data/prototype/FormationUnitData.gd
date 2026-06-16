extends PrototypeData
class_name FormationUnitData

# 鎮島錄 v0.3 — 可佈陣單位（FP-5 拍板：獨立資料類別，統一神明/家將/部將）。
# 神明（媽祖）、家將、部將（千里眼/順風耳）皆為「可擺進營」的單位。
# unit_element 供五行得位（FP-3 完整相生相剋）；unit_source_id 連結既有
# DeityData/GuardianData（可選，複用降乩管線）；unit_affinity_ids 供緣分合祀（FC-6）。
# schema：external/data/formation_units/*.json。

@export var unit_name: String = ""
@export var unit_element: String = ""			# 五行（VALID_ELEMENTS）— 得位判定
@export var unit_kind: String = ""				# deity / general（五營主將）/ vanguard（部將）
@export var unit_power: int = 0					# 削煞基值（戰鬥數值，資料層）
@export var unit_source_id: String = ""			# 連結既有 deity_id / guardian_id（可選；空＝原生單位）
@export var unit_affinity_ids: Array[String] = []	# 緣分 id（FC-6 合祀用，先佔位）
@export var unit_description: String = ""		# ≤ MAX_DESC_LEN
