## PixelFX — 像素風格大氣特效系統
##
## 讓靜態背景「活起來」的三層動畫：
##   Layer 1 — 呼吸 Shader：背景亮度輕微振盪 + 暗角脈衝
##   Layer 2 — Ken Burns：緩慢縮放偏移（FIREWORKS 場景停用，背景靜止以突顯煙火粒子）
##   Layer 3 — 粒子特效：每個場景專屬大氣粒子
##
## FIREWORKS 專用 z 分層（mainmenu_temple_v5.png 天空已去背）：
##   z = -5  SkyFill ColorRect  → 深夜藍底色 RGB(24,42,91)
##   z =  0  _FireworksManager + embers → 煙火粒子（在夜空中爆炸）
##   z = 10  PixelBackdrop（mainmenu_temple_v5.png）→ 廟宇建築不透明，天空透明
##           煙火只在廟宇建築之間的天空縫隙/上方可見
##
## 用法（在各畫面 _ready 最後）：
##   const PixelSkinCls = preload("res://scripts/ui/theme/PixelSkin.gd")
##   const PixelFXCls   = preload("res://scripts/ui/fx/PixelFX.gd")
##   var _layer = PixelSkinCls.apply_background(self, "mainmenu_bg_v4.webp")
##   if _layer: PixelFXCls.apply(_layer, PixelFXCls.Preset.FIREWORKS)
##
## 粒子 preset 對應：
##   FIREWORKS — MainMenu：煙火升空爆炸 + 浮動火星
##   EMBERS    — Combat：熾熱火星漫天 + 緊張呼吸
##   SMOKE     — NewRunMenu：香爐煙霧縷縷 + 神秘漂移
##   MIST      — Map：山間薄霧橫流 + 清晨光線
##   SPARKLE   — SplashScreen：金色星點閃爍 + 輕柔呼吸
extends Object
class_name PixelFX

## CPUParticles2D EmissionShape 整數常數（避免 static 作用域內無法存取 class enum）
const _SHAPE_POINT := 0   # EMISSION_SHAPE_POINT
const _SHAPE_BOX   := 3   # EMISSION_SHAPE_BOX

## 各場景使用的特效預設
enum Preset {
	FIREWORKS,  ## 主選單：煙火 + 火星
	EMBERS,     ## 戰鬥：浮動火星
	SMOKE,      ## 選角：香爐煙霧
	MIST,       ## 地圖：薄霧飄移
	SPARKLE,    ## 啟動：金色星點
}

# ═══════════════════════════════════════════════════
# 公開介面
# ═══════════════════════════════════════════════════

## 對 PixelSkin.apply_background 回傳的 CanvasLayer 套用特效
static func apply(layer: CanvasLayer, preset: Preset) -> void:
	if not is_instance_valid(layer):
		return

	var vp := layer.get_viewport()
	var sz: Vector2 = vp.get_visible_rect().size if vp else Vector2(1200, 700)
	var backdrop: TextureRect = layer.get_node_or_null("PixelBackdrop")

	# ── Layer 1：呼吸 Shader ──────────────────────
	_apply_shader(backdrop, preset)

	# ── Layer 2：Ken Burns 緩移 ───────────────────
	# FIREWORKS 停用：背景靜止，讓煙火粒子成為唯一動態主角
	if preset != Preset.FIREWORKS:
		_apply_ken_burns(backdrop, preset, sz)
	else:
		if is_instance_valid(backdrop):
			backdrop.size     = sz
			backdrop.position = Vector2.ZERO
		# FIREWORKS：建立夜空底色 + 廟宇壓層，讓煙火顯現在廟宇「後面」
		_setup_fireworks_layers(layer, backdrop, sz)

	# ── Layer 3：場景粒子 ─────────────────────────
	match preset:
		Preset.FIREWORKS:
			_spawn_fireworks_manager(layer, sz)
			_spawn(layer, _ember_cfg(28, Color(1.0, 0.55, 0.12, 0.75), sz))
		Preset.EMBERS:
			_spawn(layer, _ember_cfg(55, Color(1.0, 0.38, 0.08, 0.85), sz))
			_spawn(layer, _ember_cfg(22, Color(1.0, 0.75, 0.25, 0.55), sz))
		Preset.SMOKE:
			_spawn(layer, _smoke_cfg(sz))
			_spawn(layer, _ember_cfg(12, Color(0.92, 0.86, 0.82, 0.40), sz))
		Preset.MIST:
			_spawn(layer, _mist_cfg(sz))
			_spawn(layer, _sparkle_cfg(14, sz))
		Preset.SPARKLE:
			_spawn(layer, _sparkle_cfg(42, sz))
			_spawn(layer, _ember_cfg(18, Color(1.0, 0.90, 0.45, 0.60), sz))

# ═══════════════════════════════════════════════════
# Layer 1 — 呼吸 Shader
# ═══════════════════════════════════════════════════

## 內嵌 GLSL：亮度呼吸 + 暗角脈衝；每個 preset 可調參數
const _SHADER_SRC := """
shader_type canvas_item;
uniform float breathe_speed : hint_range(0.05, 3.0)  = 0.35;
uniform float breathe_amp   : hint_range(0.0,  0.25) = 0.055;
uniform float vignette_str  : hint_range(0.0,  2.0)  = 0.55;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	// 亮度輕微振盪
	float b = sin(TIME * breathe_speed) * breathe_amp;
	col.rgb = clamp(col.rgb + b, 0.0, 1.0);

	// 四角暗角，隨呼吸微脈衝
	vec2  c   = UV - 0.5;
	float vig = 1.0 - dot(c, c) * vignette_str * 2.0;
	col.rgb  *= clamp(vig, 0.0, 1.0);

	COLOR = col;
}
"""

static func _apply_shader(rect: TextureRect, preset: Preset) -> void:
	if not is_instance_valid(rect):
		return
	var shader := Shader.new()
	shader.code = _SHADER_SRC
	var mat := ShaderMaterial.new()
	mat.shader = shader
	match preset:
		Preset.FIREWORKS:
			mat.set_shader_parameter("breathe_speed", 0.38)
			mat.set_shader_parameter("breathe_amp",   0.06)
			mat.set_shader_parameter("vignette_str",  0.60)
		Preset.EMBERS:
			mat.set_shader_parameter("breathe_speed", 0.65)
			mat.set_shader_parameter("breathe_amp",   0.09)
			mat.set_shader_parameter("vignette_str",  0.75)
		Preset.SMOKE:
			mat.set_shader_parameter("breathe_speed", 0.22)
			mat.set_shader_parameter("breathe_amp",   0.042)
			mat.set_shader_parameter("vignette_str",  0.65)
		Preset.MIST:
			mat.set_shader_parameter("breathe_speed", 0.18)
			mat.set_shader_parameter("breathe_amp",   0.030)
			mat.set_shader_parameter("vignette_str",  0.40)
		Preset.SPARKLE:
			mat.set_shader_parameter("breathe_speed", 0.28)
			mat.set_shader_parameter("breathe_amp",   0.038)
			mat.set_shader_parameter("vignette_str",  0.50)
	rect.material = mat

# ═══════════════════════════════════════════════════
# FIREWORKS 專用 — 深度分層（廟宇後方天空煙火）
# ═══════════════════════════════════════════════════

## 建立三層 z-order：夜空底色（z=-5）→ 煙火粒子（z=0）→ 廟宇背景（z=10）
## PixelBackdrop 天空區透明（由 _FIREWORKS_SKY_SHADER 處理），
## 只有建築體遮住粒子 → 視覺上煙火在廟宇「後面」炸開
static func _setup_fireworks_layers(layer: CanvasLayer, backdrop: TextureRect, sz: Vector2) -> void:
	if not is_instance_valid(backdrop):
		return
	# ── 夜空底色（在所有粒子之後）──────────────────
	var sky := ColorRect.new()
	sky.name = "SkyFill"
	sky.color = Color(0.094, 0.165, 0.357, 1.0)  # 廟宇圖天空採樣色 RGB(24,42,91)
	sky.size  = sz
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sky.z_index = -5
	layer.add_child(sky)
	layer.move_child(sky, 0)   # 確保在 tree 最前（z_index 才是渲染決定因素）
	# ── 廟宇背景壓在粒子之上 ────────────────────────
	# 天空區 alpha=0 → 夜空底色 + 煙火透出；建築區 alpha=1 → 廟宇不透明
	backdrop.z_index = 10

# ═══════════════════════════════════════════════════
# Layer 2 — Ken Burns 緩移效果
# ═══════════════════════════════════════════════════

## 微幅放大背景，然後用 Tween 緩慢平移，讓靜態圖有鏡頭漂移感
static func _apply_ken_burns(rect: TextureRect, preset: Preset, sz: Vector2) -> void:
	if not is_instance_valid(rect):
		return
	const OVERSCAN := 0.12          # 放大 12%，平移時不露邊
	var nw := sz.x * (1.0 + OVERSCAN)
	var nh := sz.y * (1.0 + OVERSCAN)
	var ox := -sz.x * OVERSCAN * 0.5   # 居中偏移
	var oy := -sz.y * OVERSCAN * 0.5
	rect.size     = Vector2(nw, nh)
	rect.position = Vector2(ox, oy)

	var dx := sz.x * 0.038   # 漂移幅度 ±3.8%
	var dy := sz.y * 0.028
	var dur: float = match_preset_duration(preset)

	var tw := rect.create_tween()
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(rect, "position", Vector2(ox - dx, oy - dy), dur)
	tw.tween_property(rect, "position", Vector2(ox + dx, oy + dy), dur)

static func match_preset_duration(p: Preset) -> float:
	match p:
		Preset.FIREWORKS: return 12.0
		Preset.EMBERS:    return 10.0
		Preset.SMOKE:     return 16.0
		Preset.MIST:      return 20.0
		_:                return 14.0

# ═══════════════════════════════════════════════════
# Layer 3 — 煙火發射器（_FireworksManager）
# ═══════════════════════════════════════════════════

## 掛在 CanvasLayer 上的 Node，用 _process 驅動定期煙火
## Route B：爆炸主體改用 AnimatedSprite2D 精靈動畫（firework_burst_sheet.png）
## 若精靈表載入失敗則自動 fallback 至原 CPUParticles2D 爆炸
class _FireworksManager extends Node:
	var _t:    float = 0.0
	var _next: float = 1.2
	var _sz:   Vector2
	var _burst_frames: SpriteFrames = null  ## 8 幀爆炸精靈表（快取）
	var _sparkle_tex:  Texture2D    = null  ## 星形粒子材質（快取）

	const _BURST_PATH   := "res://assets/generated/pixellab/firework_burst_sheet.png"
	const _SPARKLE_PATH := "res://assets/generated/pixellab/firework_sparkle.png"
	const _BURST_FRAMES := 8
	const _FRAME_PX     := 128
	const _BURST_FPS    := 12.0

	func _ready() -> void:
		var vp := get_viewport()
		_sz = vp.get_visible_rect().size if vp else Vector2(1200, 700)
		_burst_frames = _build_burst_frames()
		_sparkle_tex  = _load_tex(_SPARKLE_PATH)

	## 從 1024×128 橫排精靈表建立 SpriteFrames（8 幀 × 128px）
	func _build_burst_frames() -> SpriteFrames:
		var img := Image.new()
		if img.load(_BURST_PATH) != OK:
			push_warning("PixelFX: 找不到 firework_burst_sheet.png，降級至 CPUParticles2D")
			return null
		var sheet := ImageTexture.create_from_image(img)
		var sf := SpriteFrames.new()
		sf.add_animation("burst")
		sf.set_animation_speed("burst", _BURST_FPS)
		sf.set_animation_loop("burst", false)
		for i in _BURST_FRAMES:
			var at := AtlasTexture.new()
			at.atlas  = sheet
			at.region = Rect2(i * _FRAME_PX, 0, _FRAME_PX, _FRAME_PX)
			sf.add_frame("burst", at)
		return sf

	## 從 res:// 路徑載入 PNG → Texture2D（用於粒子材質）
	func _load_tex(path: String) -> Texture2D:
		var img := Image.new()
		if img.load(path) != OK:
			push_warning("PixelFX: 找不到 " + path.get_file())
			return null
		return ImageTexture.create_from_image(img)

	func _process(delta: float) -> void:
		_t += delta
		if _t >= _next:
			_t    = 0.0
			_next = randf_range(0.9, 2.8)
			_launch()

	func _launch() -> void:
		var bx := randf_range(_sz.x * 0.12, _sz.x * 0.88)
		var by := randf_range(_sz.y * 0.05, _sz.y * 0.42)
		const PALETTES := [
			Color(1.00, 0.20, 0.07),  # 紅
			Color(1.00, 0.88, 0.10),  # 金
			Color(0.10, 0.72, 1.00),  # 藍
			Color(1.00, 0.28, 0.82),  # 桃
			Color(0.32, 1.00, 0.32),  # 綠
			Color(1.00, 1.00, 1.00),  # 白
			Color(1.00, 0.52, 0.10),  # 橙
			Color(0.72, 0.28, 1.00),  # 紫
		]
		var col: Color = PALETTES[randi() % PALETTES.size()]

		# ── 火箭升空軌跡 ──────────────────────────
		var trail := CPUParticles2D.new()
		trail.position = Vector2(bx + randf_range(-25, 25), _sz.y * 0.94)
		trail.emitting              = true
		trail.one_shot              = true
		trail.amount                = 28
		trail.lifetime              = 0.32
		trail.explosiveness         = 0.0
		trail.spread                = 5.0
		trail.direction             = Vector2((bx - _sz.x * 0.5) * 0.0008, -1.0).normalized()
		trail.gravity               = Vector2.ZERO
		trail.initial_velocity_min  = 380.0
		trail.initial_velocity_max  = 460.0
		trail.scale_amount_min      = 4.0
		trail.scale_amount_max      = 7.0
		var tg := Gradient.new()
		tg.set_color(0, Color(1.0, 0.92, 0.50, 0.90))
		tg.set_color(1, Color(1.0, 0.40, 0.10, 0.00))
		trail.color_ramp = tg
		add_child(trail)
		get_tree().create_timer(0.70).timeout.connect(trail.queue_free)

		# ── 主爆炸：AnimatedSprite2D 精靈動畫 ────────
		if _burst_frames != null:
			var sc := randf_range(2.2, 3.5)
			# 主爆炸（彩色 modulate = 調色盤色）
			var burst_anim := AnimatedSprite2D.new()
			burst_anim.position      = Vector2(bx, by)
			burst_anim.sprite_frames = _burst_frames
			burst_anim.modulate      = col
			burst_anim.scale         = Vector2(sc, sc)
			burst_anim.animation_finished.connect(burst_anim.queue_free)
			add_child(burst_anim)
			burst_anim.play("burst")
			# 中心白閃光（較小，疊在主爆炸上）
			var flash_anim := AnimatedSprite2D.new()
			flash_anim.position      = Vector2(bx, by)
			flash_anim.sprite_frames = _burst_frames
			flash_anim.modulate      = Color(1.0, 1.0, 1.0, 0.85)
			flash_anim.scale         = Vector2(sc * 0.45, sc * 0.45)
			flash_anim.animation_finished.connect(flash_anim.queue_free)
			add_child(flash_anim)
			flash_anim.play("burst")
		else:
			# ── Fallback：原 CPUParticles2D 爆炸 + 閃光 ─
			var burst := CPUParticles2D.new()
			burst.position              = Vector2(bx, by)
			burst.emitting              = true
			burst.one_shot              = true
			burst.amount                = randi_range(80, 120)
			burst.lifetime              = randf_range(1.10, 1.65)
			burst.explosiveness         = 0.97
			burst.spread                = 180.0
			burst.gravity               = Vector2(0, 55)
			burst.initial_velocity_min  = 80.0
			burst.initial_velocity_max  = 220.0
			burst.scale_amount_min      = 5.0
			burst.scale_amount_max      = 11.0
			var bg := Gradient.new()
			bg.set_color(0, col)
			bg.set_color(1, Color(col.r, col.g, col.b, 0.0))
			burst.color_ramp = bg
			add_child(burst)
			get_tree().create_timer(burst.lifetime + 0.9).timeout.connect(burst.queue_free)

			var flash := CPUParticles2D.new()
			flash.position              = Vector2(bx, by)
			flash.emitting              = true
			flash.one_shot              = true
			flash.amount                = 22
			flash.lifetime              = 0.32
			flash.explosiveness         = 0.99
			flash.spread                = 180.0
			flash.gravity               = Vector2.ZERO
			flash.initial_velocity_min  = 10.0
			flash.initial_velocity_max  = 35.0
			flash.scale_amount_min      = 8.0
			flash.scale_amount_max      = 18.0
			var fg := Gradient.new()
			fg.set_color(0, Color(1, 1, 1, 1))
			fg.set_color(1, Color(1, 1, 0.6, 0))
			flash.color_ramp = fg
			add_child(flash)
			get_tree().create_timer(0.50).timeout.connect(flash.queue_free)

		# ── 金色尾星（星形粒子材質 + 重力下墜）─────
		var glitter := CPUParticles2D.new()
		glitter.position             = Vector2(bx, by)
		glitter.emitting             = true
		glitter.one_shot             = true
		glitter.amount               = 40
		glitter.lifetime             = 1.0
		glitter.explosiveness        = 0.95
		glitter.spread               = 180.0
		glitter.gravity              = Vector2(0, 100)
		glitter.initial_velocity_min = 30.0
		glitter.initial_velocity_max = 90.0
		glitter.scale_amount_min     = 3.0
		glitter.scale_amount_max     = 6.0
		if _sparkle_tex != null:
			glitter.texture = _sparkle_tex
		var gg := Gradient.new()
		gg.set_color(0, Color(1.0, 0.95, 0.55, 0.90))
		gg.set_color(1, Color(1.0, 0.80, 0.30, 0.00))
		glitter.color_ramp = gg
		add_child(glitter)
		get_tree().create_timer(1.1).timeout.connect(glitter.queue_free)

static func _spawn_fireworks_manager(layer: CanvasLayer, _sz: Vector2) -> void:
	var mgr := _FireworksManager.new()
	layer.add_child(mgr)

# ═══════════════════════════════════════════════════
# 通用粒子生成器
# ═══════════════════════════════════════════════════

static func _spawn(layer: CanvasLayer, cfg: Dictionary) -> void:
	var p := CPUParticles2D.new()

	p.position         = cfg.get("pos",           Vector2(600, 700))
	p.emission_shape   = cfg.get("shape",          _SHAPE_POINT)
	if p.emission_shape == _SHAPE_BOX:
		# CPUParticles2D 的矩形 emission 屬性是 emission_rect_extents (Vector2)，
		# 不是 3D 的 emission_box_extents (Vector3)。_SHAPE_BOX=3 對應
		# EMISSION_SHAPE_RECTANGLE。
		p.emission_rect_extents = cfg.get("box", Vector2(600, 5))

	p.amount           = cfg.get("amount",         40)
	p.lifetime         = cfg.get("lifetime",       4.5)
	p.explosiveness    = cfg.get("explo",          0.0)

	p.direction        = cfg.get("dir",            Vector2(0, -1))
	p.spread           = cfg.get("spread",         28.0)
	p.gravity          = cfg.get("gravity",        Vector2(0, -6))
	p.initial_velocity_min = cfg.get("vmin",       14.0)
	p.initial_velocity_max = cfg.get("vmax",       44.0)
	p.angular_velocity_min = cfg.get("amin",       -18.0)
	p.angular_velocity_max = cfg.get("amax",        18.0)
	p.scale_amount_min = cfg.get("smin",           1.8)
	p.scale_amount_max = cfg.get("smax",           4.5)

	if cfg.has("grad"):
		p.color_ramp = cfg["grad"]
	else:
		p.color = cfg.get("color", Color(1, 0.6, 0.2))

	p.emitting = true
	layer.add_child(p)

# ═══════════════════════════════════════════════════
# 各粒子預設配置
# ═══════════════════════════════════════════════════

## 浮動火星/餘燼（從底部飄升）
static func _ember_cfg(cnt: int, col: Color, sz: Vector2) -> Dictionary:
	var g := Gradient.new()
	g.set_color(0,    Color(col.r, col.g, col.b, 0.00))
	g.set_color(0.14, col)
	g.set_color(0.82, col)
	g.set_color(1.0,  Color(col.r, col.g, col.b, 0.00))
	return {
		"pos":    Vector2(sz.x * 0.5, sz.y + 8),
		"shape":  _SHAPE_BOX,
		"box":    Vector2(sz.x * 0.5, 6),
		"amount": cnt,
		"lifetime": 5.8,
		"dir":    Vector2(0, -1),
		"spread": 38.0,
		"gravity": Vector2(randf_range(-4, 4), -7),
		"vmin": 12.0, "vmax": 42.0,
		"amin": -35.0, "amax": 35.0,
		"smin": 1.5, "smax": 3.5,
		"grad": g,
	}

## 香爐煙霧縷縷（從中央偏下升起）
static func _smoke_cfg(sz: Vector2) -> Dictionary:
	var g := Gradient.new()
	g.set_color(0,    Color(0.88, 0.84, 0.82, 0.00))
	g.set_color(0.12, Color(0.88, 0.84, 0.82, 0.30))
	g.set_color(0.85, Color(0.88, 0.84, 0.82, 0.12))
	g.set_color(1.0,  Color(0.88, 0.84, 0.82, 0.00))
	return {
		"pos":    Vector2(sz.x * 0.5, sz.y * 0.74),
		"shape":  _SHAPE_POINT,
		"amount": 20,
		"lifetime": 4.2,
		"dir":    Vector2(0, -1),
		"spread": 14.0,
		"gravity": Vector2(0, -11),
		"vmin": 7.0, "vmax": 20.0,
		"amin": -28.0, "amax": 28.0,
		"smin": 10.0, "smax": 28.0,
		"grad": g,
	}

## 山間薄霧（從左側橫向飄移）
static func _mist_cfg(sz: Vector2) -> Dictionary:
	var g := Gradient.new()
	g.set_color(0,    Color(0.78, 0.84, 0.90, 0.00))
	g.set_color(0.18, Color(0.78, 0.84, 0.90, 0.10))
	g.set_color(0.80, Color(0.78, 0.84, 0.90, 0.10))
	g.set_color(1.0,  Color(0.78, 0.84, 0.90, 0.00))
	return {
		"pos":    Vector2(0, sz.y * 0.56),
		"shape":  _SHAPE_BOX,
		"box":    Vector2(18, sz.y * 0.20),
		"amount": 11,
		"lifetime": 9.5,
		"dir":    Vector2(1, 0),
		"spread": 7.0,
		"gravity": Vector2(0, 0),
		"vmin": 16.0, "vmax": 46.0,
		"amin": 0.0, "amax": 0.0,
		"smin": 48.0, "smax": 108.0,
		"grad": g,
	}

## 金色星點閃爍（散佈全畫面）
static func _sparkle_cfg(cnt: int, sz: Vector2) -> Dictionary:
	var g := Gradient.new()
	g.set_color(0,    Color(1.0, 0.94, 0.58, 0.00))
	g.set_color(0.25, Color(1.0, 0.94, 0.58, 0.92))
	g.set_color(0.75, Color(1.0, 0.94, 0.58, 0.92))
	g.set_color(1.0,  Color(1.0, 0.94, 0.58, 0.00))
	return {
		"pos":    Vector2(sz.x * 0.5, sz.y * 0.5),
		"shape":  _SHAPE_BOX,
		"box":    Vector2(sz.x * 0.5, sz.y * 0.46),
		"amount": cnt,
		"lifetime": 2.6,
		"dir":    Vector2(0, 0),
		"spread": 180.0,
		"gravity": Vector2(0, 0),
		"vmin": 0.0, "vmax": 3.5,
		"amin": 0.0, "amax": 0.0,
		"smin": 1.5, "smax": 4.0,
		"grad": g,
	}
