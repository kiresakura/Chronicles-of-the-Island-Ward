# Touch-first interaction helper for major COTIW UI controls.
#
# 目的：把手機玩家真正看得到的 normal / pressed / selected / disabled 四態集中化，
# 避免每個 Reward / Shop / Gallery / Map 節點各自偷偷寫一套半成品。
extends Object
class_name TouchFeedback

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

enum TouchState { NORMAL, PRESSED, SELECTED, DISABLED }

const LONG_PRESS_SECONDS: float = 0.45
const NORMAL_SCALE := Vector2.ONE
const PRESSED_SCALE := Vector2(0.96, 0.96)
const SELECTED_SCALE := Vector2(1.045, 1.045)
const DISABLED_SCALE := Vector2.ONE
const FEEDBACK_LAYER_NAME := "TouchFeedbackLayer"
const SFX_BUS_NAME := "SFX"

static func install(target: Control, selected_predicate: Callable = Callable()) -> void:
	if target == null:
		return
	target.set_meta("touch_feedback_installed", true)
	target.set_meta("touch_feedback_sound_hook", "ui/touch_tap")
	target.set_meta("touch_feedback_particle_hook", "fu_light")
	apply_state(target, TouchState.DISABLED if _is_disabled(target) else TouchState.NORMAL)
	if target is BaseButton:
		var btn := target as BaseButton
		if not btn.button_down.is_connected(_on_button_down.bind(target)):
			btn.button_down.connect(_on_button_down.bind(target))
		if not btn.button_up.is_connected(_on_button_up.bind(target, selected_predicate)):
			btn.button_up.connect(_on_button_up.bind(target, selected_predicate))
		if not btn.toggled.is_connected(_on_button_toggled.bind(target)):
			btn.toggled.connect(_on_button_toggled.bind(target))

static func apply_state(target: Control, state: TouchState) -> void:
	if target == null:
		return
	target.set_meta("touch_state", int(state))
	target.pivot_offset = target.size * 0.5
	match state:
		TouchState.NORMAL:
			target.scale = NORMAL_SCALE
			target.self_modulate = Color(1, 1, 1, 1)
		TouchState.PRESSED:
			target.scale = PRESSED_SCALE
			target.self_modulate = Color(1.16, 1.10, 0.92, 1)
			target.set_meta("touch_feedback_sound_hook", "ui/touch_down")
			target.set_meta("touch_feedback_particle_hook", "fu_light_pressed")
			play_sfx(target, "ui/touch_down")
			spawn_particle_hook(target, "fu_light_pressed", target.get_global_rect().get_center())
		TouchState.SELECTED:
			target.scale = SELECTED_SCALE
			target.self_modulate = Color(1.12, 1.02, 0.72, 1)
			target.set_meta("touch_feedback_sound_hook", "ui/touch_selected")
			target.set_meta("touch_feedback_particle_hook", "fu_light_selected")
			play_sfx(target, "ui/touch_selected")
			spawn_particle_hook(target, "fu_light_selected", target.get_global_rect().get_center())
		TouchState.DISABLED:
			target.scale = DISABLED_SCALE
			target.self_modulate = Color(0.48, 0.44, 0.40, 0.58)
			target.set_meta("touch_feedback_sound_hook", "ui/touch_disabled")
			target.set_meta("touch_feedback_particle_hook", "disabled_ash")
			play_sfx(target, "ui/touch_disabled")

static func mark_selected(target: Control, selected: bool) -> void:
	if target == null:
		return
	target.set_meta("touch_selected", selected)
	apply_state(target, TouchState.SELECTED if selected else TouchState.NORMAL)

static func mark_disabled(target: Control, disabled: bool) -> void:
	if target == null:
		return
	target.set_meta("touch_disabled", disabled)
	if target is BaseButton:
		(target as BaseButton).disabled = disabled
	apply_state(target, TouchState.DISABLED if disabled else TouchState.NORMAL)

static func install_long_press_detail(target: Control, payload: Variant, on_long_press: Callable = Callable()) -> void:
	if target == null:
		return
	target.set_meta("long_press_detail_payload", payload)
	target.set_meta("long_press_detail_enabled", true)
	# 鎮島錄 — 可選長按攔截 callback（回傳 true 表已處理 → 不顯示詳情 overlay）。
	# 手牌長按合符用；reward/shop/map 不傳此參數 → 維持原詳情行為（向後相容）。
	if on_long_press.is_valid():
		target.set_meta("long_press_callback", on_long_press)
	if target.get_node_or_null("TouchLongPressTimer") == null:
		var timer := Timer.new()
		timer.name = "TouchLongPressTimer"
		timer.one_shot = true
		timer.wait_time = LONG_PRESS_SECONDS
		target.add_child(timer)
		timer.timeout.connect(_on_long_press_fired.bind(target))
	if not target.gui_input.is_connected(_on_gui_input_for_long_press.bind(target)):
		target.gui_input.connect(_on_gui_input_for_long_press.bind(target))

static func make_detail_overlay(payload: Variant) -> Panel:
	var panel := Panel.new()
	panel.name = "TouchDetailOverlay"
	panel.size = Vector2(500, 260)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("detail_payload", payload)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.025, 0.018, 0.97)
	style.border_color = Color(0.95, 0.72, 0.24, 0.92)
	style.set_border_width_all(4)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.70)
	style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", style)

	var seal := ColorRect.new()
	seal.name = "FuSeal"
	seal.position = Vector2(20, 18)
	seal.size = Vector2(58, 92)
	seal.color = Color(0.76, 0.06, 0.04, 0.88)
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(seal)

	var title := Label.new()
	title.name = "Title"
	title.position = Vector2(96, 24)
	title.size = Vector2(360, 38)
	title.text = _payload_title(payload)
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32, 1.0))
	panel.add_child(title)

	var label := Label.new()
	label.name = "DetailText"
	label.position = Vector2(96, 76)
	label.size = Vector2(370, 146)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = _payload_body(payload)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.80, 1.0))
	panel.add_child(label)
	return panel

static func mount_feedback_layer(root: Node) -> CanvasLayer:
	if root == null:
		return null
	var existing := root.get_node_or_null(FEEDBACK_LAYER_NAME) as CanvasLayer
	if existing != null:
		return existing
	var layer := CanvasLayer.new()
	layer.name = FEEDBACK_LAYER_NAME
	layer.layer = 90
	root.add_child(layer)
	return layer

static func play_sfx(root: Node, hook: String) -> AudioStreamPlayer:
	if root == null:
		return null
	_ensure_sfx_bus()
	var parent := _feedback_parent(root)
	var player := AudioStreamPlayer.new()
	player.name = "TouchSfxPlayer"
	player.bus = SFX_BUS_NAME
	player.volume_db = _sfx_volume_db(hook)
	player.stream = _make_click_stream(_sfx_pitch(hook))
	parent.add_child(player)
	if parent.is_inside_tree():
		player.play()
		_feed_click_tone(player, _sfx_pitch(hook))
		player.finished.connect(player.queue_free)
		player.get_tree().create_timer(0.28).timeout.connect(func(): if is_instance_valid(player): player.queue_free())
	return player

static func spawn_particle_hook(root: Node, hook: String, at: Vector2) -> CPUParticles2D:
	if root == null:
		return null
	var parent := _feedback_parent(root)
	var p := CPUParticles2D.new()
	var particle_name := "TouchFuLightFX" if hook.begins_with("fu_light") else "TouchDisabledAshFX"
	var previous := parent.get_node_or_null(particle_name)
	if previous != null:
		previous.queue_free()
		parent.remove_child(previous)
	p.name = particle_name
	p.position = at
	p.emitting = true
	p.one_shot = true
	p.amount = 28 if hook == "fu_light_selected" else 18
	p.lifetime = 0.42 if hook.begins_with("fu_light") else 0.35
	p.explosiveness = 0.92
	p.spread = 72.0 if hook.begins_with("fu_light") else 38.0
	p.gravity = Vector2(0, -18) if hook.begins_with("fu_light") else Vector2(0, 32)
	p.initial_velocity_min = 22.0
	p.initial_velocity_max = 86.0 if hook == "fu_light_selected" else 48.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0 if hook.begins_with("fu_light") else 3.0
	var g := Gradient.new()
	if hook.begins_with("fu_light"):
		g.set_color(0.0, Color(1.0, 0.92, 0.36, 0.0))
		g.set_color(0.18, Color(1.0, 0.82, 0.22, 0.92))
		g.set_color(0.72, Color(0.95, 0.18, 0.12, 0.46))
		g.set_color(1.0, Color(1.0, 0.70, 0.20, 0.0))
	else:
		g.set_color(0.0, Color(0.48, 0.44, 0.40, 0.0))
		g.set_color(0.35, Color(0.48, 0.44, 0.40, 0.42))
		g.set_color(1.0, Color(0.20, 0.18, 0.16, 0.0))
	p.color_ramp = g
	parent.add_child(p)
	if parent.is_inside_tree():
		p.get_tree().create_timer(p.lifetime + 0.2).timeout.connect(func(): if is_instance_valid(p): p.queue_free())
	return p

static func get_reward_style(kind: String, rarity: int = 0) -> Dictionary:
	return COTIW_UI_THEME.get_reward_button_style(kind, rarity)

static func apply_reward_style(button: Button, kind: String, rarity: int = 0) -> void:
	COTIW_UI_THEME.style_reward_button(button, kind, rarity)

static func _is_disabled(target: Control) -> bool:
	return target is BaseButton and (target as BaseButton).disabled

static func _feedback_parent(root: Node) -> Node:
	if not root.is_inside_tree():
		return root
	var layer := root.get_node_or_null(FEEDBACK_LAYER_NAME) as CanvasLayer
	if layer != null:
		return layer
	if root is Control:
		return mount_feedback_layer(root)
	return root

static func _ensure_sfx_bus() -> void:
	if AudioServer.get_bus_index(SFX_BUS_NAME) >= 0:
		return
	AudioServer.add_bus(AudioServer.get_bus_count())
	AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, SFX_BUS_NAME)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS_NAME), -6.0)

static func _make_click_stream(_pitch: float = 1.0) -> AudioStreamGenerator:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.08
	return stream

static func _feed_click_tone(player: AudioStreamPlayer, pitch: float) -> void:
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var sample_rate := 22050.0
	var total := int(sample_rate * 0.055)
	var base_freq := 880.0 * pitch
	for i in total:
		var t := float(i) / sample_rate
		var envelope := 1.0 - (float(i) / float(total))
		var wave := sin(TAU * base_freq * t) * 0.18 * envelope
		playback.push_frame(Vector2(wave, wave))

static func _sfx_volume_db(hook: String) -> float:
	match hook:
		"ui/touch_disabled": return -16.0
		"ui/touch_selected": return -7.0
		_: return -10.0

static func _sfx_pitch(hook: String) -> float:
	match hook:
		"ui/touch_selected": return 1.18
		"ui/touch_disabled": return 0.72
		_: return 1.0

static func _payload_title(payload: Variant) -> String:
	if payload is Dictionary:
		return str(payload.get("name", payload.get("label", payload.get("type", TranslationServer.translate("touch.detail")))))
	return TranslationServer.translate("touch.detail")

static func _payload_body(payload: Variant) -> String:
	if payload is Dictionary:
		if payload.has("description"):
			return str(payload["description"])
		return JSON.stringify(payload, "  ")
	return str(payload)

static func _on_button_down(target: Control) -> void:
	if _is_disabled(target):
		apply_state(target, TouchState.DISABLED)
		return
	apply_state(target, TouchState.PRESSED)

static func _on_button_up(target: Control, selected_predicate: Callable = Callable()) -> void:
	if _is_disabled(target):
		apply_state(target, TouchState.DISABLED)
		return
	var selected := false
	if selected_predicate.is_valid():
		selected = bool(selected_predicate.call())
	else:
		selected = bool(target.get_meta("touch_selected", false))
	apply_state(target, TouchState.SELECTED if selected else TouchState.NORMAL)

static func _on_button_toggled(toggled_on: bool, target: Control) -> void:
	mark_selected(target, toggled_on)

static func _on_gui_input_for_long_press(event: InputEvent, target: Control) -> void:
	var timer := target.get_node_or_null("TouchLongPressTimer") as Timer
	if timer == null:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			timer.start()
		else:
			timer.stop()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				timer.start()
			else:
				timer.stop()
		elif mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			_show_detail_overlay(target)

## 長按計時器到點：先嘗試攔截 callback（合符）；未處理才顯示詳情 overlay。
static func _on_long_press_fired(target: Control) -> void:
	if target != null and target.has_meta("long_press_callback"):
		var cb: Callable = target.get_meta("long_press_callback")
		if cb.is_valid() and bool(cb.call()):
			return	# 已處理（如手牌合符）→ 不顯示詳情
	_show_detail_overlay(target)

static func _show_detail_overlay(target: Control) -> void:
	if target == null or not target.has_meta("long_press_detail_payload"):
		return
	var root := target.get_tree().root if target.get_tree() != null else null
	if root == null:
		return
	var existing := root.get_node_or_null("TouchDetailOverlay")
	if existing != null:
		existing.queue_free()
	var overlay := make_detail_overlay(target.get_meta("long_press_detail_payload"))
	root.add_child(overlay)
	position_detail_overlay(overlay, target)	# UIQA Phase5：safe-rect 縮放 + 目標相對定位 + clamp（取代固定 Vector2(390,240)）

## UIQA — detail overlay 手機友善定位：
##  - 依 safe-rect 縮放使寬度 ≤ 80%（panel 內部固定版面，用 scale 保比例不裁字）
##  - 依目標 global rect：優先放目標上方，不足則翻到下方；最終 clamp 進 safe-rect
static func position_detail_overlay(overlay: Control, target: Control) -> void:
	if overlay == null or target == null:
		return
	var safe: Rect2 = COTIW_UI_THEME.get_safe_content_rect(target.get_viewport())
	var base: Vector2 = overlay.size	# make_detail_overlay 預設 500×260
	var max_w: float = safe.size.x * 0.8
	var scale: float = minf(1.0, max_w / maxf(1.0, base.x))
	overlay.scale = Vector2(scale, scale)
	var eff: Vector2 = base * scale
	var tr: Rect2 = target.get_global_rect()
	var x: float = tr.position.x + (tr.size.x - eff.x) * 0.5	# 水平對齊目標中心
	var y: float = tr.position.y - eff.y - 12.0					# 優先目標上方
	if y < safe.position.y:
		y = tr.position.y + tr.size.y + 12.0					# 不足 → 翻到目標下方
	overlay.position = COTIW_UI_THEME.clamp_rect_to_safe_area(Rect2(Vector2(x, y), eff), safe).position
