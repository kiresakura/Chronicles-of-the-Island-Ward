# 鎮島錄 Q4-D — 假雲端供應端：記憶體 KV，模擬 iCloud 同步行為（測試 / dev）。
# COTIW_CLOUD_FAKE=1 時 CloudSave 會在 dev 端啟用本端（手動 QA 跨「裝置」情境
# 可用 seed_remote() 預灌雲端資料）。
class_name FakeCloudProvider
extends "res://scripts/systems/cloud/CloudSaveProvider.gd"
# ↑ path-based extends：class_name 全域註冊在 headless 測試載入序不可靠（專案慣例）

var _remote: Dictionary = {}
var push_count: int = 0	# 測試觀測點

func is_available() -> bool:
	return true

func push_profile(profile_dict: Dictionary) -> bool:
	_remote = profile_dict.duplicate(true)
	push_count += 1
	return true

func pull_profile() -> Dictionary:
	return _remote.duplicate(true)

## 測試/QA：直接灌雲端內容（模擬另一台裝置先同步過）。
func seed_remote(profile_dict: Dictionary) -> void:
	_remote = profile_dict.duplicate(true)
