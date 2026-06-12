# 紅點 badge（UI 重修 P2-11 最小可行版）。
# 像素風方點（festival_red 底 + 金邊）+ 可選數字；錨定父 Control 右上角。
# 一律經 BadgeManager 建立/控制 — 不要手動 instantiate（id 對應集中管理）。
class_name UiBadge
extends Control

@onready var _count_label: Label = $Count

func set_count(count: int) -> void:
	if not is_node_ready():
		await ready
	_count_label.text = str(count) if count > 0 else ""
	# 純點 16px；帶數字撐寬
	custom_minimum_size = Vector2(28 if count > 0 else 16, 16)
	size = custom_minimum_size
