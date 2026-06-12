# 鎮島錄 Q4-D — 雲端存檔供應端抽象（iCloud Key-Value Store 語意）。
#
# 契約：KV 語意 = push/pull 都是「整份 profile dict」，無部分更新；
# is_available() false 時上層一律 no-op（單機照常）。
# 真機適配（NSUbiquitousKeyValueStore via godot-ios-plugins/icloud）排 Q4-F
# TestFlight 輪：屆時新增 ICloudKVProvider extends 本類，呼叫端零改動。
# iCloud KV 限制備忘：單 key ≤1MB、總量 ≤1MB/64keys — profile JSON 數 KB，綽綽有餘。
class_name CloudSaveProvider
extends RefCounted

## 平台雲端是否可用（未登入 / 無 plugin / 桌面 → false）。
func is_available() -> bool:
	return false

## 整份 profile dict 上雲。回成功與否。
@warning_ignore("unused_parameter")
func push_profile(profile_dict: Dictionary) -> bool:
	return false

## 取雲端 profile dict。無資料回空 dict。
func pull_profile() -> Dictionary:
	return {}
