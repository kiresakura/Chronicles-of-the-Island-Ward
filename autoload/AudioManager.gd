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

## BGM 場景 → 檔案（Suno 生成正式音源；lazy load 避免缺檔炸啟動）
const BGM_PATHS: Dictionary = {
	"main_menu": "res://assets/audio/bgm/bgm_main_menu.ogg",
	"map": "res://assets/audio/bgm/bgm_map.ogg",
	"battle": "res://assets/audio/bgm/bgm_battle.ogg",
	"boss": "res://assets/audio/bgm/bgm_boss.ogg",
}
const BGM_FADE := 0.45

var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _bgm_player: AudioStreamPlayer = null
var _bgm_scene: String = ""
var _bgm_cache: Dictionary = {}

func _ready() -> void:
	_ensure_bus(SFX_BUS)
	_ensure_bus(BGM_BUS)
	for i: int in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		add_child(p)
		_pool.append(p)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = BGM_BUS
	add_child(_bgm_player)
	# 中樞化場景接線：run 流程訊號 → BGM 切換（單點訂閱，不散落各畫面）
	Signals.combat_started.connect(_on_combat_started_bgm)
	Signals.combat_ended.connect(func(): play_bgm("map"))
	Signals.run_started.connect(func(): play_bgm("map"))
	Signals.run_ended.connect(func(): play_bgm("main_menu"))

## 場景 BGM 切換（同場景重複呼叫不重啟；淡出舊曲 → 換曲）。缺檔靜默略過。
func play_bgm(scene: String) -> void:
	if scene == _bgm_scene:
		return
	var path: String = str(BGM_PATHS.get(scene, ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = _bgm_cache.get(scene, null)
	if stream == null:
		stream = load(path)
		if stream == null:
			return
		_bgm_cache[scene] = stream
	_bgm_scene = scene
	var tw := create_tween()
	if _bgm_player.playing:
		tw.tween_property(_bgm_player, "volume_db", -28.0, BGM_FADE)
	tw.tween_callback(func() -> void:
		_bgm_player.stream = stream
		_bgm_player.volume_db = -6.0
		_bgm_player.play())

func stop_bgm() -> void:
	_bgm_scene = ""
	if _bgm_player != null and _bgm_player.playing:
		var tw := create_tween()
		tw.tween_property(_bgm_player, "volume_db", -32.0, BGM_FADE)
		tw.tween_callback(_bgm_player.stop)

func _on_combat_started_bgm(_event_id: String) -> void:
	var loc: LocationData = Global.get_player_location_data()
	var is_boss: bool = loc != null and loc.location_type == LocationData.LOCATION_TYPES.BOSS
	play_bgm("boss" if is_boss else "battle")

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
