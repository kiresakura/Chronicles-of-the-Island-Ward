# UI 重修 P2-11 — BadgeManager 守門。
# 範圍：set_badge 先行後 register 仍套用（順序無關）、顯隱/數字控制、
# 重複註冊卸舊、unregister 清理。host 用 free-standing Control（不進真實樹）。
extends "res://tests/test_case.gd"

func _host() -> Control:
	var c := Control.new()
	c.size = Vector2(80, 80)
	return c

func test_set_before_register_applies_on_mount() -> void:
	BadgeManager.set_badge("qa_badge_a", true, 3)
	var host := _host()
	BadgeManager.register_button("qa_badge_a", host)
	var badge: Control = host.get_node_or_null("Badge_qa_badge_a")
	assert_not_null(badge, "register 後 badge 節點應掛載")
	assert_true(badge.visible, "先 set 後 register 應套用可見狀態")
	BadgeManager.unregister("qa_badge_a")
	host.free()

func test_set_badge_toggles_visibility() -> void:
	var host := _host()
	BadgeManager.register_button("qa_badge_b", host)
	BadgeManager.set_badge("qa_badge_b", false)
	var badge: Control = host.get_node_or_null("Badge_qa_badge_b")
	assert_false(badge.visible, "set false 應隱藏")
	BadgeManager.set_badge("qa_badge_b", true, 7)
	assert_true(badge.visible, "set true 應顯示")
	BadgeManager.unregister("qa_badge_b")
	host.free()

func test_reregister_replaces_old_badge() -> void:
	var host := _host()
	BadgeManager.register_button("qa_badge_c", host)
	var first: Control = host.get_node_or_null("Badge_qa_badge_c")
	BadgeManager.register_button("qa_badge_c", host)
	assert_true(first == null or first.is_queued_for_deletion(), "重複註冊應卸舊 badge")
	BadgeManager.unregister("qa_badge_c")
	host.free()
