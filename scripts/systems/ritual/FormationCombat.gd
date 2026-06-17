# 鎮島錄 v0.3 — 五營戰鬥核心（formation_progression_v0.3.md「換骨」，FC-2a 生產版）。
#
# 把回合主要動詞從卡牌（抽牌/能量/單體）換成「佈陣/調營/守 lane/擲筊節奏/降乩」。
# 由原型 FiveCampBattle 升格：資料改讀 FC-1（FormationCampData/FormationUnitData），
# 得位改完整五行（FiveElements + 倍率資料層），勝負改「破盡所有煞=勝 / 母壇崩=敗」
# （取代原型「撐 N 回合」，更貼近殲敵），敵人事件→煞波翻譯接 run 進程。
#
# 本類只管規則（純 RefCounted、RNG 可注入），UI/接縫在 FC-2b 的 FormationCombat 場景。
# 數值由 external/data/formation_combat_config.json 注入（鐵律 1：零硬編）。
# 戰況以「結構化事件」回報（log_events），顯示文案由 UI 層走 CSV key 渲染
#   —— 核心不持有任何玩家可見字串（i18n 清零、邏輯/顯示分離）。
#
# 一場：母壇 integrity 取代玩家元神。破盡所有煞（且波次出齊）= 勝；母壇歸零 = 敗。
# 回合流程：開盤生煞 → 玩家佈陣/調營/降乩（動作數受擲筊節奏影響）→ 結算
#   （各營攔該 lane，五行得位加成；殘煞推進；煞抵母壇或營空 → 扣母壇）→ 下一回合。
class_name FormationCombat
extends RefCounted

const FiveElementsCls := preload("res://scripts/systems/ritual/FiveElements.gd")
const AffinitySystemCls := preload("res://scripts/systems/ritual/AffinitySystem.gd")
const CONFIG_PATH := "res://external/data/formation_combat_config.json"
const FU_CONFIG_PATH := "res://external/data/formation_fu.json"

const JIAO_SHENG := "sheng"	# 聖筊：加速（多一動作）
const JIAO_XIAO := "xiao"	# 笑筊：卡住（無加成）
const JIAO_YIN := "yin"		# 陰筊：反噬（某 lane 煞暴衝）

const STATE_PLAYING := "playing"
const STATE_WON := "won"
const STATE_LOST := "lost"

# 結構化戰況事件型別（UI 層據此查 CSV key 渲染；核心不含顯示文案）。
const EV_SHA_SPAWN := "sha_spawn"
const EV_MOVE := "move"
const EV_JIAO := "jiao"
const EV_YIN_SURGE := "yin_surge"
const EV_DEITY := "deity_invoke"
const EV_INTERCEPT := "intercept"
const EV_SHA_BREAK := "sha_break"
const EV_EMPTY_CAMP := "empty_camp"
const EV_ALTAR_HIT := "altar_hit"
const EV_WIN := "win"
const EV_LOSE := "lose"
const EV_RESOLVE := "resolve"
const EV_FU := "fu"
const EV_COMBO := "combo"		# 緣分合擊每回合生效

# ---- 由 setup 注入的局面 ----
var camps: Array = []				# [{id,name,element,lane}]（含中營）
var units: Dictionary = {}			# unit_id → {id,name,element,power,kind}
var unit_location: Dictionary = {}	# unit_id → camp_id
var lanes: Dictionary = {}			# lane → {camp,steps_to_altar,sha:{strength,steps,element}|null}
var waves: Array = []				# [{turn,lane,strength,element}]
var altar_max: int = 0
var altar_integrity: int = 0
var element_multipliers: Dictionary = {}
var jiao_weights: Dictionary = {}
var jiao_yin_surge: int = 0
var base_actions: int = 1
var sheng_bonus: int = 1
var max_turns: int = 30
var deity_charge_max: int = 0
var deity_invoke_power: int = 0

# ---- 回合狀態 ----
var turn: int = 1
var actions_remaining: int = 0
var jiao_rolled_this_turn: bool = false
var last_jiao: String = ""
var deity_charge: int = 0
var state: String = STATE_PLAYING
var log_events: Array = []			# [{t:型別, ...數值}]；顯示由 UI 層渲染

# ---- 符令手牌（FP-2 精簡手牌；FC-2b.3）----
var fu_defs: Dictionary = {}		# fu_id → {name,effect,magnitude,needs_target,desc}
var fu_deck: Array = []				# 抽牌堆（fu_id）
var fu_hand: Array = []				# 手牌（fu_id）
var fu_discard: Array = []			# 棄牌堆
var fu_hand_max: int = 5
var fu_draw_per_turn: int = 1
var fu_plays_per_turn: int = 1
var fu_plays_left: int = 0			# 本回合可打符令數（_begin_turn 重置）

# ---- 緣分合擊（FC-6b）----
var combo_effects_cfg: Dictionary = {}	# combo_effect 鍵 → 效果參數（資料層）
var active_combos: Array = []			# 目前佈陣啟用的合擊效果鍵（AffinitySystem 偵測）

var _rng: RandomNumberGenerator
var _waves_total: int = 0			# 翻譯出的總波數（判斷「出齊」用）

## 讀戰鬥調參（res://，回 properties；失敗回 {}）。鐵律 1：UI/控制器不硬編數值。
static func load_config() -> Dictionary:
	if not FileAccess.file_exists(CONFIG_PATH):
		return {}
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed.get("properties", {})

## 讀符令調參（res://；失敗回 {}）。鐵律 1：符令種類/數值/起手牌庫全資料層。
static func load_fu_config() -> Dictionary:
	if not FileAccess.file_exists(FU_CONFIG_PATH):
		return {}
	var f := FileAccess.open(FU_CONFIG_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed.get("properties", {})

## 組符令 config：符令定義/參數讀檔，牌庫用傳入的 deck（持久 run 牌庫）覆寫（空則用檔內預設）。
static func build_fu_config(deck: Array) -> Dictionary:
	var fc: Dictionary = load_fu_config()
	if not deck.is_empty():
		fc["starter_deck"] = deck.duplicate()
	return fc

## 抽 count 個相異符令當 draft 候選（從 draft_pool；rng 可注入求可重現）。
static func draft_fu_choices(count: int, rng: RandomNumberGenerator) -> Array:
	var cfg: Dictionary = load_fu_config()
	var pool: Array = (cfg.get("draft_pool", []) as Array).duplicate()
	if pool.is_empty():
		pool = (cfg.get("fu", {}) as Dictionary).keys()
	# Fisher–Yates 取前 count（相異）
	for i: int in range(pool.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var out: Array = []
	for k: int in range(mini(count, pool.size())):
		out.append(str(pool[k]))
	return out

## 建一場。
##  open_camp_ids：本局已揭露的營 id（FC-3 漸進揭露傳子集；空＝全部 FC-1 五營）。
##  deploy：unit_id→camp_id 指定佈陣；空＝依五行得位自動佈陣（複用「resolve 初值」概念）。
##  enemy_specs：[{id,hp,name?,element?}]（場景由 EnemyData 解析後傳入；測試直接給）。
##  config：注入調參（空＝load_config()）。run_seed：擲筊/陰筊用，可重現。
func setup(open_camp_ids: Array, deploy: Dictionary, enemy_specs: Array, config: Dictionary, run_seed: int) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = run_seed
	var cfg: Dictionary = config if not config.is_empty() else load_config()

	altar_max = int(cfg.get("altar_max_integrity", 30))
	altar_integrity = altar_max
	element_multipliers = cfg.get("element_multipliers", {})
	jiao_weights = cfg.get("jiao_weights", {})
	jiao_yin_surge = int(cfg.get("jiao_yin_surge", 4))
	base_actions = int(cfg.get("base_actions_per_turn", 1))
	sheng_bonus = int(cfg.get("sheng_bonus_actions", 1))
	max_turns = int(cfg.get("max_turns", 30))
	deity_charge_max = int(cfg.get("deity_charge_max", 3))
	deity_invoke_power = int(cfg.get("deity_invoke_power", 4))
	combo_effects_cfg = cfg.get("combo_effects", {})

	_load_camps(open_camp_ids)
	_build_lanes(int(cfg.get("lane_steps_to_altar", 3)))
	waves = _build_waves(enemy_specs, cfg)
	_waves_total = waves.size()

	if deploy.is_empty():
		auto_deploy()
	else:
		for uid: String in deploy:
			if units.has(uid) and _camp_exists(str(deploy[uid])):
				unit_location[uid] = str(deploy[uid])
	_recompute_combos()	# 緣分合擊隨佈陣偵測

	# 符令手牌（FP-2）：可由 config 注入 fu_config 覆寫（測試確定性），否則讀 formation_fu.json
	var fu_cfg: Dictionary = cfg.get("fu_config", {})
	if fu_cfg.is_empty():
		fu_cfg = load_fu_config()
	_init_fu(fu_cfg)

	turn = 1
	deity_charge = 0
	state = STATE_PLAYING
	log_events.clear()
	_begin_turn()

## 建符令牌庫：洗起手牌庫、抽起手。
func _init_fu(fu_cfg: Dictionary) -> void:
	fu_defs = fu_cfg.get("fu", {})
	fu_hand_max = int(fu_cfg.get("hand_max", 5))
	fu_draw_per_turn = int(fu_cfg.get("draw_per_turn", 1))
	fu_plays_per_turn = int(fu_cfg.get("plays_per_turn", 1))
	fu_deck = (fu_cfg.get("starter_deck", []) as Array).duplicate()
	_shuffle_fu(fu_deck)
	fu_hand = []
	fu_discard = []
	fu_plays_left = 0
	_draw_fu(int(fu_cfg.get("initial_hand", 3)))

func _shuffle_fu(arr: Array) -> void:
	# Fisher–Yates（用注入種子的 _rng，可重現）
	for i: int in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

## 抽符令 n 張（手牌滿則止；抽牌堆空則洗棄牌堆回補）。
func _draw_fu(n: int) -> void:
	for _i: int in range(n):
		if fu_hand.size() >= fu_hand_max:
			return
		if fu_deck.is_empty():
			if fu_discard.is_empty():
				return
			fu_deck = fu_discard.duplicate()
			fu_discard.clear()
			_shuffle_fu(fu_deck)
		fu_hand.append(fu_deck.pop_back())

## 打符令：本回合限打 fu_plays_per_turn 張。needs_target 須指定有煞的 lane。回成功與否。
func play_fu(fu_id: String, target_lane: String = "") -> bool:
	if state != STATE_PLAYING or fu_plays_left <= 0:
		return false
	if not fu_hand.has(fu_id) or not fu_defs.has(fu_id):
		return false
	var def: Dictionary = fu_defs[fu_id]
	var needs_target: bool = bool(def.get("needs_target", false))
	var mag: int = int(def.get("magnitude", 0))
	var effect: String = str(def.get("effect", ""))
	if needs_target:
		# 須指定「有煞」的 lane（避免空放浪費）
		if not lanes.has(target_lane) or lanes[target_lane]["sha"] == null:
			return false
	match effect:
		"po_sha":
			var sha: Variant = lanes[target_lane]["sha"]
			sha["strength"] -= mag
			if sha["strength"] <= 0:
				lanes[target_lane]["sha"] = null
		"stall":
			lanes[target_lane]["sha"]["steps"] += mag
		"action":
			actions_remaining += mag
		"deity_charge":
			deity_charge = mini(deity_charge_max, deity_charge + mag)
		_:
			return false
	fu_hand.erase(fu_id)
	fu_discard.append(fu_id)
	fu_plays_left -= 1
	_emit(EV_FU, {"fu": fu_id, "effect": effect, "lane": target_lane, "magnitude": mag})
	return true

## 從 FC-1 lookup 載入營（含中營），可選只開子集。units 載全部可佈陣單位。
func _load_camps(open_camp_ids: Array) -> void:
	camps.clear()
	units.clear()
	unit_location.clear()
	var all_camps: Dictionary = Global._id_to_formation_camp_data if "_id_to_formation_camp_data" in Global else {}
	for cid: String in all_camps:
		if not open_camp_ids.is_empty() and not open_camp_ids.has(cid):
			continue
		var c: FormationCampData = all_camps[cid]
		camps.append({"id": cid, "name": c.camp_name, "element": c.camp_element, "lane": c.camp_lane})
	var all_units: Dictionary = Global._id_to_formation_unit_data if "_id_to_formation_unit_data" in Global else {}
	for uid: String in all_units:
		var u: FormationUnitData = all_units[uid]
		units[uid] = {"id": uid, "name": u.unit_name, "element": u.unit_element, "power": u.unit_power, "kind": u.unit_kind}

## 每個方位營（lane 非空）開一條 lane；中營（lane 空）為調度中樞、無 lane。
func _build_lanes(steps_to_altar: int) -> void:
	lanes.clear()
	for c: Dictionary in camps:
		var lane: String = str(c.get("lane", ""))
		if lane == "":
			continue
		lanes[lane] = {"camp": str(c.get("id")), "steps_to_altar": steps_to_altar, "sha": null}

## 敵人事件 → 煞波：每敵一波，煞值＝clamp(hp/divisor)；lane 輪流分配；波次錯開回合。
func _build_waves(enemy_specs: Array, cfg: Dictionary) -> Array:
	var out: Array = []
	var lane_ids: Array = lanes.keys()
	if lane_ids.is_empty() or enemy_specs.is_empty():
		return out
	var divisor: int = maxi(1, int(cfg.get("enemy_hp_to_sha_divisor", 8)))
	var sha_min: int = int(cfg.get("enemy_sha_min", 3))
	var sha_max: int = int(cfg.get("enemy_sha_max", 14))
	var stagger: int = maxi(0, int(cfg.get("wave_stagger_turns", 1)))
	for i: int in range(enemy_specs.size()):
		var spec: Dictionary = enemy_specs[i]
		var hp: int = int(spec.get("hp", 0))
		var strength: int = clampi(int(round(float(hp) / float(divisor))), sha_min, sha_max)
		out.append({
			"turn": 1 + i * stagger,
			"lane": str(lane_ids[i % lane_ids.size()]),
			"strength": strength,
			"element": str(spec.get("element", "")),
		})
	return out

## 開場自動佈陣：每營一個對位單位（五行得位優先），多的塞中營（調度中樞待命）。
func auto_deploy() -> void:
	unit_location.clear()
	var available: Array = units.keys()
	# 先讓每營吃一個「同行/受生（得位）」單位
	for camp: Dictionary in camps:
		if str(camp.get("lane", "")) == "":
			continue
		var camp_el: String = str(camp.get("element"))
		var best: String = ""
		for uid: String in available:
			if FiveElementsCls.is_wei_position(str(units[uid].get("element")), camp_el):
				best = uid
				break
		if best == "":
			# 無得位者，退而求其次給任一可用單位
			best = available[0] if not available.is_empty() else ""
		if best != "":
			unit_location[best] = str(camp.get("id"))
			available.erase(best)
	# 剩餘進中營
	var center_id: String = _center_camp_id()
	if center_id != "":
		for uid: String in available:
			unit_location[uid] = center_id

func _center_camp_id() -> String:
	for c: Dictionary in camps:
		if str(c.get("lane", "")) == "":
			return str(c.get("id"))
	return ""

func _begin_turn() -> void:
	actions_remaining = base_actions
	jiao_rolled_this_turn = false
	last_jiao = ""
	# 符令：回合開始重置可打次數、抽牌
	fu_plays_left = fu_plays_per_turn
	_draw_fu(fu_draw_per_turn)
	if turn > 1:
		deity_charge = mini(deity_charge_max, deity_charge + 1)
	# 生煞：本回合排程的波落到其 lane（steps＝lane 全長）
	for w: Dictionary in waves:
		if int(w.get("turn", -1)) == turn:
			var lane: String = str(w.get("lane"))
			if lanes.has(lane):
				lanes[lane]["sha"] = {
					"strength": int(w.get("strength", 4)),
					"steps": int(lanes[lane]["steps_to_altar"]),
					"element": str(w.get("element", "")),
				}
				_emit(EV_SHA_SPAWN, {"turn": turn, "lane": lane, "strength": int(w.get("strength")), "steps": int(lanes[lane]["steps_to_altar"])})
	# 緣分合擊：每回合開盤生效（資料層數值）
	_apply_combo_start_effects()

## 調營：把單位移到某營（佈陣/移防），花一個動作。回成功與否。
func move_unit(unit_id: String, camp_id: String) -> bool:
	if state != STATE_PLAYING or actions_remaining <= 0:
		return false
	if not units.has(unit_id) or not _camp_exists(camp_id):
		return false
	if unit_location.get(unit_id, "") == camp_id:
		return false
	unit_location[unit_id] = camp_id
	actions_remaining -= 1
	_recompute_combos()	# 調營改變鄰接 → 重算緣分合擊
	_emit(EV_MOVE, {"unit": unit_id, "camp": camp_id, "actions_left": actions_remaining})
	return true

## 擲筊節奏閘（每回合一次，push-your-luck）：聖=多一動作 / 笑=無 / 陰=某 lane 暴衝。
func roll_jiao() -> String:
	if state != STATE_PLAYING or jiao_rolled_this_turn:
		return ""
	jiao_rolled_this_turn = true
	var r: float = _rng.randf()
	var sheng: float = float(jiao_weights.get("sheng", 0.45))
	var xiao: float = float(jiao_weights.get("xiao", 0.30))
	if r < sheng:
		last_jiao = JIAO_SHENG
		actions_remaining += sheng_bonus
		_emit(EV_JIAO, {"result": JIAO_SHENG, "bonus": sheng_bonus})
	elif r < sheng + xiao:
		last_jiao = JIAO_XIAO
		_emit(EV_JIAO, {"result": JIAO_XIAO})
	else:
		last_jiao = JIAO_YIN
		_apply_yin_surge()
	return last_jiao

func _apply_yin_surge() -> void:
	_emit(EV_JIAO, {"result": JIAO_YIN})
	var target_lane: String = ""
	for lane: String in lanes:
		if lanes[lane]["sha"] != null:
			target_lane = lane
			break
	if target_lane == "" and not lanes.is_empty():
		target_lane = str(lanes.keys()[_rng.randi_range(0, lanes.size() - 1)])
		if lanes[target_lane]["sha"] == null:
			lanes[target_lane]["sha"] = {
				"strength": jiao_yin_surge, "steps": int(lanes[target_lane]["steps_to_altar"]), "element": "",
			}
			_emit(EV_YIN_SURGE, {"lane": target_lane, "amount": jiao_yin_surge, "spawned": true})
			return
	if target_lane != "" and lanes[target_lane]["sha"] != null:
		lanes[target_lane]["sha"]["strength"] += jiao_yin_surge
		_emit(EV_YIN_SURGE, {"lane": target_lane, "amount": jiao_yin_surge, "spawned": false})

## 降乩：請神槽滿（>= deity_charge_max）時可發，對每條 lane 最前方的煞削 deity_invoke_power。
func invoke_deity() -> bool:
	if state != STATE_PLAYING or deity_charge < deity_charge_max:
		return false
	deity_charge = 0
	var hit: int = 0
	var broke: Array = []
	for lane: String in lanes:
		var sha: Variant = lanes[lane]["sha"]
		if sha == null:
			continue
		sha["strength"] -= deity_invoke_power
		hit += 1
		if sha["strength"] <= 0:
			lanes[lane]["sha"] = null
			broke.append(lane)
	_emit(EV_DEITY, {"hit": hit, "power": deity_invoke_power, "broke": broke})
	return true

## 緣分合擊偵測（佈陣/調營後重算）：把啟用的合擊效果鍵存進 active_combos。
func _recompute_combos() -> void:
	active_combos = AffinitySystemCls.active_combo_effects(unit_location, camps)

## 每回合開盤套用緣分合擊（效果語意在碼、數值在 combo_effects_cfg＝鐵律1）。
func _apply_combo_start_effects() -> void:
	for combo: String in active_combos:
		var params: Dictionary = combo_effects_cfg.get(combo, {})
		match combo:
			"combo_earth_ward":	# 城隍土地：母壇每回合自癒
				var heal: int = int(params.get("altar_heal_per_turn", 0))
				if heal > 0 and altar_integrity < altar_max:
					altar_integrity = mini(altar_max, altar_integrity + heal)
					_emit(EV_COMBO, {"combo": combo, "altar_heal": heal, "altar": altar_integrity})
			"combo_sea_watch":	# 媽祖三聖：預警 + 先制削最逼近母壇的煞
				var cut: int = int(params.get("presha_cut_per_turn", 0))
				if cut > 0:
					var lane: String = _frontmost_sha_lane()
					if lane != "":
						var sha: Variant = lanes[lane]["sha"]
						sha["strength"] -= cut
						if sha["strength"] <= 0:
							lanes[lane]["sha"] = null
						_emit(EV_COMBO, {"combo": combo, "lane": lane, "cut": cut})

## 最逼近母壇（剩餘步數最少）的有煞 lane（無則回空）。
func _frontmost_sha_lane() -> String:
	var best: String = ""
	var best_steps: int = 1 << 30
	for lane: String in lanes:
		var sha: Variant = lanes[lane]["sha"]
		if sha != null and int(sha["steps"]) < best_steps:
			best_steps = int(sha["steps"])
			best = lane
	return best

## 結算本回合：各 lane 該營攔煞（五行得位加成）→ 殘煞推進 → 抵母壇/營空則扣母壇 → 判勝負。
func end_turn() -> void:
	if state != STATE_PLAYING:
		return
	for lane: String in lanes:
		var sha: Variant = lanes[lane]["sha"]
		if sha == null:
			continue
		var camp_id: String = str(lanes[lane]["camp"])
		var defender: String = _unit_in_camp(camp_id)
		if defender != "":
			var dmg: int = _intercept_damage(defender, camp_id)
			sha["strength"] -= dmg
			_emit(EV_INTERCEPT, {"unit": defender, "camp": camp_id, "lane": lane, "dmg": dmg, "remaining": maxi(0, int(sha["strength"]))})
			if sha["strength"] <= 0:
				lanes[lane]["sha"] = null
				_emit(EV_SHA_BREAK, {"lane": lane})
				continue
		else:
			_emit(EV_EMPTY_CAMP, {"camp": camp_id, "lane": lane})
		sha["steps"] -= 1
		if sha["steps"] <= 0:
			altar_integrity -= int(sha["strength"])
			_emit(EV_ALTAR_HIT, {"lane": lane, "amount": int(sha["strength"]), "remaining": maxi(0, altar_integrity)})
			lanes[lane]["sha"] = null
	# 判敗：母壇崩
	if altar_integrity <= 0:
		altar_integrity = 0
		state = STATE_LOST
		_emit(EV_LOSE, {})
		return
	# 判勝：波次出齊且場上無煞 = 殲敵
	if _all_waves_spawned() and not _any_sha_on_field():
		state = STATE_WON
		_emit(EV_WIN, {})
		return
	# 安全閥：超過 max_turns 以母壇存亡裁定（防呆，正常局不會觸發）
	if turn >= max_turns:
		state = STATE_WON if altar_integrity > 0 else STATE_LOST
		_emit(EV_RESOLVE, {"state": state})
		return
	turn += 1
	_begin_turn()

## 削煞量：unit_power × 五行得位倍率（FiveElements 查資料層 element_multipliers）。
func _intercept_damage(unit_id: String, camp_id: String) -> int:
	var power: int = int(units[unit_id].get("power", 0))
	var unit_el: String = str(units[unit_id].get("element", ""))
	var camp_el: String = _camp_element(camp_id)
	var mult: float = FiveElementsCls.damage_multiplier(unit_el, camp_el, element_multipliers)
	return int(round(float(power) * mult))

func is_wei_position(unit_id: String, camp_id: String) -> bool:
	if not units.has(unit_id):
		return false
	return FiveElementsCls.is_wei_position(str(units[unit_id].get("element", "")), _camp_element(camp_id))

# ---- 局面查詢 ----
func _all_waves_spawned() -> bool:
	for w: Dictionary in waves:
		if int(w.get("turn", 0)) > turn:
			return false
	return true

func _any_sha_on_field() -> bool:
	for lane: String in lanes:
		if lanes[lane]["sha"] != null:
			return true
	return false

func _unit_in_camp(camp_id: String) -> String:
	for uid: String in unit_location:
		if unit_location[uid] == camp_id:
			return uid
	return ""

func _camp_exists(camp_id: String) -> bool:
	for c: Dictionary in camps:
		if str(c.get("id")) == camp_id:
			return true
	return false

func _camp_element(camp_id: String) -> String:
	for c: Dictionary in camps:
		if str(c.get("id")) == camp_id:
			return str(c.get("element"))
	return ""

func _emit(ev_type: String, data: Dictionary) -> void:
	data["t"] = ev_type
	log_events.append(data)
	if log_events.size() > 80:
		log_events.pop_front()
