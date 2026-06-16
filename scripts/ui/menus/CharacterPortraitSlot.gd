extends Control
class_name CharacterPortraitSlot

# 鎮島錄 — 新一局「陣容列」磚（重排後）。
# 定位轉變：英雄面板（左）是角色資訊唯一真相來源，本磚只負責「切換角色」——
# 立繪縮圖 + 姓名 + 選中霓虹環；不再重複描述/標籤/平安符（減法 + 單一真相）。
# 鎖態：剪影（暗化立繪）+ 解鎖進度章（「再勝 N 場」），勾引而非訓斥——
#       移除原紅叉「封」印（紅線：禁止感 → 期待感）。
# 霓虹紀律：選中環是全畫面僅兩處霓虹之一（另一處 = 開始開壇 CTA）。
# 長按仍可看完整細節（鐵律 2：不依賴 hover）。

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const TOUCH_FEEDBACK := preload("res://scripts/ui/theme/TouchFeedback.gd")

signal pressed(character_id: String)

var _entry: Dictionary = {}
var _selected: bool = false
var _built: bool = false
var _motion_time: float = 0.0
var _ring_base_alpha: float = 0.0
var _emphasis_tween: Tween

var _frame_panel: Panel
var _portrait_rect: TextureRect
var _selection_ring: Panel			# 霓虹選中環（稀缺資源）
var _lock_veil: ColorRect			# 剪影暗化
var _unlock_stamp: Panel			# 解鎖進度章
var _stamp_label: Label
var _nameplate_panel: Panel
var _name_label: Label
var _select_button: Button

func _ready() -> void:
	_build_once()
	set_process(true)
	if not resized.is_connected(_layout):
		resized.connect(_layout)
	_layout()
	_apply_entry()

func setup(entry: Dictionary) -> void:
	_entry = entry.duplicate(true)
	_build_once()
	_apply_entry()

func set_selected(selected: bool) -> void:
	_selected = selected
	_build_once()
	_refresh_visual_state()

func get_character_id() -> String:
	return str(_entry.get("character_id", ""))

func is_locked() -> bool:
	return bool(_entry.get("locked", true))

func _build_once() -> void:
	if _built:
		return
	_built = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(108, 132)	# 陣容磚：頭像為主（鐵律 2：≥88 觸控由 SelectButton 撐滿）

	_selection_ring = Panel.new()
	_selection_ring.name = "SelectionRing"
	_selection_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_selection_ring)

	_frame_panel = Panel.new()
	_frame_panel.name = "FramePanel"
	_frame_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_panel)

	_portrait_rect = TextureRect.new()
	_portrait_rect.name = "Portrait"
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_rect.clip_contents = true
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait_rect)

	_lock_veil = ColorRect.new()
	_lock_veil.name = "LockVeil"
	_lock_veil.color = Color(0.04, 0.03, 0.05, 0.55)
	_lock_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lock_veil)

	_nameplate_panel = Panel.new()
	_nameplate_panel.name = "NameplatePanel"
	_nameplate_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_nameplate_panel)

	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("paper_warm", Color(0.96, 0.92, 0.84)))
	_nameplate_panel.add_child(_name_label)

	# 解鎖進度章（鎖態用）：剪影上的「再勝 N 場」印章，勾引解鎖
	_unlock_stamp = Panel.new()
	_unlock_stamp.name = "UnlockStamp"
	_unlock_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_unlock_stamp.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
		Color(0.14, 0.07, 0.05, 0.92), COTIW_UI_THEME.get_color("incense_gold", Color(0.90, 0.70, 0.30)), 0, 2, 0.0))
	add_child(_unlock_stamp)

	_stamp_label = Label.new()
	_stamp_label.name = "StampLabel"
	_stamp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stamp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stamp_label.clip_text = true	# 單行不換行（避免擠到名牌）
	_stamp_label.add_theme_font_size_override("font_size", 14)
	_stamp_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.80, 0.42)))
	_unlock_stamp.add_child(_stamp_label)

	_select_button = Button.new()
	_select_button.name = "SelectButton"
	_select_button.flat = true
	_select_button.focus_mode = Control.FOCUS_NONE
	_select_button.self_modulate = Color(1, 1, 1, 0.01)
	_select_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_child(_select_button)
	TOUCH_FEEDBACK.install(_select_button, func(): return _selected)
	_select_button.button_up.connect(_on_select_button_up)

func _layout() -> void:
	if not _built:
		return
	var w: float = maxf(size.x, custom_minimum_size.x)
	var h: float = maxf(size.y, custom_minimum_size.y)
	var nameplate_h: float = 30.0
	var portrait_h: float = h - nameplate_h
	pivot_offset = Vector2(w * 0.5, h * 0.5)

	_selection_ring.position = Vector2(-4, -4)
	_selection_ring.size = Vector2(w + 8, h + 8)
	_frame_panel.position = Vector2.ZERO
	_frame_panel.size = Vector2(w, portrait_h)
	_portrait_rect.position = Vector2(3, 3)
	_portrait_rect.size = Vector2(w - 6, portrait_h - 6)
	_lock_veil.position = Vector2(3, 3)
	_lock_veil.size = Vector2(w - 6, portrait_h - 6)
	_nameplate_panel.position = Vector2(0, portrait_h - 2)
	_nameplate_panel.size = Vector2(w, nameplate_h + 2)
	_name_label.position = Vector2.ZERO
	_name_label.size = _nameplate_panel.size
	# 鎖態進度章：垂直置中於立繪、單行（剪影上的金印）
	var stamp_h: float = 36.0
	_unlock_stamp.position = Vector2(w * 0.08, (portrait_h - stamp_h) * 0.5)
	_unlock_stamp.size = Vector2(w * 0.84, stamp_h)
	_stamp_label.position = Vector2(4, 0)
	_stamp_label.size = Vector2(_unlock_stamp.size.x - 8, stamp_h)
	_select_button.position = Vector2.ZERO
	_select_button.size = Vector2(w, h)

func _apply_entry() -> void:
	if not _built:
		return
	var portrait_path: String = str(_entry.get("portrait_path", ""))
	_portrait_rect.texture = load(portrait_path) if (not portrait_path.is_empty() and ResourceLoader.exists(portrait_path)) else null
	_name_label.text = str(_entry.get("label", tr("slot.unnamed")))
	_stamp_label.text = _compose_stamp_text()
	_select_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if is_locked() else Control.CURSOR_POINTING_HAND
	TOUCH_FEEDBACK.mark_disabled(_select_button, is_locked())
	TOUCH_FEEDBACK.install_long_press_detail(_select_button, {
		"type": "character",
		"name": _entry.get("label", tr("char.title")),
		"description": _compose_detail_body(),
	})
	_refresh_visual_state()

func _refresh_visual_state() -> void:
	if not _built:
		return
	_motion_time = 0.0
	var locked: bool = is_locked()
	var border_color: Color
	var fill_color: Color
	if locked:
		border_color = Color(0.40, 0.30, 0.26, 0.50)
		fill_color = Color(0.07, 0.05, 0.05, 0.92)
		_ring_base_alpha = 0.0
	elif _selected:
		border_color = COTIW_UI_THEME.get_color("incense_gold", Color(0.98, 0.84, 0.40))
		fill_color = Color(0.20, 0.08, 0.05, 0.96)
		_ring_base_alpha = 0.55	# 霓虹環點亮（稀缺資源）
	else:
		border_color = Color(0.66, 0.48, 0.20, 0.46)
		fill_color = Color(0.11, 0.05, 0.05, 0.92)
		_ring_base_alpha = 0.0

	_frame_panel.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(fill_color, border_color, 0, 2 if not _selected else 3, 0.0))
	_nameplate_panel.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
		Color(0.16, 0.06, 0.04, 0.96) if not locked else Color(0.10, 0.07, 0.07, 0.94), border_color, 0, 2, 0.0))
	# 選中環：霓虹發光（金漆霓光），未選/鎖定全暗 → 對比即層級
	_selection_ring.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
		Color(0, 0, 0, 0), COTIW_UI_THEME.get_color("incense_gold", Color(1.0, 0.86, 0.42)), 0, 3, 0.0))
	_selection_ring.visible = _selected and not locked
	_lock_veil.visible = locked
	_unlock_stamp.visible = locked
	# 鎖態藏名牌（剪影 = 神秘/期待；進度章獨佔，杜絕名稱與進度文字打架）
	_nameplate_panel.visible = not locked
	# 剪影：鎖定立繪壓暗去彩（剪影感），選中提亮，未選略暗
	_portrait_rect.modulate = Color(0.26, 0.24, 0.28, 0.96) if locked else (Color(1.06, 1.02, 0.96, 1.0) if _selected else Color(0.92, 0.92, 0.92, 0.96))
	_name_label.add_theme_color_override("font_color",
		Color(0.70, 0.62, 0.56, 0.92) if locked else (Color(1.0, 0.92, 0.70, 1.0) if _selected else Color(0.94, 0.88, 0.76, 1.0)))
	_animate_motion(0.0)

func _process(delta: float) -> void:
	if not _built:
		return
	_motion_time += delta
	_animate_motion(_motion_time)

func _animate_motion(t: float) -> void:
	if not _built:
		return
	if _selected and not is_locked():
		# 選中環呼吸（Q-1 idle 微動效；霓虹脈動）
		_selection_ring.modulate = Color(1.0, 0.98, 0.92, clampf(_ring_base_alpha + sin(t * 2.6) * 0.18, 0.0, 1.0))
	elif is_locked():
		# 解鎖章極輕脈動（勾引）
		_unlock_stamp.modulate = Color(1, 1, 1, 0.90 + sin(t * 1.6) * 0.08)

func play_selection_emphasis() -> void:
	if not _built or not _selected or is_locked():
		return
	if _emphasis_tween != null:
		_emphasis_tween.kill()
	scale = Vector2(0.96, 0.96)
	_emphasis_tween = create_tween()
	_emphasis_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_emphasis_tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.14)
	_emphasis_tween.tween_property(self, "scale", Vector2.ONE, 0.18)

func _compose_stamp_text() -> String:
	# 解鎖進度章：優先用資料層解鎖提示（再勝 N 場），勾引而非禁止
	var unlock_hint: String = str(_entry.get("unlock_hint", ""))
	if not unlock_hint.is_empty():
		return unlock_hint
	return tr("slot.sealed_hint")

func _compose_detail_body() -> String:
	var lines: Array[String] = []
	var description: String = str(_entry.get("description", ""))
	if not description.is_empty():
		lines.append(description)
	var tags: Array = _entry.get("tags", [])
	if not tags.is_empty():
		lines.append(tr("slot.playstyle") % " / ".join(PackedStringArray(tags)))
	var starter_name: String = str(_entry.get("starter_name", ""))
	var starter_desc: String = str(_entry.get("starter_description", ""))
	if not starter_name.is_empty():
		lines.append(tr("slot.init_charm") % starter_name)
		if not starter_desc.is_empty():
			lines.append(starter_desc)
	if is_locked():
		var unlock_hint: String = str(_entry.get("unlock_hint", ""))
		if not unlock_hint.is_empty():
			lines.append(tr("slot.unlock_cond") % unlock_hint)
	return "\n".join(PackedStringArray(lines))

func _on_select_button_up() -> void:
	if is_locked():
		return
	pressed.emit(get_character_id())
