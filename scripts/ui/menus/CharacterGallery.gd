extends Control
class_name CharacterGallery

const SLOT_SCENE := preload("res://scenes/ui/menus/CharacterPortraitSlot.tscn")
const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

signal character_selected(character_id: String)

var _entries: Array = []
var _selected_character_id: String = ""
var _slot_root: Control
var _header_label: Label
var _subhead_label: Label
var _slot_order: Array = []
var _slot_by_character_id: Dictionary = {}
var _built: bool = false
var _intro_serial: int = 0
## 重排後：本 gallery 作「陣容列」（橫向切換磚），compact = 隱藏標題、磚壓扁成一列。
var compact: bool = false

func set_compact(value: bool) -> void:
	compact = value
	if _built:
		if _header_label != null:
			_header_label.visible = not compact
		if _subhead_label != null:
			_subhead_label.visible = not compact
		_layout()

func _ready() -> void:
	_build_once()
	if not resized.is_connected(_layout):
		resized.connect(_layout)
	_layout()

func setup_entries(entries: Array) -> void:
	_entries.clear()
	for entry in entries:
		if entry is Dictionary:
			_entries.append((entry as Dictionary).duplicate(true))
	_build_once()
	_rebuild_slots()

func select_character(character_id: String) -> void:
	_selected_character_id = character_id
	for slot in _slot_order:
		if is_instance_valid(slot):
			slot.set_selected(slot.get_character_id() == character_id)
			if slot.get_character_id() == character_id and slot.has_method("play_selection_emphasis"):
				slot.play_selection_emphasis()

func get_selected_character_id() -> String:
	return _selected_character_id

func _build_once() -> void:
	if _built:
		return
	_built = true
	mouse_filter = Control.MOUSE_FILTER_PASS

	_header_label = Label.new()
	_header_label.name = "HeaderLabel"
	_header_label.text = tr("gallery.title")
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_label.add_theme_font_size_override("font_size", 24)
	_header_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.82, 0.45)))
	add_child(_header_label)

	_subhead_label = Label.new()
	_subhead_label.name = "SubheadLabel"
	_subhead_label.text = tr("gallery.hint")
	_subhead_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subhead_label.add_theme_font_size_override("font_size", 13)
	_subhead_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.76, 0.82))
	add_child(_subhead_label)

	_slot_root = Control.new()
	_slot_root.name = "SlotRoot"
	_slot_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_slot_root)

func _rebuild_slots() -> void:
	_intro_serial += 1
	for child in _slot_root.get_children():
		child.queue_free()
	_slot_order.clear()
	_slot_by_character_id.clear()
	for index in _entries.size():
		var entry: Dictionary = _entries[index]
		var slot = SLOT_SCENE.instantiate()
		if slot == null:
			continue
		slot.name = "Slot_%02d" % index
		slot.setup(entry)
		slot.pressed.connect(_on_slot_pressed)
		_slot_root.add_child(slot)
		_slot_order.append(slot)
		var character_id: String = str(entry.get("character_id", ""))
		if not character_id.is_empty():
			_slot_by_character_id[character_id] = slot
	_layout()
	select_character(_selected_character_id)
	_play_slot_reveal_sequence(_intro_serial)

func _layout() -> void:
	if not _built:
		return
	var w: float = size.x
	var h: float = size.y
	if compact:
		# 陣容列：無標題，磚填滿整條
		_header_label.visible = false
		_subhead_label.visible = false
		_slot_root.position = Vector2.ZERO
		_slot_root.size = Vector2(w, h)
	else:
		_header_label.position = Vector2(0, 0)
		_header_label.size = Vector2(w, 30)
		_subhead_label.position = Vector2(0, 28)
		_subhead_label.size = Vector2(w, 22)
		_slot_root.position = Vector2(0, 56)
		_slot_root.size = Vector2(w, maxf(0.0, h - 56.0))
	_layout_slots()

func _layout_slots() -> void:
	var count: int = _slot_order.size()
	if count <= 0:
		return
	var area_w: float = _slot_root.size.x
	var area_h: float = _slot_root.size.y
	var gap: float = clampf(area_w * 0.022, 10.0, 18.0)
	# 陣容列磚：壓扁成一列（高度跟容器、寬度較窄）；非 compact 維持原大磚
	var slot_w: float = clampf((area_w - gap * float(count - 1)) / float(count), 96.0, 132.0 if compact else 186.0)
	var slot_h: float = clampf(area_h - 6.0, 110.0, 150.0) if compact else clampf(area_h - 6.0, 280.0, 430.0)
	var total_w: float = slot_w * float(count) + gap * float(count - 1)
	var start_x: float = maxf(0.0, (area_w - total_w) * 0.5)
	var top_y: float = maxf(0.0, (area_h - slot_h) * 0.5)
	for index in count:
		var slot = _slot_order[index]
		if not is_instance_valid(slot):
			continue
		slot.position = Vector2(start_x + float(index) * (slot_w + gap), top_y)
		slot.size = Vector2(slot_w, slot_h)

func _play_slot_reveal_sequence(serial: int) -> void:
	for index in _slot_order.size():
		var slot = _slot_order[index]
		if not is_instance_valid(slot):
			continue
		var final_position: Vector2 = slot.position
		slot.pivot_offset = slot.size * 0.5
		slot.modulate = Color(1.0, 1.0, 1.0, 0.0)
		slot.scale = Vector2(0.94, 0.94)
		slot.position = final_position + Vector2(0.0, 28.0)
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.05 * float(index))
		tween.tween_callback(func() -> void:
			if serial != _intro_serial or not is_instance_valid(slot):
				return
			slot.pivot_offset = slot.size * 0.5
		).set_delay(0.0)
		tween.parallel().tween_property(slot, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.28)
		tween.parallel().tween_property(slot, "scale", Vector2.ONE, 0.34)
		tween.parallel().tween_property(slot, "position", final_position, 0.34)

func _on_slot_pressed(character_id: String) -> void:
	select_character(character_id)
	character_selected.emit(character_id)
