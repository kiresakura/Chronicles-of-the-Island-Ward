# 鎮島錄 Q4-D — 雲端存檔編排（iCloud KV 先行；QUESTIONS Q4-C 選項 A）。
#
# 同步策略（KV 整份覆蓋語意）：
#   開機 reconcile：雲端空 → 推本機上雲；本機新（時戳大）→ 推上雲；
#                   雲端新 → 雲端覆蓋本機（採用後立即本機落地）。
#   平手（時戳相等）→ 不動（視為同一份）。
#   存檔時 push：FileLoader.save_profile() 落地後順手上雲（KV 寫入廉價）。
# 衝突哲學：last-writer-wins by profile_updated_at_unix —
#   單人 meta 進度（香火/建築/解鎖）丟失成本低、合併複雜度高，KV 輪不做欄位合併；
#   若日後做多裝置重度同步再升級成逐欄位 max-merge（Q4-C QUESTIONS 升級點）。
#
# Provider 選擇：iOS 真機 → ICloudKVProvider（Q4-F 落地前以 unavailable 佔位）；
# dev/測試 → COTIW_CLOUD_FAKE=1 啟用 FakeCloudProvider；其餘 unavailable（單機 no-op）。
class_name CloudSave
extends RefCounted

const ProviderBase := preload("res://scripts/systems/cloud/CloudSaveProvider.gd")
const FakeProvider := preload("res://scripts/systems/cloud/FakeCloudProvider.gd")

static var _provider: RefCounted = null

static func get_provider() -> RefCounted:
	if _provider == null:
		if OS.get_environment("COTIW_CLOUD_FAKE") == "1":
			_provider = FakeProvider.new()
		else:
			# iOS ICloudKVProvider 於 Q4-F plugin 落地後接入；現階段全平台 unavailable
			_provider = ProviderBase.new()
	return _provider

## 測試注入點。
static func set_provider(provider: RefCounted) -> void:
	_provider = provider

## 開機對帳：回動作字串（"none"/"pushed"/"pulled" — 測試/log 觀測用）。
## 採用雲端時：覆蓋 Global.profile_data 並本機落地（走 Q4-B 加密）。
static func reconcile_on_boot() -> String:
	var provider: RefCounted = get_provider()
	if not provider.is_available() or Global.profile_data == null:
		return "none"
	var local_dict: Dictionary = Global.profile_data.get_serializable_properties(true)
	var remote_dict: Dictionary = provider.pull_profile()
	if remote_dict.is_empty():
		provider.push_profile(local_dict)
		return "pushed"
	var local_ts: int = int(local_dict.get("profile_updated_at_unix", 0))
	var remote_ts: int = int(remote_dict.get("profile_updated_at_unix", 0))
	if remote_ts > local_ts:
		Global.profile_data.set_serializable_properties(remote_dict, true)
		FileLoader.save_profile()	# 落地即重新時戳 + 回推上雲（push_after_save）
		DebugLogger.log_line("[雲端] 採用雲端 profile（雲 %d > 本機 %d）" % [remote_ts, local_ts], Color.LIGHT_BLUE)
		return "pulled"
	if local_ts > remote_ts:
		provider.push_profile(local_dict)
		return "pushed"
	return "none"

## 存檔後順手上雲（FileLoader.save_profile 尾端呼叫；unavailable 時零成本）。
static func push_after_save(profile_dict: Dictionary) -> void:
	var provider: RefCounted = get_provider()
	if provider.is_available():
		provider.push_profile(profile_dict)
