# Claude Code 自主工作令 — 設計忠實度落地：claude-design → Godot 完全套用（2026-06-19）

> **完全自主 ＋ 自我驗證 ＋ 嚴格 QA/E2E。** 目標：把「設計（HTML mockup / `CLAUDE_DESIGN_BRIEF.md`）完全被 code 套用」從口號變成**可截圖證明**的事實。自己決策、自己截圖、自己打分、自己修到綠，跑到底。只在 §0 硬停與 §9 終點報告找我。
>
> **先讀（缺一不可）：** `docs/design/DESIGN_TO_CODE_FIDELITY.md`（本任務的方法論與根因診斷，**這份工單是它的執行版**）、`CLAUDE_DESIGN_BRIEF.md`、`CLAUDE.md`、`DELEGATION.md`、`scripts/ui/theme/CotiwUiTheme.gd`、`docs/design/design_tokens.json`、`ui/theme/main_theme.tres`。**repo 現狀為準。**

---

## 0. 自主契約

**你可自行決定**（所有可逆的東西）：實作細節、節點/檔案結構、命名、phase 內排序、StyleBox 數值微調、token 命名、暫用資產。遇模糊 → 選**最可逆**選項 → 記一行 `QUESTIONS.md` → **繼續，不要停**。

**先開分支**：`git checkout -b design-fidelity`，每個 Phase 結束 commit（中文訊息 `[類別] 動詞 + 對象`）。全程不動 `main`。

**硬停條件（只有這幾種才停）：**
1. 不可逆/破壞性：刪既有測試或合約節點、破壞向後相容、改動變現/文化紅線。
2. 同一錯誤修 3 次仍紅且判斷無解。
3. 需求與 repo 現狀根本矛盾。
4. 視覺自驗迴圈（§6）跑滿 6 輪仍有畫面到不了門檻 → 停，交 before/after 截圖＋評分讓人做最終品味判斷（**辨識度最終需人＋玩家測，誠實承認，不要假裝自己能定義「夠紅」**）。
5. 素材生成連續失敗 → 回退程序化/既有資產 ＋ 記 `QUESTIONS.md`，**不要卡死**（美術非阻塞）。

---

## 1. 背景與為什麼（四個根因，全部已實測）

「code 產出完全不像」不是缺設計，是**沒有「像素必須服從單一 token 真相」的強制鏈**。已診斷（證據見 `DESIGN_TO_CODE_FIDELITY.md` §1）：

1. **預設主題烤死了被明令禁止的「暗紅疊暗紅」**：`ui/theme/main_theme.tres` 的 `panel_default`／`btn_normal` ＝ `Color(0.2000,0.0706,0.0627,0.5333)`（半透明暗楓紅）。硃砂紅 on 漆黑實算僅 **2.23:1**，違反 brief §3A「禁暗紅疊暗紅」。
2. **~711 處硬寫 `Color()`** 繞過 token（`.gd` 529 / `.tscn` 162 / `.tres` 20）。
3. **`design_tokens.json` 的值 ≠ 品牌色票**：brief 五色 `#8e2a1c/#e8c46a/#f0e4c8/#1a0f0d/#46c99a` 在 token 檔出現 **0 次**。
4. **三套色票打架** ＋ 像素字 vs serif ＋ 缺漸層/陰影/輝光的「貴」層。

**心智模型（重要）**：HTML mockup 是**規格**，不是可編譯來源。不要找 HTML→Godot 自動轉換。做法＝抽 token → Godot 原生重建 → 截圖比對驗收。

---

## 2. 我已替你定案的決策（直接用，不要問）

1. **「完全套用」的定義 ＝ token＋版面＋層次＋動態忠實 ＋ 截圖比對過尺。** **不追像素級 1:1**（跨引擎不可能，且 mockup 自身用 serif 近似、非聖經）。
2. **字體聲線**：內文維持 `Cubic 11` 像素字（守 Temple Neon Pixel 鐵律）；標題可用裝飾性字距/描邊強化，不為了像 mockup 全改 serif。質感靠 §3 Phase 3 的光影，不是換字。
3. **色票 SSOT ＝ `docs/design/design_tokens.json`**，核心五色校正為 brief 精確值（§3 Phase 0 給表）。`main_theme.tres` 的值改成**對齊 token**（最可逆：先改值，不急著廢靜態主題）。
4. **招牌時刻本輪至少做兩個**：破煞碎盾（`WardBreakFX`）＋ 上上籤金光（`offering_omen_glow`）。用既有 FX，≤1.5s 可跳過。
5. **重皮畫面優先序**：① 新一局（`NewRunMenu.gd`）② 神示供桌（`RunStartOptions.gd`）③ 五營戰（`FormationCombatView.gd`，最高難度）。本輪**至少完成 ①②**到過尺；③ 若時間不足，交結構修正＋記 `QUESTIONS.md`。
6. **mockup 比對基準**：把使用者提供的兩個 HTML（`docs/design/mockups/鎮島錄 視覺重生 v1.html`、`docs/design/mockups/鎮島錄 螢幕全套 (standalone).html`）在無頭瀏覽器開來截圖，當每屏的視覺規格。找不到檔就以 `CLAUDE_DESIGN_BRIEF.md` §3 文字規格為準，並記 `QUESTIONS.md`。

---

## 3. 端到端工作流（自己跑完 Phase 0→4）

### Phase 0 — 校正 SSOT（止血，畫面立刻不糊）
- 把 `design_tokens.json` 核心五色改為 brief 精確值：

  | token | HEX | Godot Color |
  |---|---|---|
  | `cinnabar`（硃砂紅） | `#8e2a1c` | `Color(0.5569,0.1647,0.1098)` |
  | `hot_gold`（燙金） | `#e8c46a` | `Color(0.9098,0.7686,0.4157)` |
  | `paper_cream`（宣紙米） | `#f0e4c8` | `Color(0.9412,0.8941,0.7843)` |
  | `lacquer_black`（漆黑） | `#1a0f0d` | `Color(0.1020,0.0588,0.0510)` |
  | `jade`（玉青/得位） | `#46c99a` | `Color(0.2745,0.7882,0.6039)` |

  既有 token（`festival_red` 等）保留為別名或漸進替換，**不要一次砍斷**既有引用；新增 brief 五色為正典，舊名指向新值。
- 改 `ui/theme/main_theme.tres`：`panel_default` 改**漆黑實底 `Color(0.1020,0.0588,0.0510,0.96)` ＋ 燙金細框**，取消 53% 半透明暗紅；按鈕 normal＝木褐實底＋金框、hover 提亮、pressed＝硃砂。所有暗底元件的文字/邊框改用燙金/宣紙米/玉青（見 §5 對比度硬規）。

### Phase 1 — 收斂硬寫色（消滅漂移）
- **寫一支稽核腳本** `tools/audit_color_sprawl.py`（或 .gd）：掃 `.gd/.tscn/.tres` 的 `Color(` 與 `#hex`，輸出「高頻硬寫色 → 最接近的 token」對照，存 `qa_artifacts/color_sprawl_report.txt`。
- 先收編**高頻、且出現在 HUD/panel/button** 的硬寫色進 `CotiwUiTheme.get_color()`。**不必一次清 711 處**——先清三畫面用到的，其餘記基線數字，禁止淨增。

### Phase 2 — 逐元件重建三畫面（照 mockup 版面/層次）
- 對①②（必要時③）：modal 全遮（背後 lobby 不透出、清鬼影方塊）、英雄焦點（角色立繪/籤＋燙金描邊＋選中金光環）、鎖定態（剪影＋解鎖進度章）、修溢出/截斷（走 `RitualCopyBudget`）、隱藏與該畫面決策無關的戰鬥 HUD 與空貨幣。
- 神示供桌：把真籤詩搬上（`external/data/fortune_sticks/` 的 `stick_name/verse/grade`）、籤運視覺階梯（上上/上吉/中平/中下/下下 各一套色＋飾＋光，上上燙金綻放）。

### Phase 3 — 補「貴」層（HD-2D，brief 的辨識度本錢）
- 漸層→`GradientTexture2D`/`StyleBoxTexture`；霓虹焦點→自發光 shader＋（若有）`WorldEnvironment` glow；香煙/燭火/金光→粒子；暗角 vignette 壓底。**霓虹稀缺**，只給英雄焦點與招牌時刻。
- 招牌時刻：破煞碎盾、上上籤金光至少各一處接好（≤1.5s 可跳過）。

### Phase 4 — 招牌母題與一致性
- 每屏至少 2 個招牌母題在場（符/籤/筊/燈籠/五營羅盤/八卦/廟埕剪影）。三畫面並排檢查「一眼同一款」（同色票、同 chrome、同母題語言）。

---

## 4. 護欄（自主也不能碰）
- **三鐵律**：資料驅動（卡/神/路線/文字走 JSON/CSV，不硬編）、mobile-first（橫向 1200×700、最小點擊 88×88、不依賴 hover）、fork-first（新增 > 改 framework 核心）。
- **名詞紅線**：用 煞盾/破煞/合符/敕符/降乩/擲筊/五營/籤運；**禁** 韌性/弱點擊破/升階/終結技、**禁英文外洩**（尤其 "Boss"）。
- **變現紅線**：只賣外觀/角色解鎖，不碰戰力/香火/抽卡。
- **演出** ≤ 1.5s 或可跳過；placeholder 必須明顯醜。
- **向後相容**：既有 167+ 測試全程維持綠；不得刪 `test_p0_ui_ux_contract`/`test_p1_core_flow_contract` 的合約節點；新欄位預設空。

---

## 5. 嚴格 QA — 客觀關卡（每 Phase 結束跑，不綠自己修到綠）

```bash
godot --headless --import                                   # 新增資源後
godot --headless res://tests/TestRunner.tscn                # 全套測試，exit 0 = 綠（維持 167+ 綠）
godot --path . res://qa/uiux/e2e_driver.tscn                # E2E
UIUX_RES=1244x700 godot --path . res://qa/uiux/uiux_audit_driver.tscn   # ×3 解析度
UIUX_RES=1515x700 godot --path . res://qa/uiux/uiux_audit_driver.tscn
UIUX_RES=1200x900 godot --path . res://qa/uiux/uiux_audit_driver.tscn
```

**新增/擴充的硬性 QA（本任務專屬，要寫成可重跑的測試/腳本）：**
1. **暗紅疊暗紅掃描**：寫 `tests/unit/test_no_dark_red_on_dark.gd` 或在 `tools/audit_color_sprawl.py` 內——任何「暗底元件的前景文字/邊框」對比度 < 4.5:1 即 FAIL。
2. **對比度矩陣**：用 WCAG 公式重算品牌色矩陣，確認燙金/宣紙米/玉青 on 漆黑皆 ≥ 4.5:1；硃砂 on 漆黑（2.23:1）不得用於文字/細邊。
3. **token 服從度**：硬寫 `Color()` 計數**不得淨增**（對照 Phase 1 基線 711）；三畫面新碼零硬寫色。
4. **i18n 無英文殘留**：擴 `tests/unit/test_i18n_zero_residue.gd`，抓 "Boss" 等外洩。
5. **三解析度 0 FAIL**、**88×88**、**copy budget 無截斷/溢出**。

通過門檻：全測試 exit 0、三解析度 0 FAIL、上述五項全綠。

---

## 6. 嚴格 E2E — 視覺自驗迴圈（本任務核心，反覆做到夠好）

你能讀圖。**每輪**照下面跑：

1. **截圖**：跑探針抓三畫面 ×三解析度 → `qa/uiux/rso_probe.gd`（供桌）、`qa/uiux/fivecamp_shot.gd`（五營）、`qa/uiux/map_probe.gd`、`uiux_audit_driver.tscn`；存 `qa_artifacts/`。
2. **比對基準**：把對應 HTML mockup 畫面截圖並排（§2.6）。
3. **自評**：打開每張 PNG，用 **10 條尺**各打 1–5 分（商業二次元門檻 = **每條 ≥4**）：
   ① 焦點清晰 ② 層次分明 ③ 對比可讀（**無暗紅疊暗紅、字夠跳**）④ 乾淨（無溢出/截斷/modal 透背景/鬼影）⑤ 狀態與稀有有視覺差（上上籤/得位/來煞/告急一眼分）⑥ 色彩和諧（守 §3 brief 色票）⑦ 文化辨識度（≥2 招牌母題）⑧ 一拍爽（招牌時刻有演出）⑨ 新手 5 秒可解 ⑩ 觸控與安全區（88×88、不貼邊）。
4. **迭代**：任一條 <4 → 修 → 回步驟 1。**連續兩輪三畫面全條 ≥4** 才算過；最多 **6 輪**。
5. **辨識度檢核**：三畫面並排「一眼同一款？」不一致就統一。

> 誠實邊界：「市面辨識度」最終需人＋玩家測拍板。迴圈把它推到「可證明地一致且過尺」，再交人做品味終判。

---

## 7. 關鍵檔案地圖
- **token / 主題**：`docs/design/design_tokens.json`、`ui/theme/main_theme.tres`、`scripts/ui/theme/CotiwUiTheme.gd`、`project.godot`（`theme/custom`、`theme/custom_font`）。
- **三畫面**：`scripts/ui/menus/NewRunMenu.gd`（新一局）、`scripts/ui/RunStartOptions.gd`（神示供桌）、`scripts/ui/FormationCombatView.gd`（五營戰）。
- **資料**：`external/data/fortune_sticks/*.json` ＋ `FortuneSticks.gd`、`external/data/run_start_options/*.json`、`assets/translations/cotiw_main.csv`。
- **FX**：`WardBreakFX`、`DeityCutInFX`、`AwakenCutInFX`、`JiaoBeiFX`、`offering_omen_glow`。
- **探針/測試**：`qa/uiux/{rso_probe,fivecamp_shot,map_probe}.gd`、`qa/uiux/uiux_audit_driver.tscn`、`tests/TestRunner.tscn`、`tests/unit/{test_p0_ui_ux_contract,test_p1_core_flow_contract,test_i18n_zero_residue}.gd`。
- **規格**：`CLAUDE_DESIGN_BRIEF.md`、`docs/design/DESIGN_TO_CODE_FIDELITY.md`、`docs/design/ORACLE_ASSET_PROMPTS.md`、使用者的兩個 HTML mockup。

---

## 8. 素材
依 `docs/design/ORACLE_ASSET_PROMPTS.md` 生成；同 brief 色票與像素動漫風。素材**非阻塞**：連續失敗回退程序化/既有資產 ＋ 記 `QUESTIONS.md`。

---

## 9. 終點報告（只在這裡找我）
跑完給我：① 三畫面 **before/after 截圖牆**（×三解析度，並附 mockup 並排）② 每畫面 **10 條尺評分表**（逐輪變化）③ 客觀關卡結果（測試 exit code、三解析度 FAIL 數、對比度矩陣、硬寫色基線 vs 現值）④ 改/新增檔清單 ＋ 分支名 ⑤ design_tokens 校正前後對照 ⑥ 招牌時刻接了哪些 ⑦ 五營去留說明 ⑧ 記進 `QUESTIONS.md` 的決策 ⑨ 你判斷「還差什麼才到市面辨識度」的誠實清單。

## 10. 現在開始
**先 `git checkout -b design-fidelity`，讀 §先讀清單，過 §5 客觀關卡建立基線 → Phase 0 開工 → 進 §6 視覺迴圈跑到門檻 → 出 §9 報告。不要回我問題、不要等確認；只有撞到 §0 硬停才暫停。**

**END — DESIGN_FIDELITY_WORK_ORDER.md（自主 ＋ 自驗 ＋ 嚴格 QA/E2E 版）**
