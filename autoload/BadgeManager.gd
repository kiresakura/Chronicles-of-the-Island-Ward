## 紅點 badge 中樞（UI 重修 P2-11 最小可行版）。
## API：set_badge(id, visible, count)；UI 端 register_button(id, host) 掛載。
## 狀態先行：set_badge 早於 register 也會在掛載時套用（開機訊號順序無關）。
## 用法（示範 = 限時擲筊入口，MainMenu._build_activity_banner）：
##   BadgeManager.register_button("event_jiaobei", banner_btn)
##   BadgeManager.set_badge("event_jiaobei", true)
extends Node

const BADGE_SCENE := preload("res://ui/components/badge.tscn")

var _hosts: Dictionary = {}		# id -> Control（badge 節點本體）
var _states: Dictionary = {}	# id -> {"visible": bool, "count": int}

## 掛載 badge 到 host 右上角（重複註冊同 id 會先卸舊）。
func register_button(id: String, host: Control) -> void:
	if host == null:
		return
	unregister(id)
	var badge: Control = BADGE_SCENE.instantiate()
	badge.name = "Badge_" + id
	# 錨右上：右緣外凸 1/3 製造「貼角」感；host resize 自動跟隨
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -10.0
	badge.offset_top = -6.0
	badge.offset_right = 6.0
	badge.offset_bottom = 10.0
	badge.z_index = 10
	host.add_child(badge)
	_hosts[id] = badge
	_apply(id)

func unregister(id: String) -> void:
	var old: Variant = _hosts.get(id)
	if old != null and is_instance_valid(old):
		(old as Node).queue_free()
	_hosts.erase(id)

## 主 API：控制 id 對應 badge 顯隱與數字。
func set_badge(id: String, badge_visible: bool, count: int = 0) -> void:
	_states[id] = {"visible": badge_visible, "count": count}
	_apply(id)

func _apply(id: String) -> void:
	var badge: Variant = _hosts.get(id)
	if badge == null or not is_instance_valid(badge):
		return
	var st: Dictionary = _states.get(id, {"visible": false, "count": 0})
	(badge as Control).visible = bool(st["visible"])
	(badge as Control).call("set_count", int(st["count"]))
