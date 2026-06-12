# 鎮島錄 Q4-B — 進度檔加密守門。
# 範圍：round-trip、落地非明文、舊明文相容（升級遷移）、毀損不炸（回空 dict）。
# 測試檔寫在 saves/ 下以 __qa_enc 前綴隔離，每測自行清理 — 不污染真實存檔。
extends "res://tests/test_case.gd"

const DIR := "external/saves/"

func _cleanup(filename: String) -> void:
	var full_dir: String = FileLoader._get_modified_filepath(DIR)
	if FileAccess.file_exists(full_dir + filename):
		DirAccess.open(full_dir).remove(filename)

func _raw_text(filename: String) -> String:
	# 加密檔是二進位 — 用 ascii 視角檢視（get_as_text 會對非 UTF-8 噴 Unicode 解析噪音）
	var f: FileAccess = FileAccess.open(FileLoader._get_modified_filepath(DIR) + filename, FileAccess.READ)
	if f == null:
		return ""
	return f.get_buffer(f.get_length()).get_string_from_ascii()

func test_round_trip_preserves_data() -> void:
	var fn := "__qa_enc_roundtrip.json"
	var payload: Dictionary = {
		"profile_incense_balance": 1234.0,
		"nested": {"a": [1.0, 2.0, 3.0], "b": "文字值"},
	}
	FileLoader.save_json_encrypted(DIR, fn, payload)
	var back: Dictionary = FileLoader.load_json_encrypted(DIR, fn)
	assert_eq(JSON.stringify(back), JSON.stringify(payload), "加密 round-trip 應無損")
	_cleanup(fn)

func test_file_on_disk_is_not_plaintext() -> void:
	var fn := "__qa_enc_opaque.json"
	FileLoader.save_json_encrypted(DIR, fn, {"profile_incense_balance": 99999.0})
	var raw: String = _raw_text(fn)
	assert_false(raw.begins_with("{"), "落地檔不得是明文 JSON")
	assert_false(raw.contains("incense"), "落地檔不得含可讀欄位名")
	_cleanup(fn)

func test_legacy_plaintext_still_loads() -> void:
	# 升級相容：既有玩家的明文進度檔，首讀必須照常載入
	var fn := "__qa_enc_legacy.json"
	FileLoader.save_json(DIR, fn, {"profile_incense_balance": 250.0})
	var back: Dictionary = FileLoader.load_json_encrypted(DIR, fn)
	assert_eq(back.get("profile_incense_balance", -1.0), 250.0, "舊明文檔應可讀（遷移路徑）")
	_cleanup(fn)

func test_corrupted_file_returns_empty_without_crash() -> void:
	# 垃圾內容刻意用無 GDEC 頭的純 ASCII：走明文 fallback → 靜默解析失敗 → 空 dict。
	# （GDEC 頭 + 毀損體的子案例會觸發 Godot core ERROR 行 — 行為相同但會
	# 污染 log 乾淨契約，故不入測；見 FileLoader.load_json_encrypted 註記）
	var fn := "__qa_enc_corrupt.json"
	var full_dir: String = FileLoader._get_modified_filepath(DIR)
	var f: FileAccess = FileAccess.open(full_dir + fn, FileAccess.WRITE)
	f.store_string("NOT-JSON-GARBAGE####1234")
	f.close()
	var back: Dictionary = FileLoader.load_json_encrypted(DIR, fn)
	assert_eq(back.size(), 0, "毀損檔應回空 dict（上層以預設值重建）")
	_cleanup(fn)

func test_magic_detection_distinguishes_formats() -> void:
	var fn_enc := "__qa_enc_magic_enc.json"
	var fn_plain := "__qa_enc_magic_plain.json"
	FileLoader.save_json_encrypted(DIR, fn_enc, {"v": 1.0})
	FileLoader.save_json(DIR, fn_plain, {"v": 1.0})
	var full_dir: String = FileLoader._get_modified_filepath(DIR)
	assert_true(FileLoader._file_has_encryption_magic(full_dir + fn_enc), "加密檔應有 GDEC 頭")
	assert_false(FileLoader._file_has_encryption_magic(full_dir + fn_plain), "明文檔不得誤判為加密")
	_cleanup(fn_enc)
	_cleanup(fn_plain)

func test_missing_file_returns_empty() -> void:
	var back: Dictionary = FileLoader.load_json_encrypted(DIR, "__qa_enc_nonexistent.json")
	assert_eq(back.size(), 0, "不存在檔應回空 dict 不噴錯")
