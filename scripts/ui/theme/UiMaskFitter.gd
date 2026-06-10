## 鎮島錄 UIQA — 全出血遮罩 fitter（additive，不動 STR 佈局）。
##
## 問題：overlay 的調光/擋輸入層寫死 1200×700 stage 尺寸，
## 在 19.5:9 手機兩側各 ~157px、4:3 平板下方 ~200px 露出底層畫面（不調光、視覺穿幫）。
##
## 解法：把 group "fullbleed_mask" 內的 Control 鋪滿 Responsive.screen_rect
## （全邏輯畫布，含 expand 出來的側帶）。掛在 Root 下，監聽 Responsive.changed；
## runtime 動態建立的遮罩（角色面板/看板娘選擇器）進 group 即自動套用。
extends Node

const GROUP := "fullbleed_mask"

func _ready() -> void:
	var responsive: Node = get_node_or_null("/root/Responsive")
	if responsive != null and responsive.has_signal("changed"):
		responsive.changed.connect(_fit_all)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_fit_all")

func _on_node_added(node: Node) -> void:
	if node is Control and node.is_in_group(GROUP):
		_fit_one.call_deferred(node as Control)

func _fit_all() -> void:
	for node: Node in get_tree().get_nodes_in_group(GROUP):
		if node is Control:
			_fit_one(node as Control)

func _fit_one(mask: Control) -> void:
	if not is_instance_valid(mask) or not mask.is_inside_tree():
		return
	var rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1200, 700))
	var responsive: Node = get_node_or_null("/root/Responsive")
	if responsive != null:
		rect = responsive.screen_rect
	mask.global_position = rect.position
	mask.size = rect.size
