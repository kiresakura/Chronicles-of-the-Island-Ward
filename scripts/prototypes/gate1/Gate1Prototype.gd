# 鎮島錄 — Gate 1 Prototype（擲筊 + 三選一 + 媽祖 1 神）
#
# 目的：用最低成本驗證 v2 §3 Gate 1「核心循環是否真的爽」。
# **不與 Combat.gd 整合**、**不影響既有 26+ 測試**、**獨立可啟動**：
#   godot res://scenes/prototypes/Gate1Prototype.tscn
#
# 玩家流程：
#  1. 看到媽祖 + 山豬精 + 5 張手牌 + 神力 3/3
#  2. 擲筊（每回合 1 次免費）→ 聖/笑/陰結果套用到下一張卡
#  3. 出 5 張卡裡的一張 → 解算傷害（jiaobei modifier 套用 + 消耗）
#  4. 山豬精 HP → 0 → 跳出三選一（收伏/渡化/誅滅）
#  5. 玩家選擇 → 顯示獎勵敘述 → 重新開始
extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const JIAOBEI := preload("res://scripts/sim/JiaobeiSimCore.gd")
const BACKDROP_SCRIPT := preload("res://scripts/ui/menus/VectorTempleBackdrop.gd")

# 5 張媽祖派起手卡（簡化 prototype 用）
const CARDS: Array = [
	{"name": "平安拜禮", "cost": 1, "damage": 4, "kind": "attack"},
	{"name": "媽祖庇佑", "cost": 1, "damage": 0, "kind": "skill"},
	{"name": "海上慈光", "cost": 2, "damage": 6, "kind": "attack"},
	{"name": "媽姐令旗", "cost": 0, "damage": 0, "kind": "skill"},
	{"name": "拜禱",     "cost": 1, "damage": 0, "kind": "skill"},
]

const BOAR_HP_MAX: int = 30
const ENERGY_MAX: int = 3

var _rng: RandomNumberGenerator
var _energy: int = ENERGY_MAX
var _boar_hp: int = BOAR_HP_MAX
var _jiaobei_result: String = ""       # "" / "holy" / "laugh" / "yin"
var _free_jiaobei_used: bool = false
var _sincerity: int = 0
var _favor: int = 50
var _incense: int = 50
var _resolved: bool = false             # 是否已結算 yokai resolution

# UI refs (programmatic build)
var _energy_label: Label
var _hp_label: Label
var _result_label: Label
var _jiaobei_button: Button
var _card_buttons: Array[Button] = []
var _resolution_overlay: Control
var _outcome_label: Label
var _restart_button: Button


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	_build_ui()
	_redraw_state()


# ---------- UI 建構（全程式化，CotiwUiTheme 一致） ----------

func _build_ui() -> void:
	# 全向量背景
	var bg := Control.new()
	bg.set_script(BACKDROP_SCRIPT)
	bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	bg.offset_right = 1200.0
	bg.offset_bottom = 700.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var gold := COTIW_UI_THEME.get_color("incense_gold", Color(0.91, 0.77, 0.42))
	var paper := COTIW_UI_THEME.get_color("paper_warm", Color(0.96, 0.91, 0.81))

	# 標題
	var title := Label.new()
	title.text = "Gate 1 Prototype　媽祖 × 擲筊 × 三選一"
	title.position = Vector2(40, 30)
	title.size = Vector2(1120, 48)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", gold)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(title)

	# 媽祖面板（左）
	var mazu := _make_panel(Vector2(60, 110), Vector2(280, 220), "媽祖\n（本命神）\n\n慈光：每出 1 張技能 → 全體回血 1")

	# 山豬精面板（右）
	var boar := _make_panel(Vector2(860, 110), Vector2(280, 220), "山豬精\n\n（HP 將在下方顯示）")
	add_child(mazu); add_child(boar)

	# HP / 神力 / 香火 列
	_hp_label = _make_label("", Vector2(860, 340), Vector2(280, 36), 26)
	_energy_label = _make_label("", Vector2(60, 340), Vector2(280, 36), 26)
	add_child(_hp_label); add_child(_energy_label)

	# 擲筊結果（中央）
	_result_label = _make_label("【擲筊區】每回合可擲一次", Vector2(360, 130), Vector2(480, 90), 24)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_result_label)

	# 擲筊按鈕（中央）
	_jiaobei_button = _make_button("擲筊", Vector2(440, 240), Vector2(320, 76), 36, true)
	_jiaobei_button.button_up.connect(_on_jiaobei_pressed)
	add_child(_jiaobei_button)

	# 5 張手牌
	for i in CARDS.size():
		var card_data: Dictionary = CARDS[i]
		var btn := _make_card_button(card_data, i)
		_card_buttons.append(btn)
		add_child(btn)

	# 重新開始
	_restart_button = _make_button("重新開始", Vector2(990, 600), Vector2(150, 56), 22, false)
	_restart_button.button_up.connect(_on_restart_pressed)
	add_child(_restart_button)

	# 三選一 overlay（一開始隱藏）
	_build_resolution_overlay()
	_resolution_overlay.visible = false


func _make_panel(pos: Vector2, sz: Vector2, body: String) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = sz
	p.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
		COTIW_UI_THEME.get_color("panel_bg", Color(0.20, 0.07, 0.06, 0.92)),
		COTIW_UI_THEME.get_color("incense_gold", Color(0.91, 0.77, 0.42)),
		12, 3))
	var label := Label.new()
	label.text = body
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 12; label.offset_top = 12; label.offset_right = -12; label.offset_bottom = -12
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	p.add_child(label)
	return p


func _make_label(text: String, pos: Vector2, sz: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = sz
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color(0.91, 0.77, 0.42)))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _make_button(text: String, pos: Vector2, sz: Vector2, font_size: int, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		COTIW_UI_THEME.apply_primary_button_style(b)
	else:
		COTIW_UI_THEME.apply_secondary_button_style(b)
	b.add_theme_font_size_override("font_size", font_size)
	return b


func _make_card_button(data: Dictionary, idx: int) -> Button:
	var b := Button.new()
	b.text = "%s\n費 %d  傷 %d" % [data["name"], int(data["cost"]), int(data["damage"])]
	b.position = Vector2(60 + idx * 220, 470)
	b.size = Vector2(200, 110)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	COTIW_UI_THEME.apply_secondary_button_style(b)
	b.add_theme_font_size_override("font_size", 20)
	b.button_up.connect(_on_card_pressed.bind(idx))
	return b


# ---------- 三選一 overlay ----------

func _build_resolution_overlay() -> void:
	_resolution_overlay = Control.new()
	_resolution_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_resolution_overlay.offset_right = 1200
	_resolution_overlay.offset_bottom = 700

	var scrim := ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.78)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_resolution_overlay.add_child(scrim)

	var title := Label.new()
	title.text = "山豬精瀕死 — 選擇處置"
	title.position = Vector2(0, 100)
	title.size = Vector2(1200, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color.GOLD))
	_resolution_overlay.add_child(title)

	# 3 個選項
	var options := [
		{"label": "收伏\n👹", "desc": "鎮住為己用\n業力 +1\n→ 山豬召喚卡入牌組", "tag": "subdue"},
		{"label": "渡化\n👻", "desc": "送其超脫\n業力 −1\n→ +30 香火，觀音 +15", "tag": "liberate"},
		{"label": "誅滅\n💀", "desc": "徹底消滅\n業力 +3\n→ 強力卡 3 選 1", "tag": "destroy"},
	]
	for i in options.size():
		var opt: Dictionary = options[i]
		var card := Button.new()
		card.text = "%s\n\n%s" % [opt["label"], opt["desc"]]
		card.position = Vector2(140 + i * 320, 200)
		card.size = Vector2(280, 260)
		card.focus_mode = Control.FOCUS_NONE
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		COTIW_UI_THEME.apply_secondary_button_style(card)
		card.add_theme_font_size_override("font_size", 22)
		card.button_up.connect(_on_resolution_chosen.bind(opt["tag"]))
		_resolution_overlay.add_child(card)

	_outcome_label = Label.new()
	_outcome_label.position = Vector2(100, 490)
	_outcome_label.size = Vector2(1000, 100)
	_outcome_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_outcome_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_outcome_label.add_theme_font_size_override("font_size", 22)
	_outcome_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	_resolution_overlay.add_child(_outcome_label)

	add_child(_resolution_overlay)


# ---------- 互動邏輯 ----------

func _on_jiaobei_pressed() -> void:
	if _free_jiaobei_used or _resolved:
		return
	_free_jiaobei_used = true
	var state := {"sincerity": _sincerity, "favor": _favor}
	var prob: Dictionary = JIAOBEI.compute_probabilities(state)
	_jiaobei_result = JIAOBEI.roll(_rng, prob)
	var msg := ""
	match _jiaobei_result:
		"holy":
			msg = "[聖筊 🌗] 媽祖應允！下一張卡 免費 +2 傷害"
		"laugh":
			msg = "[笑筊 🌒] 媽祖微笑（搪塞）— 下一張卡照常"
		"yin":
			msg = "[陰筊 🌑] 媽祖不悅！下一張卡 多消耗 1 神力"
	_result_label.text = msg
	_redraw_state()


func _on_card_pressed(idx: int) -> void:
	if _resolved or idx < 0 or idx >= CARDS.size():
		return
	var card: Dictionary = CARDS[idx]
	var cost: int = int(card["cost"])
	var damage: int = int(card["damage"])

	# 套用 jiaobei modifier 到「下一張卡」
	match _jiaobei_result:
		"holy":
			cost = 0
			damage += 2
		"yin":
			cost += 1
		_:
			pass

	# 神力檢查
	if _energy < cost:
		_result_label.text = "神力不足！需要 %d 點" % cost
		return

	# 結算
	_energy -= cost
	if damage > 0:
		_boar_hp = maxi(_boar_hp - damage, 0)

	# 誠意更新（連續出技能類提升）
	if card["kind"] == "skill":
		_sincerity = mini(_sincerity + 1, 3)
	else:
		_sincerity = 0

	# 消費 jiaobei modifier（一次性）
	if _jiaobei_result != "":
		_result_label.text = "出牌：%s（剛才擲筊已生效）" % card["name"]
	else:
		_result_label.text = "出牌：%s（無擲筊修正）" % card["name"]
	_jiaobei_result = ""

	# 補神力（簡化：每張卡後恢復 1 點，且回合不結束 → 讓 playtester 多出幾張看 feel）
	# 真實設計是「結束回合 → 補滿 + 重置擲筊」，prototype 略簡化

	_redraw_state()

	# 檢查是否擊敗
	if _boar_hp <= 0:
		_open_resolution()


func _on_resolution_chosen(tag: String) -> void:
	_resolved = true
	match tag:
		"subdue":
			_outcome_label.text = "你鎖住了山豬精的怨念。\n業力 +1（記錄中）。山豬召喚卡入牌組。\n媽祖看你選了較不慈悲的路 → 媽祖好感 -2"
		"liberate":
			_outcome_label.text = "山豬精化為螢火飛向林木深處。\n+30 香火 / 觀音 +15 好感 / 業力 -1\n媽祖好感 +5（慈悲嘉許）"
		"destroy":
			_outcome_label.text = "神威斬下，山豬精徹底消散。\n+ 強力卡 3 選 1（範例：青龍偃月）/ 業力 +3\n媽祖好感 -5 / 觀音好感 -15"
		_:
			_outcome_label.text = "（未知選擇）"


func _on_restart_pressed() -> void:
	_energy = ENERGY_MAX
	_boar_hp = BOAR_HP_MAX
	_jiaobei_result = ""
	_free_jiaobei_used = false
	_sincerity = 0
	_resolved = false
	_result_label.text = "（已重新開始）每回合可擲一次"
	_outcome_label.text = ""
	_resolution_overlay.visible = false
	_redraw_state()


# ---------- 狀態渲染 ----------

func _redraw_state() -> void:
	_hp_label.text = "山豬精 HP  %d / %d" % [_boar_hp, BOAR_HP_MAX]
	_energy_label.text = "神力  %d / %d  ｜ 誠意 %d  ｜ 媽祖 %d" % [_energy, ENERGY_MAX, _sincerity, _favor]
	_jiaobei_button.disabled = _free_jiaobei_used or _resolved


func _open_resolution() -> void:
	_resolution_overlay.visible = true
