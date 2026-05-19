# 鎮島錄 — 零依賴測試基底類別
#
# 為何不直接用 GUT：GUT 需另外 clone bitwes/Gut addon 並啟用，離線環境不穩。
# 本基底提供 GUT 風格的 assert_* 介面，日後若導入 GUT 可低成本平移。
#
# 用法：測試檔 extends "res://tests/test_case.gd"，方法名以 test_ 開頭。
# 每個 assert 失敗會記進 failures，不中斷該測試方法（盡量收集所有問題）。
extends RefCounted
class_name CotiwTestCase

var failures: Array[String] = []          # 本測試案例所有失敗訊息
var _current_test: String = ""            # 目前執行中的 test_ 方法名

func _fail(message: String) -> void:
	failures.append("[%s] %s" % [_current_test, message])

func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_fail("assert_true 失敗：" + message)

func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_fail("assert_false 失敗：" + message)

func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		_fail("assert_eq 失敗：預期 %s 實得 %s。%s" % [str(expected), str(actual), message])

func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if actual == unexpected:
		_fail("assert_ne 失敗：值不應為 %s。%s" % [str(unexpected), message])

func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		_fail("assert_not_null 失敗：" + message)

func assert_has(collection: Variant, key: Variant, message: String = "") -> void:
	if not (key in collection):
		_fail("assert_has 失敗：找不到 %s。%s" % [str(key), message])

func assert_not_has(collection: Variant, key: Variant, message: String = "") -> void:
	if key in collection:
		_fail("assert_not_has 失敗：不應存在 %s。%s" % [str(key), message])
