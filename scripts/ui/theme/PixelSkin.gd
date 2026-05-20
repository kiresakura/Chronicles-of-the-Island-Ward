# 共用 pixel art 背景皮（v2 美術 additive 層）
#
# 各畫面 _ready 結尾呼叫 `PixelSkin.apply_background(self, path)`，
# 會用 CanvasLayer (layer=-10) 強制全螢幕背景，繞過 Control 尺寸限制。
# additive 不破壞既有 UI（鐵律 3 友善）。
extends Object
class_name PixelSkin

const BG_DIR := "res://assets/generated/mainmenu_v2/"

## 套用全螢幕像素背景到指定 Control。
## - host: 寄宿 Control 節點（畫面根，e.g. SplashScreen / Combat / NewRunMenu）
## - bg_filename: 背景檔名（已在 BG_DIR 內），e.g. "splash_bg.webp"
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

	var rect := TextureRect.new()
	rect.name = "PixelBackdrop"
	rect.texture = load(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.anchor_left = 0
	rect.anchor_top = 0
	rect.anchor_right = 1
	rect.anchor_bottom = 1
	layer.add_child(rect)
	var vp := host.get_viewport()
	if vp:
		rect.size = vp.get_visible_rect().size
	else:
		rect.size = Vector2(1200, 700)
	return layer
