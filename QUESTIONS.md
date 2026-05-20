
# 鎮島錄 — 待決策問題清單

> 本檔案累積 Claude Code 在開發過程中需要憲龍決策的問題。
> 每週末 / 每 Sprint 結束彙整一次，不要逐題打斷。

---

## 2026-05-16 Sprint 0 起手問題清單 — 已回覆 ✅

### Q1: Godot 版本選擇（4.4 vs 4.6.1）

**情境**：

- CLAUDE.md / PRD 指定 Godot 4.4 stable。
- 本機已安裝 4.6.1.stable.official，STR 也聲明需 4.4。
- 我已用 4.6.1 載入 STR 並 headless 跑 100 幀，無錯誤。

**選項 A**：留 4.6.1（已驗證可跑）

- 優：少裝一份 Godot，4.6 內含更多 mobile 渲染優化。
- 缺：未知後續是否會踩 4.4 → 4.6 不相容（特別是 GDScript 細節）。

**選項 B**：另裝 4.4 stable 並切回

- 優：完全符合 STR/PRD 指定版本。
- 缺：手動切版本、CI/CD 也要鎖 4.4。

**我的建議**：A。Godot 4 系列強調向後相容，4.6 已是穩定且能跑 STR；若日後 sprint 真的踩到問題再切回 4.4。把版本鎖在 CI 設定即可。

**🟢 憲龍回覆 2026-05-16**：✅ A（採納建議）

### Q2: 直向 mobile UI 切換時機（Sprint 0 vs Sprint 2）

**情境**：

- 鐵律 2 要求 mobile-first；但 STR 原生是 1200×700 橫向。
- Sprint 1 還要做主題替換（乩童 / 山豬精）；如果先切直向，STR 既有 UI 會立刻錯位，無法驗證資料替換是否正確。

**選項 A**：保留橫向直到 Sprint 2 才切換

- 優：Sprint 1 可在 STR 原生 UI 上驗證資料替換有效。
- 缺：違反 mobile-first 心智、Sprint 1 真機驗收會發現一堆 UI 問題。

**選項 B**：Sprint 0 馬上切直向

- 優：強迫早期面對 mobile UI 問題。
- 缺：STR 既有 UI 全錯位，Sprint 1 主題替換無從驗收，可能要連帶重寫 UI。

**我的建議**：A。先用橫向驗證資料管線通暢，Sprint 2 再做完整直向重設計。Sprint 1 真機測試用「橫向應急版」即可。

**🟢 憲龍回覆 2026-05-16**：✅ A（採納建議）

### Q3: GitHub Private Repo 建立

**情境**：

- CLAUDE.md 指示 fork STR → push 到 GitHub private repo。
- 本機 gh CLI 登入帳號為 `MusesCraft`，另一個帳號 `rush8787` 的 token 失效。
- 目前已 rename `origin` → `upstream`（指向 STR 原 repo），尚未推送。

**問**：

1. 用哪個 GH 帳號？`MusesCraft` 還是另開？
2. Repo 名稱：`cotiw`、`COTIW`、或別的？
3. 是否現在就建立並推送？我需要明確的「請建立」指令才會動作。

**🟢 憲龍回覆 2026-05-16**：

- 帳號：`kiresakura`
- Repo 名稱：`Chronicles of the Island Ward`
- 推送：**等憲龍提供 token 後再執行**

**Action Item**：等 kiresakura token → `gh auth login -u kiresakura` → `gh repo create kiresakura/Chronicles-of-the-Island-Ward --private --source . --remote origin --push`

### Q4: 素材調查文件位置

**情境**：CLAUDE.md / README.md 引用 `../鎮島錄 - 開源倉庫與台灣文化素材調查.md`，但 `/Users/crimson/Developer/` 與 COTIW 同層找不到。

**問**：檔案在哪？或是 Notion / Google Docs 連結？

**🟢 憲龍回覆 2026-05-16**：移除引用

**Action Item**：移除 README.md、CLAUDE.md 對該檔案的所有引用。

### Q5: 卡牌/敵人術語對應 — STR vs PRD

**情境**：

- PRD 用「遺物」、「邪氣」、「神力」等台灣文化詞。
- STR 框架用 `artifact`、`status_effect`、`energy` 等英文 code-level 命名。

**決策（暫定，請確認）**：

- **程式碼層**：沿用 STR 命名（artifact, status_effect, energy, etc.）—— 不改框架。
- **資料層**：JSON 內 name/description 用 i18n key 引用。
- **UI 顯示**：用 i18n 翻譯為「遺物 / 邪氣 / 神力」。

**理由**：改框架 = 失去追 upstream 能力（違反鐵律 3）。

**🟢 憲龍回覆 2026-05-16**：✅ 確認

### Q6: i18n 機制 — STR Keyword 系統 vs Godot TranslationServer

**情境**：

- PRD 7.6 指定使用 Godot 內建 `TranslationServer` + CSV。
- STR 已有 `KeywordData` 系統處理戰鬥詞彙（例：邪氣、神威）。

**選項 A**：兩者並用 — TranslationServer 處理介面 UI、KeywordData 處理戰鬥詞彙。
**選項 B**：只用 TranslationServer，把 keyword 也走 i18n key。
**選項 C**：只用 STR 的 keyword system。

**我的建議**：A。Sprint 1 先試 KeywordData 處理戰鬥詞彙，Sprint 2 加 TranslationServer 處理 UI。Sprint 3 評估是否合併。

**🟢 憲龍回覆 2026-05-16**：✅ A（採納建議）

### Q7: 真機測試與 Apple Developer Account

**情境**：

- Sprint 0 驗收條件之一是 iPhone 真機跑 STR 原版。
- Apple Developer Account 每年 US$99；尚未確認憲龍是否已有。
- Android 真機免費，需 Android Studio + USB debug。

**問**：

1. 是否已有 Apple Developer Account？
2. 沒有的話，可先用 iOS Simulator + Android 真機（其中一個是真機就符合 PRD 鐵律「真機」精神）？

**🟢 憲龍回覆 2026-05-16**：✅ 有 Apple Developer Account

**Action Item**：

- 後續 iOS 真機 deploy 需確認 bundle id 與 provisioning profile。
- 等 Sprint 1 結束前先試一次 iOS Simulator export 驗證 pipeline。

### Q8: macOS 開發環境 — Xcode 26.5 與 Godot iOS export

**情境**：本機已裝 Xcode 26.5（最新版）。Godot 4.6 iOS export 對 Xcode 26 的支援尚未廣泛驗證。

**我的建議**：先試打包 iOS Simulator 版（.zip）驗證 export pipeline 通；若失敗再評估降版 Xcode。Sprint 0 結束前產出第一份 iOS Simulator 可運行成品。

**🟢 憲龍回覆 2026-05-16**：✅ 採納建議

---

## 2026-05-19 重大決策記錄

### D1: 螢幕方向最終定案 —— 橫向（Landscape）

**背景**：
- 早期 PRD / 鐵律 2 假設直向 1080×2340；Q2（2026-05-16）僅決定「Sprint 2 才切方向」，未定最終方向。
- 實際開發 V4 起即切回橫向 R1999 lobby 風；主畫面、向量背景、設計 token 已大量以橫向實裝。
- design_tokens.json 早期仍寫 portrait、PRD/CLAUDE/AGENTS 仍寫直向，與實裝不一致。

**🟢 憲龍決策 2026-05-19**：**最終定案＝橫向（Landscape）**。

- 基準解析度＝ `project.godot` 1200×700（canvas_items stretch / keep aspect）
- mobile-first 與觸控優先精神**不變**，僅版面方向定為橫向
- 早期所有「直向 / portrait / 1080×2340」字樣作廢

**已執行的全面統整（2026-05-19）**：
- `PRD.md`：§2 鐵律、§5.1 螢幕方向、§5.3、§7.2、§7.7、§10 改橫向
- `CLAUDE.md` / `AGENTS.md`：鐵律 2、Sprint 2、決策表改橫向；§10 測試指令修正為場景模式
- `README.md`、`docs/design/*`（art direction banner、AIDA handoff、design_tokens.json）全部對齊橫向
- ✅ **已結清（commit e5468a4）**：`MainMenu.gd` 統一改走 `CotiwUiTheme`——CotiwUiTheme 新增公用 `make_stylebox()` 為全專案唯一 StyleBox 入口；MainMenu 金色改由 design_tokens 提供、`_sb()` 委派、起駕用 `apply_primary_button_style`。一致性缺口消除。

### D2: 螢幕自適應架構（全機型 / 含 iPad）

**憲龍決策 2026-05-19**：(1) 範圍＝全部畫面含 iPad/平板；(2) stretch `keep`→**`expand`**（填滿無黑邊）；(3) **全套安全區內縮**（瀏海/動態島/home indicator）。

**架構**：
- `project.godot`：`window/stretch/aspect` = `expand`；新增 autoload `Responsive`。
- `autoload/Responsive.gd`：全專案唯一可用區真相來源 —— `safe_rect`（裝置安全區換算成邏輯座標）、`screen_rect`（全出血用）、`screen_class`（phone/tablet，橫向 AR<1.6 視為平板）、`changed` 信號（resize/旋轉重算）；桌機/編輯器 fallback = 全螢幕。
- `scripts/ui/SafeFit.gd`：把固定 1200×700 版面等比置中塞進安全區（鐵律 3 友善，不動 STR scene 內部）。

**Phase 1（✅ 完成，commit a67864c / pushed）**：MainMenu 完整自適應重構（座標全由 `Responsive.safe_rect` 計算、背景全出血、phone/tablet 間距微調）；TitleScreen + Background 撐滿 viewport；NewRunMenu / CodexMenu 套 SafeFit。

**Phase 2（✅ 完成，待 commit）**：`RunScreen.gd` 對 self 做 `SafeFit.bind`（單一祖先等比置中進安全區，**一次涵蓋** Combat / Map / 9 個 overlay / RunStartOptions —— 祖先縮放與 overlay 自身 scale 動畫相容，**零 .tscn 改動、不碰任何 STR scene 內部**，鐵律 3 友善）；程式化於 Root 加全螢幕深色底襯（置 RunScreen 下層、隨 run 顯隱，避免 expand 露白；add_child 須 call_deferred 因 Root 於 _ready 仍在建構）。iPad＝安全區內等比置中 + 深色底襯（STR 戰鬥不逐一重排，屬可接受範圍）。

驗證（Phase 1+2）：import 乾淨、測試 21/21、Root.tscn headless 於 1200×700 / 2532×1170(Pro Max 2.16) / 1334×750(SE) / 1180×820(iPad 平板級) 皆無 script error。⚠️ headless 無法 render 且 DisplayServer 安全區僅真機生效；實際視覺/安全區內縮/戰鬥中版面需真機或模擬器目視確認。

**真機回饋修正（iPhone 12，2026-05-19）**：
- 兩側黑邊根因＝ iOS 相容模式 letterbox（export_presets `storyboard/use_launch_screen_storyboard=false`），**非 Godot stretch**。修：啟用 launch storyboard + 同 boot_splash 圖/紅底（詳 `docs/IOS_EXPORT_SETUP.md` 第 7 障礙）。⚠️ export 設定，須**重 export+重 build+重新部署真機**才生效。
- 載入不連貫＝ SplashScreen 進度條/文字為固定 1200 座標、受 letterbox 跑位。修：`SplashScreen.gd` 改用 `Responsive.safe_rect` 定位 + 進度組淡入承接 boot_splash + BgFill 改廟會紅（三段同圖同底連貫）。
- 已重 export 並 xcodebuild **BUILD SUCCEEDED**、Launch Screen.storyboard 為真全螢幕 storyboard。

### D3: 戰鬥畫面全向量重build（憲龍指示「比照主選單」，2026-05-19）

戰鬥畫面**功能本已完整**（Combat.gd 454 行 STR 回合邏輯 + Aida 廟會 HUD）。
「實現」＝視覺向量化至與主選單一致，**核心戰鬥邏輯/節點/信號零改動**。

**Phase 1（✅ 完成，待 commit）**：additive 視覺層。
- `scripts/ui/VectorCombatBackdrop.gd`：程序化戰場 chrome（四角暈影 + 頂/底 HUD
  漸層帶 + 金邊欞框 + 微弱燈籠光暈），疊在各章節 AI 場景圖（BackgroundButton）之上。
- `Combat.gd` 末段 additive `_apply_vector_skin()`（_ready 末尾一行呼叫，**不動既有
  454 行**）：隱藏 Aida 7 個扁平 ColorRect chrome、疊向量 backdrop、HUD 文字/結束
  回合鈕走 CotiwUiTheme。BackgroundButton 場景圖保留為底。
- Combat 仍隨 RunScreen SafeFit 等比進安全區（**不破壞核心戰鬥版面**）。
- 驗證：import 乾淨、測試 21/21、Root.tscn headless 1200×700/2532×1170/1180×820
  皆無 script error；Combat 全部 @onready 節點與信號保留。

**Phase 2（待辦，獨立里程碑，高風險）**：真正的邊到邊響應式戰鬥 HUD（Combat
排除於 SafeFit、HUD/手牌/牌堆/能量/結束回合改 Responsive.safe_rect 定位，比照
主選單），及手牌/卡牌/敵人/意圖 badge/狀態 icon 的 STR-runtime 視覺打磨。

---

## 標記用法

每個問題請以下列三種之一回覆：

- ✅ **採納建議**：接受 Claude 提的方向。
- ❌ **不接受**：請註明替代方案。
- ⏸️ **暫緩**：先擱置，下個 Sprint 再決定。
