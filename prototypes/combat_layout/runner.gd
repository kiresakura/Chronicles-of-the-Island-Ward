extends Node
## Phase A 截圖 runner：在多解析度渲染 CombatLayoutV2 並存 PNG。
## 用法：godot --path . res://prototypes/combat_layout/runner.tscn
## （加 COTIW_SAFE_INSET=64,20,64,44 可順帶驗 safe-area 內縮）
const LAYOUT := preload("res://prototypes/combat_layout/CombatLayoutV2.gd")
const SHOT_DIR := "res://prototypes/combat_layout/shots/"
var _frame_drawn := false
var _jig: ColorRect
var _t := 0.0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	var lay := CanvasLayer.new(); lay.layer = 120; add_child(lay)
	_jig = ColorRect.new(); _jig.color = Color(1, 1, 1, 0.01); _jig.size = Vector2(2, 2)
	_jig.mouse_filter = Control.MOUSE_FILTER_IGNORE; lay.add_child(_jig)
	RenderingServer.frame_post_draw.connect(func() -> void: _frame_drawn = true)
	await _run()
	get_tree().quit()

func _process(delta: float) -> void:
	_t += delta
	if _jig != null:
		_jig.position = Vector2(0.0, 0.5 + 0.5 * sin(_t * 60.0))

func _run() -> void:
	var res_list: Array[Vector2i] = [Vector2i(1244, 700), Vector2i(1515, 700), Vector2i(1200, 900)]
	for res in res_list:
		get_window().size = res
		await _frames(5)
		var layout: Control = LAYOUT.new()
		add_child(layout)
		await _frames(10)
		await _shot("phaseA_%dx%d" % [res.x, res.y])
		layout.queue_free()
		await _frames(4)
	print("[PHASE_A] done")

func _shot(name: String) -> void:
	_frame_drawn = false
	for i in 30:
		await get_tree().process_frame
		if _frame_drawn:
			break
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png(SHOT_DIR + name + ".png")
		print("[PHASE_A] shot ", name, " ", img.get_size())

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
