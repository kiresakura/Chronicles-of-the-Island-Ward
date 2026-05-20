# 鎮島錄 — Combat Simulation Harness
#
# 給設計師/平衡：跑 N 次模擬戰鬥，輸出分佈統計報告。當前覆蓋擲筊機率分佈
# 與燒金紙策略；後續隨機制落地（神明被動、業力效應、流派勝率）擴充至
# 完整流派模擬。
#
# 為何先建骨架？v2 §1.2 警報 5 ── 100+ 變數交互無法手測，必須有自動化
# simulation harness 才能平衡 6 大支柱。此檔為「先有骨架日後填內容」。
extends RefCounted
class_name CombatSimulator

const JIAOBEI := preload("res://scripts/sim/JiaobeiSimCore.gd")

## 模擬報告
class SimReport extends RefCounted:
	var runs: int = 0
	var holy_count: int = 0
	var laugh_count: int = 0
	var yin_count: int = 0
	var incense_spent: int = 0
	var rerolls_performed: int = 0
	var extra_data: Dictionary = {}

	func to_dict() -> Dictionary:
		var safe_runs: float = float(maxi(runs, 1))
		return {
			"runs": runs,
			"holy_rate": float(holy_count) / safe_runs,
			"laugh_rate": float(laugh_count) / safe_runs,
			"yin_rate": float(yin_count) / safe_runs,
			"avg_incense_spent": float(incense_spent) / safe_runs,
			"avg_rerolls": float(rerolls_performed) / safe_runs,
			"extra": extra_data,
		}

## 純擲筊分佈：給定 state，跑 N 次擲筊（無重擲策略）
static func run_jiaobei_distribution(state: Dictionary, n: int, rng_seed: int = 42) -> SimReport:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var rep := SimReport.new()
	rep.runs = n
	var prob: Dictionary = JIAOBEI.compute_probabilities(state)
	for i in n:
		var result: String = JIAOBEI.roll(rng, prob)
		_tally(rep, result)
	return rep

## 帶燒金紙策略的擲筊：陰筊時燒金紙重擲，直到聖/笑筊或預算耗盡
## strategy:
##   "never" — 不重擲
##   "burn_on_yin" — 陰筊立即重擲（受燒紙上限約束）
##   "burn_until_holy" — 任何非聖筊都重擲
static func run_jiaobei_with_strategy(state: Dictionary, strategy: String, starting_incense: int, n: int, rng_seed: int = 42) -> SimReport:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var rep := SimReport.new()
	rep.runs = n
	for i in n:
		var incense: int = starting_incense
		var burns: int = 0
		var result: String = JIAOBEI.roll(rng, JIAOBEI.compute_probabilities(state))
		while _should_reroll(result, strategy) and burns < JIAOBEI.BURN_PAPER_MAX_PER_COMBAT:
			var cost: int = JIAOBEI.burn_paper_cost(burns)
			if incense < cost:
				break
			incense -= cost
			burns += 1
			result = JIAOBEI.roll(rng, JIAOBEI.compute_probabilities(state))
		_tally(rep, result)
		rep.incense_spent += (starting_incense - incense)
		rep.rerolls_performed += burns
	return rep

static func _should_reroll(result: String, strategy: String) -> bool:
	match strategy:
		"never":
			return false
		"burn_on_yin":
			return result == "yin"
		"burn_until_holy":
			return result != "holy"
	return false

static func _tally(rep: SimReport, result: String) -> void:
	match result:
		"holy": rep.holy_count += 1
		"laugh": rep.laugh_count += 1
		"yin": rep.yin_count += 1
