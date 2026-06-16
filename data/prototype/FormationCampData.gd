extends PrototypeData
class_name FormationCampData

# 鎮島錄 v0.3 — 五營羅盤之一營（formation_progression_v0.3.md §1.1）。
# 五方位軍陣：東（青龍/木）、南（朱雀/火）、西（白虎/金）、北（玄武/水）、
# 中（中壇元帥哪吒/土）。固定 5 筆。schema：external/data/formation_camps/*.json。
# 對映既有「修廟」解鎖鍵做漸進揭露（§3）；不破既有測試（鐵律 1 資料驅動）。

@export var camp_name: String = ""
@export var camp_direction: String = ""		# east/south/west/north/center（VALID_DIRECTIONS）
@export var camp_element: String = ""			# wood/fire/earth/metal/water（五行，VALID_ELEMENTS）
@export var camp_color: String = ""				# 視覺色票鍵（青/紅/白/黑/黃）
@export var camp_general: String = ""			# 鎮營主將顯示名（青龍/朱雀/白虎/玄武/哪吒）
@export var camp_unlock_feature: String = ""	# 對映 RitualTemple.feature_open 解鎖鍵（§3 漸進揭露）
@export var camp_description: String = ""		# ≤ MAX_DESC_LEN（validator 卡死，杜絕 UI 截斷）
@export var camp_lane: String = ""				# 守備方位 lane（中營為空＝預備/調度中樞）
