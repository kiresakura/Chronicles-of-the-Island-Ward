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

func _ready():
	start_run_button.button_up.connect(_on_start_run_button_up)
	back_button.button_up.connect(_on_back_button_up)
	
	decrease_difficulty_button.button_up.connect(_on_decrease_difficulty_button)
	increase_difficulty_button.button_up.connect(_on_increase_difficulty_button)
	
	seed_input.text_changed.connect(_on_seed_input_text_changed)
	
	Signals.character_selected.connect(_on_character_selected)
	Signals.run_ended.connect(_on_run_ended)
	# v2 pixel skin（角色選擇廟堂內景）
	const PixelSkinCls = preload("res://scripts/ui/theme/PixelSkin.gd")
	PixelSkinCls.apply_background(self, "newrun_bg.webp")
	# v2 三角色立繪 gallery（廟堂 3 基座位置）
	_apply_portrait_gallery()

func _apply_portrait_gallery() -> void:
	const PORTRAIT_DIR := "res://assets/generated/portraits_v2/"
	var chars: Array = [
		{"file": "tongji.png", "label": "乩童", "locked": false},
		{"file": "daoshi.png", "label": "道士", "locked": true},
		{"file": "jiajiang.png", "label": "家將", "locked": true},
	]

	# 用 Control 而非 CanvasLayer，自動繼承 NewRunMenu visible 狀態
	var layer := Control.new()
	layer.name = "PortraitGallery"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = 5
	add_child(layer)

	var vp := get_viewport()
	var screen_w: float = vp.get_visible_rect().size.x if vp else 1200.0
	var screen_h: float = vp.get_visible_rect().size.y if vp else 700.0
	var portrait_w: float = screen_w * 0.18
	var portrait_h: float = screen_h * 0.72
	var slot_gap: float = screen_w * 0.03
	var total_w: float = portrait_w * 3 + slot_gap * 2
	var start_x: float = (screen_w - total_w) * 0.5

	for i in chars.size():
		var c: Dictionary = chars[i]
		var path: String = PORTRAIT_DIR + c.file
		if not ResourceLoader.exists(path):
			continue
		var x: float = start_x + i * (portrait_w + slot_gap)
		var y: float = (screen_h - portrait_h) * 0.5

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

func _on_seed_input_text_changed(new_text: String):
	# validate the input of the line edit
	var caret_column: int = seed_input.caret_column	# store cursor position as changing text resets it
	seed_input.text = str(new_text.to_int()) # validate inputs to only int
	seed_input.caret_column = min(caret_column, len(seed_input.text)) # reset the cursor position

func _on_character_selected(character_object_id: String):
	selected_character_object_id = character_object_id
	populate_character_info(selected_character_object_id)

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
				character_artifact_texture_rect.texture = FileLoader.load_texture(artifact_data.artifact_texture_path)
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
