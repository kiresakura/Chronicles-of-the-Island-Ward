# 鎮島錄 — Headless 測試執行器（零依賴）
#
# 執行：godot --headless res://tests/TestRunner.tscn
#   （必須以「場景」方式跑，不可用 --script；--script 不會載入 autoload，
#     Global / Random 等 singleton 會找不到。）
# 行為：autoload（Global）於場景前載完資料 → 掃 tests/unit、tests/integration 下所有 .gd
#       → 跑每個 test_ 方法 → 印總結 → 以 exit code 0(全過)/1(有失敗) 結束。
# CI 依賴此 exit code 判定成敗。
extends Node

const TEST_DIRS: Array[String] = ["res://tests/unit/", "res://tests/integration/"]

func _ready() -> void:
	# 延遲一幀，確保所有 autoload._ready()（含 Global 資料載入）都已完成
	await get_tree().process_frame
	var exit_code: int = _run_all_tests()
	get_tree().quit(exit_code)

func _run_all_tests() -> int:
	if Global._id_to_card_data.is_empty():
		push_error("Global 資料表為空，autoload 未就緒")
		return 1

	var test_scripts: Array[String] = _discover_test_scripts()
	var total: int = 0
	var passed: int = 0
	var all_failures: Array[String] = []

	print("\n==================== 鎮島錄 測試 ====================")
	for script_path: String in test_scripts:
		var script: GDScript = load(script_path)
		if script == null:
			all_failures.append("無法載入測試腳本：" + script_path)
			continue
		var instance: Object = script.new()
		var file_name: String = script_path.get_file()

		for method_info: Dictionary in instance.get_method_list():
			var method_name: String = method_info["name"]
			if not method_name.begins_with("test_"):
				continue
			total += 1
			instance.failures.clear()
			instance._current_test = method_name
			instance.call(method_name)
			if instance.failures.is_empty():
				passed += 1
				print("  PASS  %s::%s" % [file_name, method_name])
			else:
				print("  FAIL  %s::%s" % [file_name, method_name])
				for failure: String in instance.failures:
					print("      -> " + failure)
					all_failures.append("%s::%s %s" % [file_name, method_name, failure])

	print("----------------------------------------------------")
	print("結果：%d / %d 通過" % [passed, total])
	if total == 0:
		push_error("沒有找到任何測試")
		print("====================================================\n")
		return 1
	if all_failures.is_empty():
		print("[OK] 全部通過")
		print("====================================================\n")
		return 0
	print("[FAIL] %d 項失敗" % all_failures.size())
	print("====================================================\n")
	return 1

func _discover_test_scripts() -> Array[String]:
	var scripts: Array[String] = []
	for dir_path: String in TEST_DIRS:
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var entry: String = dir.get_next()
		while entry != "":
			if not dir.current_is_dir() and entry.ends_with(".gd"):
				scripts.append(dir_path + entry)
			entry = dir.get_next()
		dir.list_dir_end()
	scripts.sort()
	return scripts
