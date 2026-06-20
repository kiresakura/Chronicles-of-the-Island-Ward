# 鎮島錄 c-2 — 外觀外框視覺套用（共用：商店預覽 + 新一局立繪框）。
#
# 依 cosmetics.json 的外觀階給 Panel 上「邊框色/寬 + 暈光（stylebox shadow）」，
# 像素硬角（鐵律）。純視覺，零戰力（紅線）。素=灰細框無暈、神話=紫粗框強暈。
extends RefCounted
class_name CosmeticFrame

const THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
const CAT := preload("res://scripts/systems/cosmetics/CosmeticCatalog.gd")

## 套用外觀外框到 frame_panel（透明底 + 階梯邊框 + 暈光）。glow 以 stylebox 外陰影呈現，
## 無需額外節點/排版（避免 size 未定的定位坑）。frame_id 缺則退素。
static func apply(frame_panel: Panel, frame_id: String) -> void:
	if frame_panel == null:
		return
	var d: Dictionary = CAT.frame_def(frame_id)
	if d.is_empty():
		d = CAT.frame_def(CAT.DEFAULT_FRAME)
	var border: Color = THEME.get_color(str(d.get("border_token", "incense_gold")), Color(0.91, 0.77, 0.42))
	var width: int = int(d.get("border_width", 3))
	var glow: float = float(d.get("glow", 0.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)	# 透明底：只框立繪、不蓋
	sb.set_border_width_all(width)
	sb.border_color = border
	sb.set_corner_radius_all(0)	# 像素硬角
	if glow > 0.0:
		sb.shadow_color = Color(border.r, border.g, border.b, glow)
		sb.shadow_size = int(8.0 + glow * 16.0)
	frame_panel.add_theme_stylebox_override("panel", sb)
