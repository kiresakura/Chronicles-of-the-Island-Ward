# 鎮島錄 Q4-D — 雲端存檔守門。
# 範圍：對帳矩陣（雲空→推 / 雲新→拉採用 / 本機新→推 / 平手→不動 /
# unavailable→no-op）、save_profile 上雲鉤、時戳蓋章。
# 以 set_provider 注入 FakeCloudProvider；結束必還原 default provider 與
# Global.profile_data — 不污染其他測試與真實存檔。
extends "res://tests/test_case.gd"

const CloudSaveScript := preload("res://scripts/systems/cloud/CloudSave.gd")
const FakeCloudScript := preload("res://scripts/systems/cloud/FakeCloudProvider.gd")
const ProviderBase := preload("res://scripts/systems/cloud/CloudSaveProvider.gd")

func _with_profile(ts: int, incense: int) -> ProfileData:
	var p: ProfileData = ProfileData.new()
	p.profile_updated_at_unix = ts
	p.profile_incense_balance = incense
	return p

func _teardown_provider() -> void:
	CloudSaveScript.set_provider(ProviderBase.new())	# 回 unavailable 預設

func test_unavailable_provider_is_noop() -> void:
	CloudSaveScript.set_provider(ProviderBase.new())
	var original: ProfileData = Global.profile_data
	Global.profile_data = _with_profile(100, 50)
	assert_eq(CloudSaveScript.reconcile_on_boot(), "none", "unavailable 應 no-op")
	Global.profile_data = original

func test_empty_cloud_gets_local_push() -> void:
	var fake: RefCounted = FakeCloudScript.new()
	CloudSaveScript.set_provider(fake)
	var original: ProfileData = Global.profile_data
	Global.profile_data = _with_profile(100, 50)
	assert_eq(CloudSaveScript.reconcile_on_boot(), "pushed", "雲端空應推本機上雲")
	assert_eq(int(fake.pull_profile().get("profile_incense_balance", -1)), 50, "雲端應收到本機值")
	Global.profile_data = original
	_teardown_provider()

func test_newer_cloud_overwrites_local() -> void:
	var fake: RefCounted = FakeCloudScript.new()
	CloudSaveScript.set_provider(fake)
	fake.seed_remote(_with_profile(200, 777).get_serializable_properties(true))
	var original: ProfileData = Global.profile_data
	Global.profile_data = _with_profile(100, 50)	# 本機較舊
	assert_eq(CloudSaveScript.reconcile_on_boot(), "pulled", "雲端新應採用雲端")
	assert_eq(Global.profile_data.profile_incense_balance, 777, "本機 profile 應被雲端覆蓋")
	Global.profile_data = original
	_teardown_provider()
	# 還原真實 profile 落地（reconcile 採用雲端時會 save_profile 覆蓋真檔）
	FileLoader.save_profile()

func test_newer_local_pushes_to_cloud() -> void:
	var fake: RefCounted = FakeCloudScript.new()
	CloudSaveScript.set_provider(fake)
	fake.seed_remote(_with_profile(100, 1).get_serializable_properties(true))
	var original: ProfileData = Global.profile_data
	Global.profile_data = _with_profile(300, 999)	# 本機較新
	assert_eq(CloudSaveScript.reconcile_on_boot(), "pushed", "本機新應推上雲")
	assert_eq(int(fake.pull_profile().get("profile_incense_balance", -1)), 999, "雲端應更新為本機值")
	Global.profile_data = original
	_teardown_provider()

func test_equal_timestamps_do_nothing() -> void:
	var fake: RefCounted = FakeCloudScript.new()
	CloudSaveScript.set_provider(fake)
	fake.seed_remote(_with_profile(100, 1).get_serializable_properties(true))
	var original: ProfileData = Global.profile_data
	Global.profile_data = _with_profile(100, 50)
	assert_eq(CloudSaveScript.reconcile_on_boot(), "none", "時戳平手應視為同一份不動")
	Global.profile_data = original
	_teardown_provider()

func test_save_profile_stamps_and_pushes() -> void:
	var fake: RefCounted = FakeCloudScript.new()
	CloudSaveScript.set_provider(fake)
	var before: int = fake.push_count
	FileLoader.save_profile()	# 對真實 Global.profile_data 操作（時戳蓋章 + 上雲）
	assert_true(Global.profile_data.profile_updated_at_unix > 0, "save_profile 應蓋寫入時戳")
	assert_eq(fake.push_count, before + 1, "save_profile 應觸發一次上雲 push")
	_teardown_provider()
