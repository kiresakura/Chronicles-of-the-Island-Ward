extends "res://tests/test_case.gd"

const ROOT_SCENE_PATH := "res://scenes/Root.tscn"
const ROOT_SPLIT_PLAN_PATH := "res://docs/design/ROOT_SPLIT_PLAN.md"

const REQUIRED_ROOT_BOUNDARIES := [
	"TitleScreen",
	"TitleScreen/MainMenu",
	"TitleScreen/NewRunMenu",
	"RunScreen",
	"RunScreen/Combat",
	"RunScreen/RewardOverlay",
	"RunScreen/ShopOverlay",
	"RunScreen/Map",
	"RunScreen/PauseOverlay",
	"RunScreen/DialogueOverlay",
	"RunScreen/CardSelectionOverlay",
	"RunScreen/CardDraftSelectionOverlay",
]

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func test_root_split_plan_document_exists_and_names_current_entrypoint() -> void:
	var plan_text := _read_text(ROOT_SPLIT_PLAN_PATH)
	assert_true(plan_text.length() > 0, "Root 拆分前置必須有 docs/design/ROOT_SPLIT_PLAN.md，避免直接硬拆 Root.tscn")
	assert_true(plan_text.contains("res://scenes/Root.tscn"), "拆分計畫需明確保留 Root.tscn 為目前主入口")
	assert_true(plan_text.contains("不直接拆 `scenes/Root.tscn`"), "目前階段應標明先建立 guard，不立即拆場景")

func test_root_split_plan_covers_all_runtime_boundaries() -> void:
	var plan_text := _read_text(ROOT_SPLIT_PLAN_PATH)
	for boundary: String in REQUIRED_ROOT_BOUNDARIES:
		assert_true(plan_text.contains(boundary), "Root 拆分計畫應列出 runtime 邊界：%s" % boundary)

func test_root_scene_still_exposes_boundaries_before_actual_split() -> void:
	var root_text := _read_text(ROOT_SCENE_PATH)
	assert_true(root_text.length() > 0, "Root.tscn 應可讀取，作為拆分前 contract 來源")
	for boundary: String in REQUIRED_ROOT_BOUNDARIES:
		var node_name := boundary.get_slice("/", boundary.get_slice_count("/") - 1)
		assert_true(root_text.contains("name=\"%s\"" % node_name), "Root.tscn 拆分前仍應保留節點：%s" % boundary)
