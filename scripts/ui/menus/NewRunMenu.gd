extends Control

@onready var title_screen: Control = $%TitleScreen

@onready var character_name_label = $CharacterNameLabel
@onready var character_health_label = $CharacterHealthLabel
@onready var character_money_label = $CharacterMoneyLabel
@onready var character_description_label = $CharacterDescriptionLabel

@onready var character_artifact_texture_rect = $CharacterArtifactTextureRect
@onready var character_artifact_name_label = $CharacterArtifactNameLabel
@onready var character_artifact_description_label = $CharacterArtifactDescriptionLabel

@onready var decrease_difficulty_button = $DifficultySelect/DecreaseDifficultyButton
@onready var difficulty_label = $DifficultySelect/DifficultyLabel
@onready var increase_difficulty_button = $DifficultySelect/IncreaseDifficultyButton

@onready var custom_run_modifier_button_container = $CustomRunModifierButtonContainer

@onready var character_button_container = $CharacterButtonContainer

@onready var start_run_button: Button = $StartRunButton
@onready var seed_input: LineEdit = $SeedInput
@onready var back_button: Button = $BackButton

var selected_character_object_id: String = ""
var selected_difficulty_level: int = 0

# portrait gallery highlight nodes keyed by character_object_id
var _portrait_highlights: Dictionary = {}

func _ready():
	start_run_button.button_up.connect(_on_start_run_button_up)
	back_button.button_up.connect(_on_back_button_up)
	
	decrease_difficulty_button.button_up.connect(_on_decrease_difficulty_button)
	increase_difficulty_button.button_up.connect(_on_increase_difficulty_button)
	
	seed_input.text_changed.connect(_on_seed_input_text_changed)
	
	Signals.character_selected.connect(_on_character_selected)
	Signals.run_ended.connect(_on_run_ended)
	# v4 Recraft pixel_art 背景 + PixelFX 動畫（香爐煙霧 + 呼吸 + Ken Burns）
	const PixelSkinCls = preload("res://scripts/ui/theme/PixelSkin.gd")
	const PixelFXCls   = preload("res://scripts/ui/fx/PixelFX.gd")
	var _newrun_layer = PixelSkinCls.apply_background(self, "newrun_bg_v5.png")
	if _newrun_layer:
		PixelFXCls.apply(_newrun_layer, PixelFXCls.Preset.SMOKE)
	# v2 三角色立繪 gallery（廟堂 3 基座位置）
	_apply_portrait_gallery()

func _apply_portrait_gallery() -> void:
	const PORTRAIT_DIR := "res://assets/generated/portraits_v3/"
	var chars: Array = [
		{"file": "tongji.png",  "label": "乩童", "locked": false, "character_id": "character_tongji"},
		{"file": "luannu.png",  "label": "鸞女", "locked": false, "character_id": "character_luannu"},
		{"file": "daoshi.png",  "label": "道士", "locked": true,  "character_id": ""},
		{"file": "jiajiang.png","label": "家將", "locked": true,  "character_id": ""},
	]

	# 用 Control 而非 CanvasLayer，自動繼承 NewRunMenu visible 狀態
	var layer := Control.new()
	layer.name = "PortraitGallery"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.z_index = 5
	add_child(layer)

	var vp := get_viewport()
	var screen_w: float = vp.get_visible_rect().size.x if vp else 1200.0
	var screen_h: float = vp.get_visible_rect().size.y if vp else 700.0
	var n: int = chars.size()
	var portrait_w: float = screen_w * (0.18 if n <= 3 else 0.14)
	var portrait_h: float = screen_h * 0.72
	var slot_gap: float = screen_w * (0.03 if n <= 3 else 0.02)
	var total_w: float = portrait_w * n + slot_gap * (n - 1)
	var start_x: float = (screen_w - total_w) * 0.5

	_portrait_highlights.clear()

	for i in chars.size():
		var c: Dictionary = chars[i]
		var path: String = PORTRAIT_DIR + c.file
		if not ResourceLoader.exists(path):
			continue
		var x: float = start_x + i * (portrait_w + slot_gap)
		var y: float = (screen_h - portrait_h) * 0.5

		# selection highlight border (gold rim, hidden until selected)
		if not c.locked and c.character_id != "":
			var highlight := ColorRect.new()
			highlight.name = "Highlight_" + c.character_id
			highlight.color = Color(0.95, 0.82, 0.45, 0.25)
			highlight.position = Vector2(x - 4, y - 4)
			highlight.size = Vector2(portrait_w + 8, portrait_h + 8)
			highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
			highlight.visible = false
			layer.add_child(highlight)
			_portrait_highlights[c.character_id] = highlight

		var rect := TextureRect.new()
		rect.name = "Portrait_" + c.file.get_basename()
		rect.texture = load(path)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.position = Vector2(x, y)
		rect.size = Vector2(portrait_w, portrait_h)
		rect.modulate = Color(0.45, 0.45, 0.45, 0.7) if c.locked else Color(1, 1, 1, 0.95)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(rect)

		# 角色名 label
		var lbl := Label.new()
		lbl.text = c.label + ("（鎖）" if c.locked else "")
		lbl.position = Vector2(x, y + portrait_h - 8)
		lbl.size = Vector2(portrait_w, 32)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45) if not c.locked else Color(0.6, 0.55, 0.5))
		layer.add_child(lbl)

		# invisible click button over unlocked portrait
		if not c.locked and c.character_id != "":
			var btn := Button.new()
			btn.name = "PortraitBtn_" + c.file.get_basename()
			btn.position = Vector2(x, y)
			btn.size = Vector2(portrait_w, portrait_h)
			btn.flat = true
			btn.self_modulate = Color(1, 1, 1, 0)  # fully transparent
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			layer.add_child(btn)
			var char_id: String = c.character_id
			btn.button_up.connect(func(): Signals.character_selected.emit(char_id))

func _on_seed_input_text_changed(new_text: String):
	# validate the input of the line edit
	var caret_column: int = seed_input.caret_column	# store cursor position as changing text resets it
	seed_input.text = str(new_text.to_int()) # validate inputs to only int
	seed_input.caret_column = min(caret_column, len(seed_input.text)) # reset the cursor position

func _on_character_selected(character_object_id: String):
	selected_character_object_id = character_object_id
	populate_character_info(selected_character_object_id)
	_update_portrait_highlights(character_object_id)

func _update_portrait_highlights(active_character_id: String) -> void:
	for char_id in _portrait_highlights:
		var highlight: ColorRect = _portrait_highlights[char_id]
		if is_instance_valid(highlight):
			highlight.visible = (char_id == active_character_id)

func _on_decrease_difficulty_button():
	selected_difficulty_level = max(0, selected_difficulty_level -1)
	difficulty_label.text = "Difficulty " + str(selected_difficulty_level)
func _on_increase_difficulty_button():
	selected_difficulty_level = min(selected_difficulty_level + 1, len(PlayerData.DIFFICULTY_RUN_MODIFIER_OBJECT_IDS))
	difficulty_label.text = "Difficulty " + str(selected_difficulty_level)

func populate_new_run_menu() -> void:
	character_button_container.populate_character_buttons()
	custom_run_modifier_button_container.populate_custom_run_modifiers()

func populate_character_info(character_object_id: String) -> void:
	var character_data: CharacterData = Global.get_character_data(character_object_id)
	if character_data != null:
		character_name_label.text = character_data.character_name
		character_health_label.text = "HP: {0}".format([character_data.character_starting_health])
		character_money_label.text = "Money: {0}".format([character_data.character_starting_money])
		character_description_label.text = character_data.character_description
		
		# TODO potentially update ui to support multiple starter artifacts displayed
		if len(character_data.character_starting_artifact_ids) > 0:
			var artifact_data: ArtifactData = Global.get_artifact_data(character_data.character_starting_artifact_ids[0])
			if artifact_data != null:
				character_artifact_texture_rect.texture = CardArtRegistry.resolve_artifact_texture(artifact_data)
				character_artifact_name_label.text = artifact_data.artifact_name
				character_artifact_description_label.text = artifact_data.artifact_description

func _on_start_run_button_up():
	# get the seed and start the run
	var run_seed: int = seed_input.text.to_int()
	Global.start_run(selected_character_object_id, run_seed, selected_difficulty_level, custom_run_modifier_button_container.selected_custom_run_modififers)

func _on_back_button_up():
	title_screen.show_main_menu()

func _on_run_ended():
	# go back to tile screen on failed run, but not abandoned run
	var has_save_file: bool = FileLoader.has_save_file()
	visible = not has_save_file
	populate_new_run_menu()
