# 可重用 Toast（UI 重修 P1-5）：淡入 0.18s → 停留 1.5s → 淡出 0.4s → 自毀。
# 置於畫面「上方安全區」置中（Responsive.safe_rect）— 不遮底部 CTA 與手牌區。
# 用法：UiToast.show_toast(host_node, tr("..."))（host 提供樹；重複呼叫各自獨立浮層）
class_name UiToast
extends Label

const FADE_IN := 0.18
const HOLD := 1.5
const FADE_OUT := 0.4

static func show_toast(host: Node, text_value: String) -> Label:
	if host == null or not host.is_inside_tree():
		return null
	var t: UiToast = load("res://ui/components/toast.tscn").instantiate()
	t.text = text_value
	host.get_tree().root.add_child(t)
	t._place_and_play()
	return t

func _place_and_play() -> void:
	var safe: Rect2 = Responsive.safe_rect
	var sz: Vector2 = get_combined_minimum_size() + Vector2(36, 16)	# 內距
	custom_minimum_size = sz
	size = sz
	position = Vector2(safe.position.x + (safe.size.x - sz.x) * 0.5, safe.position.y + 12.0)
	z_index = 200	# 蓋過一般 UI；低於降乩/覺醒 cut-in CanvasLayer
	modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, FADE_IN)
	tw.tween_interval(HOLD)
	tw.tween_property(self, "modulate:a", 0.0, FADE_OUT)
	tw.tween_callback(queue_free)
