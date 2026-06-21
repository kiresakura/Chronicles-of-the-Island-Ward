extends Node
## 圖鑑佈局契約版 截圖 runner：多解析度 × 四態 渲染 CodexScreenV2 並存 PNG。
## 用法：godot --path . res://prototypes/codex_layout/runner.tscn
## （加 COTIW_SAFE_INSET=64,20,64,44 順帶驗 safe-area 內縮）
const SCREEN := preload("res://prototypes/codex_layout/CodexScreenV2.gd")
const SHOT_DIR := "res://prototypes/codex_layout/shots/"
var _frame_drawn := false

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	RenderingServer.frame_post_draw.connect(func() -> void: _frame_drawn = true)
	await _run()
	get_tree().quit()

func _run() -> void:
	# COTIW_SAFE_INSET 設定時加 _notch 後綴 → 兩套截圖並存可比對 safe-area
	var sfx := "_notch" if OS.get_environment("COTIW_SAFE_INSET") != "" else ""
	# grid 態：三斷點都跑（驗響應式欄數）
	var res_list: Array[Vector2i] = [Vector2i(1244, 700), Vector2i(1515, 700), Vector2i(1200, 900)]
	for res in res_list:
		await _one(res, "grid", 0, "grid_%dx%d%s" % [res.x, res.y, sfx])
	# 其餘狀態：在基準 1244×700 各一張
	await _one(Vector2i(1244, 700), "loading", 0, "state_loading" + sfx)
	await _one(Vector2i(1244, 700), "error", 0, "state_error" + sfx)
	await _one(Vector2i(1244, 700), "empty", 3, "state_empty" + sfx)
	await _one(Vector2i(1244, 700), "detail", 0, "state_detail" + sfx)
	print("[CODEX] done")

func _one(res: Vector2i, state: String, cat: int, shot_name: String) -> void:
	get_window().size = res
	await _frames(5)
	var screen: Control = SCREEN.new()
	screen.demo_state = state
	screen.demo_cat = cat
	add_child(screen)
	await _frames(24)  # 容 detail sheet 淡入(260ms)＋佈局沉澱
	await _shot(shot_name)
	screen.queue_free()
	await _frames(4)

func _shot(shot_name: String) -> void:
	_frame_drawn = false
	for i in 30:
		await get_tree().process_frame
		if _frame_drawn:
			break
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(SHOT_DIR + shot_name + ".png")
		print("[CODEX] shot ", shot_name, " ", img.get_size())

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
