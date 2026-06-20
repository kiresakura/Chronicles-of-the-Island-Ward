# 鎮島錄 c-2 — 外觀目錄（設計稿 捌 外觀四階）。
#
# 純讀資料層（鐵律1）：external/data/cosmetics.json → 4 階立繪外框（素/燙金/玉青/神話）。
# 變現紅線（單點強制）：外觀只賣視覺、零戰力；購買只扣元寶、只給外觀，永不碰香火/戰力。
# 素（tier 0）免費預設、其餘以元寶購買。所有「買/裝/查」邏輯集中此處 → 可單元測試。
extends RefCounted
class_name CosmeticCatalog

const PATH := "res://external/data/cosmetics.json"
const DEFAULT_FRAME := "frame_su"

static var _frames_cache: Array = []

static func frames() -> Array:
	if not _frames_cache.is_empty():
		return _frames_cache
	if not FileAccess.file_exists(PATH):
		return []
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return []
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var arr: Variant = (parsed as Dictionary).get("frames", [])
	if typeof(arr) == TYPE_ARRAY:
		_frames_cache = arr
	return _frames_cache

static func frame_def(frame_id: String) -> Dictionary:
	for fr: Variant in frames():
		if typeof(fr) == TYPE_DICTIONARY and str((fr as Dictionary).get("id", "")) == frame_id:
			return fr
	return {}

static func price(frame_id: String) -> int:
	return int(frame_def(frame_id).get("price_yuanbao", 0))

## 玩家是否擁有此外觀（素 tier0 免費預設；其餘看 profile）。
static func owns(profile: ProfileData, frame_id: String) -> bool:
	if frame_id == "" or frame_id == DEFAULT_FRAME:
		return true
	if profile == null:
		return false
	return profile.has_cosmetic(frame_id)

## 當前裝備的外觀 id（空＝素預設）。
static func equipped_id(profile: ProfileData) -> String:
	if profile == null or profile.profile_equipped_frame == "":
		return DEFAULT_FRAME
	return profile.profile_equipped_frame

## 購買外觀（紅線：只扣元寶、只給外觀，永不碰香火/戰力）。
## 失敗條件：已擁有 / 餘額不足 / 素或空 id。成功回 true（呼叫端負責 save + UI）。
static func purchase(profile: ProfileData, frame_id: String) -> bool:
	if profile == null or frame_id == "" or frame_id == DEFAULT_FRAME:
		return false
	if owns(profile, frame_id):
		return false
	if not profile.spend_yuanbao(price(frame_id)):
		return false
	profile.own_cosmetic(frame_id)
	return true

## 裝備外觀（須已擁有；素還原為空字串）。成功回 true。
static func equip(profile: ProfileData, frame_id: String) -> bool:
	if profile == null or not owns(profile, frame_id):
		return false
	profile.profile_equipped_frame = ("" if frame_id == DEFAULT_FRAME else frame_id)
	return true
