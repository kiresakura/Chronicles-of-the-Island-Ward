# 鎮島錄 — 擲筊機率引擎（純函式核心）
#
# 對應 GDD_02 §5「機率計算流程」。所有副作用（扣香火、消費 forced 結果、
# 觸發 interceptor）由上層處理；本類只負責「給定狀態 → 算機率 / 擲骰」。
#
# 這層獨立出來是為了可被 Simulation Harness 與真實戰鬥 Interceptor 共用，
# 並可獨立做高量級（10k+）模擬測試。
extends RefCounted
class_name JiaobeiSimCore

const BASE_HOLY: float = 0.25
const BASE_LAUGH: float = 0.50
const BASE_YIN: float = 0.25

# 誠意層上限（GDD_02 §3.2）
const SINCERITY_MAX_LAYERS: int = 3
const SINCERITY_PER_LAYER: float = 0.05  # 每層 +5% 聖筊

# 燒金紙成本曲線（GDD_02 §3.1）
const BURN_PAPER_BASE_COST: int = 5
const BURN_PAPER_INCREMENT: int = 3
const BURN_PAPER_MAX_PER_COMBAT: int = 5

## state 欄位：
##   sincerity: int (0..3+；自動截斷到上限)
##   favor: int (0..100) 當前神好感（預設 30 為中性區間）
##   deity_birthday: bool 是否該神聖誕
##   forced_result: String 強制結果 ("holy"/"laugh"/"yin"/"" )
##
## 設計：每個 modifier 用「配對加減」維持機率總和 = 1.0，避免 normalization
## 壓縮加成。對照 GDD_02 §5 範例：誠意+2 → 35/40/25；好感80+ → 45/40/15；
## 媽祖聖誕 → 60/30/10。最大化複合 ~65%（GDD §9.1）。
static func compute_probabilities(state: Dictionary) -> Dictionary:
	# 強制結果（默禱卡等）直接 short-circuit
	var forced: String = state.get("forced_result", "")
	if forced != "":
		var out := {"holy": 0.0, "laugh": 0.0, "yin": 0.0}
		if forced in out:
			out[forced] = 1.0
		return out

	var p := {"holy": BASE_HOLY, "laugh": BASE_LAUGH, "yin": BASE_YIN}

	# 1. 誠意修正：holy ↑ / laugh ↓（神更應允、較少搪塞）
	var sincerity: int = clampi(int(state.get("sincerity", 0)), 0, SINCERITY_MAX_LAYERS)
	var s_bonus: float = sincerity * SINCERITY_PER_LAYER
	p["holy"] += s_bonus
	p["laugh"] -= s_bonus

	# 2. 神明好感（預設 30 為中性區間）
	var favor: int = int(state.get("favor", 30))
	if favor >= 80:
		# 神喜歡你 → holy ↑ yin ↓（較少不悅）
		p["holy"] += 0.10
		p["yin"] -= 0.10
	elif favor >= 50:
		# 友善 → holy ↑ laugh ↓
		p["holy"] += 0.05
		p["laugh"] -= 0.05
	elif favor < 20:
		# 神嫌惡 → yin ↑ holy/laugh ↓
		p["yin"] += 0.10
		p["holy"] -= 0.05
		p["laugh"] -= 0.05

	# 3. 神明聖誕：holy ↑ / laugh ↓ yin ↓（吉日）
	if state.get("deity_birthday", false):
		p["holy"] += 0.15
		p["laugh"] -= 0.10
		p["yin"] -= 0.05

	# clamp + normalize（只在某機率變負時觸發）
	for k: String in p.keys():
		p[k] = maxf(p[k], 0.0)
	return _normalize(p)

static func _normalize(p: Dictionary) -> Dictionary:
	var total: float = p["holy"] + p["laugh"] + p["yin"]
	if total <= 0.0:
		# 防呆：所有機率被歸零，退化為全笑筊
		return {"holy": 0.0, "laugh": 1.0, "yin": 0.0}
	return {
		"holy": p["holy"] / total,
		"laugh": p["laugh"] / total,
		"yin": p["yin"] / total,
	}

## 給定機率與 rng 擲一次筊
static func roll(rng: RandomNumberGenerator, prob: Dictionary) -> String:
	var r: float = rng.randf()
	var holy: float = float(prob.get("holy", 0.0))
	var laugh: float = float(prob.get("laugh", 0.0))
	if r < holy:
		return "holy"
	if r < holy + laugh:
		return "laugh"
	return "yin"

## 計算第 n 次燒金紙的成本（n 從 0 起算）
static func burn_paper_cost(burn_count_so_far: int) -> int:
	return BURN_PAPER_BASE_COST + burn_count_so_far * BURN_PAPER_INCREMENT
