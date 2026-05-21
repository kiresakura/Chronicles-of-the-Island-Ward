## 程序化精靈動畫 — 對單一 Sprite2D 套用 squash & stretch 生命感變形。
##
## 不重畫像素，純用 scale / position / rotation 製造動態：
##   待機呼吸、走路起伏、空中拉伸、落地擠壓、出手前刺、受擊抖動。
## 與 AnimationPlayer 相容 — 本工具只寫 position / scale / rotation；
## 戰鬥員的 AnimationPlayer 動畫走 offset / modulate，互不衝突可疊加。
##
## 用法：宿主 _ready() 時 setup(sprite)，每幀呼叫 update()；換貼圖後
## 呼叫 refresh_texture()；出手 / 受擊 / 落地以 trigger_* 觸發。
## 卡牌戰鬥員只用呼吸 / 出手 / 受擊（update 的 moving / airborne 傳 false）。
class_name SpriteProcAnim
extends RefCounted

const ATTACK_DUR: float = 0.30   # 攻擊動畫長度（秒）
const HURT_DUR: float = 0.22     # 受擊動畫長度
const LAND_DUR: float = 0.20     # 落地擠壓長度
const BOB_SPEED: float = 11.0    # 走路擺動角速度

var _spr: Sprite2D = null
var _base_pos: Vector2 = Vector2.ZERO
var _base_scale: Vector2 = Vector2.ONE
var _half_h: float = 0.0         # 顯示半高（含基準 scale）— 踏地補正用

var _breath: float = 0.0         # 呼吸相位
var _bob: float = 0.0            # 走路相位
var _move_w: float = 0.0         # 走路權重 0..1（idle↔walk 交叉淡入）
var _lean: float = 0.0           # 當前前傾度數（平滑）
var _attack: float = 0.0         # 攻擊殘量 1→0
var _hurt: float = 0.0           # 受擊殘量 1→0
var _land: float = 0.0           # 落地殘量 1→0


## 綁定要驅動的 Sprite2D，記住其基準 transform。
func setup(spr: Sprite2D) -> void:
	_spr = spr
	_base_pos = spr.position
	_base_scale = spr.scale
	refresh_texture()


## 貼圖換新後重算踏地補正用的半高（基準 transform 不變）。
func refresh_texture() -> void:
	if _spr != null and _spr.texture != null:
		_half_h = float(_spr.texture.get_height()) * 0.5 * absf(_base_scale.y)


func trigger_attack() -> void:
	_attack = 1.0


func trigger_hurt() -> void:
	_hurt = 1.0


func trigger_land() -> void:
	_land = 1.0


## 還原基準姿勢（復活時呼叫，避免從半途動畫接續）。
func reset() -> void:
	_bob = 0.0
	_move_w = 0.0
	_lean = 0.0
	_attack = 0.0
	_hurt = 0.0
	_land = 0.0
	if _spr != null:
		_spr.scale = _base_scale
		_spr.position = _base_pos
		_spr.rotation_degrees = 0.0


## 每物理幀呼叫。moving=水平移動中；airborne=離地；facing=1（右）/-1（左）。
func update(delta: float, moving: bool, airborne: bool, facing: int) -> void:
	if _spr == null:
		return

	_breath = fmod(_breath + delta * 2.6, TAU)
	_bob = fmod(_bob + delta * BOB_SPEED, TAU)
	_move_w = move_toward(_move_w, 1.0 if (moving and not airborne) else 0.0, delta * 9.0)
	_attack = maxf(0.0, _attack - delta / ATTACK_DUR)
	_hurt = maxf(0.0, _hurt - delta / HURT_DUR)
	_land = maxf(0.0, _land - delta / LAND_DUR)

	var sx: float = 1.0
	var sy: float = 1.0
	var off: Vector2 = Vector2.ZERO
	var rot: float = 0.0

	# 待機呼吸（走路時淡出）— scale 以腳底為錨，自然帶起上半身起伏
	var idle_w: float = 1.0 - _move_w
	var breath: float = sin(_breath)
	sy += breath * 0.020 * idle_w
	sx -= breath * 0.014 * idle_w

	# 走路：通過抬高 / 接觸壓扁 + 步伐微擺
	var lift: float = -cos(_bob * 2.0)              # -1 接觸 / +1 通過
	off.y -= (lift + 1.0) * 0.5 * 9.0 * _move_w
	sy += lift * 0.05 * _move_w
	sx -= lift * 0.04 * _move_w
	rot += sin(_bob) * 2.0 * _move_w

	# 前傾（走路時傾、待機回正）
	var lean_target: float = 5.0 if _move_w > 0.5 else 0.0
	_lean = lerpf(_lean, lean_target, delta * 8.0)
	rot += _lean * float(facing)

	# 空中拉伸
	if airborne:
		sy += 0.06
		sx -= 0.05

	# 落地擠壓脈衝（sin 0→1→0）
	if _land > 0.0:
		var k: float = sin(_land * PI)
		sy -= k * 0.16
		sx += k * 0.14

	# 攻擊：拉後 → 衝刺 → 收
	if _attack > 0.0:
		var p: float = 1.0 - _attack               # 0→1 進度
		var lunge: float = 0.0
		var arot: float = 0.0
		if p < 0.28:
			var w: float = p / 0.28
			lunge = -10.0 * w
			arot = -8.0 * w
		elif p < 0.55:
			var s: float = (p - 0.28) / 0.27
			lunge = lerpf(-10.0, 34.0, s)
			arot = lerpf(-8.0, 12.0, s)
			sx += s * 0.10
		else:
			var r: float = (p - 0.55) / 0.45
			lunge = lerpf(34.0, 0.0, r)
			arot = lerpf(12.0, 0.0, r)
		off.x += lunge * float(facing)
		rot += arot * float(facing)

	# 受擊：橫向抖動 + 擠壓
	if _hurt > 0.0:
		off.x += sin(_hurt * PI * 5.0) * 5.0 * _hurt
		sy -= _hurt * 0.08
		sx += _hurt * 0.07

	# 套用（踏地補正：scale.y 變動時讓底部不位移）
	_spr.scale = Vector2(_base_scale.x * sx, _base_scale.y * sy)
	_spr.position = _base_pos + off + Vector2(0.0, _half_h * (1.0 - sy))
	_spr.rotation_degrees = rot
