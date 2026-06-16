
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

---

## 2026-06-11 Q2 開工前問題（全畫面動漫化二輪 + 修廟 UI）

> Q2 範圍（DELEGATION §5）：遶境地圖二輪、供桌四選一+筊杯、主選單三層構圖+神匾 CTA+Q版 icon、
> **修廟 screen UI + 建築解鎖實套**、商店/獎勵/歇腳/事件美術密度、tablet 4:3 專屬排版。
> 職權內自決（不問）：籤詩文案我起草驗收時你改、tablet 優先畫面取主選單/地圖/戰鬥、各畫面構圖細節。

### Q2-A: 建築 unlocks 實套的範圍切線（Q2 做多深）

**情境**：

- 修廟後端已齊（RitualTemple：修復/升級/unlocked_features 查詢 + 測試），缺 UI 與「unlocks 實際改變開局」。
- 6 個解鎖鍵分兩類：**結構型**（deity_slot 神明位數、ritual_tool_ward_break 法器進池、shop_stock 商店池擴充）— 掛接現有系統即可；**內容型**（run_modifier_fortune 開局抽籤改規則、start_passive 開局被動）— 各自是要新設計內容池的新系統。
- 把內容型硬塞進 Q2，修廟 UI 與美術密度的工時會被擠壓，且籤詩 modifier / 被動內容屬「內容量產」（DELEGATION Q3 的本業）。

**選項 A**：Q2 掛結構型三鍵（正殿/虎爺殿/夜市香鋪 + 戲台外觀），籤詩亭/鐘鼓樓 UI 上顯示「修復後 Q3 開放內容」

- 優：Q2 聚焦畫面品質；內容型留給 Q3 內容關一起設計（籤詩 modifier 池與卡池/敵人池同批量產）。
- 缺：Q2 結束時有兩棟建築「修了但效果待開放」。

**選項 B**：Q2 全六鍵實套（含設計 3-5 張開局籤詩 + 2-3 個溫和被動）

- 優：修廟系統一次完整。
- 缺：擠壓 Q2 美術主線；內容倉促設計易踩鐘鼓樓 pay-to-win 紅線（meta 文件 §6 明言此棟最接近紅線）。

**我的建議**：A。修廟的「畫面與循環」Q2 落地，「內容池」Q3 量產。兩棟未開放建築在 UI 標注開放時程，誠實不假裝。

**🟡 待憲龍回覆（未覆前按 A 進行）**

> **Q2-D 實作註記（誠實申報）**：選項 A 原列「正殿 deity_slot」為結構型，但勘查發現
> 多神明位需要「同場多神」系統（現行 run 僅單一 active deity，由護壇/法器親和解析）——
> 該系統本身是 Q3 內容。故 Q2 實掛 **虎爺殿（破煞法器進池）+ 夜市香鋪（商店加成）** 兩鍵，
> 正殿與籤詩亭/鐘鼓樓同列 Q3，修廟 UI 上已誠實標注開放時程。

### Q2-B: 解鎖實套後的 0 級基線（新玩家初始選項收多窄）

**情境**：

- 目前未實套，玩家開局即享全部選項（神明全可選、法器全池、商店全池）。實套後 0 級廟的新玩家會從較窄選項開始 — 這是 meta 進度的本意，但基線數字是體驗曲線決策。
- 香火結算現況：勝 +INCENSE_ON_VICTORY / 敗 +INCENSE_ON_LOSS（數字見 Global.gd）；正殿首修 300。

**選項 A**：溫和收窄 — 0 級＝神明位 1、基礎法器 2 把進池、商店基礎池；首修成本下調至「前 2-3 趟 run 必能修起第一棟」

- 優：新玩家前 3 趟就體驗到「修廟→開局變多」的循環勾子；既有測試/E2E 流程衝擊小。
- 缺：老玩家（你）現有存檔會感覺選項變少（可用 dev 旗標全開）。

**選項 B**：不收窄 — 0 級＝現狀全開，修廟只「再加更多」（神明位 1→但現在就全選、法器池只增不減）

- 優：零體驗倒退。
- 缺：修廟的「成長感」被稀釋成裝飾；違背 meta 文件「廟越完整選項越多」的循環設計。

**我的建議**：A，並在 debug build 提供「廟全滿」測試旗標。數字我先按 A 落，香火曲線（成本/產出）以 JSON 數據呈現，你驗收時改數字即可（鐵律 1：數值都在資料層）。

**🟡 待憲龍回覆（未覆前按 A 進行）**

### Q2-C: Recraft 額度枯竭（美術生成管線停擺）

**情境**：

- Q2-A 進行中 Recraft 餘額掉到 18 credits，**所有生成請求被拒**（v3/v2、單張皆失敗 — 低額門檻）；
  HuggingFace 免費生圖額度同日歸零。煞氣環是斷糧前最後一張可用素材。
- Q2 後續高度吃生成：山門正式圖、主選單 Q 版 icon ×6、供桌背景升級、修廟六建築立繪、商店/獎勵/歇腳美術密度。
- 已用替代法不停工：符紙改程序化設計面板、寶匣 icon 手寫 SVG、山門保留佔位。

**選項 A**：充值 Recraft（https://www.recraft.ai/profile/api）

- 優：管線原地復活，風格與既有素材連續（同模型同 substyle）。
- 缺：花錢。

**選項 B**：提供其他生圖 key（如 HF token / 其他服務），我改接管線

- 優：彈性。缺：風格連續性要重新校。

**我的建議**：A。Q2-C/D/E 開工前到位即可，我先推不吃生成的部分（Q2-B 供桌排版/筊杯演出可程序化 + 手寫 SVG）。

**🔴 阻擋 Q2 美術密度子項（不阻擋結構/排版/演出類工作）**

---

## 2026-06-11 Q3 開工前問題（內容完備與打磨）

> Q3 範圍（DELEGATION §5）：Boss 百年虎爺專屬演出、卡面/班底美術補完、音訊補齊、
> 數值平衡 pass（我出數據你拍板）、香火回報/AoE 破煞/合符神力等 PRD 續調、
> Q2 遺留內容型 unlocks（籤詩亭/鐘鼓樓/正殿）。
> 驗收：第一章通玩八基準全 ≥4、placeholder 零露臉。
> 職權內自決（不問）：Boss 演出構成、美術批 prompt、平衡模擬管線設計。

### Q3-A: SFX 正式音源來源（Q1-A 升級為硬阻擋）

**情境**：

- 驗收條款「placeholder 零露臉」— 現有 5 顆程序化 SFX 必須換正式音源，且規格書清單共 14+ 顆。
- Suno 實測不支援 one-shot 音效（song-form 模型，兩種 prompt 皆拒）；Recraft 不做音訊。

**選項 A**：提供 ElevenLabs API key（其 sound-generation 正是做短音效的）

- 優：規格書整張清單一次做完（幾百額度足夠）、風格可控可重 roll。
- 缺：再開一個服務帳號。

**選項 B**：核准我從 CC0 庫（freesound / kenney）下載挑選

- 優：零成本。缺：民俗打擊樂（鑼鈸/木魚/嗩吶）CC0 命中率低，風格一致性差。

**我的建議**：A。丟 key 過來我當天把 14+ 顆全部生完入庫（規格書 prompt 已備）。

**🔴 阻擋 Q3-C 音訊子任務（不阻擋其他子任務開工）**

### Q3-B: 鐘鼓樓 start_passive 的「溫和」量化（pay-to-win 紅線）

**情境**：

- meta 文件 §6 明言鐘鼓樓最接近紅線、open question #2 要求明文量化「溫和」。
- 分界表：數值平衡與紅線例外必須上報 — 這題不能我自定。

**選項 A**：嚴格版 — 明文禁止任何直接戰鬥數值（+攻/+血/+傷/+抽卡），被動限「便利/資訊型」：
例如「開局預覽下兩層節點型別」「首戰開場神力 +1 充能（單次，非每戰）」「歇腳選項 +1」

- 優：紅線零風險、新手老手零數值差。
- 缺：爽感較低調。

**選項 B**：允許溫和資源數值（如 +5 元神上限、開局 +20 銀兩），禁戰鬥面板數值

- 優：感知明顯。缺：「資源也是戰力」的灰區，開了口子難守。

**我的建議**：A。爽感由 Q-2 演出補（修好鐘鼓樓開場有鐘聲環境音），不靠數值。

**🟢 憲龍回覆 2026-06-11**：✅ A（嚴格版：禁戰鬥數值，限便利/資訊型）

### Q3-C: 籤詩亭 run modifier 池的風味方向

**情境**：

- 籤詩亭解鎖「開局抽籤改變該趟規則」。首發池規模我建議 5 支籤（資料驅動 JSON，數值你隨時改）。

**選項 A**：風險對沖型 — 每支籤同時帶利與弊（「商店價 -20%／獎勵選項 -1」「起手 +1 牌／元神上限 -5」）

- 優：重玩性與決策深度高，符合 roguelike 傳統與「籤有吉凶」的民俗語感。
- 缺：新手可能看不懂取捨。

**選項 B**：純正面小 buff 型（抽到就是賺）

- 優：直觀。缺：變成「為什麼不抽」，籤詩亭淪為純加成器。

**我的建議**：A（吉中帶凶才是籤）。我出 5 支籤草案+數值，你拍板後實套。

**🟢 憲龍回覆 2026-06-11**：✅ A（風險對沖型；草案+數值入 JSON 隨時可改）

### Q3-D: 正殿多神位的系統形態

**情境**：

- 正殿 unlocks=deity_slot，但現行 run 只有單一 active deity（護壇/法器親和解析）。
- 「同場多神」是系統工程，Q3 條款未明列。

**選項 A**：Q3 做最小版「備援神位」— 正殿 1 級開第二神位：降乩釋放後，自動切換至備援神
  繼續充能（一場戰鬥可請兩尊不同神）

- 優：請神系統自然延伸、改動面小（DeityInvocationSystem 加佇列）、修正殿立刻有感。
- 缺：平衡影響需模擬數據（Q3-F 管線正好餵）。

**選項 B**：整套多神同場（多神 controller 並行）移 Q4 後

- 優：避免 Q3 膨脹。缺：正殿「修了沒感」再拖一關。

**我的建議**：A 最小版（含模擬數據給你看平衡影響）。

**🟢 憲龍回覆 2026-06-11**：✅ A（最小版備援神位 + 模擬數據後補）

### Q3-E: PRD Phase 3 選做機制（道士符位/法陣、家將陣型）

**情境**：條款標明「選做，需憲龍核准」。Q3 重心已滿（Boss 演出/美術補完/音訊/平衡/續調）。

**選項 A**：本關不做，Q4 前重新評估

**選項 B**：挑一個做（道士符位 或 家將陣型）

**我的建議**：A。Q3 的驗收是「第一章完整且打磨」，新機制會稀釋打磨密度。

**🟡 待憲龍回覆（未覆前按 A：不做）**

### Q3-F: 平衡模擬數據出爐（合符經濟 + 備援神位 — 待拍板）

**情境**：模擬管線首輪數據（30 戰/變體，報表 `qa/balance/BALANCE_REPORT_2026-06-11.md`）：

| 變體 | 勝率 | 平均回合 | 殘血% | 惡煞據點勝率 |
|---|---|---|---|---|
| 現狀（合符免費） | 80% | 3.4 | 69% | 100% |
| 合符收 1 神力 | **63%** | 4.3 | **51%** | **17%** |
| 正殿備援神位 | 80% | 3.4 | 69% | 100% |

**判讀提示**（非定案）：收 1 神力對 boss 級戰鬥重創（殘血 5%）— 若仍想收費，建議
「每回合首次免費、之後收費」等溫和形式（可再跑對比）。備援神位在 4 戰切片內
請神排不到第二尊（降乩/戰 0.17）— 整章通玩數據才能評估，不構成「無用」結論。
前期排除技術超時後 AI 全勝 — 第一章前期偏簡單的訊號。

**選項 A**：合符維持免費（現狀），Q3 不動 — 等整章通玩數據再議
**選項 B**：指定一個消耗形式，我再跑對比數據

**我的建議**：A。合符是本作差異化核心爽點，數據顯示直接收費懲罰過重。

**🟡 待憲龍回覆（未覆前開關維持預設 0 = 免費）**

---

## 2026-06-12 Q4 開工前問題（上架工程）

> Q4 範圍（DELEGATION §5）：i18n 落地（程式中文清零）、IAP（嚴守紅線）、雲端+本地加密存檔、
> 效能 pass、真機矩陣。驗收：TestFlight/內測能裝能玩能買（沙盒）能跨裝置續檔。
> 職權內自決（不問）：i18n 鍵名規範與簡中/日語補全（CSV 四語欄已存在）、加密方案、
> IAP 平台抽象層設計、效能工具鏈。

### Q4-A: IAP 商品結構與定價（分界表：變現必須上報）

**情境**：技術管線（StoreKit/Play Billing 抽象 + 沙盒）我先行，但商品表是你的決策。
紅線重申：元寶只買外觀/角色解鎖/支持包；香火與戰力不可販售。

**需要你給**：
1. 元寶包面額檔位（建議 6 檔慣例：NT$33/90/170/330/670/1690 對應元寶量 + 首充加倍？）
2. 角色解鎖定價（鸞女/道士/家將 — 元寶價）
3. 外觀首發清單與價（卡背 ×N、主畫面裝飾、神明降臨 skin）
4. 支持者包內容

**我的建議**：先給「檔位骨架」即可（數字可後改 — 商品表做成資料驅動 JSON）；
首發外觀走「卡背 ×2 + 看板娘換裝 ×1」最小集。

**🟡 待憲龍回覆（未覆前用測試商品表開發，不上正式配置）**

### Q4-B: 開發者帳號與簽名（只有你能辦）

**情境**：TestFlight 需 Apple Developer Program（US$99/年）；Google Play 內測需
開發者帳號（US$25 一次性）。註冊/付費/憑證皆屬帳號持有人操作，我不能代辦。

**需要你做**：
1. Apple Developer 註冊（johnny963214@gmail.com 或專用帳號）→ 給我 Team ID
2. （可後補）Google Play Console 註冊
3. Bundle ID 確認：建議 `com.kiresakura.cotiw`（或你指定）

**🔴 阻擋 TestFlight/內測上傳與真機簽名（不阻擋 i18n/IAP管線/加密/效能工程）**

### Q4-C: 雲端存檔範圍切線

**選項 A**：Q4 做 iOS（iCloud Key-Value，Godot 官方 plugin 路徑成熟）+ 本地加密雙平台；
Android 雲存（Play Games Saved Games）Q5 前補

**選項 B**：Q4 雙平台雲存一次到位

**我的建議**：A。iOS 先行對齊 TestFlight 驗收；Android 插件鏈（Godot 4 + Play Games v2）
坑較多，不押在同一關。

**🟡 待憲龍回覆（未覆前按 A 進行）**

### Q4-D: 真機矩陣 — 你手上有哪些設備？

**情境**：條款要求 iPhone SE 級→Pro Max 級 + 中階 Android。模擬器我能跑，
真機需要實體（或你跑我給的測試清單）。

**需要你給**：手上可測設備清單（型號）。缺口我會列「建議借/買清單」或以模擬器+
效能預算保守值補位（誠實標注未實測機型）。

**🟡 待憲龍回覆（未覆前模擬器矩陣先行）**

---

## 新一局／開壇設定畫面重排（2026-06-12，憲龍當場拍板）

### NR-1: 名詞紅線 — 家將標籤「爆裂終結」撞「終結技」
**情境**：`new_run_character_shelf.json` 家將標籤含「爆裂終結」，「終結」踩名詞紅線。
**選項 A**：爆裂強攻　**選項 B**：破陣猛擊
**拍板**：**破陣猛擊**（憲龍當場）。

### NR-2: 模式分段（標準／易／無盡／自訂）對應既有 run_modifier
**情境**：目標設計引入模式分段，需對應既有資料、不發明新玩法。
**選項 A（採用）**：標準=無修正／易=run_modifier_custom_easy_mode／無盡=run_modifier_endless_mode／
自訂=展開既有 checkbox 清單自由勾。難度 stepper（敵 HP 0..5）維持獨立，與模式正交。100% 復用現有資料。
**選項 B**：易併進難度 stepper（難度0=易）。
**拍板**：**A**（憲龍當場）。難度與模式語意分離：難度=敵強度、模式=規則修正。

### NR-3: 「自訂」清單的 STR 佔位（自訂1／自訂2）
**情境**：custom_1/2 JSON 說明僅「自訂修正1/2」、無實際效果，是 STR 殘留，像 debug。
**選項 A（採用）**：自訂清單只列有實效項（七彩 等），隱藏無實效 STR 佔位。
**拍板**：**A**（憲龍當場）。以 run_modifier_description 非佔位文案 + 有實際 patch 為「有實效」判準。

### NR-4: 觸控尺寸 — 鐵律2「88×88」vs audit「64 floor/80 comfort」vs 1200×700 右欄預算
**情境**：開壇設定卡在 1200×700 右欄需容納「難度 stepper + 模式分段4鈕 + 護壇 + 法器
（+自訂清單）」五組控件。全部 88×88 在 700px 高度塞不下（會溢出/重疊）。專案 audit
實際門檻為 64 floor（<64 FAIL）/ 80 comfort（<80 WARN），既有畫面（主選單等）亦採此標準。
**選項 A（採用）**：以 repo 現狀 audit 標準為準 — 此密集設定卡控件 ≥64（0 FAIL 達標），
部分落 64-72（comfort WARN，無 FAIL）；88×88 保留給主 CTA（開始開壇 132 高 ✓）與
陣容磚（108×132 ✓）。
**選項 B**：右欄改 ScrollContainer+VBox，全控件升 80+（需重構絕對定位版面為 Container）。
**現況**：採 A（DoD 要求 0 FAIL 已達）。若憲龍要求嚴守 88，走 B（成本中，另開工項）。

### NR-5（範圍外提報）: 1515×700 地圖節點觸控 FAIL（main 既有）
**情境**：三解析度 audit 中，1515×700 的 09_map 有一個遶境節點 TextureButton 短邊 47px
（<64 FAIL）。經 git checkout main 驗證為**既有問題**，非本次重排引入；且屬地圖畫面，
超出「新一局」任務範圍（禁碰其他畫面）。
**建議**：另開「地圖節點觸控尺寸」工項處理（地圖節點寬度隨寬螢幕被擠扁）。本任務不動。
