# 鎮島錄 — 螢幕自適應單例（autoload）
#
# 提供全專案唯一的「可用安全區」真相來源，供各畫面把邊緣 UI 錨定在
# 避開瀏海/動態島/home indicator 的範圍內。背景可用 screen_rect 全出血。
#
# stretch = canvas_items + expand：Control 座標在「邏輯畫布」空間；
# DisplayServer 安全區是「實體像素」，本單例負責換算成邏輯座標。
extends Node

signal changed  # viewport 尺寸或安全區變動時發出

const DESIGN := Vector2(1200, 700)  # 設計基準（與 project.godot viewport 一致）

enum ScreenClass { PHONE, TABLET }

var screen_rect: Rect2 = Rect2(Vector2.ZERO, DESIGN)  # 完整邏輯畫布（全出血用）
var safe_rect: Rect2 = Rect2(Vector2.ZERO, DESIGN)    # 扣掉裝置安全區後的可用範圍
var screen_class: int = ScreenClass.PHONE

func _ready() -> void:
	# autoload 早於場景；首幀後 viewport 尺寸才穩定
	get_tree().root.size_changed.connect(_recompute)
	call_deferred("_recompute")

func is_tablet() -> bool:
	return screen_class == ScreenClass.TABLET

## 把固定 base 版面等比塞進安全區的縮放係數（給 SafeFitContainer 用）
func fit_scale(base: Vector2 = DESIGN) -> float:
	if base.x <= 0.0 or base.y <= 0.0:
		return 1.0
	return minf(safe_rect.size.x / base.x, safe_rect.size.y / base.y)

func _recompute() -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var logical: Vector2 = vp.get_visible_rect().size
	if logical.x <= 0.0 or logical.y <= 0.0:
		logical = DESIGN
	screen_rect = Rect2(Vector2.ZERO, logical)

	# 預設：safe = 全畫布（桌機/編輯器無瀏海）
	var new_safe: Rect2 = screen_rect

	# 僅行動平台才套用裝置安全區
	if OS.has_feature("mobile") or OS.get_name() in ["iOS", "Android"]:
		var phys: Vector2i = DisplayServer.window_get_size()
		var sa: Rect2i = DisplayServer.get_display_safe_area()
		if phys.x > 0 and phys.y > 0 and sa.size.x > 0 and sa.size.y > 0:
			# 實體像素 → 邏輯畫布座標
			var sx: float = logical.x / float(phys.x)
			var sy: float = logical.y / float(phys.y)
			new_safe = Rect2(
				sa.position.x * sx, sa.position.y * sy,
				sa.size.x * sx, sa.size.y * sy
			)
			# 防呆：安全區必須落在畫布內、且不為空
			new_safe = new_safe.intersection(screen_rect)
			if new_safe.size.x < 1.0 or new_safe.size.y < 1.0:
				new_safe = screen_rect

	# Debug：強制模擬安全區內縮（桌機 audit 重現瀏海/手勢區，找出沒接 safe 的畫面）。
	# COTIW_SAFE_INSET="left,top,right,bottom"（邏輯px）→ 直接套成最終 safe_rect。
	var _dbg_inset: String = OS.get_environment("COTIW_SAFE_INSET")
	if _dbg_inset != "":
		var _pi: PackedStringArray = _dbg_inset.split(",")
		if _pi.size() == 4:
			new_safe = Rect2(
				screen_rect.position.x + _pi[0].to_float(),
				screen_rect.position.y + _pi[1].to_float(),
				screen_rect.size.x - _pi[0].to_float() - _pi[2].to_float(),
				screen_rect.size.y - _pi[1].to_float() - _pi[3].to_float()
			).intersection(screen_rect)

	safe_rect = new_safe

	# 機型分類：橫向長寬比 < 1.6 視為平板（iPad 4:3≈1.33），其餘為手機
	var ar: float = logical.x / maxf(logical.y, 1.0)
	screen_class = ScreenClass.TABLET if ar < 1.6 else ScreenClass.PHONE

	changed.emit()
