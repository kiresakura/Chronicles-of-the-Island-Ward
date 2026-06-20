extends Node

const SHOT_DIR: String = "res://qa/collection_codex/"
var _pass: int = 0
var _fail: int = 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	await _run()
	print("[COLLECTION_QA] ===== PASS=%d FAIL=%d =====" % [_pass, _fail])
	get_tree().quit(0 if _fail == 0 else 1)

func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
		print("[COLLECTION_QA][PASS] ", msg)
	else:
		_fail += 1
		print("[COLLECTION_QA][FAIL] ", msg)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(sname: String) -> void:
	await RenderingServer.frame_post_draw
	var vp: Viewport = get_viewport()
	if vp == null or vp.get_texture() == null:
		print("[COLLECTION_QA] no viewport texture, skip ", sname)
		return
	var img: Image = vp.get_texture().get_image()
	if img == null:
		print("[COLLECTION_QA] no image, skip ", sname)
		return
	img.save_png(SHOT_DIR + sname + ".png")
	print("[COLLECTION_QA] shot %s size=%s" % [sname, str(img.get_size())])

func _dump_codex_state(tag: String, codex: Node) -> void:
	var grid: GridContainer = codex.get_node_or_null("ScrollContainer/MarginContainer/CodexCardContainer")
	if grid == null:
		print("[COLLECTION_QA][%s] missing grid" % tag)
		return
	var child_count := grid.get_child_count()
	var texture_rects := 0
	var null_textures := 0
	var empty_labels := 0
	var label_count := 0
	for nd in grid.find_children("*", "TextureRect", true, false):
		if nd is TextureRect:
			texture_rects += 1
			if (nd as TextureRect).texture == null:
				null_textures += 1
	for nd2 in grid.find_children("*", "Label", true, false):
		if nd2 is Label:
			label_count += 1
			if (nd2 as Label).text.strip_edges() == "":
				empty_labels += 1
	print("[COLLECTION_QA][%s] children=%d columns=%d texture_rects=%d null_textures=%d labels=%d empty_labels=%d" % [tag, child_count, grid.columns, texture_rects, null_textures, label_count, empty_labels])
	var sample := 0
	for c in grid.get_children():
		if sample >= 12:
			break
		var texts: Array[String] = []
		var missing := 0
		for l in c.find_children("*", "Label", true, false):
			if l is Label:
				texts.append((l as Label).text)
		for tr in c.find_children("*", "TextureRect", true, false):
			if tr is TextureRect and (tr as TextureRect).texture == null:
				missing += 1
		print("[COLLECTION_QA][%s][SAMPLE] node=%s texts=%s missing_tex=%d" % [tag, c.name, str(texts), missing])
		sample += 1

func _run() -> void:
	await _frames(2)
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	await _frames(80)
	_ok(root != null, "Root 載入並進入主畫面")
	await _shot("01_main_menu")
	var title: Node = root.get_node_or_null("TitleScreen")
	_ok(title != null, "找到 TitleScreen")
	if title != null and title.has_method("show_codex_menu"):
		title.show_codex_menu()
	await _frames(30)
	var codex: Node = root.get_node_or_null("TitleScreen/CodexMenu")
	_ok(codex != null and (codex as CanvasItem).visible, "點擊收藏後 CodexMenu 顯示")
	if codex == null:
		return
	_dump_codex_state("cards", codex)
	await _shot("02_collection_cards")
	if codex.has_method("_on_tab_jiajiang"):
		codex._on_tab_jiajiang()
	await _frames(20)
	_dump_codex_state("jiajiang", codex)
	await _shot("03_collection_jiajiang")
	if codex.has_method("_on_tab_deities"):
		codex._on_tab_deities()
	await _frames(20)
	_dump_codex_state("deities", codex)
	await _shot("04_collection_deities")
