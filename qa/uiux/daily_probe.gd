extends Node
# c-1 每日上香 overlay 渲染探針：給 profile 一個「連簽 3、今日未領」狀態後開面板截圖。
func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_window().size = Vector2i(1244, 700)
	for i in 5: await get_tree().process_frame
	# 模擬狀態：連簽 3 天、最後上香日為很久以前（→ 今日可領、即將領第 4 日）
	Global.profile_data.profile_incense_streak = 3
	Global.profile_data.profile_last_incense_day = "2000-01-01"
	Global.profile_data.profile_incense_balance = 240
	Global.profile_data.profile_yuanbao = 12
	var overlay: Control = preload("res://scripts/ui/menus/DailyIncenseOverlay.gd").new()
	get_tree().root.add_child(overlay)
	overlay.call("open")
	for i in 16: await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("/tmp/daily_overlay.png")
	print("[DAILY] saved /tmp/daily_overlay.png")
	get_tree().quit()
