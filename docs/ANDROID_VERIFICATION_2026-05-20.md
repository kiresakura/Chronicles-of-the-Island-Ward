# Android 實機驗收報告 — 2026-05-20

> **裝置**：Redmi 25080RABDG（Android 物理 1280×2772、實際橫向 2772×1280、520dpi）
> **APK**：`build/android/cotiw.apk` 81MB（debug-signed），commit `e8f721d` 之後重 build
> **截圖**：`build/android/shots_redmi/01..10.png`
> **耗時**：≈ 25 min（含解 BlueStacks Vulkan 黑屏 + qemu AVD config 問題）

---

## TL;DR

✅ **核心流程跑通**：Splash → MainMenu → 起手選項 → 起手卡選擇 → 地圖 → 戰鬥 → end turn → 出牌 → 擊殺敵人
✅ **STR 戰鬥邏輯完整**：回合制、敵人 intent、出牌 drag-to-target、能量扣抵、卡牌洗牌、HP/block/vulnerable 狀態都 OK
✅ **效能**：FPS **120**（device cap），Vulkan/Forward Mobile 在 Redmi GPU 跑得很順
🔴 **重大美術缺口**：戰鬥所有角色/卡圖/敵人/玩家頭像 = STR 預設 Godot icon **占位完全沒被換掉**
🔴 **大量英文文案**：卡牌名、效果敘述、狀態名仍是 STR 原文（"Basic Attack" / "Apply 1 weakness"…）— 中文翻譯沒套到 runtime
🟡 **layout bug**：RunStartOptions overlay 沒套 SafeFit，4 選項擠在左下角

---

## 1. 完整流程截圖逐張對照

| # | 檔案 | 階段 | 通過 | 問題 |
|---|---|---|---|---|
| 01 | `01_after_5s.png` | SplashScreen 載入完成 → MainMenu | ✅ | 廟宇向量背景、5 燈籠、神主牌位、HUD（香火 250/Lv1 0/3/元寶 0）、6 utility icons、橘紅 CTA「繼續」全部正確；FPS 120 |
| 02 | `02_tap_continue.png` | 第一次 tap 繼續 (1386,960) | ❌ | y 座標太高，未命中（畫面同 01）|
| 03 | `03_tap_continue_retry.png` | tap 繼續 (1386,1140) | ⚠️ | 進到 RunStartOptions overlay；**但 4 選項擠在左下角**，沒套 SafeFit |
| 04 | `04_starter_chosen.png` | 選 option 2「選 1 普通卡 + 元神 -10」| ⚠️ | 進到 3 選 1 卡片獎勵 overlay；卡片框 layout、文字 overflow、art slot 是 Godot 占位、文案部份英文 |
| 05 | `05_after_card_pick.png` | 卡片選完 → 地圖 | ⚠️ | 5×6 STR-style 層級地圖；節點全是占位圓盤（非向量 icon）；cyan 高亮起手節點 OK |
| 06 | `06_map_node_tapped.png` | tap 中間節點 → 進戰鬥 | 🔴 | Combat 進入，3 敵人（70/24/18 HP）+ intent 4×2 / 3 + 玩家 5 卡手 + 結束回合鈕；**敵人/玩家/卡圖全 Godot 占位**；卡牌名英文「Basic Attack」|
| 07 | `07_end_turn.png` | 第一次 tap 結束回合 (2300,1140) | ❌ | 未命中（畫面同 06）|
| 08 | `08_end_turn_retry.png` | tap 結束回合 (2480,1210) | ✅ | **敵人攻擊回合執行**：HP 70→59、HUD 變紅警示、手牌洗牌 5 張新卡、左敵 vulnerable 12 stack 顯示、玩家 block 8 顯示 |
| 09 | `09_card_played.png` | drag card「Attack 25 dam」往敵人 | ✅ | 進入「**選擇目標**」mode；中敵首次顯示中文名「**山豬精**」(24/24)；其他敵人未顯示名字 |
| 10 | `10_attack_landed.png` | tap 山豬精完成出牌 | ✅ | 山豬精死亡消失；手牌 5→4；energy 1 扣；戰鬥邏輯完整跑通 |

---

## 2. 渲染／效能（綠燈）

- ✅ **Vulkan Forward Mobile** 在 Redmi GPU 完整工作（vs BlueStacks Apple Silicon Vulkan 黑屏）
- ✅ **FPS 120** 穩定（device cap，無下降）
- ✅ **VectorCombatBackdrop**：金色四角欞框、頂底 HUD chrome 在實機與 headless 一致
- ✅ **MainMenu 向量重 build**：5 燈籠、神主牌位、香爐、供桌、3 大門柱、飄雲、紅色廟會背景 — 全部完整渲染
- ✅ **CotiwUiTheme**：「繼續」橘紅 CTA、結束回合紅按鈕、HUD 標籤排版都對
- ✅ **SafeFit**（MainMenu/SplashScreen）：實機橫向 2772×1280（AR 2.166）內版面置中正確
- ✅ **`exported` feature tag**：FileLoader 讀取 `external/data/**/*.json` 成功（卡牌/敵人資料有載；否則戰鬥連敵人都沒得放）

---

## 3. 🔴 P0 — 必修阻塞

### 3.1 戰鬥內容**全占位**（無 1 張 COTIW 自家美術上場）

**症狀**：
- 玩家頭像、3 個敵人 sprite、5 張卡片 art slot — 全部都是 STR 預設 Godot 機器人 icon
- COTIW 已有 40 張 AI 美術（乩童立繪/11 卡圖/6 敵人/4 場景）放在 `assets/generated/`，但戰鬥中**完全沒被引用**

**根因**（推測）：
- STR 原版資料用 `placeholder` 路徑，COTIW data JSON 應該已覆寫，但 runtime 沒接到生成的美術；可能：
  - (a) CardData / EnemyData JSON 的 `art_path` 還指向 STR 原路徑或 placeholder
  - (b) `external/data/**/*.json` 對應的 `assets/generated/**` 路徑沒對齊
  - (c) 場景 .tres 是 STR 原版，玩家/敵人 sprite 還寫死在場景內

**應對**：下一個 sprint 主項目 — 「**接線 runtime 美術**」（卡圖、敵人、玩家、地圖節點 icon）。先 audit `assets/generated/` vs JSON `art_path` vs scene `texture_2d` 三者對齊。

---

### 3.2 文案全英文（STR 原文沒翻）

**症狀**：
- 卡牌名「Basic Attack / Basic Skill / Basic Block」（應「基礎攻擊／基礎技能／基礎格擋」）
- 卡片效果敘述「Apply 1 weaknesss」（多打一個 s 是 typo）/「Attack for 25 dam, can only be playe...」
- 多數狀態 buff/debuff 也應該是英文
- 反例：MainMenu「香火/元寶/Lv」、Combat「選擇目標／山豬精／結束回合」是中文，**所以 i18n 系統有運作，但卡牌/狀態的 JSON 字串沒翻**

**應對**：
- audit 所有 card_data / status_data / enemy_data JSON 的中英文欄位
- 加 i18n key 對應表（建議用 `tr()` + `translations.csv`），把 STR 原 hardcoded 字串砍掉
- 補測試：CardData/StatusData 所有 entry 必須有 zh-TW 欄位

---

### 3.3 HP 雙顯（玩家 HP 兩個位置不同步）

**症狀**：
- top HUD 顯示玩家 HP（59/70 紅色警示色 OK）
- 左下小頭像旁邊顯示 「10/10」 — 完全對不上
- 戰鬥中央大 Godot icon 旁的 HP bar 是 59/70（對）

**根因**（推測）：左下小頭像可能是 Aida HUD 的 player marker，HP label 沒接 player 真實 HP signal。

**應對**：找左下小頭像對應節點，把 HP label 接 `Run.player.hp_changed` signal，或乾脆刪掉重複顯示。

---

### 3.4 RunStartOptions overlay 沒套 SafeFit

**症狀**：4 個起手選項擠在螢幕左下角（佔約 30% 寬度），而非置中在 1200×700 stage 內。

**根因**：Phase 2 (`17d0b00`) RunScreen 整體 SafeFit 但 RunStartOptions 是 STR 的 menu overlay，可能在 RunScreen 之外被 add_child 到 Run.tscn root → 跳過 SafeFit 的祖先縮放。

**應對**：定位 RunStartOptions 的實際父節點，把它移到 SafeFit 之內；或單獨對其 apply SafeFit.bind。

---

## 4. 🟡 P1 — 體感／視覺缺口

### 4.1 地圖節點全占位圓盤
- 戰鬥／精英／事件／休息／商店／Boss 6 種節點都用同一個棕色圓盤
- 應該各自有不同向量 icon（PRD §7.6 / design system 已規劃 6 種）
- 目前無從一眼判讀地圖

### 4.2 敵人名只在 targeting 時顯示
- 「山豬精」label 只有在 drag 卡時才出現
- 平時應該顯示（小字 below sprite），讓玩家認得敵人

### 4.3 卡牌成本 `1` 紅色 badge 蓋住卡名
- 卡片左上角紅底白字「1」（energy cost）位置剛好壓在卡名首字上
- 需要 z-order 或留 padding 給卡名

### 4.4 玩家敵人區雙 marker（top 3 icons + 左下 1 icon + 中央 1 icon）
- 不知 top HUD 3 個 Godot icon 是要呈現「3 神好感」還是「召喚物」還是裝飾
- 太多 Godot 占位 marker 混雜，分不清意義

---

## 5. 🟢 結論

**Phase 1 鐵律驗證**：
- ✅ ① 資料驅動：external JSON 載入正常（`exported` tag 後）
- ✅ ② Mobile-first 直向 → **橫向**（D1 決策）：2772×1280 橫向實機表現正確
- ✅ ③ Fork-first：STR 戰鬥邏輯零改動，所有觀察到的問題都在「視覺層／美術接線／文案」非核心邏輯

**Phase 1 目標「乩童完整跑通一局」進度評估**：
- ⚙️ **底層機制 90%**：STR 引擎、自家 vector chrome、SafeFit、design tokens、test 37/37 全綠
- 🎨 **內容層 30%**：自家美術已生產但 runtime 沒接、文案中文化未完成、地圖 icon 仍占位
- **里程碑**：底層基建完成，可以正式啟動「接線 sprint」把 40 張美術接到 CardData/EnemyData/PlayerSprite + 補中文翻譯。

---

## 6. Sprint 待辦建議（從本驗收推出）

| 優先 | 任務 | 預估 |
|---|---|---|
| P0 | runtime 美術接線：CardData.art / EnemyData.sprite / PlayerSprite 對齊 `assets/generated/` | 1-2 day |
| P0 | i18n 全面盤點 + STR 卡牌/狀態 zh-TW 翻譯（包含 typo "weaknesss"）| 1 day |
| P0 | 玩家 HP 雙顯修正（左下小 marker 接 HP signal 或刪除）| 1 hr |
| P0 | RunStartOptions overlay 套 SafeFit | 1 hr |
| P1 | 地圖節點 6 種 icon 接 vector asset | 0.5 day |
| P1 | 敵人 sprite 旁常駐中文名 label | 0.5 day |
| P1 | 卡牌 energy badge z-order / padding | 15 min |

---

## 7. Android 工具鏈狀態

- ✅ JDK 17（avdmanager 必需）已設 `JAVA_HOME`
- ✅ Android SDK 36.1 google_apis_playstore arm64-v8a image 已裝
- ✅ debug.keystore 自簽（`~/.android/debug.keystore`）
- ✅ Godot Android export template 已驗證可用
- ✅ `export_presets.cfg` Android preset：`custom_features="exported"`、arm64-v8a only、不用 gradle build
- ⚠️ qemu emulator AVD config 還壞掉（指向不存在 android-34 路徑），未修；測試以**實機為主**
- ❌ BlueStacks Apple Silicon：Vulkan→Metal 翻譯 `QueuePresentKHR error 5`，**不可用**

詳細坑點記錄：`QUESTIONS.md` 2026-05-20 L1-L3

---

**END OF REPORT**
