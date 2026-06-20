# 鎮島錄 c-1 每日上香 + c-2 外觀變現紅線 — 連簽/獎勵階梯/扣款守門。
# 純邏輯：以注入的 today/yesterday 日字串做確定性測試（不依系統時鐘）。
extends "res://tests/test_case.gd"

func _profile() -> ProfileData:
	return ProfileData.new()

# ── 每日上香連簽 ──
func test_first_offer_starts_streak_one() -> void:
	var p := _profile()
	var r: Dictionary = p._offer_on("2026-06-20", "2026-06-19")
	assert_true(r["claimed"], "首次上香應成功")
	assert_eq(r["streak"], 1, "首日連簽＝1")
	assert_eq(r["incense"], 20, "第1日香火＝20（階梯首格）")
	assert_eq(p.profile_incense_balance, 20, "香火入帳 20")

func test_same_day_second_offer_is_noop() -> void:
	var p := _profile()
	p._offer_on("2026-06-20", "2026-06-19")
	var r: Dictionary = p._offer_on("2026-06-20", "2026-06-19")
	assert_false(r["claimed"], "同日二次上香應被擋")
	assert_eq(p.profile_incense_balance, 20, "香火不重複入帳")

func test_consecutive_day_increments_streak() -> void:
	var p := _profile()
	p._offer_on("2026-06-20", "2026-06-19")
	var r: Dictionary = p._offer_on("2026-06-21", "2026-06-20")
	assert_eq(r["streak"], 2, "連續日連簽 +1")
	assert_eq(r["incense"], 25, "第2日香火＝25")

func test_gap_resets_streak() -> void:
	var p := _profile()
	p._offer_on("2026-06-20", "2026-06-19")
	p._offer_on("2026-06-21", "2026-06-20")	# streak 2
	var r: Dictionary = p._offer_on("2026-06-25", "2026-06-24")	# 斷簽
	assert_eq(r["streak"], 1, "斷簽後連簽歸 1")
	assert_eq(r["incense"], 20, "歸 1 後香火回階梯首格")

func test_day_seven_milestone_grants_yuanbao() -> void:
	var p := _profile()
	var dates: Array = ["2026-06-20", "2026-06-21", "2026-06-22", "2026-06-23", "2026-06-24", "2026-06-25", "2026-06-26"]
	var prev: String = "2026-06-19"
	var r: Dictionary = {}
	for d: String in dates:
		r = p._offer_on(d, prev)
		prev = d
	assert_eq(r["streak"], 7, "連簽 7 日")
	assert_eq(r["incense"], 80, "第7日香火里程碑＝80")
	assert_eq(r["yuanbao"], ProfileData.DAILY_YUANBAO_MILESTONE, "第7日加碼元寶")
	assert_eq(p.profile_yuanbao, ProfileData.DAILY_YUANBAO_MILESTONE, "元寶入帳")

func test_yuanbao_only_on_milestone_not_other_days() -> void:
	var p := _profile()
	var r1: Dictionary = p._offer_on("2026-06-20", "2026-06-19")
	assert_eq(r1["yuanbao"], 0, "非里程碑日不給元寶")

func test_cycle_day_wraps_after_seven() -> void:
	var p := _profile()
	p.profile_incense_streak = 8
	assert_eq(p.incense_cycle_day(), 1, "第 8 日連簽 → 循環日序回 1")

func test_yesterday_of_handles_boundaries() -> void:
	assert_eq(ProfileData._yesterday_of("2026-07-01"), "2026-06-30", "跨月前一日正確")
	assert_eq(ProfileData._yesterday_of("2026-01-01"), "2025-12-31", "跨年前一日正確")

# ── 外觀變現紅線（c-2）──
func test_spend_yuanbao_deducts_when_affordable() -> void:
	var p := _profile()
	p.profile_yuanbao = 100
	assert_true(p.spend_yuanbao(30), "餘額足應扣款成功")
	assert_eq(p.profile_yuanbao, 70, "元寶扣 30")

func test_spend_yuanbao_rejects_when_insufficient() -> void:
	var p := _profile()
	p.profile_yuanbao = 10
	assert_false(p.spend_yuanbao(30), "餘額不足應拒絕")
	assert_eq(p.profile_yuanbao, 10, "拒絕時元寶不變")

func test_spend_yuanbao_never_touches_incense() -> void:
	var p := _profile()
	p.profile_yuanbao = 100
	p.profile_incense_balance = 500
	p.spend_yuanbao(50)
	assert_eq(p.profile_incense_balance, 500, "紅線：買外觀不得動香火/戰力")

func test_own_cosmetic_is_idempotent() -> void:
	var p := _profile()
	p.own_cosmetic("frame_gold")
	p.own_cosmetic("frame_gold")
	assert_eq(p.profile_owned_cosmetics.size(), 1, "重複擁有不重複入庫")
	assert_true(p.has_cosmetic("frame_gold"), "查詢已擁有")
