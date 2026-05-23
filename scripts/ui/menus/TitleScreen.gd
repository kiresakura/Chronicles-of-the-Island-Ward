# title screen of game
# composed of sub menus with their own logic
# does nothing except control sub menu display logic
extends Control

const CharacterPanelScript := preload("res://scripts/ui/menus/CharacterPanel.gd")

@onready var main_menu = $MainMenu
@onready var new_run_menu = $NewRunMenu
@onready var codex_menu = $CodexMenu
@onready var _background: ColorRect = $Background if has_node("Background") else null

var _character_panel: Control

func _ready():
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)

	# 自適應地基：TitleScreen 與底色撐滿整個 viewport（expand 下不留空白）
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _background:
		_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# MainMenu 自己做完整自適應；NewRunMenu/CodexMenu 為固定 1200×700 版面，
	# 用 SafeFit 等比置中塞進安全區（Phase 1；戰鬥/地圖等留 Phase 2）
	SafeFit.bind(new_run_menu)
	SafeFit.bind(codex_menu)

	# 角色面板：程序化建構，動態 add_child（不需要 .tscn 節點）
	_character_panel = Control.new()
	_character_panel.set_script(CharacterPanelScript)
	_character_panel.name    = "CharacterPanel"
	_character_panel.visible = false
	add_child(_character_panel)

func hide_menus():
	main_menu.visible = false
	new_run_menu.visible = false
	codex_menu.visible = false
	if is_instance_valid(_character_panel):
		_character_panel.visible = false

func show_main_menu():
	hide_menus()
	main_menu.visible = true

func show_new_run_menu():
	hide_menus()
	new_run_menu.visible = true
	new_run_menu.populate_new_run_menu()

func show_codex_menu():
	hide_menus()
	codex_menu.visible = true
	codex_menu.populate_codex_menu()

func show_character_panel():
	hide_menus()
	if is_instance_valid(_character_panel):
		_character_panel.visible = true

func _on_run_started():
	visible = false

func _on_run_ended():
	visible = true
