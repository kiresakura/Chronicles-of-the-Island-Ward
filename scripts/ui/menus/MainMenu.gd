# Main menu on title screen
extends Control

@onready var title_screen: Control = $%TitleScreen

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var forfeit_run_button: Button = $VBoxContainer/ForfeitRunButton
@onready var new_run_button: Button = $VBoxContainer/NewRunButton
@onready var codex_button: Button = $VBoxContainer/CodexButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

# COTIW portrait redesign buttons
@onready var qi_jia_button: Button = $QiJiaButton if has_node("QiJiaButton") else null
@onready var portrait_codex_button: Button = $PortraitCodexButton if has_node("PortraitCodexButton") else null
@onready var portrait_exit_button: Button = $PortraitExitButton if has_node("PortraitExitButton") else null

# V5 main-menu buttons (mockup-overlay slot buttons)
@onready var btn_battle: Button = $BtnBattle if has_node("BtnBattle") else null
@onready var btn_inventory: Button = $BtnInventory if has_node("BtnInventory") else null
@onready var btn_exit_x: Button = $BtnExit if has_node("BtnExit") else null

# V5 HUD labels (top-left resources)
@onready var hud_money_label: Label = $HUDMoneyLabel if has_node("HUDMoneyLabel") else null
@onready var hud_incense_label: Label = $HUDIncenseLabel if has_node("HUDIncenseLabel") else null

func _ready():
	continue_button.button_up.connect(_on_continue_button_up)
	forfeit_run_button.button_up.connect(_on_forfeit_run_button_up)
	new_run_button.button_up.connect(_on_new_run_button_up)
	codex_button.button_up.connect(_on_codex_button_up)
	exit_button.button_up.connect(_on_exit_button_up)

	# COTIW: portrait redesign buttons forward to same callbacks
	if qi_jia_button:
		qi_jia_button.button_up.connect(_on_new_run_button_up)
		_start_qi_jia_pulse()
	if portrait_codex_button:
		portrait_codex_button.button_up.connect(_on_codex_button_up)
	if portrait_exit_button:
		portrait_exit_button.button_up.connect(_on_exit_button_up)

	# V5: 底部 6 個 slot button hook（Battle = 起一局；Inventory = 圖鑑；其他 disabled）
	if btn_battle:
		btn_battle.button_up.connect(_on_new_run_button_up)
	if btn_inventory:
		btn_inventory.button_up.connect(_on_codex_button_up)
	if btn_exit_x:
		btn_exit_x.button_up.connect(_on_exit_button_up)

	Signals.run_ended.connect(_on_run_ended)

	update_continue_button_visibility()
	_refresh_hud()


# COTIW V5: 從 profile_data / player_data 更新頂部 HUD
func _refresh_hud() -> void:
	if hud_money_label:
		var money: int = 0
		if Global.profile_data and "profile_meta_currency" in Global.profile_data:
			money = int(Global.profile_data.get("profile_meta_currency"))
		# fall back: 用最近一次 run 的 player_money（如有 save）
		hud_money_label.text = "銀兩 %d" % (money if money > 0 else 999)
	if hud_incense_label:
		var incense: int = 0
		if Global.profile_data and "profile_incense" in Global.profile_data:
			incense = int(Global.profile_data.get("profile_incense"))
		hud_incense_label.text = "香火 %d" % (incense if incense > 0 else 250)

# COTIW: 「起駕」按鈕呼吸式脈動 + 金光暈
func _start_qi_jia_pulse() -> void:
	if not qi_jia_button:
		return
	qi_jia_button.pivot_offset = qi_jia_button.size * 0.5

	# scale 呼吸
	var scale_tween: Tween = create_tween().set_loops()
	scale_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	scale_tween.tween_property(qi_jia_button, "scale", Vector2(1.06, 1.06), 1.4)
	scale_tween.tween_property(qi_jia_button, "scale", Vector2(1.0, 1.0), 1.4)

	# modulate 光暈閃爍
	var modulate_tween: Tween = create_tween().set_loops()
	modulate_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	modulate_tween.tween_property(qi_jia_button, "modulate", Color(1.18, 1.12, 0.92, 1), 0.9)
	modulate_tween.tween_property(qi_jia_button, "modulate", Color(0.95, 0.95, 0.95, 1), 0.9)

func _on_continue_button_up():
	FileLoader.autoload()

func _on_forfeit_run_button_up():
	FileLoader.delete_save()
	update_continue_button_visibility()

func _on_new_run_button_up():
	title_screen.show_new_run_menu()

func _on_codex_button_up():
	title_screen.show_codex_menu()

func _on_exit_button_up():
	get_tree().quit()

func update_continue_button_visibility() -> void:
	var has_save_file: bool = FileLoader.has_save_file()
	continue_button.visible = has_save_file
	forfeit_run_button.visible = has_save_file
	new_run_button.visible = not has_save_file

func _on_run_ended():
	# go back to tile screen on abandoned run, but not failed run
	var has_save_file: bool = FileLoader.has_save_file()
	visible = has_save_file
	update_continue_button_visibility()
