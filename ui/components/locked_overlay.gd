# 可重用鎖定覆蓋層（UI 重修 P1-6）。
# 套用效果：①目標按鈕整體灰階（shader material；子節點 use_parent_material）
# ②中央鎖頭 icon（不灰階 — 自有 material 斷開繼承）③點擊 → toast 解鎖說明。
# 用法：LockedOverlay.apply(btn, "解鎖條件文字")；解鎖時 LockedOverlay.clear(btn)。
class_name LockedOverlay
extends Control

const SHADER := preload("res://ui/components/locked_grayscale.gdshader")
const LOCK_ICON := "res://assets/ui/icons/ui_icon_lock.svg"
const UI_TOAST := preload("res://ui/components/toast.gd")
const NODE_NAME := "LockedOverlay"

var _hint: String = ""

static func apply(btn: Button, unlock_hint: String, desaturate: float = 0.85) -> Control:
	if btn == null or btn.has_node(NODE_NAME):
		return btn.get_node_or_null(NODE_NAME) if btn != null else null
	# ① 整鈕灰階：material 掛 btn、既有子節點繼承（鎖頭 overlay 除外）
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("desaturate", desaturate)
	btn.material = mat
	for child: Node in btn.get_children():
		if child is CanvasItem:
			(child as CanvasItem).use_parent_material = true

	# ② 鎖頭覆蓋（scene 實例 — 自帶非繼承 material 維持彩色）
	var overlay: Control = load("res://ui/components/locked_overlay.tscn").instantiate()
	overlay.name = NODE_NAME
	overlay._hint = unlock_hint
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(overlay)

	# ③ 點擊 → toast（接管鎖定點擊回饋）
	btn.button_up.connect(overlay._on_locked_pressed)
	return overlay

## 解鎖還原：移除灰階與鎖頭（按鈕重新接線由呼叫端負責）。
static func clear(btn: Button) -> void:
	if btn == null:
		return
	btn.material = null
	for child: Node in btn.get_children():
		if child is CanvasItem:
			(child as CanvasItem).use_parent_material = false
	var ov: Node = btn.get_node_or_null(NODE_NAME)
	if ov != null:
		ov.queue_free()

func _on_locked_pressed() -> void:
	UI_TOAST.show_toast(self, _hint)
