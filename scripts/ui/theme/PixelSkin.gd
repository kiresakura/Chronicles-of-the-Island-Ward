# 共用 pixel art 背景皮（v3 Recraft pixel_art 統一風格）
#
# 各畫面 _ready 結尾呼叫 `PixelSkin.apply_background(self, path)`，
# 會用 CanvasLayer (layer=-10) 強制全螢幕背景，繞過 Control 尺寸限制。
# additive 不破壞既有 UI（鐵律 3 友善）。
# v3：全部背景改用 assets/generated/pixellab/ 統一像素風格素材。
extends Object
class_name PixelSkin

const BG_DIR := "res://assets/generated/pixellab/"

## 套用全螢幕像素背景到指定 Control。
## - host: 寄宿 Control 節點（畫面根，e.g. SplashScreen / Combat / NewRunMenu）
## - bg_filename: 背景檔名（已在 BG_DIR 內），e.g. "splash_bg_v3.webp"
## - hide_node_names: 額外要隱藏的 legacy 背景節點名陣列（可選）
static func apply_background(host: Control, bg_filename: String, hide_node_names: Array = []) -> CanvasLayer:
	var path: String = BG_DIR + bg_filename
	if not ResourceLoader.exists(path):
		push_warning("PixelSkin: bg not found at " + path)
		return null

	# 隱藏 legacy backdrop 節點
	for n in hide_node_names:
		var legacy: Node = host.get_node_or_null(n)
		if legacy:
			if legacy is CanvasItem:
				legacy.visible = false

	# CanvasLayer fullscreen
	var layer := CanvasLayer.new()
	layer.name = "PixelBgLayer"
	layer.layer = -10
	host.add_child(layer)
	host.move_child(layer, 0)
	# 跟隨 host 顯隱（CanvasLayer 不自動承襲 visible）
	host.visibility_changed.connect(func(): layer.visible = host.visible)
	layer.visible = host.visible

	var rect := TextureRect.new()
	rect.name = "PixelBackdrop"
	rect.texture = load(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# anchors 改為 TOP_LEFT（全部 0）— CanvasLayer 父節點下 anchors 並非「相對 viewport」自動套用，
	# 反而是 (0,0,1,1) 會讓引擎在 _ready 後依 anchors 反覆覆寫我們設定的 size，
	# 觸發「Nodes with non-equal opposite anchors will have their size overridden」警告。
	# 改以 size 絕對值控制即可（PixelFX Ken Burns 也依賴 size 直設）。
	rect.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	layer.add_child(rect)
	_sync_backdrop_to_viewport(host, rect)
	return layer

static func _sync_backdrop_to_viewport(host: Control, rect: TextureRect) -> void:
	var update_rect := func() -> void:
		if not is_instance_valid(rect):
			return
		var vp := host.get_viewport()
		rect.position = Vector2.ZERO
		rect.size = vp.get_visible_rect().size if vp else Vector2(1200, 700)

	update_rect.call()
	var vp := host.get_viewport()
	if vp != null and not vp.size_changed.is_connected(update_rect):
		vp.size_changed.connect(update_rect)
