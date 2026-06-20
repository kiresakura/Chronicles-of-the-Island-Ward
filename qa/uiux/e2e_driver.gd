extends Node
# 鎮島錄 — 實際 E2E / 視覺 QA 驅動。
# 以遊戲 API 驅動「主畫面 → 開局 → 遶境地圖 → 戰鬥」全流程，每階段渲染截圖 + console 斷言。
# 非 headless 執行才有畫面；輸出 qa/uiux/e2e/。
const SHOT_DIR: String = "res://qa/uiux/e2e/"
var _pass: int = 0
var _fail: int = 0

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)	# QA 靜音：審計不放鑼鼓
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOT_DIR))
	await _run()
	print("[E2E] ===== PASS=%d FAIL=%d =====" % [_pass, _fail])
	get_tree().quit(0 if _fail == 0 else 1)

func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
		print("[E2E][PASS] ", msg)
	else:
		_fail += 1
		print("[E2E][FAIL] ", msg)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

# 列出當前場景樹中所有「可見且可點」的按鈕（含 global 位置），用來理解導航結構
func _dump_buttons(tag: String) -> void:
	var n: int = 0
	for b: Node in get_tree().root.find_children("*", "BaseButton", true, false):
		var bb: BaseButton = b as BaseButton
		if bb == null or not bb.is_visible_in_tree():
			continue
		var txt: String = ""
		if bb is Button:
			txt = (bb as Button).text
		var gpos: Vector2 = (bb as Control).global_position if bb is Control else Vector2.ZERO
		print("[E2E][BTN][%s] name=%s text=%s pos=%s parent=%s" % [tag, bb.name, txt, str(gpos), bb.get_parent().name])
		n += 1
	print("[E2E][BTN][%s] 可見按鈕共 %d 個" % [tag, n])

# 列出 Combat 子樹中「中左區 / 大型」可見節點，找出遮擋乩童的元素
func _dump_combat_sprites(combat_node: Node) -> void:
	if combat_node == null:
		return
	for nd: Node in combat_node.find_children("*", "", true, false):
		if nd is CanvasItem and not (nd as CanvasItem).is_visible_in_tree():
			continue
		var gpos: Vector2 = Vector2.ZERO
		var info: String = ""
		if nd is Node2D:
			gpos = (nd as Node2D).global_position
		elif nd is Control:
			gpos = (nd as Control).global_position
		else:
			continue
		# 只看中左帶（x 40-460, y 150-470）— 乩童立繪所在
		if gpos.x < 40.0 or gpos.x > 460.0 or gpos.y < 150.0 or gpos.y > 470.0:
			continue
		if nd is Sprite2D and (nd as Sprite2D).texture != null:
			var s: Sprite2D = nd as Sprite2D
			info = "Sprite2D tex=%s texsize=%s scale=%s" % [s.texture.resource_path, str(s.texture.get_size()), str(s.scale)]
		elif nd is AnimatedSprite2D:
			info = "AnimatedSprite2D anim=%s" % (nd as AnimatedSprite2D).animation
		elif nd is TextureRect and (nd as TextureRect).texture != null:
			info = "TextureRect tex=%s size=%s" % [(nd as TextureRect).texture.resource_path, str((nd as TextureRect).size)]
		elif nd is Control:
			var c: Control = nd as Control
			info = "Control(%s) size=%s meta_bagua=%s" % [nd.get_class(), str(c.size), str(c.has_meta("is_circular_bagua"))]
		if info != "":
			print("[E2E][SPR] %s gpos=%s | %s | parent=%s" % [nd.name, str(gpos), info, nd.get_parent().name])

# 列出 RunScreen 下方的子畫面與可見性，理解「哪個畫面在前」
func _dump_runscreen(root: Node) -> void:
	var rs: Node = root.get_node_or_null("RunScreen")
	if rs == null:
		print("[E2E][NAV] 找不到 RunScreen")
		return
	for c: Node in rs.get_children():
		var vis: String = "?"
		if c is CanvasItem:
			vis = str((c as CanvasItem).visible)
		print("[E2E][NAV] RunScreen/%s type=%s visible=%s" % [c.name, c.get_class(), vis])

func _shot(sname: String) -> void:
	await get_tree().process_frame
	RenderingServer.force_draw()	# 防視窗遮擋時 frame_post_draw 不發
	var vp: Viewport = get_viewport()
	if vp == null:
		print("[E2E] no viewport, skip ", sname)
		return
	var tex: ViewportTexture = vp.get_texture()
	if tex == null:
		print("[E2E] no viewport texture (headless?), skip ", sname)
		return
	var img: Image = tex.get_image()
	if img == null:
		print("[E2E] no image, skip ", sname)
		return
	img.save_png(SHOT_DIR + sname + ".png")
	var nonblack: bool = false
	var w: int = img.get_width()
	var h: int = img.get_height()
	for p: Vector2i in [Vector2i(w / 2, h / 2), Vector2i(40, 40), Vector2i(w - 40, h - 40), Vector2i(w / 2, 60)]:
		if img.get_pixelv(p).v > 0.06:
			nonblack = true
	print("[E2E] shot %s size=%s nonblack=%s" % [sname, str(img.get_size()), nonblack])

func _run() -> void:
	# 先讓 SceneTree 完成主場景（driver 自身）掛載，避免 "Parent node is busy setting up children"
	await get_tree().process_frame
	await get_tree().process_frame
	CotiwUiTheme.use_card_frame_v2 = true	# P1：示範 — 讓本次戰鬥手牌用 v2 符令框（live 預設 false）
	# 1) 載入 Root → 主畫面
	var root: Node = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(root)
	# Q0-1：等主選單可互動（取代固定 70 幀，消啟動競態）
	var mm: Node = root.get_node_or_null("TitleScreen/MainMenu")
	for i: int in 900:
		await get_tree().process_frame
		if mm == null:
			mm = root.get_node_or_null("TitleScreen/MainMenu")
			continue
		if not (mm as CanvasItem).visible:
			continue
		var nbtn: int = 0
		for b: Node in mm.find_children("*", "BaseButton", true, false):
			if (b as BaseButton).is_visible_in_tree():
				nbtn += 1
		if nbtn >= 10:
			break
	await _frames(5)
	_ok(root != null, "Root 載入（主畫面）")
	_ok(TranslationServer.get_locale().begins_with("zh"), "locale=%s（應 zh_TW）" % TranslationServer.get_locale())
	_ok(TranslationServer.translate("battle.victory") == "鎮煞成功", "i18n 解析 battle.victory=鎮煞成功")
	_ok(TranslationServer.translate("ui.leave") == "離開", "i18n 解析 ui.leave=離開")
	await _shot("01_main_menu")

	# 2) 開一局 run（乩童）→ 起手選項（boon）畫面（start_run 已生成世界）
	Global.start_run("character_tongji", 20260607)
	await _frames(30)
	_ok(Global.is_run, "start_run → is_run=true")
	_ok(Global.get_run_active_deity_id() == "deity_tiger_god", "乩童出戰神明 = 虎爺（loadout 解析）")
	var locs: Array = Global.get_all_act_locations()
	_ok(locs.size() >= 10, "遶境地圖節點數 = %d" % locs.size())
	var has_boss: bool = false
	var has_route_flavor: bool = false
	for l: Variant in locs:
		var loc: LocationData = l as LocationData
		if loc.location_type == LocationData.LOCATION_TYPES.BOSS:
			has_boss = true
		if loc.location_route_flavor != "":
			has_route_flavor = true
	_ok(has_boss, "地圖含鎮煞大醮（BOSS）")
	_ok(has_route_flavor, "節點帶遶境路線 flavor")
	await _shot("02_run_start_boon")

	# 3) 點「起手選項」→ 真實導航進入遶境地圖
	# 走真實 signal 路徑（dialogue_option_clicked，等同點擊）；選「即時效果」選項（index 1），
	# 避開第 1 項「選一張普通卡加入牌組」會開卡牌選擇 overlay 而阻塞。用輪詢等地圖出現（不 await handler）。
	var rso: Node = root.get_node_or_null("RunScreen/RunStartOptions")
	var map_node: Node = root.get_node_or_null("RunScreen/Map")
	_ok(rso != null and (rso as CanvasItem).visible, "起手選項（RunStartOptions）顯示中")
	var advanced: bool = false
	if rso != null:
		var container: Node = rso.get_node_or_null("StartingOptionContainer")
		var pick_idx: int = 1 if (container != null and container.get_child_count() > 1) else 0
		if container != null and container.get_child_count() > pick_idx:
			var opt: DialogueOption = container.get_child(pick_idx) as DialogueOption
			if opt != null:
				opt.dialogue_option_clicked.emit(opt)
				advanced = true
	for i: int in 300:	# Q2-B 擲筊節拍 1.15s；120Hz 下 120 幀只有 1s → 放寬輪詢上限
		await get_tree().process_frame
		if map_node != null and (map_node as CanvasItem).visible:
			break
	await get_tree().create_timer(0.35).timeout	# 站照防漂移：擲筊層尾巴收完再拍
	_ok(advanced and map_node != null and (map_node as CanvasItem).visible, "選起手選項後 → 遶境地圖顯示")
	await _shot("03_pilgrimage_map")

	# 4) 點一個「戰」節點 → 真實 visit-location 導航進入巡境遇煞
	var cur: LocationData = Global.get_player_location_data()
	var combat_id: String = ""
	for l: Variant in locs:
		var loc2: LocationData = l as LocationData
		if loc2.location_type == LocationData.LOCATION_TYPES.COMBAT and cur != null and cur.location_next_location_ids.has(loc2.location_id):
			combat_id = loc2.location_id
			break
	if combat_id == "":
		for l2: Variant in locs:
			if (l2 as LocationData).location_type == LocationData.LOCATION_TYPES.COMBAT:
				combat_id = (l2 as LocationData).location_id
				break
	_ok(combat_id != "", "找到可進入的『戰』節點 id=%s" % combat_id)
	if combat_id != "":
		ActionGenerator.generate_visit_location(combat_id)
		if ActionHandler.actions_being_performed:
			await ActionHandler.actions_ended
	await _frames(60)
	var combat_node: Node = root.get_node_or_null("RunScreen/Combat")
	_ok(combat_node != null and (combat_node as CanvasItem).visible, "戰鬥畫面顯示中")
	# v0.3 換骨：五營戰鬥畫面（取代卡牌敵人/煞盾/手牌）
	var fview: Object = combat_node.get("_formation_view") if combat_node != null else null
	_ok(fview != null and (fview as CanvasItem).visible, "五營戰鬥畫面顯示中")
	var fcore: Object = fview.get("_core") if fview != null else null
	_ok(fcore != null and fcore.camps.size() == 5, "五營佈陣：5 營就緒 = %d" % [fcore.camps.size() if fcore != null else 0])
	_ok(fcore != null and fcore.altar_max > 0, "母壇就緒 integrity = %d" % [fcore.altar_integrity if fcore != null else 0])
	await _shot("04_combat_enter")

	# 5) 符令手牌已抽出（取代卡牌手牌）
	for i: int in 120:
		await get_tree().process_frame
		if fcore != null and fcore.fu_hand.size() > 0:
			break
	_ok(fcore != null and fcore.fu_hand.size() > 0, "符令手牌已抽出 = %d 張" % [fcore.fu_hand.size() if fcore != null else 0])
	await _frames(25)
	await _shot("05_combat_hand")
	# 追查：中左大型元素是哪個節點（八卦盤遮乩童）
	_dump_combat_sprites(combat_node)

	# 6) UIQA 實況：combat toast 顯示在 safe-area 頂部 lane（不遮敵/手牌/請神槽）
	if combat_node != null and combat_node.has_method("show_combat_toast"):
		combat_node.show_combat_toast("合符！")
		await _frames(25)
		await _shot("06_combat_toast")

	# 7) P0-4 合符 FX 實況：注入兩張攻拳 → merge_cards → 截 FX 峰值
	var hand_node: Node = combat_node.get_node_or_null("Hand") if combat_node != null else null
	if hand_node != null and hand_node.has_method("merge_cards"):
		var a: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
		var b: CardData = Global.get_card_data_from_prototype("card_tongji_punch")
		var pair: Array[CardData] = [a, b]
		Global.player_data.player_hand = pair
		var created: Array = hand_node.create_cards(pair)
		if created.size() >= 2:
			hand_node.card_data_to_hand_card[a] = created[0]
			hand_node.card_data_to_hand_card[b] = created[1]
		hand_node.hand_disabled = false
		hand_node._merges_used_this_turn = 0
		var merged: bool = hand_node.merge_cards(a, b)
		_ok(merged, "合符成功（觸發 FuheFX）")
		await _frames(8)	# FX 峰值（~0.13s）
		await _shot("07_fuhe_fx")

	# 8) P0-3 卡框 v2 預覽板（五稀有度並排）
	await _shot_card_frames_v2()

	# 9-11) 收藏（圖鑑）三分頁：過濾後卡牌 / 家將 / 神明
	await _shot_codex(root)
	# Q0-2：釋放 Root 消 exit leak 噪音
	root.queue_free()
	await _frames(10)
	print("[E2E] flow done")

func _shot_card_frames_v2() -> void:
	var board := ColorRect.new()
	board.name = "CardFrameV2Board"
	board.color = Color(0.11, 0.07, 0.06, 1.0)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(board)
	var keys: Array = ["common", "uncommon", "rare", "boss", "curse"]
	var labels: Array = ["共通", "進階", "稀有", "神威", "咒煞"]
	var title := Label.new()
	title.text = "符令卡框 v2（共通 / 進階 / 稀有 / 神威 / 咒煞）"
	title.position = Vector2(70, 70)
	title.add_theme_font_size_override("font_size", 34)
	board.add_child(title)
	var x: float = 80.0
	for i: int in keys.size():
		var path: String = "res://assets/ui/frames_v2/ui_frame_card_%s_anime.svg" % keys[i]
		if ResourceLoader.exists(path):
			var tr := TextureRect.new()
			tr.texture = load(path)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			tr.size = Vector2(200, 300)
			tr.position = Vector2(x, 190)
			board.add_child(tr)
		var lbl := Label.new()
		lbl.text = labels[i]
		lbl.position = Vector2(x + 78, 156)
		lbl.add_theme_font_size_override("font_size", 26)
		board.add_child(lbl)
		x += 232.0
	await _frames(10)
	await _shot("08_card_frames_v2")
	board.queue_free()
	await _frames(3)


# 收藏（圖鑑）三分頁驗收：卡牌過濾（無 STR legacy 污染）、家將 8 尊、神明 6 尊
func _shot_codex(root: Node) -> void:
	var ts: CanvasItem = root.get_node_or_null("TitleScreen") as CanvasItem
	var codex: Node = root.get_node_or_null("TitleScreen/CodexMenu")
	if ts == null or codex == null:
		_ok(false, "找不到 TitleScreen/CodexMenu")
		return
	var rs: CanvasItem = root.get_node_or_null("RunScreen") as CanvasItem
	if rs != null:
		rs.visible = false
	ts.visible = true
	for c: Node in ts.get_children():
		if c is CanvasItem:
			(c as CanvasItem).visible = (c == codex)
	codex.call("populate_codex_menu")
	await _frames(20)
	var grid: Node = codex.get_node_or_null("ScrollContainer/MarginContainer/CodexCardContainer")
	var n_cards: int = grid.get_child_count() if grid != null else -1
	_ok(n_cards >= 30 and n_cards <= 40, "收藏卡牌頁過濾後=%d 張（30–40，無 legacy 污染）" % n_cards)
	await _shot("09_codex_cards")
	codex.call("_on_tab_jiajiang")
	await _frames(15)
	var n_jj: int = grid.get_child_count() if grid != null else -1
	_ok(n_jj == 8, "家將分頁=8 尊（實際 %d）" % n_jj)
	await _shot("10_codex_jiajiang")
	codex.call("_on_tab_deities")
	await _frames(15)
	var n_d: int = grid.get_child_count() if grid != null else -1
	_ok(n_d == 6, "神明分頁=6 尊（實際 %d）" % n_d)
	await _shot("11_codex_deities")
