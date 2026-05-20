# 鎮島錄 — Run 主畫面（戰鬥/地圖/各 overlay 容器）+ 螢幕自適應
#
# RunScreen 與 TitleScreen 結構同構：底下是固定 1200×700 設計的子畫面
# （Combat / Map / Rest/Shop/Reward/… overlay / RunStartOptions）。
# 自適應策略：對 RunScreen 本節點做 SafeFit（單一祖先等比置中進安全區，
# 一次涵蓋全部子畫面含 Combat；祖先縮放與 overlay 自身 scale 動畫相容，
# 零 STR 內部改動）。Combat 的視覺向量化在其 1200×700 設計空間內進行，
# 隨 SafeFit 一起縮放，不破壞核心戰鬥版面（真正的邊到邊響應式 HUD 列 Phase 2）。
# expand 下安全區外的露出區域由程式化加的全螢幕深色底襯填滿。
extends Control

const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")

var _backing: ColorRect

func _ready() -> void:
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	# 父節點(Root)於 _ready 期間仍在建構子節點，add_child 需延後
	_setup_backing.call_deferred()
	# 整個 run/combat/map/overlay 一起等比置中塞進安全區（鐵律 3 友善）
	SafeFit.bind(self, Vector2(1200, 700))

# 在 Root（RunScreen 的父節點）加一張全螢幕深色底襯，置於 RunScreen 之下，
# 隨 run 顯隱。避免 expand 下安全區外露出空白。
func _setup_backing() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	_backing = ColorRect.new()
	_backing.name = "RunBacking"
	_backing.color = COTIW_UI_THEME.get_color("night_ink", Color(0.07, 0.04, 0.035, 1.0))
	_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_backing)
	parent.move_child(_backing, get_index())  # 插在 RunScreen 之前 → 繪於其下層
	_backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backing.visible = visible

func _on_run_started() -> void:
	visible = true
	if is_instance_valid(_backing):
		_backing.visible = true

func _on_run_ended() -> void:
	visible = false
	if is_instance_valid(_backing):
		_backing.visible = false
