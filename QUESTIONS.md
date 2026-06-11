
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
- 兩側黑邊根因＝ iOS 相容模式 letterbox（export_presets `storyboard/use_launch_screen_storyboard=false`），**非 Godot stretch**。修：啟用 launch storyboard + 同 boot splash 圖/紅底（詳 `docs/IOS_EXPORT_SETUP.md` 第 7 障礙）。⚠️ export 設定，須**重 export+重 build+重新部署真機**才生效。
- 載入不連貫（歷史流程）＝ 舊版獨立 `SplashScreen` 的進度條/文字使用固定 1200 座標、受 letterbox 跑位。當時修法是 `SplashScreen.gd` 改用 `Responsive.safe_rect` 定位 + 進度組淡入承接 boot_splash + BgFill 改廟會紅（三段同圖同底連貫）。
- **現況補註（2026-05-28）**：runtime 已改為 `Root.tscn` 啟動後直接顯示 Root 內建 loading overlay；獨立 `SplashScreen` scene / script 已移除，`boot_splash_v5.png` 僅保留給引擎 boot splash / export 素材。

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

## 2026-05-20 Android 匯出環境學習

### L1: Apple Silicon × BlueStacks 不能用 Vulkan 渲染

**現象**：APK install 成功、process 活（PID 4442）、`OnGodotMainLoopStarted` 已觸發，
但畫面**全黑**。logcat：

```
godot: Vulkan 1.2.250 - Forward Mobile - Using Device #0: Apple - Apple M4 Pro
godot: ERROR: QueuePresentKHR failed with error: 5
       at: command_queue_execute_and_present (vulkan/rendering_device_driver_vulkan.cpp:3064)
```

**根因**：BlueStacks 在 Apple Silicon 上把 Vulkan 翻譯成 host Metal，但
`QueuePresentKHR`（呈現 swap chain 影格到螢幕）持續失敗 → swap chain 從未成功
present，所以畫面是黑底，但遊戲邏輯活著。

**選項評估**：
- (A) **實機 Redmi 25080RABDG**（採用）：Vulkan 在實機原生，必定可跑；MIUI 需手動
  開啟「USB 安裝」+「USB 偵錯（安全設定）」。
- (B) 切 Android 走 GL Compatibility（GL ES 3.0）：BlueStacks GL 翻譯比 Vulkan
  成熟，但會影響 mobile renderer 統一性，需另開 `rendering_method.mobile` 平台
  覆蓋。暫不採。
- (C) qemu AVD：android-cmdline-tools 重裝後 AVD config 路徑壞掉指向不存在的
  android-34；要再修。暫擱。

**結論**：**Android 測試以實機為主**；BlueStacks 不適用 Apple Silicon + Vulkan 組合。

### L2: Android 匯出 `exported` feature tag 必加

FileLoader autoload（`autoload/FileLoader.gd:50`）啟動會檢查
`OS.has_feature("exported")`，沒有就不會載 `external/data/**/*.json` ——
亦即整個資料驅動系統（卡片/敵人/事件 JSON）會空。

**已修**：`export_presets.cfg` Android preset `custom_features="exported"`。iOS preset
（preset.0）原本就空，**待 iOS 真機測試時也需補同樣 feature**（避免相同症狀）。

### L3: Android 工具鏈坑點記錄

- `avdmanager` 要 **JDK 17**，不認 Java 1.8。`export JAVA_HOME=$(brew --prefix
  openjdk@17)/libexec/openjdk.jdk/Contents/Home`
- Godot Android export 要的 `~/Library/Application Support/Godot/editor_settings-4.tres`
  關鍵欄位：`export/android/android_sdk_path`、`debug_keystore`、
  `debug_keystore_user/pass`
- debug keystore 自簽：`keytool -genkey -keystore ~/.android/debug.keystore
  -alias androiddebugkey -storepass android -keypass android -keyalg RSA
  -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"`
- 啟動 app 用 `adb shell monkey -p <pkg> -c android.intent.category.LAUNCHER 1`
  而非 `am start -n <pkg>/<activity>`（activity 名隨 Godot 版本改）

---

## 標記用法

每個問題請以下列三種之一回覆：

- ✅ **採納建議**：接受 Claude 提的方向。
- ❌ **不接受**：請註明替代方案。
- ⏸️ **暫緩**：先擱置，下個 Sprint 再決定。

---

## 2026-06-06 儀式編排型重構（Phase 1A）— 待決策

> 本輪完成「文件 + schema + 資料 + validator」落地（PRD v0.2、6 份設計文件、CardData/EnemyData 擴充、
> DeityData/GuardianData/RitualToolData、RitualTags/WardBreakSystem、乩童/鸞女卡 + act1 敵人注入、
> 4 神/2 護壇/3 法器/4 路線/6 建築、101/101 測試綠燈）。以下為接 Phase 1B–2 前需要產品決策的問題，
> 各系統設計文件的「開放問題」彙整於此。

### Q-R1: 合符（符階合成）的消耗規則
- 設計文件暫用「消耗一次合符行動 / 回合」。完整規則待定：是否改為消耗神力？每回合合符上限？合成後新卡是否當回合可立即打出？
- **我的建議**：MVP 先「每回合 1 次免費合符」最易懂；數值平衡後再評估神力消耗。詳見 talisman_merge_system.md。
- **🟡 2026-06-06 更新**：Phase 1C 已**實作簡化版**——右鍵可合符的卡 → 與手牌第一張同組同階夥伴合成升階，`MERGES_PER_TURN = 1`（每回合 1 次免費）。仍待決策：①是否改為消耗神力？②每回合上限要不要 >1？③**手機手勢**——目前觸發走右鍵，手機需定義合符手勢（長按已用於看詳情）。

### Q-R2: 請神滿槽的釋放 UX 與溢出
- 已定「不自動釋放，玩家擇時降乩」。待定：滿槽後溢出的請神值丟棄或保留？降乩按鈕擺位（側欄 vs 神明立繪可點）？同時多神滿槽如何呈現？
- **我的建議**：溢出丟棄、側欄請神槽 + 滿槽發光可點。詳見 deity_invocation_system.md。
- **🟡 2026-06-06 更新**：Phase 1D 已實作**虎爺 MVP**——請神槽以頂部置中按鈕呈現（請神中顯示 `N/max` 且 disabled；滿槽顯示「降乩！」可點），溢出夾在 max（丟棄），手動釋放。`DeityChargeController.BREAK_CHARGE = 25`。仍待決策：①按鈕版位（手機是否改側欄/神明立繪可點）②多神同時滿槽呈現 ③出戰神明選擇（目前固定虎爺，待 Phase 2 主祭/護壇/法器配置）④BREAK_CHARGE 與 tiger_roar 傷害平衡。

### Q-R3: 破煞爆發窗口的數值
- 暫定 `BROKEN_DAMAGE_MULTIPLIER = 1.5`、破煞當下不一定跳過敵方行動（由 break_effect 決定）。是否要讓部分 break_effect（如 break_stun）跳過敵方下一次行動？BOSS（百年虎爺 break_invoke_window）窗口應否更長？
- **我的建議**：break_stun 跳過 1 次行動、BOSS 窗口 2 回合（已資料化 broken_turns=2）。詳見 ward_break_system.md。

### Q-R4: 主祭 / 護壇 / 法器 首發開放範圍
- 三件配置是否首發全開？還是 MVP 先「單主祭 + 法器」，護壇 Phase 2 再開？
- **我的建議**：Phase 1 先主祭 + 法器（資料已備），護壇隨道士/家將 Phase 2 一起開。

### Q-R5: 道士 / 家將內容排序
- 兩角目前只有設計與護壇樣本（guardian_jiajiang_front），未建卡。是否確認 Phase 2 才做、先把乩童 + 鸞女的破煞/合符/請神打磨完整？
- **我的建議**：是。先深做 2 角（已有 18 卡）跑通四支柱，再橫向擴角。

---

## 2026-06-06 QA 修復後待辦（P2 視覺/文件，非阻斷）

> 本次已修 P0/P1：手機合符長按入口、百年虎爺 fist 弱點、Enemy turn hook 呼叫 super、合符限額攔截 + toast。
> 以下 P2 為非阻斷待辦：

- **硬編碼戰鬥字串 i18n TODO**：「破煞！」「合符！」「本回合已合符」「請神/降乩！」散落於 Enemy.gd / Hand.gd / Combat.gd。
  待 i18n 導入時集中為 `tr()` key（或先抽 `RitualStrings` 常數）。範圍故意保守，本次未擴大。
- **煞盾 Label mobile-safe**：Enemy.gd 頭頂煞盾指示為 sprite 子 Label + 固定 px 偏移（隨 sprite 縮放，尚可，非 anchor/container）。待 RitualHud 容器化一併處理。
- **請神槽/狀態提示版位**：已把降乩按鈕下移至 y46–80 避開頂部回合狀態 Label（y8–42）。長線建議整理成 `RitualHud`/`InvocationHud` 容器統一管理（請神槽 + 煞盾 + 回合狀態），目前為程序化獨立節點。

---

## 2026-06-11 Q0 守門關卡問題

### Q0-A: exit leak 殘量的處置（已用白名單契約，是否排程根治）

**情境**：

- Q0 要求「處理 exit leak」。實測定位：洩漏不是 QA driver 或 autoload 快取，而是**跑局期 action↔combatant↔data 物件圖的 RefCounted 循環引用**（清掉所有 _id_to_*、ActionHandler 堆疊、static Script 快取、FileLoader 映射後，洩漏簽名一條不動；minimal boot 與 start_run-only 路徑皆零洩漏，僅完整戰鬥流程產生）。
- 根治 = 對 STR 核心 action/interceptor 反向引用做 weakref 重構，觸碰鐵律 3（fork-first）且估 1–2 天，超出 Q0 工具範圍。
- 已落地的處置：`tools/pre_release_check.sh` 把「恰好這兩行退場簽名」列為已知良性白名單，**任何其他** WARNING/ERROR 一律紅燈。白名單契約本身已在驗收中抓到兩條真 bug（res://res:// 雙前綴、e2e 預覽板 anchor warning），證明訊號可信。

**選項 A**：排程 weakref 根治（建議放 Q4 效能 pass 一併做，屆時本來就要動記憶體剖析）

- 優：退場報告真乾淨；杜絕長 session 記憶體緩慢增長的理論風險。
- 缺：動 STR 核心，1–2 天，回歸風險需全套測試護航。

**選項 B**：維持白名單契約至上架後

- 優：零風險零成本；CI 訊號已可信；玩家不受影響（程序退出時 OS 回收一切）。
- 缺：簽名永遠掛在 log 上；若未來洩漏圖長大，白名單可能掩蓋增量（緩解：守門可改記錄資源數量趨勢）。

**我的建議**：B 為現狀 + A 排入 Q4。循環引用在「單局內」不增長（每局結束物件圖被新局取代），實際風險低；Q4 效能 pass 有 profiler 在手時順手根治最划算。

**🟡 待憲龍回覆**

---

## 2026-06-11 Q1 開工前問題（戰鬥降噪 + 三大演出）

### Q1-A: Q1 配套 SFX 的墊檔來源（5 顆：出牌/破煞/降乩/合符/回合結束）

**情境**：

- 全案目前零音訊檔；完整音訊架構與來源決策排在 Q3。
- 但 Q1 驗收要求「打擊有爽感」，至少 5 顆戰鬥 SFX 不能再等。

**選項 A**：CC0 素材庫暫墊（freesound / kenney.nl 等，標記 PLACEHOLDER 前綴）

- 優：當天可用、零成本、零授權風險；Q3 統一替換時好識別。
- 缺：風格不保證統一（民俗打擊樂感要挑）。

**選項 B**：AI 生成（ElevenLabs SFX / Stable Audio）

- 優：可下「廟會鑼鼓/木魚/鞭炮」prompt，風格貼。
- 缺：需開通服務與額度決策（碰預算 = 你的線）。

**我的建議**：A 墊檔 + 把「民俗 SFX prompt 規格書」寫好放 Q3 一次決。Q1 不因音訊卡關。

**🟢 部分解決 2026-06-11**：憲龍提供 sunoapi.org key → **BGM 四場景已正式生成落地**
（Suno V4 器樂、OGG loop、AudioManager 場景自動切換，餘額 ~1018 credits 可續用於更多場景/變奏）。
**SFX 仍開放**：Suno 不支援 one-shot 音效（實測兩種 prompt 皆拒）。選項：
(a) 補一把 ElevenLabs key（sound-generation API，數百音效額度足夠全清單）
(b) 核准我從 CC0 庫（freesound/kenney）下載挑選
(c) 維持程序化佔位至 Q3。**建議 (a)**。

### Q1-B: 降乩 cut-in 的神明立繪素材策略（4 神各一）

**情境**：

- 降乩 cut-in 需要神明視覺主體。現有資產：deities_v3 六神肖像（收藏頁那套，方形半身）。
- cut-in 理想上是橫向大構圖（斜切色塊 + 神明半身掃入 + 金光），方形肖像直接放會略侷促。

**選項 A**：現有肖像 + 動效包裝（斜切紅布色塊、光芒、縮放掃入）

- 優：零新素材、身份感與收藏頁連續（Q-5 美術密度一致）、當天可出。
- 缺：構圖張力略遜專屬橫圖。

**選項 B**：Recraft 重生 4 張 cut-in 專屬橫向立繪（1820×1024）

- 優：演出峰值最大化。
- 缺：與現有肖像的一致性風險（同神兩套臉）；生成審核迭代成本。

**我的建議**：A 先落地（cut-in 框架 + 動效是可重用的；素材是可替換的 data），Q3 美術補完時若你點頭再升級 B。框架先行，素材後換，不返工。

**🟡 待憲龍回覆（未覆前按 A 進行）**
