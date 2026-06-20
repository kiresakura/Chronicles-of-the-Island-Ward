# COTIW UI/UX QA 報告

> 掃描日期：2026-06-06
> 範圍：橫向 1200×700、Phase 2C 結束狀態
> 評等：⚠️ 中度關注（基底可用，但有結構性與真機驗收缺口）

---

## 一、嚴重問題（建議下個 Sprint 必修）

### S1. 場景檔案幾乎全數缺失，UI 完全以程式碼動態建構
- `scenes/ui/Combat.tscn`、`MainMenu.tscn`、`NewRunMenu.tscn`、`Map.tscn`、`RewardOverlay.tscn`、`ShopOverlay.tscn` 均為 **MISSING**
- 所有 UI 在 `.gd` 中以 `position = Vector2(...)` / `size = Vector2(...)` 寫死建構
  - `MainMenu.gd`：26 處 `position = Vector2`、24 處 `size = Vector2`
  - `Root.tscn` 單檔承載 **595 處 offset_、125 處 anchor_**，等同 monolith UI
- **影響**：
  - 違反 CLAUDE.md「資料驅動」鐵律的精神（UI layout 應走 scene，不是 code）
  - 美術／QA 無法在 Godot Editor 直接調整視覺，每次微調都要動 GDScript
  - 後續 Phase 3+ 換橫向素材時，沒有可視化錨點預覽
- **建議**：至少把 `Combat.tscn`、`MainMenu.tscn`、`Map.tscn` 抽回 scene，`.gd` 只保留邏輯綁定

### S2. 真機驗收未通過（Android 啟動異常）
- 「adb install/launch closed，截圖不是 COTIW」表示 APK 安裝後 **應用未停在自己畫面**，可能是：
  - 啟動即崩、或被系統踢回 launcher
  - export preset 的 main scene 未正確指向 `Root.tscn`
  - splash / orientation 配置不符 Android
- 違反 CLAUDE.md 鐵律 2「每個 Sprint 結束都要在真機測試」
- **建議**：先抓 `adb logcat -s godot:*` 看崩潰堆疊，再動 UI

### S3. 角色 roster 測試失敗（預期 2、實際 4）
- TestRunner 138/139 通過，唯一紅燈是 roster 數量
- Phase 2C 新增道士／家將後未更新 `expected_roster_count`，或反之 UI 仍只展示 2 個
- **影響**：`NewRunMenu` 的角色 gallery 與資料層不一致，玩家可能看到「選不到的角色」或「測試騙過 CI 但 UI 漏顯」
- **建議**：對齊 `data/characters/` 實際 enabled 數量與測試斷言，並在 `NewRunMenu` 跑一次 visual smoke

---

## 二、UI/UX 體質問題

### U1. 寫死的 1200×700 與螢幕適配風險
- `Combat.gd:557-560` 將背景硬釘 `offset_right = 1200.0`、`offset_bottom = 700.0`
- `MainMenu.gd:140` `_pixel_bg.size = Vector2(1200, 700)`
- `Root.tscn` 多處 `offset_right = 1200.0 / offset_bottom = 700.0`
- **隱憂**：iPhone 15 Pro Max 邏輯解析度比例 ≈ 19.5:9，iPhone SE ≈ 16:9，1200×700 ≈ 1.71:1 介於兩者之間
  - 雖然 `safe` 出現 21 處（MainMenu）、15 處（CombatHudOverlay）顯示有 safe area 處理
  - 但背景與 stage 內容沒有按 viewport 比例縮放，極端尺寸下會出現「黑邊」或「裁切重要 UI」
- **建議**：把 1200×700 收斂成單一 `STAGE_SIZE` 常數，並改用 `anchor_*` + `keep_aspect` viewport stretch

### U2. Hand.gd 取消鍵位置寫死在畫面正中
- `Hand.gd:336`：`_cancel_target_button.position = Vector2(520, 250)`
- 在 1200×700 大致是中偏左上，但**指向流程中玩家手指應該在下方手牌區**
- 取消鍵離手太遠，且若橫握手機左手持機，520px 可能被左手遮擋
- **建議**：改放右下手牌區附近，或用 `anchor_bottom = 1.0` 跟隨手牌列

### U3. Combat toast 位置可能蓋住戰鬥資訊
- `Combat.gd:637-639`：toast `position = Vector2(400, 300)`、`size = Vector2(400, 50)`、`font_size = 30`
- 落點是畫面正中心，會蓋住敵人與牌面互動
- **建議**：移到上方或下方非互動帶，並加入淡出與佇列管理（避免多 toast 疊壓）

### U4. 字級沒有走 design token
- 大量 `add_theme_font_size_override("font_size", 數字)` 散落各處：
  - `MainMenu.gd`：2 處
  - `NewRunMenu.gd`：5 處（13、14、16）
  - `CombatHudOverlay.gd`：7 處（12、15、22、52）
  - `Hand.gd:332`：26
  - `TouchFeedback.gd`：18、25
- `CotiwUiTheme.gd` 已經有 `get_typography_size("h2"/"caption"/"micro")`，但只在 `RewardOverlay.gd` 與 `CotiwUiTheme.gd` 內部被呼叫
- **影響**：字級風格漂移、i18n 換語系（PRD M2 要求繁中／簡中／英文）時無法統一縮放
- **建議**：所有 `font_size = 數字` 改走 `COTIW_UI_THEME.get_typography_size(token, fallback)`

### U5. CanvasLayer 與 z_index 散亂
- `MainMenu.gd` 3 個 CanvasLayer、4 處 z_index
- `Map.gd` 10 處 layer_、4 處 z_index
- `TouchFeedback.gd` 4 個 CanvasLayer
- 層級沒有集中文件化，後續疊 overlay（reward、shop、touch feedback）時極易出現「覆蓋優先順序錯誤」
- **建議**：在 `CotiwUiTheme.gd` 加 `LAYER_*` 常數（BG / WORLD / HUD / OVERLAY / TOAST / DEBUG），全專案統一引用

---

## 三、觸控與 Mobile-First 檢核

| 項目 | 結果 | 備註 |
|---|---|---|
| 長按詳情 | ✅ | `Card.gd` 5 處 long_press、`Hand.gd` 2 處、`TouchFeedback.gd` 14 處 |
| 拖曳出卡 | ⚠️ 未在掃描證據中明確看到 drag handler | 需驗證 Hand.gd 拖曳熱區 |
| 取消鍵尺寸 | ✅ 160×54（`Hand.gd:330`） | 高度 54px 約合 44pt 觸控最小值，OK |
| 主選單按鈕 | ✅ 320×112（`CotiwUiTheme.gd:217`） | 大尺寸對拇指友善 |
| safe area | ✅ MainMenu 21、CombatHudOverlay 15 | 但 Combat.gd / Hand.gd / Map.gd 出現 0 次，瀏海機可能踩到 |
| mouse_filter | ✅ 散落各處 | 但建議集中文件化各層 PASS/STOP/IGNORE 策略 |

**主要 gap**：`Combat.gd`、`Hand.gd`、`Map.gd` 沒有看到 safe area 處理，戰鬥場與地圖在 iPhone 14+ 瀏海／動態島下會踩到。

---

## 四、待補測試

1. **iPhone SE（小螢幕極端）**：1200×700 stage 內容是否能完整顯示
2. **iPhone 15 Pro Max（瀏海／動態島）**：Combat / Map / Hand 是否避開瀏海
3. **Android 啟動黑屏／崩潰**：抓 logcat 釐清 S2
4. **角色選擇 → 進戰鬥全鏈路**：roster 4 個角色都能從 NewRunMenu 一路走到 Combat
5. **多 toast 連發**：Combat toast 是否會疊壓

---

## 五、優先級總結

| 優先 | 項目 | 預估工時 |
|---|---|---|
| P0 | S2 Android 啟動修復 | 0.5–1 天 |
| P0 | S3 roster 4 角色對齊 | 0.5 天 |
| P1 | S1 場景檔案抽出（先 Combat + MainMenu） | 2–3 天 |
| P1 | U2 取消鍵位置 + U3 toast 位置 | 0.5 天 |
| P2 | U1 viewport 縮放統一 | 1–2 天 |
| P2 | U4 字級走 token | 1 天 |
| P3 | U5 CanvasLayer 集中常數 | 0.5 天 |

---

**結論**：Phase 2C 邏輯擴張（道士／家將／多神請神）走在 PRD 軌道上，但 UI 層**真機驗收與場景化欠帳**正在累積。建議下個 Sprint 先還 P0+P1 的技術債，再推 Phase 3 美術替換，避免在 placeholder 階段把寫死座標固化成正式 layout。
