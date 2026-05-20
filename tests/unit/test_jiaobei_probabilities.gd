# 鎮島錄 — 擲筊機率守護測試
#
# 對應 GDD_02 §5 機率計算流程與 §9 平衡考量。每次跑 10k 次模擬，
# 驗證分佈在 ±2% 內，並驗證各 modifier（誠意/好感/聖誕/燒金紙策略）
# 行為符合設計。
extends "res://tests/test_case.gd"

const SIM := preload("res://scripts/sim/CombatSimulator.gd")
const CORE := preload("res://scripts/sim/JiaobeiSimCore.gd")

# 統計誤差容忍（10k 樣本下標準差約 0.5%，容忍 ±2% 給安全邊際）
const TOL: float = 0.02
const N: int = 10000

# ---------- 基線分佈 ----------

func test_jiaobei_baseline_25_50_25() -> void:
	var d: Dictionary = SIM.run_jiaobei_distribution({}, N, 12345).to_dict()
	assert_true(absf(d["holy_rate"] - 0.25) < TOL,
		"baseline 聖筊 ~25%%（實得 %.3f）" % d["holy_rate"])
	assert_true(absf(d["laugh_rate"] - 0.50) < TOL,
		"baseline 笑筊 ~50%%（實得 %.3f）" % d["laugh_rate"])
	assert_true(absf(d["yin_rate"] - 0.25) < TOL,
		"baseline 陰筊 ~25%%（實得 %.3f）" % d["yin_rate"])

# ---------- 誠意修正 ----------

func test_jiaobei_sincerity_3_layers_caps_at_15pct() -> void:
	# 3 層 × 5% = +15% 聖筊上限
	var d: Dictionary = SIM.run_jiaobei_distribution({"sincerity": 3}, N, 12345).to_dict()
	assert_true(d["holy_rate"] > 0.38 and d["holy_rate"] < 0.42,
		"誠意 3 層應使聖筊 ~40%%（實得 %.3f）" % d["holy_rate"])

func test_jiaobei_sincerity_caps_no_overflow() -> void:
	# 即使 sincerity=10 也應截斷在 3 層
	var d3: Dictionary = SIM.run_jiaobei_distribution({"sincerity": 3}, N, 12345).to_dict()
	var d10: Dictionary = SIM.run_jiaobei_distribution({"sincerity": 10}, N, 12345).to_dict()
	assert_true(absf(d3["holy_rate"] - d10["holy_rate"]) < TOL,
		"誠意上限為 3 層，更高值不應再加成（diff=%.3f）" % absf(d3["holy_rate"] - d10["holy_rate"]))

# ---------- 神明好感 ----------

func test_jiaobei_favor_80_plus_boosts_holy_10pct() -> void:
	var d: Dictionary = SIM.run_jiaobei_distribution({"favor": 90}, N, 12345).to_dict()
	# 25% + 10% = 35%
	assert_true(d["holy_rate"] > 0.32 and d["holy_rate"] < 0.38,
		"好感 90 應使聖筊 ~35%%（實得 %.3f）" % d["holy_rate"])

func test_jiaobei_favor_below_20_raises_yin_lowers_holy() -> void:
	var d: Dictionary = SIM.run_jiaobei_distribution({"favor": 5}, N, 12345).to_dict()
	# yin +10% → 35%; holy -5% → 20%
	assert_true(d["yin_rate"] > 0.32 and d["yin_rate"] < 0.38,
		"好感 < 20 應使陰筊 ~35%%（實得 %.3f）" % d["yin_rate"])
	assert_true(d["holy_rate"] > 0.17 and d["holy_rate"] < 0.23,
		"好感 < 20 應使聖筊 ~20%%（實得 %.3f）" % d["holy_rate"])

# ---------- 神明聖誕 ----------

func test_jiaobei_deity_birthday_boosts_holy_15pct() -> void:
	var d: Dictionary = SIM.run_jiaobei_distribution({"deity_birthday": true}, N, 12345).to_dict()
	# 25 + 15 = 40%
	assert_true(d["holy_rate"] > 0.37 and d["holy_rate"] < 0.43,
		"神明聖誕應使聖筊 ~40%%（實得 %.3f）" % d["holy_rate"])

# ---------- 複合修正 ----------

func test_jiaobei_max_compound_ceiling_around_65pct() -> void:
	# GDD_02 §9.1：誠意封頂 + 好感 80+ + 聖誕，理論上限約 65%
	var d: Dictionary = SIM.run_jiaobei_distribution({
		"sincerity": 3,
		"favor": 90,
		"deity_birthday": true,
	}, N, 12345).to_dict()
	# 25 + 15 + 10 + 15 = 65%（含 normalize 後微差）
	assert_true(d["holy_rate"] > 0.60 and d["holy_rate"] < 0.70,
		"複合上限應 ~65%%（實得 %.3f）" % d["holy_rate"])

# ---------- 強制結果（默禱卡） ----------

func test_jiaobei_forced_holy_is_deterministic() -> void:
	var rep: SIM.SimReport = SIM.run_jiaobei_distribution({"forced_result": "holy"}, 100, 12345)
	assert_eq(rep.holy_count, 100, "forced=holy 應 100%% 聖筊（如默禱卡）")
	assert_eq(rep.laugh_count, 0, "forced=holy 不應有笑筊")
	assert_eq(rep.yin_count, 0, "forced=holy 不應有陰筊")

# ---------- 燒金紙策略 ----------

func test_burn_paper_strategy_reduces_yin_rate() -> void:
	# 不重擲 vs 陰筊時重擲，後者陰筊率應顯著下降
	var no_reroll: Dictionary = SIM.run_jiaobei_with_strategy({}, "never", 1000, N, 12345).to_dict()
	var burn_on_yin: Dictionary = SIM.run_jiaobei_with_strategy({}, "burn_on_yin", 1000, N, 12345).to_dict()
	assert_true(no_reroll["yin_rate"] > burn_on_yin["yin_rate"] + 0.10,
		"陰筊燒金紙策略應使陰筊率明顯下降（no=%.3f burn=%.3f）" % [no_reroll["yin_rate"], burn_on_yin["yin_rate"]])

func test_burn_paper_cost_curve_5_8_11_14_17() -> void:
	# GDD_02 §3.1：5 → 8 → 11 → 14 → 17（每次 +3）
	assert_eq(CORE.burn_paper_cost(0), 5, "第 1 次燒紙 5 香火")
	assert_eq(CORE.burn_paper_cost(1), 8, "第 2 次 8")
	assert_eq(CORE.burn_paper_cost(2), 11, "第 3 次 11")
	assert_eq(CORE.burn_paper_cost(3), 14, "第 4 次 14")
	assert_eq(CORE.burn_paper_cost(4), 17, "第 5 次 17")

func test_burn_paper_limited_to_5_per_combat() -> void:
	# 給超大預算，看會不會超過 5 次重擲
	var rep: SIM.SimReport = SIM.run_jiaobei_with_strategy({}, "burn_until_holy", 9999, 1000, 12345)
	# 平均重擲次數應 < 5（受上限約束）
	var avg_rerolls: float = float(rep.rerolls_performed) / float(rep.runs)
	assert_true(avg_rerolls <= 5.0,
		"燒金紙每場上限 5 次，平均重擲應 ≤ 5（實得 %.2f）" % avg_rerolls)
