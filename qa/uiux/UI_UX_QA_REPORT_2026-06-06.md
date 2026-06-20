# COTIW UI/UX QA 報告 — 2026-06-06

> 角色：遊戲策劃 / UI/UX QA 交叉審查  
> 專案：`/Users/crimson/Developer/COTIW`  
> 目標：針對手機版 COTIW 進行全面 UI/UX 測試，確認其是否能支撐「台灣民俗題材的儀式編排型 roguelike 卡牌手遊」，並降低「殺戮尖塔換皮」感。  
> 結論等級：**Major Risk — 可跑、可匯出，但 Android 真機/模擬器啟動驗收未通過，且 UI layout 技術債偏高。**

---

## 1. 測試環境

| 項目 | 結果 |
|---|---|
| OS | macOS host |
| Godot | `4.6.1.stable.official.14d19694e` |
| 專案 branch | `main...origin/main [ahead 1]` |
| 工作區狀態 | 測試前後新增 `qa/` 測試產物；原有程式碼未修改 |
| Android emulator | `emulator-5554`, `model: SM_G998B` |
| Android export | Debug APK 成功產出並簽署：`qa/uiux/build/cotiw-uiux.apk` |

---

## 2. 執行項目與結果

### 2.1 Godot import / project load

命令：

```bash
godot --headless --import
```

結果：**PASS**

證據：`qa/uiux/automated_import_tests.log`

備註：import 階段出現 `cannot connect to daemon at tcp:5037: Connection refused`，屬 ADB daemon 狀態訊息，不影響 Godot import 本身。

---

### 2.2 自動化測試

命令：

```bash
godot --headless res://tests/TestRunner.tscn
```

結果：**FAIL — 138 / 139 通過，1 個測試案例失敗，3 個 assert 失敗。**

失敗測試：

```text
test_data_validation.gd::test_cotiw_character_roster_matches_expected
```

失敗內容：

```text
預期 2 實得 4。鎮島錄角色表大小應為 2（目前為乩童 + 鸞女）
角色表中出現非鎮島錄角色：character_daoshi
角色表中出現非鎮島錄角色：character_jiajiang
```

判讀：

- 如果道士 / 家將已經是正式角色：測試規格落後，應更新 expected roster 與 NewRun UI 驗收。
- 如果道士 / 家將只是實驗資料：資料註冊污染正式角色表，會造成角色選擇 UI、進局流程、平衡驗收混亂。

---

### 2.3 UI scene smoke

執行：

```bash
godot --headless --path . --scene res://scenes/Root.tscn --quit-after 300
godot --headless --path . --scene res://scenes/prototypes/Gate1Prototype.tscn --quit-after 300
godot --headless --path . --scene res://scenes/dev/UIComponentGallery.tscn --quit-after 300
```

結果：**PASS**

| Scene | 結果 | 備註 |
|---|---|---|
| `Root.tscn` | PASS | log 顯示 TitleScreen ready → splash transition → main menu shown |
| `Gate1Prototype.tscn` | PASS | headless smoke exit 0 |
| `UIComponentGallery.tscn` | PASS | headless smoke exit 0 |

證據：

- `qa/uiux/root.log`
- `qa/uiux/gate1.log`
- `qa/uiux/ui_gallery.log`

---

### 2.4 Android export

命令：

```bash
godot --headless --path . --export-debug "Android" qa/uiux/build/cotiw-uiux.apk
```

結果：**PASS**

證據：`qa/uiux/android_export.log`

重點：

- APK 建立成功。
- Debug signing 成功。
- `custom_features="exported"` 已設定，這能避免 FileLoader 在 exported build 找不到外部資源的常見問題。

---

### 2.5 Android install / launch 驗收

命令摘要：

```bash
adb install -r qa/uiux/build/cotiw-uiux.apk
adb shell monkey -p com.kiresakura.cotiw -c android.intent.category.LAUNCHER 1
adb exec-out screencap -p > qa/uiux/android_launch_retry_10s.png
```

結果：**FAIL / BLOCKED**

ADB 安裝與啟動均失敗：

```text
adb: failed to run abb_exec. Error: closed
adb: retrieving the default device installation mode failed: closed
adb: connect error for write: closed
error: closed
```

截圖結果：**不是 COTIW**。畫面顯示另一款戰國策略遊戲介面，因此目前不能宣稱 Android 實機/模擬器可啟動 COTIW。

證據：

- `qa/uiux/adb_install.log`
- `qa/uiux/adb_retry.log`
- `qa/uiux/android_launch_8s.png`
- `qa/uiux/android_launch_retry_10s.png`

---

## 3. 缺陷清單

### Critical-1：Android 模擬器安裝 / 啟動驗收未通過

**嚴重度：Critical**

**位置：** Android install / launch 流程  
**證據：** `adb install` 與 `monkey launch` 回傳 `closed`，截圖不是 COTIW。  
**玩家影響：** 目前只能證明 APK 可匯出，不能證明玩家手機能成功安裝、啟動、看到主畫面。對手機遊戲而言這是發版阻斷項。  
**建議修正：**

1. 先釐清 emulator / ADB 是否健康：
   - `adb kill-server && adb start-server`
   - `adb devices -l`
   - 確認 emulator 未被其他遊戲佔用或處於異常狀態。
2. 改用乾淨 Android emulator 或實機重測。
3. 安裝後立刻抓：
   - `adb logcat -d | grep -Ei 'godot|cotiw|crash|fatal|exception'`
   - `adb shell dumpsys package com.kiresakura.cotiw`
4. 驗收標準：安裝成功、launch 成功、10 秒內截圖可見 COTIW splash / main menu，且 logcat 無 crash。

---

### Major-1：角色 roster 規格與資料不一致

**嚴重度：Major**

**位置：** `test_data_validation.gd::test_cotiw_character_roster_matches_expected`  
**證據：** 測試預期 2 位角色，實際註冊 4 位，新增 `character_daoshi` / `character_jiajiang`。  
**玩家影響：** New Run / 角色選擇 / loadout UI 可能與資料層不一致；玩家可能看到不該出現的角色，或正式角色不能完整進局。  
**建議修正：**

- 若道士 / 家將是正式內容：更新測試、角色 gallery、角色敘事卡、起始套牌、請神 / 法器 loadout 驗收。
- 若非正式內容：從正式 registry 移除或加 `enabled=false / dev_only=true` gating。
- 補測：四位角色逐一從 NewRunMenu 進入 Gate1Prototype / Combat，確認不 crash、不缺圖、不缺起始牌組。

---

### Major-2：UI 場景高度集中於 `Root.tscn` 與 GDScript 動態座標，layout 可維護性差

**嚴重度：Major**

**位置：** `Root.tscn`、`scripts/ui/menus/MainMenu.gd`、`scripts/ui/menus/NewRunMenu.gd`、`scripts/ui/Combat.gd`、`scripts/ui/Hand.gd`  
**證據：** 靜態掃描：

- `Root.tscn`：`offset_` 595 處、`anchor_` 125 處、`font_size` 48 處。
- `MainMenu.gd`：`position = Vector2` 26 處、`size = Vector2` 24 處。
- `NewRunMenu.gd`：多處手寫 `gallery_x / guide_x / info_y` layout。
- `Combat.gd`：背景與 toast / status label 有固定座標。
- `scenes/ui/Combat.tscn`、`scenes/ui/MainMenu.tscn`、`scenes/ui/NewRunMenu.tscn` 等獨立 scene 不存在。

**玩家影響：** 手機比例、瀏海、安全區、平板尺寸變化時，UI 容易裁切或錯位。設計師也難以在 Godot Editor 直接微調。  
**建議修正：**

1. 先拆出三個高風險場景：`MainMenu.tscn`、`NewRunMenu.tscn`、`Combat.tscn`。
2. GDScript 保留狀態刷新與互動，不直接散落絕對座標。
3. 將 1200×700 stage size 收斂成 theme/layout token。
4. 補 snapshot / layout contract 測試：16:9、19.5:9、20:9、4:3 tablet。

---

### Major-3：戰鬥 UI 有固定座標與中心覆蓋風險

**嚴重度：Major**

**位置：** `scripts/ui/Combat.gd`、`scripts/ui/Hand.gd`  
**證據：**

- `Combat.gd` 背景固定：`offset_right = 1200.0`、`offset_bottom = 700.0`。
- `Combat.gd` toast：`position = Vector2(400.0, 300.0)`、`size = Vector2(400.0, 50.0)`、`font_size = 30`。
- `Hand.gd` 取消目標按鈕：`size = Vector2(160, 54)`、`position = Vector2(520, 250)`。

**玩家影響：**

- toast 出現在畫面中心，可能遮住敵人、意圖、破煞狀態或拖牌目標。
- 取消鍵離手牌區太遠，不符合橫向手機的拇指操作動線。
- 20:9 或瀏海機可能更明顯。

**建議修正：**

- toast 改為非互動區，例如上方 HUD 下緣或手牌上方 toast lane，並做 queue / throttle。
- cancel target button 改 anchor 到底部手牌列上方或右下安全區。
- 補 UI test：進入選目標狀態 → 顯示取消鍵 → 不覆蓋手牌、不覆蓋敵人 intent。

---

### Major-4：Safe area 處理不均，Combat / Hand / Map 仍有瀏海與極端比例風險

**嚴重度：Major**

**證據：** 靜態掃描顯示：

- `MainMenu.gd` 有 21 處 safe 相關處理。
- `CombatHudOverlay.gd` 有 15 處 safe 相關處理。
- 但 `Combat.gd`、`Hand.gd`、`Map.gd` 幾乎沒有等量 safe area layout 保護。

**玩家影響：** 主選單看起來可用，但真正高頻的戰鬥 / 手牌 / 地圖可能在瀏海、動態島、導覽列或超寬比例上踩邊。  
**建議修正：**

- 建立全域 `COTIW_UI_THEME.get_safe_content_rect()` / layout service。
- 所有 HUD / hand / map / overlay 必須以 safe rect 為根。
- 新增測試：safe rect 模擬窄屏 / notch / tablet。

---

### Major-5：Touch detail overlay 固定位置，可能不適配手機與平板

**嚴重度：Major**

**位置：** `scripts/ui/theme/TouchFeedback.gd`  
**證據：**

- detail overlay 固定 `panel.size = Vector2(500, 260)`。
- 顯示位置固定：`overlay.position = Vector2(390, 240)`。

**玩家影響：** 長按查看卡牌 / reward 詳情時，overlay 可能遮住被長按的物件、超出小螢幕安全區，或在平板上位置怪異。  
**建議修正：**

- overlay 依 target global rect、viewport safe rect 自動選擇上 / 下 / 左 / 右彈出。
- 限制最大寬度為 safe rect 的 80%。
- 點擊 backdrop 或再次長按外部可關閉。

---

### Minor-1：字級 token 使用不一致

**嚴重度：Minor**

**證據：** 多處直接 `add_theme_font_size_override("font_size", 數字)`；但 `CotiwUiTheme.gd` 已提供 typography token。  
**玩家影響：** 繁中 / 簡中 / 英文切換或手機尺寸縮放時，字級一致性會漂移。  
**建議修正：** 全部改用 `COTIW_UI_THEME.get_typography_size()`，並建立 `h1/h2/body/caption/micro/button/card` token。

---

### Minor-2：CanvasLayer / z_index 層級缺乏集中規格

**嚴重度：Minor**

**證據：** `MainMenu.gd`、`Map.gd`、`TouchFeedback.gd`、`CombatHudOverlay.gd` 分別建立 CanvasLayer / z_index。  
**玩家影響：** reward、shop、toast、touch detail、combat FX 疊加時，未來容易出現遮擋順序錯誤。  
**建議修正：** 在 `CotiwUiTheme.gd` 或 `UiLayer.gd` 定義：

```gdscript
const LAYER_BACKGROUND := 0
const LAYER_WORLD := 10
const LAYER_HUD := 20
const LAYER_FX := 30
const LAYER_OVERLAY := 60
const LAYER_TOAST := 80
const LAYER_TOUCH_DETAIL := 90
```

---

## 4. 正向觀察

1. **已經不是單純 STS UI 皮膚：** 測試中可見 `ward / break / deity / talisman merge / ritual loadout / jiaobei` 等系統測試，玩法語彙已往「開壇鎮煞」移動。
2. **戰鬥核心測試覆蓋佳：** 破煞、合符、請神、deity routing、combat HUD、touch feedback、reward style 都有測試。
3. **Android export 已成功：** APK 打包與簽署通過，問題目前集中在 install / launch 驗收環境或 runtime 啟動驗證，而不是 export pipeline 完全不可用。
4. **觸控回饋有集中 helper：** `TouchFeedback.gd` 已處理 pressed / selected / disabled / long press detail，是手機化的正確方向。
5. **地圖已嘗試轉向「遶境路線」：** `Map.gd` 使用 pilgrimage route、boss omen、reachable flow line，這是擺脫爬塔感的重要 UI 語彙。

---

## 5. 產品差異化 UI/UX 建議

若要徹底擺脫「殺戮尖塔換皮」，UI 不只要好看，還要讓玩家每 5 秒都感覺自己不是在爬塔出牌，而是在做一場儀式。

### 5.1 戰鬥主 HUD：從「能量 / 回合 / 意圖」改成「壇場狀態」

建議讓戰鬥 HUD 的資訊架構優先顯示：

1. 香火 / 法力：本回合可用資源。
2. 煞盾：敵方護煞韌性。
3. 破煞窗口：敵人被破後的增傷 / 控制回合。
4. 神明槽：請神條件、目前神明偏好、可否降臨。
5. 合符提示：可合成的同階符令。

重點：不要把能量圖示和敵人 intent 做得像 STS，只是換字。玩家應看到的是「壇上的局勢」。

### 5.2 手牌：合符應是主要 affordance，不是隱藏長按彩蛋

目前長按合符是可用方向，但 UX 上應更明確：

- 可合符卡牌邊緣出現同色符光。
- 長按第一張時，其他可合符卡牌浮起。
- 合符完成不是普通 upgrade，而是「兩符相疊 → 燃起 → 新符落壇」。
- 新手前 3 戰用一次強制教學示範。

### 5.3 地圖：強化「遶境選路」而不是節點爬塔

地圖目前已有 pilgrimage route，但可以更進一步：

- 節點名稱改為地點 / 宮廟 / 禁地 / 路祭，不叫 encounter / event。
- 分岔不是風險收益數字，而是「走海線鎮水煞 / 走山線破虎煞」。
- Boss omen 應持續在遠方壓迫，形成路線敘事。

### 5.4 Reward：供桌語言正確，但選擇規則要更像神示

目前 `RewardOverlay.gd` 已有「神示供桌」和「三份神示只能領一份」，方向正確。建議：

- reward card 背景改為供品盤 / 籤詩 / 神符。
- 稀有度不只用顏色，也用供桌高度 / 香火 / 金紙層次。
- 長按詳情 overlay 應像「籤詩解讀」，而不是 generic JSON/detail panel。

---

## 6. 優先修正順序

| 優先 | 項目 | 理由 |
|---|---|---|
| P0 | 修正 Android install / launch 驗收 | 手機遊戲不能只停在 export 成功 |
| P0 | 對齊角色 roster 2 vs 4 的產品規格 | New Run / 角色選擇是核心入口，不可規格漂移 |
| P1 | Combat / Hand / Touch detail 改 safe rect layout | 高頻遊玩區，直接影響可用性 |
| P1 | 拆出 MainMenu / NewRun / Combat scene 或集中 layout service | 降低未來 UI 技術債 |
| P1 | 合符 UX 明示化 | 這是擺脫 STS 的核心差異化 affordance |
| P2 | 字級 token / layer token 統一 | 提升長期一致性與多語支援 |
| P2 | 地圖與 reward 的 ritual language 再強化 | 強化產品辨識度 |

---

## 7. 未能完整測試項目

| 項目 | 原因 | 下一步 |
|---|---|---|
| Android 真機啟動後實際 UI | ADB install / launch `closed` | 換乾淨 emulator 或實機，抓 logcat |
| 實際觸控拖牌手感 | headless 無法驗證手感 | 用 Android / iOS 實機錄影測試 |
| 多解析度視覺截圖 | 目前僅 headless smoke + emulator 截圖失敗 | 補 viewport matrix screenshot test |
| 音效 / haptic feedback | headless 不驗證音訊體感 | 實機 QA checklist |
| 長時間 run overlay lifecycle | 未跑完整一局 | 建立 scripted run smoke |

---

## 8. 測試產物

本輪產物都在：`qa/uiux/`

重要檔案：

- `automated_import_tests.log`
- `root.log`
- `gate1.log`
- `ui_gallery.log`
- `android_export.log`
- `adb_install.log`
- `adb_retry.log`
- `android_launch_8s.png`
- `android_launch_retry_10s.png`
- `static_scan_summary.md`
- `claude_second_opinion.md`
- `UI_UX_QA_REPORT_2026-06-06.md`

注意：`qa/uiux/build/cotiw-uiux.apk` 是測試 APK，若不想納入版本控制，建議把 `qa/` 或 `qa/uiux/build/` 加入 `.gitignore` 或以 artifacts 管理。

---

## 9. 總結

COTIW 目前的 UI/UX 基底不是壞的。更準確地說：**戰鬥系統差異化已經開始長出來，但 UI layout 和真機驗收還停在工程原型階段。**

最需要立刻處理的不是再加更多美術，而是：

1. 讓 Android 真機真的跑起來。
2. 讓角色 roster 規格一致。
3. 把高頻戰鬥 / 手牌 / overlay 從固定座標改成 safe-area-first。
4. 讓「合符、破煞、請神」在 UI 上成為第一眼就懂的主要互動，而不是藏在文字或測試裡。

做到這四點，COTIW 才會從「能跑的 Slay the Spire 變體」往「手機上開壇鎮煞的儀式卡牌遊戲」真正跨過去。

---

# Claude Code 修正結果（2026-06-07）

## 修改摘要
- 建立 safe-area / layer / typography 集中式 UI 基礎設施（CotiwUiTheme），UI 定位改以 `Responsive.safe_rect` 為單一真相來源。
- Combat toast、Hand 取消選敵鈕、Touch detail overlay 從固定 magic Vector2 改為 safe-area 相對定位 + clamp。
- 合符 affordance：可合符卡暖金提示（強化「開壇鎮煞」辨識度）。
- 新增多比例 safe-area contract 測試 + 戰鬥 UI 行為整合測試。

## 修正哪些 Critical / Major / Minor
- **Critical #1** Android install/launch：export ✅，但 install **BLOCKED（環境）** — 見下。
- **Major #2** 角色 roster：✅ 已於 Phase 2C 將 daoshi/jiajiang 升為正式角色（4 角），測試預期同步為 4。
- **Major #4** Combat/Hand/Touch 固定座標：✅ toast 不再 (400,300)、cancel 不再 (520,250)、overlay 不再 (390,240)。
- **Major #5** Safe area 不均：✅ toast/cancel/overlay 皆走 safe-rect；contract 測試覆蓋 16:9 / 19.5:9 / 20:9 / 4:3。
- **Major #6** 字級/layer token：✅ 新增 `LAYER_*` 常數 + 本任務觸及 UI 字級改走 `get_typography_size`。
- **Minor** 合符 affordance：✅ 可合符卡暖金提示 + 既有「合符！」ritual feedback。

## 未修正項目與原因
- **Major #3** Root.tscn 過大 / scene extraction：未做（高風險 framework scene 重構；本任務以 additive 降風險，scene 拆分留專屬里程碑）。
- Phase 8 token **全面**收斂：僅收斂本任務觸及 UI；其餘 magic font_size/layer 留漸進清理。
- Android install/launch：環境阻斷（見下）。

## 測試命令與結果
- `godot --headless --import`：✅
- `godot --headless res://tests/TestRunner.tscn`：✅ **161/161**
- Root / Gate1Prototype / UIComponentGallery scene smoke：✅ 無 SCRIPT ERROR
- `git diff --check`：✅

## Android install / launch 結果
- **export**：✅ `qa/uiux/build/cotiw-uiux-fixed.apk`（258M、已簽章）
- **adb 控制通道**（shell getprop）：✅ 可用（`ro.build.version.release = 13`）
- **install**：❌ **BLOCKED** — 所有模式皆失敗：
  - streamed/incremental：`failed to run abb_exec. Error: closed`
  - no-streaming/push：`file_sync_client.cpp protocol fault: failed to read stat response`
  - 已執行 `adb kill-server` / `start-server` / `reconnect` 仍失敗
- **launch / screenshot**：無法取得（install 未完成），**不偽造成功**
- **Blocked reason（明確）**：adb **資料/檔案傳輸通道**在本機 ↔ emulator-5554 之間損壞（控制通道正常）→ **ADB/emulator 環境問題，非 app/APK 問題**。APK export 與簽章皆正常。建議：重建 AVD / 對齊 platform-tools 版本 / 或改用實機 USB 後重試。
