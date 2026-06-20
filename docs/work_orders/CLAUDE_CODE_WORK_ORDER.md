# Claude Code 自主工作令 — 新一局重排 + 五營原型（2026-06-17）

> **完全自主模式。** 不停下來問、不逐步等簽核:你自己決策、自己驗證、自己修,跑到底。只在 §0 的「硬停條件」與 §7 的「終點」找我。把你當能獨立交付的資深工程師。

---

## 0. 自主契約（最重要,先讀）

**你有權自行決定(不必問):** 實作細節、檔案/節點結構、命名、phase 內排序、UI 微調、暫用數值、所有**可逆**的東西。

**你必須:** 自己跑驗收、自己修到綠才往下;不要把半成品或紅燈丟回來。

**遇到模糊時的預設行為:** 選**最可逆**的選項 → 記一行進 `QUESTIONS.md`（情境/選項/你選了哪個/理由）→ **繼續走,不要停**。

**硬停條件（只有這幾種才暫停找我,其餘一律自主走完）:**
1. 要做**不可逆 / 破壞性**動作:刪既有測試、改既有 schema 破壞相容、**把 Task B 原型合進主線**、或任何牽涉**變現 / 文化敏感**紅線的改動。
2. 同一錯誤**修 3 次仍紅**,且你判斷再試無解。
3. 需求與 repo 現狀**根本矛盾**,無法用預設化解。

## 1. 角色與目標
你是 COTIW 代理製作人兼首席工程師。當前戰場「商業產品感」(對標 R1999 製作精緻度)。兩件事:**A(主線/可出貨)** 重排「新一局」畫面;**B(探索/賭注)** 用五營驗證能否徹底擺脫殺戮尖塔骨架。成功判準:新玩家說得出「破煞/請神/鎮守五營」而非「STS 換皮」。先讀 `DELEGATION.md`、`CLAUDE.md`、`PRD.md` §3–5、`docs/design/formation_progression_v0.3.md`。**repo 現狀為準**。

## 2. 我已替你定案的決策（別再評估,直接用）
- **Task A 進入點:** `scripts/ui/menus/NewRunMenu.gd`;文案/資料 `external/data/ui/new_run_copy_budget.json`、`external/data/ui/new_run_character_shelf.json`、`data/readonly/NewRunCopyBudgetData.gd`。可接續既有分支 `feature/newrun-redesign`。
- **Task A 截斷修法:** 對齊「copy budget」與實際容器,**長度上限驗證擴充既有** `tests/unit/test_new_run_copy_schema.gd`（不要新造平行系統）。
- **Task B 手牌:** 純佈陣為主 + 2–3 張號令符令,**不保留傳統 5 張手牌**（手牌留太多就還是 StS,違背換骨目的）。
- **Task B 得位:** 原型用**二元加成**(同屬性 +X%,數值在資料層);五行相生相剋**不做**。
- **Task B 分支:** `prototype/five-camp`,全部檔案放 `prototypes/five_camp/`,**完工不合主線**。

## 3. 端到端工作流（你自己一路跑完）

### Phase A — 新一局重排（主線分支）
1. 定位上述檔案;先跑一次現狀 `TestRunner` 確認基線綠。
2. 重排三區單向動線 **① 選將 →② 設定 →③ 開壇**:左側單一英雄面板(唯一真相來源,刪重複)、右上開壇設定卡(難度/模式/護壇/法器)、右下**獨佔 CTA**,種子收進「進階」。霓虹只給「選中光環+CTA」;鎖角色改「剪影+解鎖進度章」。全資料驅動。
3. 修文字截斷 + 加長度上限 validator(擴充 `test_new_run_copy_schema.gd`)。
4. 自驗(全綠才往下):`godot --headless --import` → `godot --headless res://tests/TestRunner.tscn` → `godot --path . res://qa/uiux/e2e_driver.tscn` → 三解析度 `UIUX_RES={1244x700,1515x700,1200x900} godot --path . res://qa/uiux/uiux_audit_driver.tscn` 全 `0 FAIL` → 三語不破版。
5. 過 R1999 八條自評(任一 < 4 自己回頭修)。
6. 一個邏輯一個中文 commit。

### Phase B — 五營手感原型（throwaway 分支）
1. 開 `prototype/five-camp`,內容放 `prototypes/five_camp/`。
2. 最小切片:3 營(中營+2)+ 佈陣/調營 + lane 煞推進 + 母壇 HP(取代元神)+ 擲筊三結果 + 二元得位。複用 `FortuneSticks`、`DeityInvocationSystem`、`RitualLoadout.resolve_deity_queue`。**不做** 敕封/緣分/完整五行/美術/平衡。
3. 寫原型自帶煙霧測試(放 `prototypes/five_camp/`)。
4. **切回主線跑 `TestRunner` 確認仍綠(零污染)**。
5. 真機 A/B(現行卡牌 vs 五營,各錄 30–60s),寫 `prototypes/five_camp/FEEL_REPORT.md`,含**去留建議**。
6. **停在這裡——不發 PR、不合主線、不自行把五營升為 v0.3 核心(那是憲龍決策)。**

## 4. 護欄（自主也絕不能碰）
三鐵律(資料驅動 / mobile-first 88×88 / fork-first)、名詞紅線(用 煞盾/破煞/敕封/五營/得位;禁 韌性/弱點擊破/升階/終結技)、變現紅線(只賣外觀,敕封/修廟只花香火)、向後相容(新欄位預設空/0,既有測試維持綠)、演出 ≤ 1.5s。

## 5. 自我驗證（取代我逐步簽核）
每個 Phase 結束**自己**跑 §3 的驗收指令;不綠就自己迭代到綠。完成 = 全綠 + R1999 八條皆 ≥ 4 + 交付物齊全。沒達標不算完成,繼續修。

## 6. 終點報告（只在這裡找我）
兩個 Phase 跑完,給我一份收尾:① 改/新增了哪些檔 ② 測試與三解析度結果 ③ 三解析度截圖 ④ R1999 八條分數 ⑤ Task B 去留建議 ⑥ 過程記進 `QUESTIONS.md` 的決策清單。

## 7. 現在開始
**不要回我問題、不要等我確認。** 直接從 Phase A 第 1 步開工,一路自主跑到 §6 終點報告。只有撞到 §0 硬停條件才暫停找我。

---
### 附錄:細節來源
`NEW_RUN_REDESIGN_PROMPT.md`(Task A 全清單)・`FIVE_CAMP_PROTOTYPE_PROMPT.md`(Task B 全清單)・`docs/design/formation_progression_v0.3.md`(五營/養成藍圖)

**END — CLAUDE_CODE_WORK_ORDER.md（自主版）**
