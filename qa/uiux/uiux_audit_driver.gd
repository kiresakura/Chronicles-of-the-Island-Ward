extends Node
# 鎮島錄 — UI/UX 嚴格審計 driver
# 走訪所有可達畫面；每站執行五類檢查 + 截圖：
#   TAP     觸控目標：短邊 <64 邏輯px=FAIL（≈35pt 實機）、<80=WARN（44pt Apple HIG）
#   OOB     可互動元件出視口（以裁切後有效矩形計）
#   SAFE    可互動元件超出 CotiwUiTheme safe-area
#   OVERLAP 可見按鈕 pairwise 重疊 >25%（非祖孫；排除全螢幕捕捉鈕）
#   CLIP    Label 需求寬 > 實際寬（無 autowrap/clip → 視覺溢出）
# 雜訊規則：
#   - 祖先鏈上有 clip_contents/ScrollContainer → 取交集為有效矩形；摺疊外（<4px²）整顆跳過
#   - 有效面積 ≥ 視口 55% 視為「捕捉鈕」（deselect/背景層）：僅記 INFO，不進 TAP/OVERLAP/SAFE/OOB
# 解析度：環境變數 UIUX_RES（"1244x700" 16:9 / "1515x700" 19.5:9 / "1200x900" 4:3）
# 輸出：qa/uiux/uiux_audit/<res>/NN_tag.png + [UIUX] console 行
const MIN_TAP_FAIL := 64.0
const MIN_TAP_WARN := 80.0
const CATCHER_VP_RATIO := 0.55

var shot_dir: String
var res_tag: String = "1244x700"
var _pass: int = 0
var _warn: int = 0
var _fail: int = 0
var _shot_count: int = 0
var _root: Node = null
var _frame_drawn: bool = false
var _jiggle: ColorRect = null
var _jig_t: float = 0.0

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)	# QA 靜音：審計不放鑼鼓
	var env: String = OS.get_environment("UIUX_RES")
	if env != "":
		res_tag = env
	var parts: PackedStringArray = res_tag.split("x")
	get_window().size = Vector2i(int(parts[0]), int(parts[1]))
	shot_dir = "res://qa/uiux/uiux_audit/%s/" % res_tag
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(shot_dir))
	# 強制持續重繪的隱形微動節點（防止靜止畫面停繪 → frame_post_draw 不發）
	var lay := CanvasLayer.new()
	lay.layer = 120
	add_child(lay)
	_jiggle = ColorRect.new()
	_jiggle.color = Color(1, 1, 1, 0.01)
	_jiggle.size = Vector2(2, 2)
	_jiggle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lay.add_child(_jiggle)
	RenderingServer.frame_post_draw.connect(func() -> void: _frame_drawn = true)
	await _walk()
	# Q0-1 自測旋鈕：驗證守門 exit code 路徑（CI self-test 用）
	if OS.get_environment("UIUX_SELFTEST_FAIL") == "1":
		_emit("FAIL", "selftest", "SELFTEST", "UIUX_SELFTEST_FAIL=1 注入的合成失敗")
	print("[UIUX] ===== %s 完成 PASS=%d WARN=%d FAIL=%d shots=%d =====" % [res_tag, _pass, _warn, _fail, _shot_count])
	# Q0-2：退場前釋放實例化的 Root，消除 ObjectDB/resource leak 噪音
	if _root != null:
		_root.queue_free()
		_root = null
	await _frames(10)
	# Q0-1 守門：有 FAIL 必須紅（quit(1)），否則不配叫守門員
	get_tree().quit(1 if _fail > 0 else 0)

func _process(delta: float) -> void:
	_jig_t += delta
	if _jiggle != null:
		_jiggle.position = Vector2(0.0, 0.5 + 0.5 * sin(_jig_t * 60.0))

# ---------- 基礎工具 ----------

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

## Q0-1：啟動競態根治 — 等主選單真的可互動（visible + 按鈕數達標）才進站，
## 取代固定 _frames(70)（曾在 1200×900 首跑造成 transient false fail）
func _wait_main_menu_ready(root: Node, min_buttons: int = 10, max_frames: int = 900) -> void:
	var mm: Node = root.get_node_or_null("TitleScreen/MainMenu")
	for i: int in max_frames:
		await get_tree().process_frame
		if mm == null:
			mm = root.get_node_or_null("TitleScreen/MainMenu")
			continue
		if not (mm as CanvasItem).visible:
			continue
		var n: int = 0
		for b: Node in mm.find_children("*", "BaseButton", true, false):
			if (b as BaseButton).is_visible_in_tree() and not (b as BaseButton).disabled:
				n += 1
		if n >= min_buttons:
			await _frames(5)	# 佈局穩定緩衝
			print("[UIUX] main menu ready（%d 顆可互動，第 %d 幀）" % [n, i])
			return
	print("[UIUX] WARN: main menu ready 輪詢逾時（%d 幀），照常進站" % max_frames)

func _emit(sev: String, tag: String, kind: String, msg: String) -> void:
	if sev == "FAIL":
		_fail += 1
	elif sev == "WARN":
		_warn += 1
	print("[UIUX][%s][%s][%s] %s" % [sev, tag, kind, msg])

func _np(n: Node) -> String:
	var p: String = str(n.get_path())
	return p.replace("/root/QaUiUxAudit/", "").replace("/root/", "")

func _btn_desc(b: BaseButton) -> String:
	var txt: String = ""
	if b is Button:
		txt = (b as Button).text.substr(0, 10)
	return "%s(%s)" % [_np(b), txt]

func _shot(sname: String) -> void:
	# 視窗被遮擋時 macOS 抑制重繪 → frame_post_draw 不發、空等造成遊戲狀態飄移
	# → 改 force_draw() 同步強制渲染，截圖確定性 + 零等待
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw()
	var img: Image = get_viewport().get_texture().get_image()
	if img == null:
		print("[UIUX] no image, skip ", sname)
		return
	img.save_png(shot_dir + sname + ".png")
	_shot_count += 1
	print("[UIUX] shot %s/%s size=%s" % [res_tag, sname, str(img.get_size())])

# ---------- 審計核心 ----------

## 沿祖先鏈把 clip_contents / ScrollContainer 的裁切交集進來，回傳有效可見矩形
func _effective_rect(c: Control) -> Rect2:
	var r: Rect2 = c.get_global_rect()
	var p: Node = c.get_parent()
	while p != null:
		if p is Control:
			var pc: Control = p as Control
			if pc.clip_contents or pc is ScrollContainer:
				r = r.intersection(pc.get_global_rect())
		p = p.get_parent()
	return r

func _audit(tag: String, scope: Node = null) -> void:
	var vp: Rect2 = get_viewport().get_visible_rect()
	var safe: Rect2 = CotiwUiTheme.get_safe_content_rect(get_viewport())
	var vp_area: float = vp.get_area()
	var root_scan: Node = scope if scope != null else get_tree().root
	var items: Array = []	# [BaseButton, eff_rect]
	for n: Node in root_scan.find_children("*", "BaseButton", true, false):
		var b: BaseButton = n as BaseButton
		if b == null or not b.is_visible_in_tree() or b.disabled:
			continue
		var raw: Rect2 = (b as Control).get_global_rect()
		if raw.size.x < 2.0 or raw.size.y < 2.0:
			continue
		var eff: Rect2 = _effective_rect(b)
		if eff.get_area() < 4.0:
			continue	# 摺疊/完全裁切 → 非當前觸控目標
		if eff.get_area() >= CATCHER_VP_RATIO * vp_area:
			print("[UIUX][INFO][%s][CATCHER] %s rect=%s（全螢幕捕捉鈕，排除於 TAP/OVERLAP）" % [tag, _btn_desc(b), str(raw)])
			continue
		items.append([b, eff])
		var mind: float = minf(eff.size.x, eff.size.y)
		# 寬列控件（勾選列/下拉列，寬 ≥3× 高）採列高標準：<40 FAIL、<48 WARN（Apple 44pt 列）
		var is_wide_row: bool = eff.size.x >= 3.0 * eff.size.y
		var t_fail: float = 40.0 if is_wide_row else MIN_TAP_FAIL
		var t_warn: float = 48.0 if is_wide_row else MIN_TAP_WARN
		if mind < t_fail:
			_emit("FAIL", tag, "TAP", "%s 短邊 %.0fpx（<%.0f）rect=%s" % [_btn_desc(b), mind, t_fail, str(eff)])
		elif mind < t_warn:
			_emit("WARN", tag, "TAP", "%s 短邊 %.0fpx（<%.0f）" % [_btn_desc(b), mind, t_warn])
		else:
			_pass += 1
		var inter: Rect2 = vp.intersection(eff)
		var off_ratio: float = 1.0 - (inter.get_area() / maxf(eff.get_area(), 1.0))
		var is_hand_card: bool = str(b.get_path()).contains("/Hand/")
		if is_hand_card and off_ratio <= 0.25:
			pass	# 手牌扇形刻意微出下緣（by-design），≤25% 豁免
		elif off_ratio > 0.02:
			_emit("FAIL", tag, "OOB", "%s 出視口 %.0f%% rect=%s vp=%s" % [_btn_desc(b), off_ratio * 100.0, str(eff), str(vp)])
		else:
			var sinter: Rect2 = safe.intersection(eff)
			var soff: float = 1.0 - (sinter.get_area() / maxf(eff.get_area(), 1.0))
			if soff > 0.05:
				var _strict: bool = OS.get_environment("COTIW_SAFE_INSET") != ""
				_emit("FAIL" if _strict else "WARN", tag, "SAFE", "%s 超出 safe-area %.0f%%（safe=%s）" % [_btn_desc(b), soff * 100.0, str(safe)])
			else:
				_pass += 1
	# pairwise 重疊（以有效矩形）
	for i: int in items.size():
		for j: int in range(i + 1, items.size()):
			var a: Control = items[i][0] as Control
			var c: Control = items[j][0] as Control
			if a.is_ancestor_of(c) or c.is_ancestor_of(a):
				continue
			var ra: Rect2 = items[i][1]
			var rc: Rect2 = items[j][1]
			var ov: Rect2 = ra.intersection(rc)
			if ov.get_area() > 0.25 * minf(ra.get_area(), rc.get_area()):
				var benign: bool = false
				for bn: String in ["MascotButton", "LanternHot"]:
					if str(a.name) == bn or str(c.name) == bn:
						benign = true
				if benign:
					print("[UIUX][INFO][%s][OVERLAP-BENIGN] %s × %s（裝飾點擊區，輸入由後繪者接收）" % [tag, _btn_desc(items[i][0]), _btn_desc(items[j][0])])
				else:
					_emit("FAIL", tag, "OVERLAP", "%s × %s 重疊 %.0f%%" % [_btn_desc(items[i][0]), _btn_desc(items[j][0]), 100.0 * ov.get_area() / minf(ra.get_area(), rc.get_area())])
	# Label 截字（需求寬 > 實際寬；排除 autowrap/clip/空字/被裁切）
	for n: Node in root_scan.find_children("*", "Label", true, false):
		var l: Label = n as Label
		if l == null or not l.is_visible_in_tree():
			continue
		if l.clip_text or l.autowrap_mode != TextServer.AUTOWRAP_OFF or l.max_lines_visible > 0:
			continue
		if l.text.strip_edges() == "":
			continue
		var eff_l: Rect2 = _effective_rect(l)
		if eff_l.get_area() < 4.0:
			continue
		var need: Vector2 = l.get_minimum_size()
		var r2: Rect2 = l.get_global_rect()
		if need.x > r2.size.x + 2.0:
			_emit("WARN", tag, "CLIP", "Label「%s…」需 %.0fpx 實 %.0fpx @%s" % [l.text.substr(0, 12), need.x, r2.size.x, _np(l)])
	print("[UIUX][AUDIT] %s/%s 可互動按鈕 %d 顆" % [res_tag, tag, items.size()])

func _station(tag: String, scope: Node = null, modal: bool = false) -> void:
	await _frames(8)
	# 時序根治（Q4-E 暴露）：固定幀緩衝會賭「發牌/overlay 建構在 N 幀內完成」—
	# 紋理上傳、BGM 解碼等正當變更移動時序就 transient FAIL。
	# 改等子樹版面真正靜止（連續 3 幀 Control rect 不變；4px 量化容忍 jiggle 微動畫）
	await _wait_subtree_stable(scope if scope != null else _root)
	_covisible_info(tag)
	if modal and scope is Control:
		_modal_check(tag, scope as Control)
	_audit(tag, scope)
	await _shot(tag)

## 等 scope 子樹版面靜止（上限 120 幀 ≈2s — 永動畫面保底退出，不卡站）。
func _wait_subtree_stable(scope: Node, stable_needed: int = 3, max_frames: int = 120) -> void:
	if scope == null:
		return
	var last_hash: int = -1
	var stable: int = 0
	for i: int in max_frames:
		await get_tree().process_frame
		var h: int = _layout_hash(scope)
		if h == last_hash:
			stable += 1
			if stable >= stable_needed:
				return
		else:
			stable = 0
			last_hash = h

## 子樹可見 Control 的 rect 雜湊（4px 量化 — jiggle 0.5px 級微動不擾動）。
func _layout_hash(scope: Node) -> int:
	var acc: int = 0
	var stack: Array[Node] = [scope]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Control and (n as Control).visible:
			var c: Control = n as Control
			var gp: Vector2 = c.global_position
			acc = (acc * 31 + int(gp.x / 4.0)) & 0x3FFFFFFF
			acc = (acc * 31 + int(gp.y / 4.0)) & 0x3FFFFFFF
			acc = (acc * 31 + int(c.size.x / 4.0)) & 0x3FFFFFFF
		for ch: Node in n.get_children():
			stack.push_back(ch)
	return acc

## 等 overlay 真的開（visit 非同步）；等不到就 populate fallback；回傳最終是否可見
func _ensure_overlay_open(ov: Node, populate_method: String) -> bool:
	for i: int in 300:
		await get_tree().process_frame
		if ov != null and (ov as CanvasItem).visible:
			return true
	if ov != null and populate_method != "" and ov.has_method(populate_method):
		ov.call(populate_method)
		(ov as CanvasItem).visible = true
		await _frames(15)
		return true
	return ov != null and (ov as CanvasItem).visible

## overlay 必須有全幅 mouse_filter=STOP 輸入遮罩，否則底層畫面吃得到點擊（穿透事故）
func _modal_check(tag: String, overlay: Control) -> void:
	# 隱藏中的 overlay 沒有顯示＝沒有模態＝沒有點穿風險 → 不適用，跳過（修假性 FAIL）
	if overlay == null or not overlay.is_visible_in_tree():
		return
	var vp: Rect2 = get_viewport().get_visible_rect()
	var found: bool = false
	var stop_count: int = 0
	var best_cov: float = 0.0
	var stack: Array = [overlay]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		if nd is Control:
			var c: Control = nd as Control
			if c.is_visible_in_tree() and c.mouse_filter == Control.MOUSE_FILTER_STOP:
				stop_count += 1
				var r: Rect2 = c.get_global_rect()
				var cov: float = vp.intersection(r).get_area() / maxf(vp.get_area(), 1.0)
				best_cov = maxf(best_cov, cov)
				if cov >= 0.95:
					found = true
					break
		for ch: Node in nd.get_children():
			stack.append(ch)
	if found:
		_pass += 1
	else:
		_emit("FAIL", tag, "MODAL", "%s 無全幅 STOP 輸入遮罩（STOP子=%d 最大覆蓋=%.0f%% vis=%s）— 底層按鈕可能吃到點擊" % [overlay.name, stop_count, best_cov * 100.0, str(overlay.visible)])

## 同時 visible 的頂層畫面（被 overlay 蓋住仍渲染 → 手機 GPU 浪費觀察）
func _covisible_info(tag: String) -> void:
	var names: Array = []
	var rs: Node = _root.get_node_or_null("RunScreen") if _root != null else null
	if rs != null:
		for c: Node in rs.get_children():
			if c is CanvasItem and (c as CanvasItem).visible:
				names.append(c.name)
	var tsn: Node = _root.get_node_or_null("TitleScreen") if _root != null else null
	if tsn != null and (tsn as CanvasItem).visible:
		names.append("TitleScreen")
	if names.size() > 1:
		print("[UIUX][INFO][%s][COVIS] 同時 visible 畫面 %d：%s" % [tag, names.size(), str(names)])

# ---------- 走訪 ----------

func _walk() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_root = load("res://scenes/Root.tscn").instantiate()
	get_tree().root.add_child(_root)
	await _wait_main_menu_ready(_root)

	var ts: Node = _root.get_node_or_null("TitleScreen")
	var mm: Node = _root.get_node_or_null("TitleScreen/MainMenu")

	# 01 主選單
	await _station("01_main_menu", ts)

	# 02 角色面板
	if ts != null and ts.has_method("show_character_panel"):
		ts.call("show_character_panel")
		await _frames(5)
		var cpanel: Node = _root.get_node_or_null("TitleScreen/CharacterPanel")
		await _station("02_character_panel", cpanel if cpanel != null else ts, cpanel != null)
		ts.call("show_main_menu")
		await _frames(5)

	# 03 看板娘選擇器
	if mm != null and mm.has_method("show_mascot_selector"):
		mm.call("show_mascot_selector")
		await _frames(5)
		var msel0: Node = mm.get_node_or_null("MascotSelector")
		await _station("03_mascot_selector", msel0 if msel0 != null else ts, msel0 != null)
		var msel: Node = mm.get_node_or_null("MascotSelector")
		if msel != null:
			(msel as CanvasItem).visible = false
		await _frames(5)

	# 04 新開局選單（含護壇/法器 picker）
	if ts != null and ts.has_method("show_new_run_menu"):
		ts.call("show_new_run_menu")
		await _frames(5)
		var nrm: Node = _root.get_node_or_null("TitleScreen/NewRunMenu")
		await _station("04_new_run_menu", nrm if nrm != null else ts, nrm != null)

	# 05-07 收藏三分頁
	if ts != null and ts.has_method("show_codex_menu"):
		ts.call("show_codex_menu")
		await _frames(20)
		var codex: Node = _root.get_node_or_null("TitleScreen/CodexMenu")
		await _station("05_codex_cards", codex if codex != null else ts, codex != null)
		if codex != null:
			codex.call("_on_tab_jiajiang")
			await _station("06_codex_jiajiang", codex, true)
			codex.call("_on_tab_deities")
			await _station("07_codex_deities", codex, true)

	# 08 開局 → 神示供桌
	Global.start_run("character_tongji", 20260610)
	await _frames(30)
	await _station("08_boon_altar", _root.get_node_or_null("RunScreen/RunStartOptions"), true)

	# 09 選即時效果選項 → 遶境地圖
	var rso: Node = _root.get_node_or_null("RunScreen/RunStartOptions")
	var map_node: Node = _root.get_node_or_null("RunScreen/Map")
	if rso != null:
		var container: Node = rso.get_node_or_null("StartingOptionContainer")
		var pick_idx: int = 1 if (container != null and container.get_child_count() > 1) else 0
		if container != null and container.get_child_count() > pick_idx:
			var opt: DialogueOption = container.get_child(pick_idx) as DialogueOption
			if opt != null:
				opt.dialogue_option_clicked.emit(opt)
	var draft0: Node = _root.get_node_or_null("RunScreen/CardDraftSelectionOverlay")
	for i: int in 300:	# Q2-B 擲筊節拍 1.15s；120Hz 下 120 幀只有 1s → 放寬輪詢上限
		await get_tree().process_frame
		if map_node != null and (map_node as CanvasItem).visible:
			break
		if draft0 != null and (draft0 as CanvasItem).visible:
			break
	# 站照防漂移：等 RSO 真正隱藏 + 擲筊層尾巴（1.35s-1.15s）收完再拍（wall-clock，幀率無關）
	for i: int in 120:
		await get_tree().process_frame
		if rso == null or not (rso as CanvasItem).visible:
			break
	await get_tree().create_timer(0.35).timeout
	# 起手選項可能開「媽祖賜禮」卡選 → 當正式一站審計，再點略過離開
	if draft0 != null and (draft0 as CanvasItem).visible:
		await _station("09a_boon_draft", draft0, true)
		var skip_btn: BaseButton = null
		for n: Node in draft0.find_children("*", "BaseButton", true, false):
			if n is Button and ((n as Button).text.contains("略過") or str(n.name).to_lower().contains("skip")):
				skip_btn = n
				break
		if skip_btn != null:
			skip_btn.button_up.emit()
			print("[UIUX] 09a：點略過離開賜禮")
		else:
			(draft0 as CanvasItem).visible = false
			print("[UIUX] 09a：找不到略過鈕，強制隱藏")
		for i: int in 120:
			await get_tree().process_frame
			if map_node != null and (map_node as CanvasItem).visible:
				break
	await _station("09_map", map_node)

	# 10-11 進戰鬥 + 手牌
	var locs: Array = Global.get_all_act_locations()
	var combat_node: Node = _root.get_node_or_null("RunScreen/Combat")
	var combat_id: String = _find_loc_id(locs, LocationData.LOCATION_TYPES.COMBAT, [])
	if combat_id != "":
		ActionGenerator.generate_visit_location(combat_id)
		for i: int in 600:
			await get_tree().process_frame
			if not ActionHandler.actions_being_performed:
				break
	await _frames(60)
	await _station("10_combat_enter", combat_node)
	for i: int in 240:
		await get_tree().process_frame
		if Global.player_data.player_hand.size() > 0:
			break
	await _frames(25)
	await _station("11_combat_hand", combat_node)

	# 12 長按細節 overlay（TouchFeedback.make_detail_overlay）
	if Global.player_data.player_hand.size() > 0 or Global.player_data.player_deck.size() > 0:
		var payload: CardData = Global.player_data.player_hand[0] if Global.player_data.player_hand.size() > 0 else Global.player_data.player_deck[0]
		var detail: Panel = TouchFeedback.make_detail_overlay(payload)
		if detail != null:
			get_tree().root.add_child(detail)
			# 鏡像真實長按路徑：以第一張手牌為目標就近定位（先前 (0,0) 為合成用法產物）
			var anchor_card: Node = null
			for n: Node in combat_node.find_children("*", "BaseButton", true, false):
				if str(n.get_path()).contains("/Hand/"):
					anchor_card = n
					break
			if anchor_card is Control:
				TouchFeedback.position_detail_overlay(detail, anchor_card as Control)
			await _station("12_touch_detail", detail)
			detail.queue_free()
			await _frames(3)
		else:
			print("[UIUX][SKIP] 12_touch_detail：make_detail_overlay 回 null")
	else:
		print("[UIUX][SKIP] 12_touch_detail：手牌與牌庫皆空")

	# 13 combat toast
	if combat_node != null and combat_node.has_method("show_combat_toast"):
		combat_node.call("show_combat_toast", "合符！")
		await _station("13_combat_toast", combat_node)

	# 14 暫停 overlay
	var pause0: Node = _root.get_node_or_null("RunScreen/PauseOverlay")
	Global.pause_game()
	await _station("14_pause", pause0, true)
	Global.unpause_game()
	if pause0 != null:
		(pause0 as CanvasItem).visible = false
	await _frames(5)

	# 15 勝利 → 獎勵 overlay（殺光敵人走真實 combat_ended 流程）
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if e.has_method("damage"):
			e.call("damage", 9999, true)
			await _frames(10)
	var reward: Node = _root.get_node_or_null("RunScreen/RewardOverlay")
	for i: int in 600:
		await get_tree().process_frame
		if reward != null and (reward as CanvasItem).visible:
			break
	await _frames(20)
	await _station("15_reward", reward, true)

	# 16 卡牌獎勵 draft（點真實 CardRewardButton）
	var draft_overlay: Node = _root.get_node_or_null("RunScreen/CardDraftSelectionOverlay")
	if reward == null or not (reward as CanvasItem).visible:
		print("[UIUX][SKIP] 16_card_draft：RewardOverlay 未顯示")
	if reward != null and (reward as CanvasItem).visible:
		var crb: Node = null
		for n: Node in reward.find_children("*", "BaseButton", true, false):
			var spath: String = str(n.get_script().resource_path) if n.get_script() != null else ""
			if spath.contains("CardRewardButton") or str(n.name).contains("CardReward"):
				crb = n
				break
		if crb == null:
			print("[UIUX][SKIP] 16_card_draft：RewardOverlay 內找不到 CardRewardButton（buttons=%d）" % reward.find_children("*", "BaseButton", true, false).size())
		if crb != null:
			(crb as BaseButton).button_up.emit()
			for i: int in 120:
				await get_tree().process_frame
				if draft_overlay != null and (draft_overlay as CanvasItem).visible:
					break
			await _station("16_card_draft", draft_overlay, true)
			if draft_overlay != null:
				(draft_overlay as CanvasItem).visible = false
		(reward as CanvasItem).visible = false
	await _frames(10)

	# 17 商店（真實 visit；無 SHOP 節點則 populate fallback）
	var shop: Node = _root.get_node_or_null("RunScreen/ShopOverlay")
	var shop_id: String = _find_loc_id(locs, LocationData.LOCATION_TYPES.SHOP, [combat_id])
	if shop_id != "":
		ActionGenerator.generate_visit_location(shop_id)
		for i: int in 600:
			await get_tree().process_frame
			if not ActionHandler.actions_being_performed:
				break
		await _frames(40)
	var shop_open: bool = await _ensure_overlay_open(shop, "populate_shop")
	if not shop_open:
		print("[UIUX][SKIP] 17_shop：開不起來")
	await _station("17_shop", shop, shop_open)
	if shop != null:
		(shop as CanvasItem).visible = false

	# 18 歇腳（REST_SITE）
	var rest: Node = _root.get_node_or_null("RunScreen/RestOverlay")
	var rest_id: String = _find_loc_id(locs, LocationData.LOCATION_TYPES.REST_SITE, [combat_id, shop_id])
	if rest_id != "":
		ActionGenerator.generate_visit_location(rest_id)
		for i: int in 600:
			await get_tree().process_frame
			if not ActionHandler.actions_being_performed:
				break
		await _frames(40)
	var rest_open: bool = await _ensure_overlay_open(rest, "populate_rest_actions")
	if not rest_open:
		print("[UIUX][SKIP] 18_rest：開不起來")
	await _station("18_rest", rest, rest_open)
	if rest != null:
		(rest as CanvasItem).visible = false

	# 19 事件對話（EVENT）
	var dlg: Node = _root.get_node_or_null("RunScreen/DialogueOverlay")
	var event_id: String = _find_loc_id(locs, LocationData.LOCATION_TYPES.EVENT, [combat_id, shop_id, rest_id])
	if event_id != "":
		ActionGenerator.generate_visit_location(event_id)
		for i: int in 600:
			await get_tree().process_frame
			if not ActionHandler.actions_being_performed:
				break
		await _frames(40)
	var dlg_open: bool = await _ensure_overlay_open(dlg, "")
	if not dlg_open:
		print("[UIUX][SKIP] 19_dialogue_event：開不起來")
	await _station("19_dialogue_event", dlg, dlg_open)
	if dlg != null:
		(dlg as CanvasItem).visible = false

	# 20 牌庫檢視（CardSelectionOverlay VIEW 模式）
	var csel: Node = _root.get_node_or_null("RunScreen/CardSelectionOverlay")
	if csel != null and Global.player_data != null:
		var deck: Array[CardData] = []
		for cd: Variant in Global.player_data.player_deck:
			deck.append(cd as CardData)
		if deck.size() > 0:
			csel.call("set_card_mode", 0)	# VIEW
			csel.call("populate_cards", deck)
			(csel as CanvasItem).visible = true
			await _station("20_deck_view", csel, true)
			(csel as CanvasItem).visible = false

	# 21 敗北 → 結算 overlay（再進一場戰鬥，玩家受致命傷走真實死亡流程）
	var combat_id2: String = _find_loc_id(locs, LocationData.LOCATION_TYPES.COMBAT, [combat_id])
	if combat_id2 != "":
		ActionGenerator.generate_visit_location(combat_id2)
		for i: int in 600:
			await get_tree().process_frame
			if not ActionHandler.actions_being_performed:
				break
		await _frames(60)
		var player: Node = _root.get_node_or_null("RunScreen/Combat/Player")
		if player != null and player.has_method("damage"):
			player.call("damage", 9999, true)
		var summary: Node = _root.get_node_or_null("RunScreen/RunSummaryOverlay")
		for i: int in 600:
			await get_tree().process_frame
			if summary != null and (summary as CanvasItem).visible:
				break
		await _frames(20)
		await _station("21_run_summary", summary, true)
	print("[UIUX] walk done")

func _find_loc_id(locs: Array, want_type: int, exclude: Array) -> String:
	for l: Variant in locs:
		var loc: LocationData = l as LocationData
		if loc != null and loc.location_type == want_type and not exclude.has(loc.location_id):
			return loc.location_id
	return ""
