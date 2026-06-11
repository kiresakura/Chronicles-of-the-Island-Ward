# 鎮島錄 Q1-F — AudioManager 守門（bus/池/未知名安全）。
extends "res://tests/test_case.gd"

func test_buses_exist() -> void:
	assert_true(AudioServer.get_bus_index("SFX") != -1, "SFX bus 應存在")
	assert_true(AudioServer.get_bus_index("BGM") != -1, "BGM bus 應存在")

func test_five_combat_sfx_registered() -> void:
	for key: String in ["card_play", "ward_break", "invoke", "fuhe", "turn_end"]:
		assert_true(AudioManager.SFX_STREAMS.has(key), "SFX 應註冊：%s" % key)
		assert_not_null(AudioManager.SFX_STREAMS[key], "音源應載入：%s" % key)

func test_unknown_sfx_is_safe() -> void:
	AudioManager.play_sfx("not_a_sound")	# 不得炸
	assert_true(true, "未知 SFX 靜默略過")

func test_play_assigns_stream_to_pool() -> void:
	AudioManager.play_sfx("turn_end")
	var assigned: bool = false
	for p: Node in AudioManager.get_children():
		if p is AudioStreamPlayer and (p as AudioStreamPlayer).stream != null:
			assigned = true
	assert_true(assigned, "play_sfx 應指派 stream 至池內 player")
