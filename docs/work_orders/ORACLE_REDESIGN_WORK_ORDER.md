# Claude Code 自主工作令 — 神示供桌（RSO）重設計（2026-06-17）

> **完全自主模式。** 自己決策、自己驗證、自己修,跑到底。只在 §0 硬停條件與 §7 終點報告找我。這不是從零做——**舞台已搭好一半,你的工作是補實、餵對料、慶祝稀有。**

---

## 0. 自主契約
**你可自行決定:** 實作細節、節點/檔案結構、命名、phase 內排序、UI 微調、暫用數值——所有**可逆**的東西。遇模糊 → 選最可逆選項 → 記一行 `QUESTIONS.md` → **繼續,不要停**。

**硬停條件（只有這幾種才停）:**
1. 不可逆/破壞性:刪既有測試或合約節點、破壞向後相容、改動變現/文化紅線。
2. 同一錯誤修 3 次仍紅且判斷無解。
3. 需求與 repo 現狀根本矛盾。
4. **素材生成** 連續失敗 → 回退既有/程序化資產 + 記 QUESTIONS.md,**不要卡死**(美術非阻塞)。

## 1. 背景與為什麼
畫面 = `scripts/ui/RunStartOptions.gd`(開局「神示供桌」,四籤擇一 + 擲筊)。chrome 已寫(供桌底、乩童 presenter、`JiaoBeiFX` 擲筊、金光 `offering_omen_glow`)。**但三個病:** ① 最美的籤詩資料(`external/data/fortune_sticks/*.json` 的 `stick_name`/`stick_verse`)沒被用,畫面走另一套 `run_start_options` + 無意義干支籤名(`omen.head1–4`);② 籤運不分視覺,上上籤跟廢籤長一樣;③ 底圖洗白、戰鬥 HUD 亂入、標題後鬼影、卡內文截斷。目標:把求籤做成**令人流連忘返**的問神儀式。

先讀:`DELEGATION.md`、`CLAUDE.md`、本目錄 `docs/design/ORACLE_ASSET_PROMPTS.md`。**repo 現狀為準。**

## 2. 我已替你定案的決策（直接用）
- **籤運階梯(唯一一套,enum):** `上上 / 上吉 / 中平 / 中下 / 下下`。把 `fortune_sticks` 的 `下/中下/中/上/上上` 與 `omen.head` 的 `中平/上上` **統一到這一套**。
- **餵料方式:** 給 RSO 的每個 `run_start_option` JSON **新增** `option_qian_name`(籤名)、`option_qian_verse`(四字籤詩)、`option_qian_grade`(籤運),沿用 `fortune_sticks` 既有詩句語氣。**廢掉寫死的 `omen.head1–4` 靜態籤名**(改成讀該籤自己的 `option_qian_name+grade`)。
- **遺物名:** 用「大醮遺物」(資料已是);**確保 `artifact_boss_*`(測試用)不在正式選池**,別讓「Boss」外洩到畫面。
- **HUD:** 求籤畫面隱藏 護 / 神力 / 預兆 與 0/0/0 空貨幣,只留與決策相關者。
- **素材:** 依 `ORACLE_ASSET_PROMPTS.md` 生成;底圖→`run_start_offering_bg_v3`、金光→`offering_omen_glow_v2`、依籤運套 `qian_frame_{tier}`。

## 3. 端到端工作流（自己跑完）

**Phase 1 — 餵對料（靈魂回 C 位）**
四張神示卡 = 真正籤詩:籤名 + 四字籤詩 + 利/忌 + 籤運。新增上述 JSON 欄位(全資料驅動,鐵律 1);`_apply_offering_strip_style` 改讀該籤自己的 `籤名/詩句/籤運`。保留 `test_p1_core_flow_contract.gd` 要求的 `OfferingCloth/OfferingTitle/ChoiceRuleLabel` 節點與「只能選一」語意。

**Phase 2 — 籤運視覺階梯（慶祝稀有）**
`_apply_offering_strip_style` 依 `grade` 分支:套 `qian_frame_{tier}` + tier 配色 + 籤首印章 `qian_seal_{tier}`;**上上**額外加金光/微放大,讓它一眼跳出。下下走灰燼裂紋。

**Phase 3 — 舞台補實 + 清雜訊**
換 `OFFERING_BG_PATH`→v3、`OMEN_GLOW`→v2;疊 籤筒/香煙/燭火 層(找不到素材回退,沿用現有 `ResourceLoader.exists` 寫法)。**修標題後方鬼影**(移除/拉高對比那個 stray label)、**修卡內文截斷**(走 `RitualCopyBudget` 長度預算)。RSO 隱藏戰鬥 HUD 與空貨幣。驗證渲染出「大醮遺物」。

**Phase 4 — 利忌分層 + 擲筊兩段 + 籤譜（stretch）**
每籤拆 ↑利(綠+icon)/↓忌(紅+icon),icons 用 `res_*`。擲筊改兩段:點籤→選中態(籤升起鍍金,沿用現有 tween)→「求此籤?」→ `JiaoBeiFX` 落定(聖筊才算)。**籤譜收藏(X/60)** 若工作量可控就做(持久存 `ProfileData`),否則記 QUESTIONS.md 標 stretch,不阻塞交付。

## 4. 護欄（自主也不能碰）
三鐵律(資料驅動 / mobile-first 88×88 / fork-first 新增>改核心)、名詞紅線(用 籤運/擲筊/聖筊/大醮;禁 韌性/弱點擊破/升階/終結技、禁英文 Boss 外洩)、變現(只賣外觀)、向後相容(新欄位預設空,既有測試維持綠)、演出 ≤ 1.5s 可跳過。**不得刪除 `test_p1_core_flow_contract` 的供桌合約節點。**

## 5. 自我驗證（取代逐步簽核）
每 Phase 結束自己跑,不綠自己修到綠:
- `godot --headless --import` → `godot --headless res://tests/TestRunner.tscn`(exit 0)
- 擴充驗證:籤運 enum 合法、`option_qian_*` 長度上限(擴 `tests/unit/test_new_run_copy_schema.gd` 或 `test_ritual_schema.gd`)、英文殘留(擴 `tests/unit/test_i18n_zero_residue.gd` 抓 "Boss")
- RSO 截圖:`godot --path . res://qa/uiux/rso_probe.gd` + 三解析度 `UIUX_RES={1244x700,1515x700,1200x900} … uiux_audit_driver.tscn`(08 神示供桌)全 `0 FAIL`
- 過 R1999 八條自評,任一 < 4 自己回頭修。
完成 = 全綠 + 八條 ≥ 4 + 截圖無鬼影/無截斷/上上發光/HUD 已清。

## 6. 關鍵檔案地圖
`scripts/ui/RunStartOptions.gd`・`external/data/run_start_options/*.json`・`external/data/fortune_sticks/*.json` + `FortuneSticks.gd`・`assets/translations/cotiw_main.csv`(omen.head/fortune.summary)・`scripts/ui/theme/CotiwUiTheme.gd`(paper_warm/incense_gold/lacquer_black)・`scripts/ui/fx/JiaoBeiFX.gd`・`scripts/ui/theme/CombatHudOverlay.gd`(護/預兆 strip)・`qa/uiux/rso_probe.gd`・`tests/unit/{test_p1_core_flow_contract,test_new_run_copy_schema,test_ritual_schema,test_i18n_zero_residue}.gd`・素材 prompt:`docs/design/ORACLE_ASSET_PROMPTS.md`

## 7. 終點報告（只在這裡找我）
跑完給我:① 改/新增檔清單 ② 測試 + 三解析度結果 ③ 神示供桌前後截圖 ④ R1999 八條分數 ⑤ 素材清單(生成/回退) ⑥ 籤譜去留 ⑦ 記進 `QUESTIONS.md` 的決策。

## 8. 現在開始
**不要回我問題、不要等確認。** 從 Phase 1 開工,自主跑到 §7 終點報告。只有撞到 §0 硬停條件才暫停。

**END — ORACLE_REDESIGN_WORK_ORDER.md（自主版）**
