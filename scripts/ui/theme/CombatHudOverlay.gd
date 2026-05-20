# Combat HUD overlay — 八卦 energy + 3 神明 affinity badges（pixel skin v2）
#
# Combat._ready 結尾呼叫 `CombatHudOverlay.apply(self)`；
# additive 加 1 CanvasLayer(layer=20) 浮在 Combat 之上，3 神明 badge + 八卦 ring。
# 不動 STR 既有 HUD 節點，鐵律 3 友善。
extends Object
class_name CombatHudOverlay

const DEITY_DIR := "res://assets/generated/icons/deities/"
const DEITIES := [
	{"key": "mazu", "label": "媽", "value": "62"},
	{"key": "guanyin", "label": "觀", "value": "30"},
	{"key": "wangye", "label": "爺", "value": "12"},
]

static func apply(host: Control) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "CombatHudOverlay"
	layer.layer = 20
	host.add_child(layer)
	# 跟隨 host 顯隱
	host.visibility_changed.connect(func(): layer.visible = host.visible)
	layer.visible = host.visible

	# 3 神明 affinity badges (top-left)
	var x: float = 16
	for i in DEITIES.size():
		var d: Dictionary = DEITIES[i]
		var path: String = DEITY_DIR + "deity_" + d.key + ".svg"
		if not ResourceLoader.exists(path):
			continue
		var badge_bg := ColorRect.new()
		badge_bg.name = "BadgeBg_" + d.key
		badge_bg.position = Vector2(x, 92)
		badge_bg.size = Vector2(54, 54)
		badge_bg.color = Color(0.08, 0.04, 0.04, 0.78)
		layer.add_child(badge_bg)

		var badge := TextureRect.new()
		badge.name = "DeityBadge_" + d.key
		badge.texture = load(path)
		badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		badge.position = Vector2(x + 3, 95)
		badge.size = Vector2(48, 48)
		badge.modulate = Color(1, 0.85, 0.45)  # 金色 tint
		layer.add_child(badge)

		var lbl := Label.new()
		lbl.text = d.value
		lbl.position = Vector2(x, 146)
		lbl.size = Vector2(54, 18)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
		layer.add_child(lbl)

		x += 64

	# 八卦 energy ring (left-bottom)
	var bagua := _make_bagua_ring()
	bagua.position = Vector2(20, 460)
	layer.add_child(bagua)

	return layer

static func _make_bagua_ring() -> Control:
	var holder := Control.new()
	holder.name = "BaguaRing"
	holder.size = Vector2(120, 120)

	# 外環
	var ring := ColorRect.new()
	ring.size = Vector2(120, 120)
	ring.color = Color(0.06, 0.03, 0.03, 0.92)
	holder.add_child(ring)

	# 八卦十字（簡化版）
	var cross_h := ColorRect.new()
	cross_h.position = Vector2(0, 57)
	cross_h.size = Vector2(120, 6)
	cross_h.color = Color(0.31, 0.78, 0.9, 0.6)
	holder.add_child(cross_h)
	var cross_v := ColorRect.new()
	cross_v.position = Vector2(57, 0)
	cross_v.size = Vector2(6, 120)
	cross_v.color = Color(0.31, 0.78, 0.9, 0.6)
	holder.add_child(cross_v)

	# 中央 energy 文字
	var energy_num := Label.new()
	energy_num.name = "EnergyNum"
	energy_num.position = Vector2(0, 32)
	energy_num.size = Vector2(120, 60)
	energy_num.text = "3"
	energy_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	energy_num.add_theme_font_size_override("font_size", 48)
	energy_num.add_theme_color_override("font_color", Color(0.31, 0.78, 0.9))
	holder.add_child(energy_num)

	var energy_sub := Label.new()
	energy_sub.position = Vector2(0, 88)
	energy_sub.size = Vector2(120, 20)
	energy_sub.text = "神 力"
	energy_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_sub.add_theme_font_size_override("font_size", 14)
	energy_sub.add_theme_color_override("font_color", Color(0.96, 0.91, 0.81))
	holder.add_child(energy_sub)

	return holder
