# 鎮島錄 — 主畫面（全向量 + 螢幕自適應）
#
# 設計：用戶 V5 mockup（廟宇 lobby，橫向）。chrome 為程序化向量（StyleBox + 自繪背景），
# icon 為 SVG。所有座標**不寫死 1200×700**，改由 Responsive.safe_rect 即時計算，
# 邊緣 UI 一律落在裝置安全區內（避瀏海/動態島/home indicator）；背景全出血填滿螢幕。
# 既有 Root.tscn 節點（QiJiaButton / Btn* / VBoxContainer 邏輯鈕）保留以維持導航/存檔。
extends Control

const ICON_DIR := "res://assets/ui/icons/"
const BACKDROP_SCRIPT := preload("res://scripts/ui/menus/VectorTempleBackdrop.gd")
const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const LOBBY_ACTIONS_PATH := "res://external/data/ui/lobby_actions.json"
const LOBBY_UTILITIES_PATH := "res://external/data/ui/lobby_utilities.json"

# 廟會配色 —— 全部由 design_tokens.json 經 CotiwUiTheme 提供（_ready 賦值）
var GOLD: Color = Color(0.95, 0.82, 0.45)
var GOLD_DIM: Color = Color(0.62, 0.49, 0.24)
var PANEL_BG: Color = Color(0.20, 0.07, 0.06, 0.53)
var PANEL_BG_HOVER: Color = Color(0.34, 0.11, 0.09, 0.96)
var PANEL_BG_LOCK: Color = Color(0.13, 0.09, 0.09, 0.80)

@onready var title_screen: Control = $%TitleScreen
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var forfeit_run_button: Button = $VBoxContainer/ForfeitRunButton
@onready var new_run_button: Button = $VBoxContainer/NewRunButton
@onready var codex_button: Button = $VBoxContainer/CodexButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var qi_jia_button: Button = $QiJiaButton if has_node("QiJiaButton") else null
@onready var btn_exit_x: Button = $BtnExit if has_node("BtnExit") else null

const MascotPanelScript := preload("res://scripts/ui/MascotPanel.gd")
const MascotSelectorScript := preload("res://scripts/ui/menus/MascotSelector.gd")
var _mascot_panel: MascotPanel = null
var _mascot_selector: MascotSelector = null

# 自適應重排用的節點參照
var _backdrop: Control
var _avatar_frame: Panel
var _res_rows: Array = []          # 每列 {icon,pill,label,fill}
var _resource_tray: Panel
var _slot_btns: Array[Button] = []
var _util_btns: Array[Button] = []
var _res_incense: Label
var _res_level: Label
var _res_yuanbao: Label
var _level_fill: ColorRect
var _slot_definitions: Array = []
var _utility_definitions: Array = []

func _ready() -> void:
	GOLD = COTIW_UI_THEME.get_color("incense_gold", GOLD)
	GOLD_DIM = COTIW_UI_THEME.get_color("old_gold", GOLD_DIM)
	PANEL_BG = COTIW_UI_THEME.get_color("panel_bg", PANEL_BG)
	PANEL_BG_HOVER = COTIW_UI_THEME.get_color("panel_bg_hover", PANEL_BG_HOVER)
	PANEL_BG_LOCK = COTIW_UI_THEME.get_color("panel_bg_lock", PANEL_BG_LOCK)
	_slot_definitions = _load_ui_definition_array(LOBBY_ACTIONS_PATH)
	_utility_definitions = _load_ui_definition_array(LOBBY_UTILITIES_PATH)
	_hide_legacy_nodes()
	_add_backdrop()
	_build_avatar()
	_build_resource_bars()
	_build_slots()
	_build_utilities()
	_build_primary()

	Signals.run_ended.connect(_on_run_ended)
	Responsive.changed.connect(_relayout)
	update_continue_button_visibility()
	_refresh_resources()
	# Responsive autoload 以 call_deferred 算 safe_rect；等一幀再首次排版
	await get_tree().process_frame
	_relayout()
	# v2 pixel skin（additive，蓋在 _build_* 之上）
	_apply_pixel_skin()

# ---------- v2 像素皮（Recraft 美術 additive 層）----------
# 蓋在程序化向量背景之上：底襯 → 神龕 → 標題匾，UI 元素留在最上層。
# 鐵律 3 友善：不動 STR 既有節點。
## BG 時段變體 — 由 _pick_bg_for_time_of_day() 依系統時間挑選
const PIXEL_BG_DAY   := "res://assets/generated/pixellab/mainmenu_temple_day.png"
const PIXEL_BG_DUSK  := "res://assets/generated/pixellab/mainmenu_temple_dusk.png"
const PIXEL_BG_NIGHT := "res://assets/generated/pixellab/mainmenu_temple_night.png"
const PIXEL_BG_V6    := "res://assets/generated/pixellab/mainmenu_temple_v6.png"   # fallback dusk
const PIXEL_BG_PATH  := PIXEL_BG_V6   # 保留向後相容，但實際走 _pick

## 系統時間決定 bg：05-10=day, 10-17=day, 17-19=dusk, 19-05=night
static func _pick_bg_for_time_of_day() -> String:
	var hour: int = Time.get_time_dict_from_system().get("hour", 18)
	if hour >= 5 and hour < 17:
		return PIXEL_BG_DAY
	elif hour >= 17 and hour < 19:
		return PIXEL_BG_DUSK
	else:
		return PIXEL_BG_NIGHT
const PIXEL_ALTAR_PATH := "res://assets/generated/pixellab/altar_shrine_v3.png"
const PIXEL_TITLE_PATH := "res://assets/generated/ui_v3/title_plaque.png"
const PIXEL_CTA_PATH := "res://assets/generated/ui_v3/cta_button_frame.png"

var _pixel_bg: TextureRect
var _pixel_altar: TextureRect
var _pixel_title: TextureRect
var _plaque_label: Label = null			# P0-1 匾額文字（廟名+廟級）
var _plaque_shown_once: bool = false	# 首次顯示才淡入（之後刷新不重播）
const RITUAL_TEMPLE := preload("res://scripts/systems/ritual/RitualTemple.gd")
const UI_TOAST := preload("res://ui/components/toast.gd")	# P1-5 可重用 toast
const LOCKED_OVERLAY := preload("res://ui/components/locked_overlay.gd")	# P1-6 鎖定覆蓋

func _apply_pixel_skin() -> void:
	# 1. 隱藏舊向量 backdrop
	if is_instance_valid(_backdrop):
		_backdrop.visible = false

	# 2. 底襯 — 用 CanvasLayer 強制 fullscreen，繞過 MainMenu Control 尺寸限制
	# 依系統時間選 day/dusk/night 變體（pick fallback chain）
	var bg_picked: String = _pick_bg_for_time_of_day()
	if not ResourceLoader.exists(bg_picked):
		bg_picked = PIXEL_BG_V6
	if ResourceLoader.exists(bg_picked):
		var bg_layer := CanvasLayer.new()
		bg_layer.name = "PixelBgLayer"
		bg_layer.layer = -10  # 在預設 layer 之下
		add_child(bg_layer)
		move_child(bg_layer, 0)

		_pixel_bg = TextureRect.new()
		_pixel_bg.name = "PixelBackdrop"
		_pixel_bg.texture = load(bg_picked)
		_pixel_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_pixel_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_pixel_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST	# P0-2 像素素材銳利取樣（全域 filter 維持 Linear — 高解析卡圖/bust 不受害）
		_pixel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 與 PixelSkin 相同：在 CanvasLayer 下改用絕對 size 控制，不用 (0,0,1,1) anchors，
		# 避免引擎於 _ready 後回寫尺寸而觸發 Control anchor warning。
		_pixel_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		bg_layer.add_child(_pixel_bg)
		# 顯式設定為 viewport 大小
		var vp := get_viewport()
		if vp:
			_pixel_bg.size = vp.get_visible_rect().size
		else:
			_pixel_bg.size = Vector2(1200, 700)
		# PixelFX：煙火 + 火星 + 呼吸 shader + Ken Burns
		const PixelFXCls = preload("res://scripts/ui/fx/PixelFX.gd")
		PixelFXCls.apply(bg_layer, PixelFXCls.Preset.FIREWORKS)
	else:
		push_warning("PIXEL_BG_PATH not found: " + PIXEL_BG_PATH)

	# 3. 中央神龕 — 已被看板娘取代（_build_mascot 在中央），不再 instantiate。
	# 若日後想恢復可把這段 uncomment。
	# if ResourceLoader.exists(PIXEL_ALTAR_PATH):
	# 	_pixel_altar = TextureRect.new()
	# 	_pixel_altar.name = "PixelAltar"
	# 	_pixel_altar.texture = load(PIXEL_ALTAR_PATH)
	# 	_pixel_altar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# 	_pixel_altar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# 	_pixel_altar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 	_pixel_altar.z_index = -50
	# 	_pixel_altar.z_as_relative = false
	# 	add_child(_pixel_altar)

	# 4. 標題匾（HUD top area）
	if ResourceLoader.exists(PIXEL_TITLE_PATH):
		_pixel_title = TextureRect.new()
		_pixel_title.name = "PixelTitlePlaque"
		_pixel_title.texture = load(PIXEL_TITLE_PATH)
		_pixel_title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_pixel_title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_pixel_title.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST	# P0-2 像素素材銳利取樣
		_pixel_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pixel_title.z_index = -40
		_pixel_title.z_as_relative = false
		_pixel_title.visible = false	# P0-1 空狀態鐵則：資料就緒前整組不可見
		add_child(_pixel_title)
		# P0-1：匾額文字 — 廟名 + 廟級（方案 A，接修廟系統真資料）
		_plaque_label = Label.new()
		_plaque_label.name = "PlaqueText"
		_plaque_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_plaque_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# 不設 anchors — 位置/尺寸由 _relayout 對齊「實繪匾面」計算
		_plaque_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_plaque_label.add_theme_font_size_override("font_size", COTIW_UI_THEME.get_typography_size("h2", 28))
		_plaque_label.add_theme_color_override("font_color", GOLD)
		_plaque_label.add_theme_color_override("font_shadow_color", Color(0.07, 0.03, 0.02, 0.95))
		_plaque_label.add_theme_constant_override("shadow_offset_x", 2)
		_plaque_label.add_theme_constant_override("shadow_offset_y", 2)
		_pixel_title.add_child(_plaque_label)
		_refresh_plaque()

	# 5. CTA「起駕」按鈕 — 改用 CotiwUiTheme 程序化 StyleBox（紅金圓角）。
	# 原 cta_button_frame.png 是 NBP「去背圖」，實際把透明格紋畫進圖裡（非真 alpha），
	# 套上去會帶灰格背景。程序化 StyleBox 無底圖 → 零去背問題，_build_primary 已套。

	# 6. 看板娘 — 動畫角色 sprite，覆蓋在神龕中央上方
	_build_mascot()

	# 7. 活動 banner — 右側中部，1999-style 大型橫幅
	_build_activity_banner()

	# 8. 前景物件 hot zones — 香爐 / 燈籠 隱形 hit-area，tap → toast (MVP)
	_build_foreground_hotspots()

	_layout_pixel_skin()

# ────────────────────────────────────────────────
# 前景物件 hot zones（MVP — Phase 3B）
# ────────────────────────────────────────────────
var _hotspot_censer: Button = null
var _hotspot_lantern: Button = null

func _build_foreground_hotspots() -> void:
	# 香爐 hot zone（右下，廟宇前空地）
	_hotspot_censer = _make_invisible_hotspot("CenserHot")
	_hotspot_censer.button_up.connect(func(): _show_coming_soon(tr("menu.hotspot_censer")))
	add_child(_hotspot_censer)

	# 燈籠 hot zone（右上方紅燈籠群）
	_hotspot_lantern = _make_invisible_hotspot("LanternHot")
	_hotspot_lantern.button_up.connect(func(): _show_coming_soon(tr("menu.hotspot_lantern")))
	add_child(_hotspot_lantern)

func _make_invisible_hotspot(node_name: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.self_modulate = Color(1, 1, 1, 0)   # 透明 hit area
	return b

# ────────────────────────────────────────────────
# 活動 banner（UI 重修 P0-3：可點 Button 根 + 倒數 + 獎勵預覽，包覆內容）
# 資料：external/data/ui/lobby_events.json（假活動資料 — 鐵律 1 數值在資料層）
# TODO(正式接入點): 未來活動系統/伺服器下發 end_ts 後，改呼叫
#   set_event_end_time(server_ts) 取代 JSON duration 推算（QUESTIONS 待立項）
# ────────────────────────────────────────────────
const LOBBY_EVENTS_PATH := "res://external/data/ui/lobby_events.json"

## 活動入口被點擊（入口場景尚未存在 — 接收端暫走 coming_soon toast；
## TODO(正式接入點): 活動 overlay 場景落地後改開該場景）
signal event_panel_pressed(event_id: String)

var _activity_banner: Button = null
var _event_id: String = ""
var _event_end_unix: int = 0
var _event_countdown_label: Label = null
var _event_timer: Timer = null
var _banner_breath_tween: Tween = null

func _build_activity_banner() -> void:
	var events: Array = _load_ui_definition_array(LOBBY_EVENTS_PATH)
	if events.is_empty():
		return	# 無活動資料 → 不建面板（空狀態 = 不存在，與匾額同哲學）
	var ev: Dictionary = events[0]
	_event_id = str(ev.get("event_id", ""))

	# 根 = Button：theme 四態（P0-2）自帶 normal/hover/pressed 視覺回饋
	_activity_banner = Button.new()
	_activity_banner.name = "ActivityBanner"
	_activity_banner.focus_mode = Control.FOCUS_NONE
	_activity_banner.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_activity_banner.button_up.connect(func() -> void: event_panel_pressed.emit(_event_id))
	event_panel_pressed.connect(_on_event_panel_pressed)
	add_child(_activity_banner)

	# 內容：Margin(14) > VBox：標題 → 獎勵縮圖 → 副題 → 倒數
	var margin := MarginContainer.new()
	margin.name = "EventMargin"
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)	# 隨 Button 撐滿
	_activity_banner.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "EventVBox"
	vbox.add_theme_constant_override("separation", 6)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	var title := Label.new()
	title.name = "EventTitle"
	title.text = tr(str(ev.get("title_key", "menu.banner_event")))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_font(title, 24)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	# 獎勵縮圖（56px；佔位 = 筊杯 svg。TODO(美術): 換正式活動獎勵圖）
	var reward := TextureRect.new()
	reward.name = "EventRewardIcon"
	var icon_path: String = str(ev.get("reward_icon", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		reward.texture = load(icon_path)
	reward.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reward.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward.custom_minimum_size = Vector2(56, 56)
	reward.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(reward)

	var sub := Label.new()
	sub.name = "EventSubtitle"
	sub.text = tr(str(ev.get("subtitle_key", "menu.banner_tag")))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_font(sub, 18)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub)

	_event_countdown_label = Label.new()
	_event_countdown_label.name = "EventCountdown"
	_event_countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_countdown_label.add_theme_font_size_override("font_size", 20)
	_event_countdown_label.add_theme_color_override("font_color", COTIW_UI_THEME.get_color("paper_warm", Color.WHITE))
	_event_countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_event_countdown_label)

	# 倒數心跳（1s）；demo 結束時間 = 現在 + JSON duration_hours
	_event_timer = Timer.new()
	_event_timer.name = "EventTimer"
	_event_timer.wait_time = 1.0
	_event_timer.timeout.connect(_update_event_countdown)
	_activity_banner.add_child(_event_timer)
	set_event_end_time(int(Time.get_unix_time_from_system()) + int(ev.get("duration_hours", 24)) * 3600)

	# 呼吸縮放（2s 週期 1.0↔1.03 — 可互動提示；hover/pressed 交給 theme 四態）
	_banner_breath_tween = create_tween().set_loops()
	_banner_breath_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_banner_breath_tween.tween_property(_activity_banner, "scale", Vector2(1.03, 1.03), 1.0)
	_banner_breath_tween.tween_property(_activity_banner, "scale", Vector2.ONE, 1.0)

## 活動結束時間注入點（unix 秒）。正式接入：活動系統/伺服器下發後呼叫本函式。
func set_event_end_time(unix_ts: int) -> void:
	_event_end_unix = unix_ts
	if _event_timer != null:
		_event_timer.start()
	_update_event_countdown()

func _update_event_countdown() -> void:
	if _event_countdown_label == null or not is_instance_valid(_activity_banner):
		return
	var remain: int = _event_end_unix - int(Time.get_unix_time_from_system())
	if remain <= 0:
		# 歸零收場：隱藏面板（憲龍拍板⑤）；timer 停止避免空轉
		_activity_banner.visible = false
		_event_timer.stop()
		if _banner_breath_tween != null and _banner_breath_tween.is_valid():
			_banner_breath_tween.kill()
		return
	@warning_ignore("integer_division")
	_event_countdown_label.text = "%02d:%02d:%02d" % [remain / 3600, (remain % 3600) / 60, remain % 60]

func _on_event_panel_pressed(_pressed_event_id: String) -> void:
	# TODO(正式接入點): 活動入口場景（擲筊活動 overlay）落地後改開場景
	_show_coming_soon(tr("menu.banner_tag"))

## 看板娘 v3：全螢幕 MascotPanel，bust 高度撐滿，底邊接觸畫面下緣。
## move_child 到第一順位 → 渲染在所有 UI 之下（slot bar / CTA 浮在上面，
## bust 透過去背在 UI 後方延伸到螢幕底部）。
func _build_mascot() -> void:
	_mascot_panel = MascotPanel.new()
	_mascot_panel.name = "MascotPanel"
	_mascot_panel.mascot_tapped.connect(_on_mascot_tapped)
	# 全螢幕 size（_layout_pixel_skin 會覆寫，但先給 vp size 避開 0×0）
	var vp := get_viewport()
	var vp_size: Vector2 = vp.get_visible_rect().size if vp else Vector2(1200, 700)
	_mascot_panel.position = Vector2.ZERO
	_mascot_panel.size = vp_size
	add_child(_mascot_panel)
	# 移到 MainMenu 子節點最前（draw 順序最早 → render 在最底，UI 蓋在上面）
	move_child(_mascot_panel, 0)

	# Selector overlay — 預設隱藏，點擊看板娘 / 角色卡時顯示
	_mascot_selector = MascotSelector.new()
	_mascot_selector.name = "MascotSelector"
	_mascot_selector.visible = false
	_mascot_selector.z_index = 50  # 蓋在所有 UI 之上
	_mascot_selector.z_as_relative = false
	add_child(_mascot_selector)

func _on_mascot_tapped() -> void:
	# v5：tap mascot 不再開 selector，只看 mascot 自己的 bounce + dialog
	# 切換看板娘改走 _on_character_button_up → CharacterPanel（後續加 "設為
	# 看板娘" 按鈕）or MascotSelector keyboard shortcut
	pass

## 暫時保留：showMascotSelector 可由外部呼叫（如 CharacterPanel 內按鈕）
func show_mascot_selector() -> void:
	if is_instance_valid(_mascot_selector):
		_mascot_selector.visible = true

func _layout_pixel_skin() -> void:
	# MainMenu Control 在 Root.tscn 是 40×40（offset_right=40,offset_bottom=40），
	# self.size 不能當「畫面尺寸」用 → 改讀 viewport 的可視 rect。
	var vp := get_viewport()
	var stage_size: Vector2 = vp.get_visible_rect().size if vp != null else Vector2(1200, 700)

	# 背景底圖：跟隨 viewport 尺寸變化，避免改成 TOP_LEFT anchors 後失去自動伸展。
	if is_instance_valid(_pixel_bg):
		_pixel_bg.position = Vector2.ZERO
		_pixel_bg.size = stage_size

	# 神龕：螢幕中央（已 disabled，留代碼方便回復）
	if is_instance_valid(_pixel_altar):
		var altar_w: float = stage_size.x * 0.36
		var altar_h: float = stage_size.y * 0.62
		_pixel_altar.size = Vector2(altar_w, altar_h)
		_pixel_altar.position = Vector2((stage_size.x - altar_w) * 0.5, stage_size.y * 0.12)

	# 看板娘 v3：全螢幕。bust 內部由 _process 動態 fit 高度 + 底對齊。
	if is_instance_valid(_mascot_panel):
		_mascot_panel.position = Vector2.ZERO
		_mascot_panel.size = stage_size

	# 前景 hot zones（位置 / 大小）
	if is_instance_valid(_hotspot_censer):
		_hotspot_censer.position = Vector2(stage_size.x * 0.55, stage_size.y * 0.72)
		_hotspot_censer.size = Vector2(stage_size.x * 0.10, stage_size.y * 0.14)
	if is_instance_valid(_hotspot_lantern):
		_hotspot_lantern.position = Vector2(stage_size.x * 0.72, stage_size.y * 0.06)
		_hotspot_lantern.size = Vector2(stage_size.x * 0.08, stage_size.y * 0.12)

	# 活動 banner（P0-3）：包覆內容 — 尺寸由 Margin+VBox 內容自然撐開，
	# 不再給固定大框（原 18%×28% 留白超七成）。右側中段定位維持 Responsive 計算。
	if is_instance_valid(_activity_banner) and _activity_banner.visible:
		var on_tablet: bool = Responsive.is_tablet()
		# Button 不自動佈局子節點 — 尺寸以內容容器（Margin>VBox）最小需求為準
		var inner: Control = _activity_banner.get_node_or_null("EventMargin")
		var bsize: Vector2 = inner.get_combined_minimum_size() if inner != null else Vector2(220, 180)
		_activity_banner.size = bsize
		_activity_banner.pivot_offset = bsize * 0.5	# 呼吸縮放以中心為軸
		# 定位錨定「安全區」右緣（非 stage 物理右緣）— 模擬器實測 stage 錨定
		# 會壓進橫向動態島區（島在 stage 右側、safe_rect 已扣除）
		var safe_b: Rect2 = Responsive.safe_rect
		_activity_banner.position = Vector2(safe_b.position.x + safe_b.size.x - bsize.x - 24,
											safe_b.position.y + safe_b.size.y * (0.24 if on_tablet else 0.28))

	# 標題匾：頂部置中
	if is_instance_valid(_pixel_title):
		# 與本函式其餘 layout 一致，改用 viewport 尺寸（stage_size），
		# 不可依賴 MainMenu self.size（在 Root.tscn 為 40×40，會把標題匾縮成一點）。
		var stage_size_t: Vector2 = stage_size
		var title_w: float = stage_size_t.x * 0.42
		var title_h: float = title_w * 0.30
		_pixel_title.size = Vector2(title_w, title_h)
		_pixel_title.position = Vector2((stage_size_t.x - title_w) * 0.5, stage_size_t.y * 0.02)
		# P0-1：匾額文字對齊「實繪匾面」。貼圖（1584×672）上下有透明 padding，
		# 米色匾面實測佔圖高 25%~61%（tools 掃描）— 文字帶按繪區同比例放，
		# 非容器置中（KEEP_ASPECT_CENTERED：繪區置中，繪縮放 = min(w/texw, h/texh)）
		if _plaque_label != null and _pixel_title.texture != null:
			var tw_px: float = float(_pixel_title.texture.get_width())
			var th_px: float = float(_pixel_title.texture.get_height())
			var s: float = minf(title_w / tw_px, title_h / th_px)
			var drawn: Vector2 = Vector2(tw_px, th_px) * s
			var origin: Vector2 = (Vector2(title_w, title_h) - drawn) * 0.5
			_plaque_label.position = origin + Vector2(0, drawn.y * 0.25)
			_plaque_label.size = Vector2(drawn.x, drawn.y * 0.36)

# ---------- 清掉舊 V4 / 點陣節點 ----------

func _hide_legacy_nodes() -> void:
	for n in ["MainMenuBg", "PortraitBackdrop", "Vignette", "Shrine", "ShrineGold",
			"ShrineGoldBottom", "ShrineGoldLeft", "ShrineGoldRight", "CharacterPlaceholder",
			"CharacterLabel", "CharacterHP", "Label", "Subtitle", "SmokeParticles",
			"IncenseLabel", "IncenseProgressBar", "HUDMoneyLabel", "HUDIncenseLabel",
			"PortraitCodexButton", "PortraitEventButton", "PortraitExitButton"]:
		if has_node(n):
			get_node(n).visible = false

func _add_backdrop() -> void:
	_backdrop = Control.new()
	_backdrop.name = "VectorBackdrop"
	_backdrop.set_script(BACKDROP_SCRIPT)
	_backdrop.set_anchors_preset(Control.PRESET_TOP_LEFT)
	add_child(_backdrop)
	move_child(_backdrop, 0)

# ---------- StyleBox：委派全專案共用工廠 ----------

func _sb(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	return COTIW_UI_THEME.make_stylebox(bg, border, radius, bw)

# ---------- 建立節點（不寫死座標，座標交給 _relayout） ----------

func _build_avatar() -> void:
	_avatar_frame = Panel.new()
	_avatar_frame.name = "AvatarFrame"
	_avatar_frame.add_theme_stylebox_override("panel", _sb(PANEL_BG, GOLD, 3, 8))
	_avatar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_avatar_frame)

	var ic := TextureRect.new()
	ic.name = "Icon"
	ic.texture = _load_icon("avatar_tongji")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ic.offset_left = 8; ic.offset_top = 8; ic.offset_right = -8; ic.offset_bottom = -8
	ic.modulate = GOLD
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_frame.add_child(ic)

	# P1-4：原「等級 N」標籤與頂部膠囊同為勝場制等級 — 重複顯示已移除
	# （憲龍拍板③：等級資訊單一顯示點 = 頂部膠囊「香客 Lv」）

func _build_resource_bars() -> void:
	_resource_tray = Panel.new()
	_resource_tray.name = "ResourceOfferingTray"
	_resource_tray.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_resource_tray.set_meta("p0_role", "resource_offering_tray")
	_resource_tray.add_theme_stylebox_override("panel", _sb(Color(0.07, 0.035, 0.025, 0.72), GOLD_DIM, 2, 16))
	add_child(_resource_tray)
	_resource_tray.z_index = -1

	_res_incense = _make_resource_row(0, "icon_incense", GOLD)
	_res_level = _make_resource_row(1, "icon_level", Color(0.96, 0.78, 0.40))
	_res_yuanbao = _make_resource_row(2, "icon_yuanbao", Color(0.55, 0.78, 0.95))
	# P1-4：「晉升 0/3」語意說明（桌面 hover；手機長按由 TouchFeedback 接手）
	if _res_rows.size() > 1 and _res_rows[1].get("pill") != null:
		(_res_rows[1]["pill"] as Control).tooltip_text = tr("ui.level_tooltip")
		(_res_rows[1]["label"] as Control).tooltip_text = tr("ui.level_tooltip")

func _make_resource_row(idx: int, icon: String, tint: Color) -> Label:
	var ic := TextureRect.new()
	ic.texture = _load_icon(icon)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.modulate = tint
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ic)

	var pill := Panel.new()
	pill.add_theme_stylebox_override("panel", _sb(Color(0.06, 0.03, 0.03, 0.78), GOLD_DIM, 2, 12))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pill)

	var fill: ColorRect = null
	if idx == 1:
		fill = ColorRect.new()
		fill.color = Color(0.96, 0.62, 0.24, 0.55)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(fill)
		_level_fill = fill

	var lbl := Label.new()
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_font(lbl, 16)
	add_child(lbl)

	# P1-5：貨幣膠囊右端內嵌「+」（取得途徑入口）— 等級列（idx 1）不給。
	# 結構 = Button 64px 透明熱區（觸控鐵則 ≥64）+ 28px icon child（視覺尺寸照規格）
	var plus: Button = null
	if idx != 1:
		plus = Button.new()
		plus.name = "RowPlus%d" % idx
		plus.flat = true
		plus.focus_mode = Control.FOCUS_NONE
		plus.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		plus.button_up.connect(_on_resource_plus.bind(idx))
		var plus_ic := TextureRect.new()
		plus_ic.name = "PlusIcon"
		plus_ic.texture = load("res://assets/ui/icons/ui_icon_plus.svg")
		plus_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plus_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plus_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plus.add_child(plus_ic)
		_hook_hover(plus)
		add_child(plus)

	_res_rows.append({"icon": ic, "pill": pill, "label": lbl, "fill": fill, "plus": plus})
	return lbl

## P1-5：「+」行為 — 香火 → 修廟（香火回報來源）；元寶 → 商店（鎖定時 toast 解鎖說明）
func _on_resource_plus(row_idx: int) -> void:
	if row_idx == 0:
		_open_temple_screen()
		return
	# 元寶：商店 slot 定義（資料層 unlock_hint）決定提示
	for d: Variant in _slot_definitions:
		if str(d.get("node", "")) == "BtnShop":
			if bool(d.get("ready", false)):
				_perform_slot_act(d)	# 商店開放後直接進（目前資料 ready=false）
			else:
				UI_TOAST.show_toast(self, str(d.get("unlock_hint", tr("menu.coming_soon") % str(d.get("label", "")))))
			return

## slot act 執行（P1-5 抽共用 — slot 按鈕與「+」捷徑同路）
func _perform_slot_act(data: Dictionary) -> void:
	match str(data.get("act", "")):
		"run": _on_new_run_button_up()
		"codex": _on_codex_button_up()
		"character": _on_character_button_up()
		"temple": _open_temple_screen()
		_: _show_coming_soon(str(data.get("label", "")))

func _build_slots() -> void:
	for i in _slot_definitions.size():
		var data: Dictionary = _slot_definitions[i]
		if not has_node(data["node"]):
			_slot_btns.append(null)
			continue
		var btn: Button = get_node(data["node"])
		btn.flat = false
		btn.focus_mode = Control.FOCUS_NONE
		btn.disabled = false
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_apply_slot_style(btn, data["ready"])
		_set_slot_content(btn, data["icon"], data["label"], data["ready"])
		_hook_hover(btn)
		for c in btn.button_up.get_connections():
			btn.button_up.disconnect(c["callable"])
		if data["ready"]:
			btn.button_up.connect(_perform_slot_act.bind(data))
		else:
			# P1-6：鎖定視覺/回饋交給 LockedOverlay 元件（灰階 shader + 鎖頭 + toast）
			LOCKED_OVERLAY.apply(btn, str(data.get("unlock_hint", tr("menu.coming_soon") % str(data.get("label", "")))))
		_slot_btns.append(btn)

func _apply_slot_style(btn: Button, ready: bool) -> void:
	var bg := PANEL_BG if ready else PANEL_BG_LOCK
	var border := GOLD if ready else GOLD_DIM
	btn.add_theme_stylebox_override("normal", _sb(bg, border, 2, 10))
	btn.add_theme_stylebox_override("hover", _sb(PANEL_BG_HOVER if ready else PANEL_BG_LOCK, GOLD, 3, 10))
	btn.add_theme_stylebox_override("pressed", _sb(bg.darkened(0.15), GOLD, 2, 10))
	btn.add_theme_stylebox_override("disabled", _sb(PANEL_BG_LOCK, GOLD_DIM, 2, 10))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _set_slot_content(btn: Button, icon: String, label_text: String, ready: bool) -> void:
	btn.text = ""
	var tint := GOLD	# P1-6：鎖定態的去飽和由 LockedOverlay shader 全管，不再手動壓灰
	var ic := btn.get_node_or_null("Icon") as TextureRect
	if ic == null:
		ic = TextureRect.new()
		ic.name = "Icon"
		btn.add_child(ic)
	ic.texture = _load_icon(icon)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Q2-C：v2 彩色 Q 版 icon 不吃金染（會黃偏）— 白底直出；鎖定壓灰。v1 白線稿維持金染。
	var has_v2_icon: bool = ResourceLoader.exists("res://assets/generated/icons_v2/icon_%s.svg" % icon)
	if has_v2_icon:
		ic.modulate = Color.WHITE
	else:
		ic.modulate = tint
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var lbl := btn.get_node_or_null("Label") as Label
	if lbl == null:
		lbl = Label.new()
		lbl.name = "Label"
		btn.add_child(lbl)
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gold_font(lbl, 17)
	lbl.add_theme_color_override("font_color", tint)

func _build_primary() -> void:
	if qi_jia_button == null:
		return
	var b := qi_jia_button
	b.flat = false
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	COTIW_UI_THEME.apply_primary_button_style(b)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", 52)
	b.add_theme_constant_override("shadow_offset_x", 2)
	b.add_theme_constant_override("shadow_offset_y", 2)
	b.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))

	var ic := b.get_node_or_null("Icon") as TextureRect
	if ic == null:
		ic = TextureRect.new()
		ic.name = "Icon"
		b.add_child(ic)
	ic.texture = _load_icon("qijia")
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.modulate = GOLD
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_dress_plaque_cta(b)	# Q2-C：紅布神匾造型（程序化 — 金釘/垂帶/雙框）

	for c in b.button_up.get_connections():
		b.button_up.disconnect(c["callable"])
	b.button_up.connect(_on_primary_pressed)
	# 同時觸發 mascot 反應（user spec：tap 起駕 → 看板娘也對話）
	b.button_up.connect(_on_qi_jia_mascot_react)
	_hook_hover(b)

## Q2-C 紅布神匾 CTA（程序化）：匾身雙金框 + 四角金釘 + 底緣紅布垂帶×2 —
## 「不要只是一塊平面矩形」（動漫化審查 3.1）。零素材依賴；裝飾全 IGNORE 不影響點擊。
func _dress_plaque_cta(b: Button) -> void:
	if b.get_node_or_null("PlaqueDeco") != null:
		return
	var deco := Control.new()
	deco.name = "PlaqueDeco"
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deco.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(deco)
	# 內金框（細線，與外框成雙框「匾」式）
	var inner := Panel.new()
	inner.name = "PlaqueInnerFrame"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 7; inner.offset_top = 7; inner.offset_right = -7; inner.offset_bottom = -7
	var sbi := StyleBoxFlat.new()
	sbi.bg_color = Color.TRANSPARENT
	sbi.border_color = Color(0.95, 0.82, 0.45, 0.55)
	sbi.set_border_width_all(1)
	sbi.set_corner_radius_all(0)	# P0-2 像素硬邊
	inner.add_theme_stylebox_override("panel", sbi)
	deco.add_child(inner)
	# 四角金釘
	for corner: int in 4:
		var nail := Panel.new()
		nail.name = "PlaqueNail%d" % corner
		nail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sbn := StyleBoxFlat.new()
		sbn.bg_color = Color(0.95, 0.82, 0.45)
		sbn.set_corner_radius_all(0)	# P0-2 方釘（像素風）
		sbn.border_color = Color(0.45, 0.30, 0.10)
		sbn.set_border_width_all(1)
		nail.add_theme_stylebox_override("panel", sbn)
		nail.custom_minimum_size = Vector2(10, 10)
		nail.size = Vector2(10, 10)
		var on_right: bool = corner % 2 == 1
		var on_bottom: bool = corner >= 2
		nail.set_anchors_preset(Control.PRESET_TOP_LEFT)
		nail.anchor_left = 1.0 if on_right else 0.0
		nail.anchor_right = nail.anchor_left
		nail.anchor_top = 1.0 if on_bottom else 0.0
		nail.anchor_bottom = nail.anchor_top
		nail.offset_left = (-16.0 if on_right else 6.0)
		nail.offset_right = nail.offset_left + 10.0
		nail.offset_top = (-16.0 if on_bottom else 6.0)
		nail.offset_bottom = nail.offset_top + 10.0
		deco.add_child(nail)
	# 底緣紅布垂帶 ×2（左右對位，帶金緣 — 神匾披紅）
	for side: int in 2:
		var ribbon := Panel.new()
		ribbon.name = "PlaqueRibbon%d" % side
		ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sbr := StyleBoxFlat.new()
		sbr.bg_color = Color(0.52, 0.10, 0.08, 0.96)
		sbr.border_color = Color(0.95, 0.82, 0.45, 0.85)
		sbr.border_width_left = 2
		sbr.border_width_right = 2
		sbr.border_width_bottom = 3

		ribbon.add_theme_stylebox_override("panel", sbr)
		ribbon.set_anchors_preset(Control.PRESET_TOP_LEFT)
		ribbon.anchor_left = 0.18 if side == 0 else 0.82
		ribbon.anchor_right = ribbon.anchor_left
		ribbon.anchor_top = 1.0
		ribbon.anchor_bottom = 1.0
		ribbon.offset_left = -11.0
		ribbon.offset_right = 11.0
		ribbon.offset_top = -2.0
		ribbon.offset_bottom = 20.0
		ribbon.z_index = -1	# 垂帶從匾後垂出
		deco.add_child(ribbon)
	_start_qi_jia_pulse()

func _on_qi_jia_mascot_react() -> void:
	if is_instance_valid(_mascot_panel) and _mascot_panel.has_method("_play_tap_reaction"):
		_mascot_panel._play_tap_reaction()

func _on_primary_pressed() -> void:
	if FileLoader.has_save_file():
		_on_continue_button_up()
	else:
		_on_new_run_button_up()

func _build_utilities() -> void:
	for i in _utility_definitions.size():
		var u := Button.new()
		u.name = "Util%d" % i
		u.flat = false
		u.focus_mode = Control.FOCUS_NONE
		u.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		u.add_theme_stylebox_override("normal", _sb(PANEL_BG, GOLD_DIM, 2, 8))
		u.add_theme_stylebox_override("hover", _sb(PANEL_BG_HOVER, GOLD, 2, 8))
		u.add_theme_stylebox_override("pressed", _sb(PANEL_BG.darkened(0.15), GOLD, 2, 8))
		u.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		add_child(u)
		var ic := TextureRect.new()
		ic.name = "Icon"
		ic.texture = _load_icon(str(_utility_definitions[i].get("icon", "")))
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = 9; ic.offset_top = 9; ic.offset_right = -9; ic.offset_bottom = -9
		ic.modulate = GOLD
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		u.add_child(ic)
		if str(_utility_definitions[i].get("act", "")) == "temple":
			u.button_up.connect(_open_temple_screen)	# Q2-D：修廟入口
		else:
			u.button_up.connect(_show_coming_soon.bind(str(_utility_definitions[i].get("name", tr("menu.feature")))))
		_hook_hover(u)
		_util_btns.append(u)

	if btn_exit_x:
		# 手機平台不給「離開遊戲」鈕：iOS HIG 視程式自退為 crash（上架紅線），
		# Android 也有系統返回手勢 — ✕ 只留桌面（fork 遺產，實機驗收回報「意義不明的 X」）
		if OS.has_feature("mobile"):
			btn_exit_x.visible = false
		btn_exit_x.flat = true
		btn_exit_x.focus_mode = Control.FOCUS_NONE
		btn_exit_x.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_gold_font(btn_exit_x, 28)
		btn_exit_x.add_theme_color_override("font_color", GOLD)
		btn_exit_x.add_theme_color_override("font_hover_color", Color(1, 0.6, 0.5))
		for c in btn_exit_x.button_up.get_connections():
			btn_exit_x.button_up.disconnect(c["callable"])
		btn_exit_x.button_up.connect(_on_exit_button_up)
		_hook_hover(btn_exit_x)


func _load_ui_definition_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("MainMenu: missing UI definition data: " + path)
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("MainMenu: cannot open UI definition data: " + path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("MainMenu: UI definition data must be an array: " + path)
		return []
	var entries: Array = []
	for item in parsed:
		if typeof(item) == TYPE_DICTIONARY:
			entries.append((item as Dictionary).duplicate(true))
	return entries

# ---------- 自適應排版：所有座標由 Responsive.safe_rect 計算 ----------

func _relayout_pixel_skin_safe() -> void:
	if is_instance_valid(_pixel_altar) or is_instance_valid(_pixel_title) or is_instance_valid(_mascot_panel):
		_layout_pixel_skin()

func _relayout() -> void:
	var screen: Rect2 = Responsive.screen_rect
	var safe: Rect2 = Responsive.safe_rect
	var ts: float = 1.15 if Responsive.is_tablet() else 1.0   # 平板放大
	var pad: float = roundf(18.0 * ts)

	# 背景：全出血填滿整個螢幕（可延伸到瀏海下）
	if _backdrop:
		_backdrop.position = screen.position
		_backdrop.size = screen.size
		_backdrop.queue_redraw()

	# 左上：頭像 + 等級
	var av: float = roundf(64.0 * ts)
	var ax: float = safe.position.x + pad
	var ay: float = safe.position.y + pad
	if _avatar_frame:
		_avatar_frame.position = Vector2(ax, ay)
		_avatar_frame.size = Vector2(av, av)

	# 上中：3 條資源列（水平排列，置中於螢幕頂部，HUD 4 區「資源區」）
	var icon_sz: float = roundf(28.0 * ts)
	var row_h: float = roundf(28.0 * ts)
	var pill_w: float = clampf(safe.size.x * 0.13, 130.0, 200.0) * ts
	var pill_gap: float = roundf(14.0 * ts)
	var group_w: float = pill_w + icon_sz + roundf(6.0 * ts)  # 單組（icon + pill）寬度
	var pills_total_w: float = group_w * _res_rows.size() + pill_gap * (_res_rows.size() - 1)
	# P1-5：置中帶 = avatar 右緣 ↔ 右上工具列左緣（全幅置中在 1244 寬時
	# 元寶尾端「+」會嵌進 Util 鈕 — 審計實測）
	var band_left: float = safe.position.x + roundf(96.0 * ts)
	var band_right: float = safe.position.x + safe.size.x - roundf(3.0 * (80.0 + 6.0) * ts) - roundf(80.0 * ts)
	var pills_start_x: float = band_left + maxf(0.0, (band_right - band_left - pills_total_w) * 0.5)
	var pills_y: float = safe.position.y + roundf(pad * 0.5)
	if is_instance_valid(_resource_tray):
		_resource_tray.position = Vector2(pills_start_x - roundf(18.0 * ts), pills_y - roundf(8.0 * ts))
		_resource_tray.size = Vector2(pills_total_w + roundf(36.0 * ts), row_h + roundf(16.0 * ts))
	for i in _res_rows.size():
		var r: Dictionary = _res_rows[i]
		var gx: float = pills_start_x + i * (group_w + pill_gap)
		r["icon"].position = Vector2(gx, pills_y)
		r["icon"].size = Vector2(icon_sz, icon_sz)
		var px: float = gx + icon_sz + roundf(6.0 * ts)
		r["pill"].position = Vector2(px, pills_y)
		r["pill"].size = Vector2(pill_w, row_h)
		if r["fill"] != null:
			r["fill"].position = Vector2(px + 3, pills_y + 3)
			r["fill"].size = Vector2(maxf(4.0, (pill_w - 6) * _level_ratio()), row_h - 6)
		r["label"].position = Vector2(px + 8, pills_y)
		r["label"].size = Vector2(pill_w - 12, row_h)
		# P1-5：「+」熱區 64px（觸控鐵則）對齊 pill 右端、icon 28px 視覺居中；
		# label 讓出右側避免壓字
		if r.get("plus") != null:
			var hit_sz: float = roundf(80.0 * ts)	# 80 = 舒適線（W 級守則）
			var vis_sz: float = roundf(28.0 * ts)
			var plus_btn: Control = r["plus"]
			plus_btn.size = Vector2(hit_sz, hit_sz)
			# 熱區夾安全區上緣（pill 貼頂 — 置中會頂出視口）；icon 自行對齊 pill 中心
			var hit_y: float = maxf(pills_y + (row_h - hit_sz) * 0.5, safe.position.y)
			plus_btn.position = Vector2(px + pill_w - vis_sz - 4.0 - (hit_sz - vis_sz) * 0.5, hit_y)
			plus_btn.pivot_offset = Vector2(hit_sz, hit_sz) * 0.5
			var plus_icon: Control = plus_btn.get_node_or_null("PlusIcon")
			if plus_icon != null:
				plus_icon.size = Vector2(vis_sz, vis_sz)
				plus_icon.position = Vector2((hit_sz - vis_sz) * 0.5,
											pills_y + (row_h - vis_sz) * 0.5 - hit_y)
			r["label"].size = Vector2(pill_w - vis_sz - 14.0, row_h)

	# 右上：✕ + 3 工具鈕（貼安全區右上）
	# tokens.touch_targets：min 88 / comfortable 96 / cta 112
	# UIQA P1-5：角落 ✕ 與工具列升至 64（手機 ≥35pt 觸控底線；原 44/48 過小）
	var ex: float = roundf(80.0 * ts)
	var ux: float = roundf(80.0 * ts)
	var ugap: float = roundf(6.0 * ts)
	var right: float = safe.position.x + safe.size.x - pad
	if btn_exit_x:
		btn_exit_x.position = Vector2(right - ex, safe.position.y + pad)
		btn_exit_x.size = Vector2(ex, ex)
	# 手機上 ✕ 隱藏（無離開鈕）→ 工具列直接貼安全區右緣，不留幽靈空位
	var util_right: float = right
	if btn_exit_x and btn_exit_x.visible:
		util_right = right - ex - roundf(10.0 * ts)
	for i in _util_btns.size():
		var u: Button = _util_btns[i]
		# 由右往左排：i=0(設定) 最靠近 ✕
		var uxp: float = util_right - ux - i * (ux + ugap)
		u.position = Vector2(uxp, safe.position.y + pad)
		u.size = Vector2(ux, ux)
		u.pivot_offset = u.size * 0.5

	# 底部：6 格 slot + 中央起駕（貼安全區下緣）
	# tokens：slot ≥ minimum 88×88；primary CTA = cta_height 112
	var sw: float = roundf(88.0 * ts)
	var sh: float = roundf(88.0 * ts)
	var pw: float = roundf(284.0 * ts)
	var ph: float = roundf(112.0 * ts)
	var by: float = safe.position.y + safe.size.y - sh - pad
	var sgap: float = roundf(10.0 * ts)
	var cx: float = safe.position.x + safe.size.x * 0.5
	# 左 3：自安全區左緣起；右 3：對稱靠右緣
	var lx: float = safe.position.x + pad
	var rx2: float = safe.position.x + safe.size.x - pad - (3 * sw + 2 * sgap)
	for i in _slot_btns.size():
		var btn: Button = _slot_btns[i]
		if btn == null:
			continue
		var col: int = i if i < 3 else i - 3
		var gx: float = (lx if i < 3 else rx2) + col * (sw + sgap)
		btn.position = Vector2(gx, by)
		btn.size = Vector2(sw, sh)
		btn.pivot_offset = btn.size * 0.5
		_layout_slot_content(btn, sw, sh)

	if qi_jia_button:
		qi_jia_button.position = Vector2(cx - pw * 0.5, safe.position.y + safe.size.y - ph - pad)
		qi_jia_button.size = Vector2(pw, ph)
		qi_jia_button.pivot_offset = qi_jia_button.size * 0.5
		var qic := qi_jia_button.get_node_or_null("Icon") as TextureRect
		if qic:
			qic.position = Vector2(roundf(20 * ts), (ph - roundf(44 * ts)) * 0.5)
			qic.size = Vector2(roundf(44 * ts), roundf(44 * ts))


	# Pixel skin (altar + title plaque + 看板娘) 也要重排
	_relayout_pixel_skin_safe()

func _layout_slot_content(btn: Button, sw: float, sh: float) -> void:
	var ic := btn.get_node_or_null("Icon") as TextureRect
	if ic:
		var isz: float = roundf(sh * 0.48)
		ic.position = Vector2((sw - isz) * 0.5, sh * 0.12)
		ic.size = Vector2(isz, isz)
	var lbl := btn.get_node_or_null("Label") as Label
	if lbl:
		lbl.position = Vector2(0, sh * 0.64)
		lbl.size = Vector2(sw, sh * 0.30)
	var lock := btn.get_node_or_null("Lock") as Label
	if lock:
		lock.position = Vector2(sw - 24, 4)
		lock.size = Vector2(22, 22)

func _level_ratio() -> float:
	var wins := _profile_int("profile_total_wins", 0)
	return float(wins % 3) / 3.0

# ---------- Toast ----------

func _show_coming_soon(feature_name: String) -> void:
	# P1-5：遷移至可重用 UiToast 元件（ui/components/toast.tscn — 上方安全區）
	UI_TOAST.show_toast(self, tr("menu.coming_soon") % feature_name)

# ---------- 互動回饋 ----------

func _hook_hover(c: Control) -> void:
	c.mouse_entered.connect(func(): _scale_to(c, 1.05))
	c.mouse_exited.connect(func(): _scale_to(c, 1.0))
	if c is BaseButton:
		c.button_down.connect(func(): _scale_to(c, 0.95))
		c.button_up.connect(func(): _scale_to(c, 1.05 if c.get_global_rect().has_point(get_global_mouse_position()) else 1.0))

func _scale_to(c: Control, s: float) -> void:
	if c == qi_jia_button:
		return
	var t := create_tween()
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "scale", Vector2(s, s), 0.12)

func _start_qi_jia_pulse() -> void:
	if qi_jia_button == null:
		return
	var st := create_tween().set_loops()
	st.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	st.tween_property(qi_jia_button, "scale", Vector2(1.05, 1.05), 1.4)
	st.tween_property(qi_jia_button, "scale", Vector2(1.0, 1.0), 1.4)
	var mt := create_tween().set_loops()
	mt.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	mt.tween_property(qi_jia_button, "modulate", Color(1.15, 1.10, 0.92, 1), 0.95)
	mt.tween_property(qi_jia_button, "modulate", Color(0.96, 0.96, 0.96, 1), 0.95)

# ---------- 資源刷新 ----------

func _refresh_resources() -> void:
	# Q2-D 修 bug：原讀不存在的 profile_incense → fallback 恆 250；真欄位是 profile_incense_balance（0 合法）
	var incense: int = Global.profile_data.profile_incense_balance if Global.profile_data != null else 0
	var yuanbao := _profile_int("profile_yuanbao", 0)
	var wins := _profile_int("profile_total_wins", 0)
	var level: int = 1 + int(wins / 3)
	var xp_in_level: int = wins % 3
	if _res_incense: _res_incense.text = tr("temple.incense_badge") % incense
	if _res_yuanbao: _res_yuanbao.text = tr("menu.yuanbao") % yuanbao
	if _res_level: _res_level.text = tr("ui.level_progress") % [level, xp_in_level]
	_refresh_plaque()	# P0-1：修廟等級變動同步匾額
	# 進度填充寬度交由 _relayout 依 _level_ratio() 重算
	_relayout()

## P0-1 匾額資料綁定：廟名「鎮島廟」+ 廟級（建築等級總和；方案 A）。
## 空狀態鐵則：profile 未就緒（temple_level=-1）→ 整組隱藏；
## 就緒 → 填字後顯示，首次以 0.3s 淡入（之後資源刷新不重播）。
func _refresh_plaque() -> void:
	if not is_instance_valid(_pixel_title) or _plaque_label == null:
		return
	var lvl: int = RITUAL_TEMPLE.temple_level(Global.profile_data)
	if lvl < 0:
		_pixel_title.visible = false
		return
	_plaque_label.text = tr("menu.plaque_with_level") % lvl if lvl > 0 else tr("menu.plaque_temple_name")
	if not _pixel_title.visible:
		_pixel_title.visible = true
		if not _plaque_shown_once:
			_plaque_shown_once = true
			_pixel_title.modulate = Color(1, 1, 1, 0)
			var tw := create_tween()
			tw.tween_property(_pixel_title, "modulate:a", 1.0, 0.3)

const TEMPLE_SCREEN := preload("res://scripts/ui/menus/TempleScreen.gd")	# class_name 全域註冊 headless 不可靠 → preload 慣例
var _temple_screen: Control = null

## Q2-D：修廟畫面（lazy 建立；修復成功 → 刷新香火列）
func _open_temple_screen() -> void:
	if _temple_screen == null or not is_instance_valid(_temple_screen):
		_temple_screen = TEMPLE_SCREEN.new()
		_temple_screen.name = "TempleScreen"
		add_child(_temple_screen)
		_temple_screen.temple_changed.connect(_refresh_resources)
	_temple_screen.open()

func _profile_int(field: String, fallback: int) -> int:
	if Global.profile_data and field in Global.profile_data:
		var v := int(Global.profile_data.get(field))
		if v > 0:
			return v
	return fallback

# ---------- helper ----------

func _gold_font(c: Control, sz: int) -> void:
	c.add_theme_font_size_override("font_size", sz)
	c.add_theme_color_override("font_color", GOLD)
	c.add_theme_constant_override("shadow_offset_x", 2)
	c.add_theme_constant_override("shadow_offset_y", 2)
	c.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))

const ICON_DIR_V2 := "res://assets/generated/icons_v2/"

func _load_icon(name: String) -> Texture2D:
	# v2 優先：Recraft 生彩色 flat icon (icons_v2/icon_<name>.svg)
	var v2_path := ICON_DIR_V2 + "icon_" + name + ".svg"
	if ResourceLoader.exists(v2_path):
		return load(v2_path)
	# fallback v1：白色線條 SVG
	var v1_path := ICON_DIR + "ui_icon_" + name + "_default.svg"
	if ResourceLoader.exists(v1_path):
		return load(v1_path)
	return null

# ---------- 既有導航邏輯（保留） ----------

func _on_continue_button_up() -> void:
	FileLoader.autoload()

func _on_forfeit_run_button_up() -> void:
	FileLoader.delete_save()
	update_continue_button_visibility()

func _on_new_run_button_up() -> void:
	title_screen.show_new_run_menu()

func _on_codex_button_up() -> void:
	title_screen.show_codex_menu()

func _on_character_button_up() -> void:
	title_screen.show_character_panel()

func _on_exit_button_up() -> void:
	get_tree().quit()

func update_continue_button_visibility() -> void:
	var has_save: bool = FileLoader.has_save_file()
	if qi_jia_button:
		qi_jia_button.text = tr("menu.continue") if has_save else tr("menu.depart")
	if continue_button: continue_button.visible = has_save
	if forfeit_run_button: forfeit_run_button.visible = has_save
	if new_run_button: new_run_button.visible = not has_save

func _on_run_ended() -> void:
	var has_save: bool = FileLoader.has_save_file()
	visible = has_save
	update_continue_button_visibility()
