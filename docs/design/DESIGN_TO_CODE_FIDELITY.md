# 設計如何「完全被 code 套用」— claude-design → Godot 落地方法論 ＋ COTIW 落差診斷

> 對象：為什麼「我有一張設計好的 HTML，但 code 產出的成品完全不像」。
> 結論先講：**HTML mockup 不是可編譯的原始碼，是高保真「規格」。** 跨引擎無法「套用」，只能「依規格在 Godot 原生重建 ＋ 截圖比對驗證」。下面是可重複的管線，加上 COTIW 此刻落差的根因（全部有證據）。
> 產出者：外部美學稽核（美學大師＋專案管理）｜2026-06-19

---

## 0. TL;DR

1. **心智模型要先改**：mockup 是「效果圖」，Godot 是「用不同建材實際蓋」。你不會把效果圖 JPG 貼到工地——你會把它讀成**尺寸／材質／顏色清單（token）**，用真材料蓋，最後拿照片跟效果圖**並排比對**。沒有可靠的 HTML→Godot 自動轉換器；硬轉只會更不像。
2. **「完全一樣」是錯的目標**。連你的 mockup 自己都不是像素忠實的（瀏覽器用 `Noto Serif/楷` 近似，而遊戲鐵律是 `Cubic 11` 像素字）。對的目標是：**token／版面／層次／動態忠實，且截圖比對過尺**。
3. **COTIW 看起來「完全不像」有四個結構性根因**（全部實測）：
   - 預設主題 `main_theme.tres` 把**被明令禁止的「暗紅疊暗紅」烤死成預設**。
   - **~711 處硬寫 `Color()`** 繞過 token 系統。
   - `design_tokens.json` 存在，但**值不等於品牌色票**（brief 的 5 個精確色出現 0 次）。
   - **三套色票互相打架** ＋ 像素字 vs serif ＋ 缺漸層／陰影／輝光的「貴」層。

---

## 1. 根因診斷（為什麼 code 產出完全不像）

| # | 症狀 | 證據（本 repo 實測） | 後果 |
|---|------|------|------|
| 1 | **暗紅疊暗紅**（brief §3A 明令禁止） | `ui/theme/main_theme.tres` 的 `panel_default` 與 `btn_normal` 都是 `bg_color = Color(0.2000,0.0706,0.0627,0.5333)`＝半透明暗楓紅，疊在暗底上。硃砂紅 on 漆黑實算只有 **2.23:1**（連大字 AA 3:1 都不過）。 | 整個介面糊成一片暗紅，沒有焦點、沒有層次——這正是 brief §1 說的「賣相未到」。 |
| 2 | **token 被大規模繞過** | `Color(` 在 `.gd` 出現 **529** 次、`.tscn` **162** 次、`.tres` **20** 次 ≈ **711 處硬寫色**。`CotiwUiTheme` 只被 33 檔引用；`main_theme.tres` 以名稱被引用 **0** 次（它靠 `project.godot` 當預設默默生效）。 | 改色票改不動畫面；每個硬寫點都會各自漂移，永遠不一致。 |
| 3 | **token 檔不等於品牌色票** | `docs/design/design_tokens.json` 存在，但 brief 的 5 個精確值 `#8e2a1c / #e8c46a / #f0e4c8 / #1a0f0d / #46c99a` **各出現 0 次**。檔內是另一套：`festival_red #D94A2B`、`temple_red #A62F1F`、`spirit_jade #4FA56D`… | 即使有走 token 的地方，得到的也**不是 mockup 那個顏色**。 |
| 4 | **三套色票打架** | (a) brief／HTML mockup 一套；(b) `design_tokens.json` 一套；(c) `main_theme.tres` 生的 `Color()` 浮點又一套。三者互不相等，無人為準。 | 同一個「金」在三個地方是三個值；畫面永遠拼湊感。 |
| 5 | **字體聲線不同** | 遊戲 `default_font = Cubic_11.ttf`（像素字）；HTML mockup 用 `Noto Serif / 楷`（grep：Noto 780×、Kai 82×、serif 37×）。 | 同樣的字，一個像素一個書卷，氣質完全不同。**注意**：mockup 的 serif 是瀏覽器近似，非聖經。 |
| 6 | **缺「貴」層** | mockup JS 用 `linear-gradient ×46`、`radial-gradient ×7`、`box-shadow ×33`、圓角 ×21、輝光。Godot `StyleBoxFlat` **無漸層**、陰影能力有限、無 backdrop blur。 | mockup 立體有光，Godot 平。brief §2.7 要的「HD-2D 高級像素」沒做出來。 |

> 關鍵領悟：**問題不是缺設計文件。** `docs/design/` 已經有 `FIGMA_DESIGN_SYSTEM_V1`、`FIGMA_MAKE_UI_ADOPTION`、`UI_COMPONENT_RULES`、`COMPONENTS`、`wireframes/`… 一堆。問題是**沒有任何一層強制「像素必須服從 token」**。解法是 enforcement／SSOT，不是再寫一份文件。

---

## 2. 心智模型：mockup 是「規格」，不是「來源」（費曼版）

**為什麼不能直接把 HTML 套到 Godot？** 因為兩邊是不同的算繪引擎，能力不對等：

| | HTML/React mockup | Godot UI |
|---|---|---|
| 排版 | DOM ＋ CSS flexbox/grid（瀏覽器自動算） | `Control` ＋ `Container` 節點樹（手搭） |
| 上色 | CSS / inline style / 漸層 | `Theme` ＋ `StyleBox` ＋ shader |
| 字體 | 任何 web font，serif 隨手可得 | `FontFile` 資源，CJK 像素字得自己備 |
| 效果 | box-shadow / blur / gradient 內建 | StyleBoxFlat 子集；其餘要貼圖或 shader |

把效果圖 JPG 丟給工地不會蓋出房子。**正解管線**：規格 →（抽）token →（在 Godot）原生重建 →（拿）截圖跟規格並排比對 → 迭代。下一節就是這條管線。

---

## 3. 「完全被 code 套用」的五步管線（可重複）

```
[brief / HTML mockup]
        │  Step 1：抽 token（單一真相）
        ▼
[design_tokens.json]  ← 唯一色票/字級/間距/圓角/陰影/母題/動態 來源
        │  Step 2：Theme 集中化（消滅硬寫）
        ▼
[Godot Theme + CotiwUiTheme]  ← 唯一上色/字體/間距入口
        │  Step 3：CSS→Godot 能力對照（gradient/shadow/glow…）
        │  Step 4：逐元件原生重建（Container + themed Control + 母題貼圖）
        ▼
[實際畫面] ──Step 5：截圖 × 三解析度──▶ 與 mockup 並排 ▶ 照尺打分 ▶ 不到門檻就回 Step 4
```

- **Step 1 抽 token**：把 brief/HTML 的每個決策抽成機器可讀的值（色、字級階、間距階、圓角、陰影規格、母題清單、動態 timing）。COTIW 已有 `design_tokens.json`——**但要校正成 brief 精確值**（見 §5）。
- **Step 2 Theme 集中化**：Godot `Theme` ＋ `CotiwUiTheme.get_color()` 成為**唯一**入口。把 711 處硬寫 `Color()` 逐步收編；廢掉 `main_theme.tres` 那套流氓暗紅預設。**鐵律：Scene 不准自己猜顏色。**（你的 `CotiwUiTheme` 註解其實已寫了這句話，只是沒被遵守。）
- **Step 3 能力對照**：見 §4——CSS 的每個效果都要先決定它在 Godot 怎麼實現，否則一定掉漆。
- **Step 4 逐元件重建**：照 mockup 的版面與層次，用 `HBox/VBox/Grid/MarginContainer` ＋ themed `Control` 重搭，母題（符/籤/筊/燈籠/羅盤）用 SVG/貼圖。
- **Step 5 截圖比對閘門**：跑 probe 截 3 解析度 → 與 mockup 並排 → 照 brief §4 四尺 ＋ POLISH 工單 10 條尺打分（每條 ≥4）→ 迭代。**你已經有這個 loop**（`qa/uiux/{rso_probe,fivecamp_shot,map_probe}.gd`、`uiux_audit_driver.tscn`）——這是你最該倚重的資產。

---

## 4. CSS → Godot 能力對照表（落地關鍵）

| mockup 的 CSS | Godot 對應 | 備註 / 陷阱 |
|---|---|---|
| `background: #hex` | `StyleBoxFlat.bg_color` | 直接對應；走 token。 |
| `border-radius` | `StyleBoxFlat.corner_radius_*` | 直接對應。 |
| `border: Npx solid` | `StyleBoxFlat.border_width_* / border_color` | 直接對應。 |
| `linear/radial-gradient` | **`GradientTexture2D` ＋ `StyleBoxTexture`**，或 `ColorRect`＋shader | ⚠️ `StyleBoxFlat` **不支援漸層**。要嘛烤成貼圖，要嘛 shader。這是「平 vs 立體」的分水嶺。 |
| `box-shadow`（外陰影） | `StyleBoxFlat.shadow_color / shadow_size / shadow_offset` | 只能外陰影、無 spread/inset/blur 半徑控制；要 CSS 級柔陰影得烤 9-slice 貼圖。 |
| `box-shadow: inset` / 內發光 | 9-slice `StyleBoxTexture` 或 shader | StyleBoxFlat 做不到。 |
| `backdrop-filter: blur` | backbuffer 取樣 shader（`hint_screen_texture`） | 中等工程量；非戰鬥畫面慎用（效能）。 |
| `text-shadow` | `Label`/`Button` 的 `font_shadow_color`/`shadow_offset` theme 屬性 | 對應 OK。 |
| `letter-spacing` | `LabelSettings` / 字體 `extra_spacing` | 對應 OK。 |
| 霓虹輝光 glow | `WorldEnvironment` Glow（HDR）＋ `CanvasItem` 自發光 shader / `Light2D` | brief 的「霓虹稀缺」就靠這層；**這是讓像素看起來「貴」的關鍵**，不是改色票能得到的。 |
| 粒子（香煙/燭火/金光） | `GPUParticles2D` / `CPUParticles2D` | brief「一拍爽」的料；你已有 `WardBreakFX/DeityCutInFX/JiaoBeiFX`，要用滿。 |
| flex/grid 自動排版 | `HBox/VBox/GridContainer` ＋ `size_flags` | 概念可對映，但要手搭；mockup 的絕對定位不要照抄。 |
| web font（serif/楷） | `FontFile` 資源 | 見 §7 字體決策；像素 vs serif 是聲線抉擇。 |

---

## 5. 校正後的色票（Godot 值，立即可用）

把 `design_tokens.json` 的核心五色**校正為 brief 精確值**，並換算成 Godot `Color()`（4 位小數，可直接貼進 `.tres` / `.gd`）：

| 名稱 | brief HEX | Godot Color | 現況 token（不符，待改） |
|------|-----------|-------------|------------------|
| 硃砂紅 cinnabar | `#8e2a1c` | `Color(0.5569, 0.1647, 0.1098)` | festival_red `#D94A2B`／temple_red `#A62F1F`（偏亮偏橘） |
| 燙金 hot_gold | `#e8c46a` | `Color(0.9098, 0.7686, 0.4157)` | incense_gold `#E8C56A`（基本相符 ✅） |
| 宣紙米 paper_cream | `#f0e4c8` | `Color(0.9412, 0.8941, 0.7843)` | paper_warm `#F5E7CF`（接近，仍不同） |
| 漆黑 lacquer_black | `#1a0f0d` | `Color(0.1020, 0.0588, 0.0510)` | lacquer_black `#1B0F0D`（基本相符 ✅） |
| 玉青 jade（吉/得位） | `#46c99a` | `Color(0.2745, 0.7882, 0.6039)` | spirit_jade `#4FA56D`（偏暗偏綠，差最多） |

### 高對比規則（取代「暗紅疊暗紅」，對比度已實算 WCAG）

| 前景 on 背景 | 對比度 | 判定 |
|---|---:|---|
| 燙金 on 漆黑 | **11.21:1** | ✅ 正文 AA |
| 宣紙米 on 漆黑 | **14.88:1** | ✅ 正文 AA |
| 玉青 on 漆黑 | **9.02:1** | ✅ 正文 AA |
| 宣紙米 on 硃砂紅 | **6.66:1** | ✅ 正文 AA |
| 燙金 on 硃砂紅 | **5.02:1** | ✅ 正文 AA |
| **硃砂紅 on 漆黑** | **2.23:1** | ❌ 低對比——硃砂只能當**色塊/帶**，不能當漆黑上的文字/邊框 |

> **規則一句話**：大面積漆黑底，**文字與邊框一律用燙金／宣紙米／玉青**（皆 ≥9:1）；硃砂紅只做標題帶或色塊，永不拿來在暗底上寫字。這就是 brief「禁暗紅疊暗紅」的可執行版本。

---

## 6. COTIW 修復路線（分階段，對齊既有自驗 loop）

**P0 — 止血（改 3 個檔，畫面立刻不糊）**
1. 校正 `design_tokens.json` 核心五色為 §5 brief 值。
2. 改 `ui/theme/main_theme.tres`：`panel_default` 改為**漆黑實底 `Color(0.1020,0.0588,0.0510,0.96)` ＋ 燙金細框**，取消 53% 半透明暗紅；按鈕同理（normal 用木褐實底＋金框，hover 提亮，pressed 用硃砂）。
3. 決定 `default_font`（見 §7）。

**P1 — 收斂 SSOT（消滅漂移）**
4. 寫一支稽核腳本：掃描 `.gd/.tscn/.tres` 的硬寫 `Color()`，列出高頻值 → 收編進 token（先 HUD/panel/button 三類）。
5. **二選一定 SSOT**：讓 `main_theme.tres` 的值改由 `design_tokens.json` 生成（建置步驟），或乾脆讓所有 Control 走 `CotiwUiTheme` 而廢掉靜態 `.tres` 預設。**不能再兩套並存。**

**P2 — 補「貴」層（HD-2D）**
6. 漸層→`GradientTexture2D`；霓虹焦點→自發光 shader ＋ `WorldEnvironment` glow；香煙/燭火/金光→粒子；暗角→全屏 vignette。霓虹**稀缺**，只給英雄焦點與招牌時刻。

**P3 — 逐屏對齊 mockup ＋ 截圖比對**
7. 三畫面（新一局／神示供桌／五營戰）各跑 probe 截 3 解析度，與 HTML 對應畫面**並排**，照 §8 尺打分，迭代到過關。

**P4 — 字體與動態（聲線與手感）**
8. 字體決策落地（§7）；`WardBreakFX/DeityCutInFX/JiaoBeiFX` 在破煞/降乩/聖筊/上上籤/母壇告急**用滿**（≤1.5s 可跳過）。

---

## 7. 三個你必須拍板的決策（誠實邊界，AI 不該替你定品味）

1. **字體聲線**：保留 `Cubic 11` 像素字（符合「Temple Neon Pixel」鐵律），還是改 serif/楷（像 mockup）？
   - 建議：**內文像素為主**（守鐵律與辨識度），**標題可混排裝飾性字**；靠 HD-2D 光影撐質感，而非換字。**mockup 的 serif 是瀏覽器近似，不是規格的一部分。**
2. **「完全一樣」的定義**：像素級 1:1（跨引擎不可能、且會犧牲你的像素藝術定位），還是 **token＋層次＋動態忠實**（可達、可截圖證明）？
   - 建議：明確選後者，寫進驗收標準，省得追一個不存在的目標。
3. **動態/輝光投資**：brief 的「貴」與「一拍爽」靠 shader/particle 工，不是改色票就有。要不要把 P2 排進這一輪？
   - 建議：至少做**破煞碎盾 ＋ 上上籤金光**兩個招牌時刻，CP 值最高。

---

## 8. 驗收：怎樣算「設計成功被 code 套用」

- [ ] `design_tokens.json` 核心五色＝brief 精確值；新加色都登記在此檔（零畫面外硬寫新色）。
- [ ] **零「暗紅疊暗紅」**：自動掃 `main_theme.tres` ＋ 高頻 `Color()`，暗底元件文字/邊框對比度 ≥ 4.5:1。
- [ ] 三畫面 vs HTML mockup **並排截圖**，brief §4 四尺 ＋ POLISH 10 條尺**每條 ≥4**。
- [ ] 對比度矩陣全過 WCAG AA。
- [ ] 三解析度（1244×700 / 1515×700 / 1200×900）`uiux_audit_driver` **0 FAIL**。
- [ ] 167+ 既有測試維持綠（向後相容）。

---

## 9. 一句話總結

> 你缺的不是設計，是**一條「像素必須服從單一 token 真相」的強制鏈**，加上**把 CSS 效果翻成 Godot 原生機制**的對照表，最後用**截圖比對**證明它真的像。HTML 是規格，Godot 來蓋，照片來驗收——這三件事做齊，「完全被 code 套用」才成立。

*外部美學稽核（美學大師＋專案管理）｜2026-06-19*
