# 鎮島錄 v0.3 — 符令 draft 獎勵（FC-2b.3b-2）。
#
# 戰勝後「三選一符令」的輕量模態（程序化、不動巨型 Root.tscn）。由 Combat 接縫在
# formation_won 時叫 offer(...) 顯示；玩家點一張 → 發 fu_picked → 加進本局 run_fu_deck
# → Combat 續發 combat_ended 接既有獎勵流程。顯示文案全走 CSV key（核心零中文）。
extends Control

signal fu_picked(fu_id: String)

const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const ELEMENT_COLOR := {
	"wood": Color(0.35, 0.66, 0.40), "fire": Color(0.86, 0.30, 0.20),
	"earth": Color(0.80, 0.64, 0.28), "metal": Color(0.82, 0.80, 0.62), "water": Color(0.30, 0.55, 0.82),
}
const BTN_SIZE := Vector2(240, 156)
const BTN_GAP := 28.0

var _backdrop: ColorRect
var _title: Label
var _buttons: Array = []		# 候選符令按鈕

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.62)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP	# 擋住背後輸入（模態）
	add_child(_backdrop)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", THEME.get_color("incense_gold", Color(0.96, 0.84, 0.45)))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	visible = false
	if not resized.is_connected(_layout):
		resized.connect(_layout)

## 顯示三選一。choices: 符令 id 陣列；defs: id→{name,desc,element?}。
func offer(choices: Array, defs: Dictionary) -> void:
	_title.text = tr("combat.fu_draft.title")
	for b: Button in _buttons:
		b.queue_free()
	_buttons.clear()
	for fu_id: Variant in choices:
		var def: Dictionary = defs.get(str(fu_id), {})
		_buttons.append(_make_choice(str(fu_id), def))
	visible = true
	_layout()

func _make_choice(fu_id: String, def: Dictionary) -> Button:
	var b := Button.new()
	b.size = BTN_SIZE
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 18)
	b.text = str(def.get("name", fu_id)) + "\n\n" + str(def.get("desc", ""))
	var el_col: Color = ELEMENT_COLOR.get(str(def.get("element", "")), THEME.get_color("incense_gold", Color(0.95, 0.84, 0.5)))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.11, 0.08, 0.96)
	sb.set_corner_radius_all(8)
	sb.border_color = el_col
	sb.set_border_width_all(2)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.button_up.connect(_on_pick.bind(fu_id))
	add_child(b)
	return b

func _on_pick(fu_id: String) -> void:
	visible = false
	fu_picked.emit(fu_id)

## 依安全區置中排列標題 + 候選列（不依賴 HBox 自動尺寸，可同步測試）。
func _layout() -> void:
	if _buttons.is_empty():
		return
	var safe: Rect2 = THEME.get_safe_content_rect()
	var cx: float = safe.position.x + safe.size.x * 0.5
	var cy: float = safe.position.y + safe.size.y * 0.5
	var n: int = _buttons.size()
	var total: float = n * BTN_SIZE.x + maxf(0.0, n - 1) * BTN_GAP
	var x0: float = cx - total * 0.5
	for i: int in range(n):
		(_buttons[i] as Button).position = Vector2(x0 + i * (BTN_SIZE.x + BTN_GAP), cy - BTN_SIZE.y * 0.5)
		(_buttons[i] as Button).size = BTN_SIZE
	_title.position = Vector2(cx - 320.0, cy - BTN_SIZE.y * 0.5 - 64.0)
	_title.size = Vector2(640, 40)
