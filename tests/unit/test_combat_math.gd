# 鎮島錄 — 戰鬥核心邏輯單元測試
#
# 對應 CLAUDE.md §7「戰鬥核心邏輯：必須有單元測試」。
# 聚焦 headless 下穩定、純粹的核心：確定性 RNG（PRD 7.2 要求 run 可重現）
# 與 ArtifactFilter 篩選邏輯（決定 reward / 商店池）。
extends "res://tests/test_case.gd"

# ---------- 確定性 RNG（種子可重現） ----------

func test_seeded_shuffle_is_deterministic() -> void:
	var base: Array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

	var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_a.seed = 424242
	var result_a: Array = Random.shuffle_array(rng_a, base.duplicate())

	var rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_b.seed = 424242
	var result_b: Array = Random.shuffle_array(rng_b, base.duplicate())

	assert_eq(result_a, result_b, "同種子洗牌結果必須一致（run 可重現的基礎）")
	# 洗牌後仍是原集合的排列，不可遺失或新增元素
	var sorted_result: Array = result_a.duplicate()
	sorted_result.sort()
	assert_eq(sorted_result, base, "洗牌不應改變集合內容")

func test_different_seeds_differ() -> void:
	var base: Array = []
	for i in 30:
		base.append(i)
	var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_a.seed = 1
	var rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_b.seed = 999999
	var a: Array = Random.shuffle_array(rng_a, base.duplicate())
	var b: Array = Random.shuffle_array(rng_b, base.duplicate())
	assert_ne(a, b, "不同種子在 30 元素下幾乎不可能得到相同排列")

# ---------- 加權選擇（敵人意圖 / rarity 抽取的核心） ----------

func test_weighted_selection_skips_zero_weight() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var weights: Dictionary[Variant, int] = {"never": 0, "always": 1}
	for i in 50:
		var picked: Variant = Random.get_weighted_selection(rng, weights)
		assert_eq(picked, "always", "權重 0 的選項永遠不應被選中")

func test_weighted_selection_single_option() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var weights: Dictionary[Variant, int] = {"only": 5}
	assert_eq(Random.get_weighted_selection(rng, weights), "only",
		"唯一選項必被選中")

func test_weighted_selection_empty_returns_null() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var weights: Dictionary[Variant, int] = {}
	assert_eq(Random.get_weighted_selection(rng, weights), null,
		"空權重表應回傳 null")

# ---------- ArtifactFilter：reward / 商店遺物池篩選 ----------

func test_artifact_filter_by_color_tongji() -> void:
	var ids: Array[String] = ArtifactFilter.new().filter_colors(["color_tongji"]).convert_to_unique_artifact_object_ids()
	assert_true(ids.has("artifact_tongji_amulet"),
		"color_tongji 篩選應包含平安符")
	for id: String in ids:
		var ad: ArtifactData = Global.get_artifact_data(id)
		assert_eq(ad.artifact_color_id, "color_tongji",
			"color 篩選後不應混入非乩童色遺物：%s" % id)

func test_artifact_filter_appears_in_packs() -> void:
	# 平安符 artifact_appears_in_artifact_packs=false，不應出現在「可進池」結果
	var pack_ids: Array[String] = ArtifactFilter.new().filter_appears_in_artifact_packs(true).convert_to_unique_artifact_object_ids()
	assert_false(pack_ids.has("artifact_tongji_amulet"),
		"起手專屬遺物平安符不應進入 reward 池")
