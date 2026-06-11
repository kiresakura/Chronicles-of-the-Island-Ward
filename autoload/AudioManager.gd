# 鎮島錄 Q1-F — 最小音訊管線（DELEGATION §5 Q1 配套 SFX／Q3 全面音訊的地基）。
#
# 架構：Master ← SFX / BGM 兩條 bus；SFX 走 8 槽 AudioStreamPlayer 輪替池
# （同名快速連發不互斷）。BGM 預留單一 player（Q3 接手）。
# 音源：assets/audio/sfx_placeholder/PLACEHOLDER_*.wav（程序化佔位，Q1-A 問題
# 決議前的墊檔；Q3 統一替換時以 PLACEHOLDER_ 前綴識別）。
# 用法：AudioManager.play_sfx("ward_break")
extends Node

const SFX_BUS := "SFX"
const BGM_BUS := "BGM"
const POOL_SIZE := 8

const SFX_STREAMS: Dictionary = {
	"card_play": preload("res://assets/audio/sfx_placeholder/PLACEHOLDER_card_play.wav"),
	"ward_break": preload("res://assets/audio/sfx_placeholder/PLACEHOLDER_ward_break.wav"),
	"invoke": preload("res://assets/audio/sfx_placeholder/PLACEHOLDER_invoke.wav"),
	"fuhe": preload("res://assets/audio/sfx_placeholder/PLACEHOLDER_fuhe.wav"),
	"turn_end": preload("res://assets/audio/sfx_placeholder/PLACEHOLDER_turn_end.wav"),
}

var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0

func _ready() -> void:
	_ensure_bus(SFX_BUS)
	_ensure_bus(BGM_BUS)
	for i: int in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_pool.append(p)

## 播放一顆 SFX（未知名稱靜默略過 — 不讓音訊缺檔炸遊戲流程）。
func play_sfx(sfx_name: String, volume_db: float = 0.0) -> void:
	var stream: AudioStream = SFX_STREAMS.get(sfx_name, null)
	if stream == null:
		return
	if _pool.is_empty():
		return
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.play()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
