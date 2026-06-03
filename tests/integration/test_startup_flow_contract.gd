# 鎮島錄 — 啟動流程 contract test
#
# 目的：把「點 App → 主畫面」啟動流程的關鍵契約鎖進測試，避免日後回歸：
#   1. main_scene 必須是 Root.tscn
#   2. 舊 SplashScreen.tscn 已移除且無人引用（不可復活舊架構）
#   3. TitleScreen 不得殘留假進度條邏輯
#   4. 品牌過場 BRAND_HOLD_SEC 不得過長（<= 0.5s）
#   5. 啟動 overlay 支援 mouse/touch tap-to-skip
#   6. 過場後主畫面 MainMenu 能正常顯示
#
# 說明：run_all.gd 以 instance.call() 執行、不 await，故全程同步斷言
#（add_child 同步觸發 _ready；show_main_menu() 為同步公開方法）。
extends "res://tests/test_case.gd"

const ROOT_SCENE_PATH: String = "res://scenes/Root.tscn"
const SPLASH_SCENE_PATH: String = "res://scenes/SplashScreen.tscn"
const TITLE_SCRIPT_PATH: String = "res://scripts/ui/menus/TitleScreen.gd"


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_as_text() if f != null else ""


func _title_script() -> GDScript:
	return load(TITLE_SCRIPT_PATH) as GDScript


func _title_method_names() -> Array:
	var names: Array = []
	var s := _title_script()
	if s == null:
		return names
	for m: Dictionary in s.get_script_method_list():
		names.append(m["name"])
	return names


# 1. main_scene 必須是 Root.tscn
func test_main_scene_is_root() -> void:
	var txt: String = _read_text("res://project.godot")
	assert_true(txt.contains('run/main_scene="res://scenes/Root.tscn"'),
		"project.godot 的 run/main_scene 應為 res://scenes/Root.tscn")


# 2. 舊 SplashScreen.tscn 已移除且無人引用
func test_splashscreen_removed_and_unreferenced() -> void:
	assert_false(FileAccess.file_exists(SPLASH_SCENE_PATH),
		"舊 SplashScreen.tscn 應已移除，不可復活舊啟動架構")
	for p: String in ["res://project.godot", ROOT_SCENE_PATH, TITLE_SCRIPT_PATH]:
		assert_false(_read_text(p).contains("SplashScreen"),
			"%s 不應再引用 SplashScreen" % p)


# 3. TitleScreen 不得殘留假進度條邏輯
func test_titlescreen_has_no_fake_progress_bar() -> void:
	var s := _title_script()
	assert_not_null(s, "應能載入 TitleScreen.gd")
	if s == null:
		return
	var consts: Dictionary = s.get_script_constant_map()
	assert_false(consts.has("ROOT_LOADING_DURATION"), "不應殘留假進度條時長常數 ROOT_LOADING_DURATION")
	assert_false(consts.has("ROOT_LOADING_TIPS"), "不應殘留假進度條提示常數 ROOT_LOADING_TIPS")
	assert_false(_title_method_names().has("_apply_root_loading_progress"),
		"不應殘留假進度更新方法 _apply_root_loading_progress")
	# 只檢查「真正建立 ProgressBar 節點」，避免誤判說明用的註解文字
	assert_false(_read_text(TITLE_SCRIPT_PATH).contains("ProgressBar.new("),
		"TitleScreen 不應再建立 ProgressBar 節點（誤導性假進度條）")


# 4. 品牌過場停留不得過長
func test_brand_hold_sec_is_short() -> void:
	var consts: Dictionary = _title_script().get_script_constant_map()
	assert_true(consts.has("BRAND_HOLD_SEC"), "TitleScreen 應有 BRAND_HOLD_SEC 常數")
	var hold: float = float(consts.get("BRAND_HOLD_SEC", 999.0))
	assert_true(hold <= 0.5, "品牌過場 BRAND_HOLD_SEC 應 <= 0.5 秒，實得 %s" % hold)


# 5. 啟動 overlay 支援 mouse/touch tap-to-skip
func test_startup_overlay_supports_skip() -> void:
	var methods: Array = _title_method_names()
	assert_true(methods.has("_on_overlay_input"), "啟動 overlay 應有輸入處理 _on_overlay_input")
	assert_true(methods.has("_skip_root_transition"), "啟動 overlay 應支援 tap-to-skip（_skip_root_transition）")
	var src: String = _read_text(TITLE_SCRIPT_PATH)
	assert_true(src.contains("InputEventScreenTouch"), "tap-to-skip 應支援觸控 InputEventScreenTouch")
	assert_true(src.contains("InputEventMouseButton"), "tap-to-skip 應支援滑鼠 InputEventMouseButton")


# 6. 過場後主畫面 MainMenu 能正常顯示
func test_main_menu_shows_after_transition() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var scene := load(ROOT_SCENE_PATH) as PackedScene
	assert_not_null(scene, "Root.tscn 應可載入")
	if scene == null:
		return
	var root: Node = scene.instantiate()
	tree.root.add_child(root)   # 同步觸發整棵 _ready（含 TitleScreen 過場啟動）

	var title: Node = root.get_node_or_null("TitleScreen")
	assert_not_null(title, "Root 應含 TitleScreen 節點")
	if title != null and title.has_method("show_main_menu"):
		title.show_main_menu()  # 模擬過場收尾
		var mm: Node = title.get_node_or_null("MainMenu")
		assert_not_null(mm, "TitleScreen 應含 MainMenu 節點")
		if mm != null:
			assert_true(mm.visible, "過場後主畫面 MainMenu 應為可見")

	# 同步拆除，避免殘留 Root 影響後續測試
	tree.root.remove_child(root)
	root.free()
