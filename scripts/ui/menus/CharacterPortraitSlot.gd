extends Control
class_name CharacterPortraitSlot

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const TOUCH_FEEDBACK := preload("res://scripts/ui/theme/TouchFeedback.gd")

signal pressed(character_id: String)

var _entry: Dictionary = {}
var _selected: bool = false
var _built: bool = false
var _selection_motion_time: float = 0.0
var _beam_base_alpha: float = 0.06
var _halo_base_alpha: float = 0.04
var _thread_base_alpha: float = 0.88
var _selection_emphasis_tween: Tween

var _frame_panel: Panel
var _altar_halo: Panel
var _light_beam: ColorRect
var _portrait_rect: TextureRect
var _lock_veil: ColorRect
var _seal_paper: Panel
var _seal_label: Label
var _red_thread_top: ColorRect
var _red_thread_bottom: ColorRect
var _pedestal_glow: Panel
var _smoke_particles: CPUParticles2D
var _nameplate_panel: Panel
var _name_label: Label
var _tag_flow: HFlowContainer
var _hint_label: Label
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
	custom_minimum_size = Vector2(132, 320)

	_frame_panel = Panel.new()
	_frame_panel.name = "FramePanel"
	_frame_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_panel)

	_altar_halo = Panel.new()
	_altar_halo.name = "AltarHalo"
	_altar_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_altar_halo)

	_light_beam = ColorRect.new()
	_light_beam.name = "LightBeam"
	_light_beam.color = Color(1.0, 0.86, 0.34, 0.16)
	_light_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_light_beam)

	_pedestal_glow = Panel.new()
	_pedestal_glow.name = "PedestalGlow"
	_pedestal_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pedestal_glow)

	_smoke_particles = CPUParticles2D.new()
	_smoke_particles.name = "SmokeParticles"
	_smoke_particles.one_shot = false
	_smoke_particles.amount = 16
	_smoke_particles.lifetime = 2.0
	_smoke_particles.preprocess = 1.4
	_smoke_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_smoke_particles.emission_rect_extents = Vector2(14, 4)
	_smoke_particles.direction = Vector2(0, -1)
	_smoke_particles.spread = 26.0
	_smoke_particles.gravity = Vector2(0, -24)
	_smoke_particles.initial_velocity_min = 6.0
	_smoke_particles.initial_velocity_max = 18.0
	_smoke_particles.scale_amount_min = 1.5
	_smoke_particles.scale_amount_max = 3.4
	_smoke_particles.radial_accel_min = -1.0
	_smoke_particles.radial_accel_max = 1.0
	var smoke_gradient := Gradient.new()
	smoke_gradient.set_color(0, Color(0.94, 0.88, 0.78, 0.42))
	smoke_gradient.set_color(1, Color(0.55, 0.56, 0.58, 0.0))
	_smoke_particles.color_ramp = smoke_gradient
	add_child(_smoke_particles)

	_portrait_rect = TextureRect.new()
	_portrait_rect.name = "Portrait"
	_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait_rect)

	_lock_veil = ColorRect.new()
	_lock_veil.name = "LockVeil"
	_lock_veil.color = Color(0.05, 0.03, 0.03, 0.52)
	_lock_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_lock_veil)

	_seal_paper = Panel.new()
	_seal_paper.name = "SealPaper"
	_seal_paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_seal_paper)

	_seal_label = Label.new()
	_seal_label.name = "SealLabel"
	_seal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_seal_label.text = "封"
	_seal_label.add_theme_font_size_override("font_size", 22)
	_seal_label.add_theme_color_override("font_color", Color(0.52, 0.0, 0.0, 1.0))
	_seal_paper.add_child(_seal_label)

	_red_thread_top = ColorRect.new()
	_red_thread_top.name = "RedThreadTop"
	_red_thread_top.color = Color(0.86, 0.08, 0.10, 0.88)
	_red_thread_top.rotation_degrees = -12.0
	_red_thread_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_red_thread_top)

	_red_thread_bottom = ColorRect.new()
	_red_thread_bottom.name = "RedThreadBottom"
	_red_thread_bottom.color = Color(0.86, 0.08, 0.10, 0.88)
	_red_thread_bottom.rotation_degrees = 10.0
	_red_thread_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_red_thread_bottom)

	_nameplate_panel = Panel.new()
	_nameplate_panel.name = "NameplatePanel"
	_nameplate_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_nameplate_panel)

	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 20)
	_name_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("paper_warm", Color(0.96, 0.92, 0.84)))
	_nameplate_panel.add_child(_name_label)

	_tag_flow = HFlowContainer.new()
	_tag_flow.name = "TagFlow"
	_tag_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_tag_flow.add_theme_constant_override("h_separation", 6)
	_tag_flow.add_theme_constant_override("v_separation", 6)
	add_child(_tag_flow)

	_hint_label = Label.new()
	_hint_label.name = "HintLabel"
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color(0.90, 0.84, 0.72, 0.90))
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_label)

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
	var portrait_h: float = h * 0.68
	var pedestal_h: float = maxf(18.0, h * 0.07)
	var nameplate_h: float = 34.0
	var tags_y: float = portrait_h + 40.0
	var hint_y: float = h - 54.0
	pivot_offset = Vector2(w * 0.5, h * 0.5)

	_frame_panel.position = Vector2.ZERO
	_frame_panel.size = Vector2(w, portrait_h)

	_altar_halo.position = Vector2(w * 0.18, -6.0)
	_altar_halo.size = Vector2(w * 0.64, 24.0)

	_light_beam.position = Vector2(w * 0.18, 8)
	_light_beam.size = Vector2(w * 0.64, portrait_h - 24.0)

	_pedestal_glow.position = Vector2(w * 0.12, portrait_h - pedestal_h * 0.55)
	_pedestal_glow.size = Vector2(w * 0.76, pedestal_h)

	_smoke_particles.position = Vector2(w * 0.5, portrait_h - pedestal_h * 0.45)
	_smoke_particles.emission_rect_extents = Vector2(maxf(10.0, w * 0.11), 4)

	_portrait_rect.position = Vector2(8, 4)
	_portrait_rect.size = Vector2(w - 16, portrait_h - 12)

	_lock_veil.position = Vector2.ZERO
	_lock_veil.size = Vector2(w, portrait_h)

	_seal_paper.position = Vector2(w * 0.38, portrait_h * 0.08)
	_seal_paper.size = Vector2(w * 0.24, portrait_h * 0.28)
	_seal_label.position = Vector2.ZERO
	_seal_label.size = _seal_paper.size

	_red_thread_top.position = Vector2(w * 0.16, portrait_h * 0.26)
	_red_thread_top.size = Vector2(w * 0.70, 4)
	_red_thread_bottom.position = Vector2(w * 0.13, portrait_h * 0.52)
	_red_thread_bottom.size = Vector2(w * 0.74, 4)

	_nameplate_panel.position = Vector2(8, portrait_h - 6)
	_nameplate_panel.size = Vector2(w - 16, nameplate_h)
	_name_label.position = Vector2.ZERO
	_name_label.size = _nameplate_panel.size

	_tag_flow.position = Vector2(8, tags_y)
	_tag_flow.size = Vector2(w - 16, 42)

	_hint_label.position = Vector2(10, hint_y)
	_hint_label.size = Vector2(w - 20, 44)

	_select_button.position = Vector2.ZERO
	_select_button.size = Vector2(w, h)

func _apply_entry() -> void:
	if not _built:
		return
	var portrait_path: String = str(_entry.get("portrait_path", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		_portrait_rect.texture = load(portrait_path)
	else:
		_portrait_rect.texture = null

	_name_label.text = str(_entry.get("label", tr("slot.unnamed")))
	_hint_label.text = _compose_hint_text()
	_select_button.tooltip_text = str(_entry.get("tooltip", _entry.get("description", "")))
	_select_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if is_locked() else Control.CURSOR_POINTING_HAND
	TOUCH_FEEDBACK.mark_disabled(_select_button, is_locked())
	TOUCH_FEEDBACK.install_long_press_detail(_select_button, {
		"type": "character",
		"name": _entry.get("label", tr("char.title")),
		"description": _compose_detail_body(),
	})
	_rebuild_tags()
	_refresh_visual_state()

func _rebuild_tags() -> void:
	for child in _tag_flow.get_children():
		child.queue_free()
	var tags: Array = _entry.get("tags", [])
	for raw_tag in tags:
		var tag_text: String = str(raw_tag)
		if tag_text.is_empty():
			continue
		var pill := Panel.new()
		pill.name = "Tag_%s" % tag_text
		pill.custom_minimum_size = Vector2(0, 22)
		pill.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
			Color(0.18, 0.08, 0.05, 0.92),
			Color(0.86, 0.65, 0.24, 0.72),
			11,
			1,
			0.12
		))
		var label := Label.new()
		label.text = tag_text
		label.position = Vector2(8, 1)
		label.size = Vector2(maxf(56.0, 14.0 * float(tag_text.length())), 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.72, 1.0))
		pill.add_child(label)
		pill.custom_minimum_size.x = label.size.x + 16.0
		_tag_flow.add_child(pill)

func _refresh_visual_state() -> void:
	if not _built:
		return
	_selection_motion_time = 0.0
	var locked: bool = is_locked()
	var border_color: Color = Color(0.56, 0.43, 0.24, 0.62)
	var fill_color: Color = Color(0.10, 0.05, 0.04, 0.92)
	var beam_alpha: float = 0.06
	var halo_alpha: float = 0.04
	var pedestal_fill: Color = Color(0.36, 0.18, 0.04, 0.42)
	var pedestal_border: Color = Color(0.72, 0.52, 0.18, 0.58)
	if locked:
		border_color = Color(0.42, 0.24, 0.20, 0.55)
		fill_color = Color(0.07, 0.05, 0.05, 0.90)
		beam_alpha = 0.0
		halo_alpha = 0.0
		pedestal_fill = Color(0.16, 0.10, 0.10, 0.30)
		pedestal_border = Color(0.42, 0.25, 0.25, 0.44)
	elif _selected:
		border_color = COTIW_UI_THEME.get_color("incense_gold", Color(0.95, 0.82, 0.45))
		fill_color = Color(0.22, 0.08, 0.04, 0.97)
		beam_alpha = 0.22
		halo_alpha = 0.24
		pedestal_fill = Color(0.94, 0.72, 0.18, 0.46)
		pedestal_border = Color(1.0, 0.84, 0.38, 0.92)
	else:
		border_color = Color(0.72, 0.52, 0.18, 0.54)
		fill_color = Color(0.13, 0.05, 0.04, 0.94)
		beam_alpha = 0.08
		halo_alpha = 0.08
		pedestal_fill = Color(0.52, 0.24, 0.08, 0.34)
		pedestal_border = Color(0.82, 0.62, 0.22, 0.54)

	_beam_base_alpha = beam_alpha
	_halo_base_alpha = halo_alpha
	_thread_base_alpha = 0.94 if locked else 0.0
	_frame_panel.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(fill_color, border_color, 16, 2 if not _selected else 3, 0.22))
	_altar_halo.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
		Color(0.98, 0.84, 0.42, maxf(0.0, halo_alpha * 0.72)),
		Color(1.0, 0.94, 0.70, maxf(0.0, halo_alpha)),
		12,
		1,
		0.12
	))
	_pedestal_glow.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(pedestal_fill, pedestal_border, 14, 2 if _selected else 1, 0.18))
	_nameplate_panel.add_theme_stylebox_override("panel", COTIW_UI_THEME.make_stylebox(
		Color(0.17, 0.06, 0.04, 0.96) if not locked else Color(0.12, 0.08, 0.08, 0.94),
		pedestal_border,
		12,
		2,
		0.18
	))
	_light_beam.color = Color(1.0, 0.86, 0.34, beam_alpha)
	_altar_halo.visible = not locked
	_light_beam.visible = not locked
	_lock_veil.visible = locked
	_seal_paper.visible = locked
	_red_thread_top.visible = locked
	_red_thread_bottom.visible = locked
	_tag_flow.visible = not locked
	_smoke_particles.emitting = _selected and not locked
	_portrait_rect.modulate = Color(0.38, 0.38, 0.38, 0.72) if locked else (Color(1.08, 1.03, 0.97, 1.0) if _selected else Color(0.96, 0.96, 0.96, 0.94))
	_name_label.add_theme_color_override("font_color",
		Color(0.72, 0.64, 0.56, 0.92) if locked else (Color(1.0, 0.93, 0.72, 1.0) if _selected else Color(0.95, 0.88, 0.76, 1.0)))
	_hint_label.add_theme_color_override("font_color",
		Color(0.86, 0.74, 0.70, 0.88) if locked else (Color(1.0, 0.90, 0.76, 0.95) if _selected else Color(0.90, 0.84, 0.72, 0.90)))
	_animate_motion_frame(0.0)

func _process(delta: float) -> void:
	if not _built:
		return
	_selection_motion_time += delta
	_animate_motion_frame(_selection_motion_time)

func play_selection_emphasis() -> void:
	if not _built or not _selected or is_locked():
		return
	if _selection_emphasis_tween != null:
		_selection_emphasis_tween.kill()
	scale = Vector2(0.972, 0.972)
	_selection_emphasis_tween = create_tween()
	_selection_emphasis_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_selection_emphasis_tween.tween_property(self, "scale", Vector2(1.01, 1.01), 0.14)
	_selection_emphasis_tween.tween_property(self, "scale", Vector2.ONE, 0.18)

func _animate_motion_frame(time_value: float) -> void:
	if not _built:
		return
	if is_locked():
		var seal_pulse: float = 0.94 + sin(time_value * 1.7) * 0.03
		_seal_paper.scale = Vector2.ONE * seal_pulse
		_red_thread_top.modulate.a = _thread_base_alpha + sin(time_value * 2.1) * 0.06
		_red_thread_bottom.modulate.a = _thread_base_alpha + cos(time_value * 1.8) * 0.05
		_altar_halo.modulate = Color(1.0, 1.0, 1.0, 0.0)
		return
		
	var selected_pulse: float = 1.0 if _selected else 0.0
	var beam_pulse: float = _beam_base_alpha + sin(time_value * 2.4) * (0.06 if _selected else 0.018)
	var halo_pulse: float = _halo_base_alpha + cos(time_value * 2.0) * (0.08 if _selected else 0.02)
	_light_beam.color = Color(1.0, 0.88, 0.42, clampf(beam_pulse, 0.02, 0.32))
	_altar_halo.modulate = Color(1.0, 0.98, 0.92, clampf(halo_pulse, 0.04, 0.34))
	_pedestal_glow.modulate = Color(1.0, 0.98, 0.92, 0.92 + selected_pulse * 0.08 + sin(time_value * 2.2) * 0.04)
	_nameplate_panel.modulate = Color(1.0, 0.98, 0.94, 0.94 + selected_pulse * 0.08 + cos(time_value * 2.3) * 0.03)
	_smoke_particles.speed_scale = 1.0 + selected_pulse * 0.35 + maxf(0.0, sin(time_value * 1.6)) * 0.1

func _compose_hint_text() -> String:
	if is_locked():
		var unlock_hint: String = str(_entry.get("unlock_hint", ""))
		if not unlock_hint.is_empty():
			return tr("slot.sealed_name") % unlock_hint
		return tr("slot.sealed_hint")
	var starter_name: String = str(_entry.get("starter_name", ""))
	if not starter_name.is_empty():
		return tr("slot.start_charm") % starter_name
	return tr("slot.tap_hint")

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
