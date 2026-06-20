# 鎮島錄 UI/UX 嚴格 QA + E2E 測試報告

**日期**：2026-06-11 11:55 CST  
**測試者角色**：UI/UX 設計師 / QA reviewer  
**專案路徑**：`/Users/crimson/Developer/COTIW`  
**引擎**：Godot `4.6.1.stable.official.14d19694e`  
**測試範圍**：啟動、主選單、角色/看板娘/收藏、新開局、神示供桌、遶境地圖、戰鬥 HUD/手牌/Toast/合符 FX、獎勵、商店、歇腳、事件、牌庫、結算。

---

## 1. 結論

目前這版已經不像早期那種「把漂亮東西貼上去」的粗糙狀態；它已經有一套可被測試保護的 UI 系統。  
**嚴格測試結論：主流程可玩、E2E 乾淨、三解析度 UI audit 最終重跑為 0 FAIL / 0 WARN。**

但作為商業 mobile roguelike card game，它還有幾個美學與產品層級問題：

1. **角色面板在 4:3 / tablet 比例有可讀性壓迫**：不是功能壞，是畫面氣質不夠從容。
2. **戰鬥畫面的資訊階層仍偏吵**：神力、銀兩、HP、護身、預兆、請神、手牌、結束回合同時爭焦點。
3. **QA driver 存在啟動畫面競態風險**：第一次 1200×900 audit 曾在主選單尚未完全 shown 時進站，產生 transient false fail；重跑消失。
4. **Artifact fallback 仍有 export warning**：商店測試會載入 `external/sprites/artifacts/artifact_white.png`，Godot 警告「Loaded resource as image file, this will not work on export」。這是 P2 工程風險，不是當場 UI 破圖。
5. **Godot exit leak/resource warnings 持續存在**：所有測試通過，但退出時仍有 ObjectDB/resources in use；短期可接受，長期會污染 CI 訊號。

---

## 2. 實測結果

### 2.1 基線

| 項目 | 結果 |
|---|---:|
| `git status --short` | working tree 有多個 UI/asset/qa 變更，未提交 |
| Godot 版本 | `4.6.1.stable.official.14d19694e` |
| main scene | `res://scenes/Root.tscn` |
| viewport | `1200×700` |
| stretch | `canvas_items + expand` |
| orientation | `landscape` |
| autoload | `Signals`, `Global`, `Responsive` |

### 2.2 Headless test suite

指令：

```bash
godot --headless res://tests/TestRunner.tscn
```

結果：

| 測試 | 結果 |
|---|---:|
| 單元 + 整合測試 | **167 / 167 PASS** |
| Exit code | `0` |
| 主要殘留警告 | `CharacterPanel.gd:46` / `MascotSelector.gd:48` non-equal opposite anchors size override；exit leak/resource warnings |

### 2.3 E2E runtime flow

指令：

```bash
godot --path . res://qa/uiux/e2e_driver.tscn
```

結果：

| 指標 | 結果 |
|---|---:|
| E2E assertions | **21 PASS / 0 FAIL** |
| 截圖輸出 | `qa/uiux/e2e/01_main_menu.png` ~ `11_codex_deities.png` |
| 覆蓋 | 主畫面 → 起手選項 → 地圖 → 戰鬥 → 手牌 → Toast → 合符 FX → 卡框 v2 → 收藏三分頁 |

### 2.4 三解析度 UI/UX audit

指令：

```bash
UIUX_RES=1244x700 godot --path . res://qa/uiux/uiux_audit_driver.tscn
UIUX_RES=1515x700 godot --path . res://qa/uiux/uiux_audit_driver.tscn
UIUX_RES=1200x900 godot --path . res://qa/uiux/uiux_audit_driver.tscn
```

最終有效結果：

| 解析度 | 模擬 | PASS | WARN | FAIL | screenshots |
|---|---|---:|---:|---:|---:|
| 1244×700 | 16:9 Android landscape | 322 | 0 | 0 | 22 |
| 1515×700 | 19.5:9 iPhone landscape | 322 | 0 | 0 | 22 |
| 1200×900 | 4:3 tablet | 320 | 0 | 0 | 22 |

備註：第一次 1200×900 曾出現 `CharacterPanel 無全幅 STOP 輸入遮罩`，但同輪 log 顯示 `main menu shown` 晚於 `01_main_menu` 站；重跑為 0 FAIL。判定為 **QA driver 啟動等待競態 / transient false positive**，不是可穩定重現的產品缺陷。

---

## 3. 嚴格 UX 發現

### P1 — 現在不必停版，但下一輪應優先處理

#### P1-1｜QA driver 啟動競態：1200×900 首次 audit 可出現假失敗

- **現象**：第一次 1200×900 audit：`01_main_menu 可互動按鈕 0 顆`，`02_character_panel` 被判無全幅 STOP 遮罩。
- **佐證**：同輪 log 顯示 `[啟動] main menu shown` 出現在 `01_main_menu` 截圖之後。
- **重跑**：`1200×900` 重跑後 `PASS=320 WARN=0 FAIL=0`。
- **判定**：測試工具競態，不是玩家穩定可見問題。
- **修法**：`uiux_audit_driver.gd` 不應固定 `await _frames(70)`；應等待 TitleScreen/MainMenu ready signal 或輪詢 `MainMenu.visible && 可互動按鈕數 > 0` 後再進站。

#### P1-2｜戰鬥畫面焦點過多，資訊層級還不夠狠

戰鬥手牌截圖可見：

- 左上返回、地圖、銀兩、HP、回合、請神、消耗品、三個黑槽、角色狀態、敵人煞盾、左下神力、手牌、右下結束回合，同時使用高亮邊框與高飽和色。
- 功能上都能按；美學上像廟口很熱鬧，但還沒像「高級手遊」那樣有主次。
- `結束回合` 按鈕觸控尺寸合格，但視覺重量與手牌/神力盤爭搶焦點。

**設計建議**：建立戰鬥 UI 的三層閱讀秩序：

1. **每回合必讀**：HP / 敵意圖 / 神力 / 結束回合。
2. **本回合操作**：手牌 / 消耗品 / 合符可能性。
3. **低頻資訊**：銀兩、牌庫四區、請神進度、地圖/暫停。

把低頻資訊降亮度、縮對比、延後動效；不要每個東西都像在喊「看我」。吵，不等於熱鬧；熱鬧要有鼓點。

#### P1-3｜角色面板 tablet 比例可用，但視覺不夠從容

- 1515×700 角色面板：整體正確，有暗底、返回、四卡清楚。
- 1200×900 tablet：首輪截圖若落在主畫面可看到主選單與大角色被拉高，視覺焦點過度偏左；重跑後功能通過，但 tablet layout 應有專屬排版策略。

**設計建議**：tablet 不要只是放大橫向手機 layout。改成「上方 tab / 中央 2×2 卡格 / 右側角色詳情」會更像產品，而不是把手機畫面塞進 iPad。

### P2 — 工程/品質風險

#### P2-1｜Artifact fallback 使用 external PNG 產生 export warning

- **警告**：`Loaded resource as image file, this will not work on export: res://external/sprites/artifacts/artifact_white.png`
- **呼叫鏈**：`CardArtRegistry.resolve_artifact_texture()` → `FileLoader.load_texture()` → `ShopOverlay.populate_shop()`
- **來源**：`autoload/Global.gd:664,673` 與 `data/prototype/ArtifactData.gd:6` 仍指向 `external/sprites/artifacts/artifact_white.png`。

**修法**：把 `artifact_white` 納入 `CardArtRegistry.ARTIFACTS` preload，或改用正式 `assets/generated/artifacts_v3/` fallback；不要在 export-critical UI 中依賴 external file loading。

#### P2-2｜Anchor warning 仍在污染 QA log

- `CharacterPanel.gd:46`
- `MascotSelector.gd:48`

這類警告不醜到玩家臉上，但會讓真正警告變得不醒目。美學上也是雜訊；雜訊就是醜。

**修法**：避免 `_ready()` 內直接 size 給 non-equal opposite anchors 的 Control；改為 `set_deferred()`、統一透過 `UiMaskFitter` / `_relayout()`，或先設定 anchors 再設 size。

#### P2-3｜Exit leak/resource warnings 長期會傷 CI 信任度

- `ObjectDB instances leaked at exit`
- `resources still in use at exit`

目前所有測試 exit code 仍為 0；不阻塞。但如果未來 CI 需要嚴格 parse log，這會變成噪音。

---

## 4. 優化方案 / Roadmap

### 第 1 優先：把 QA 工具變成可信守門員（0.5 天）

1. `uiux_audit_driver.gd` 加 `wait_for_main_menu_ready()`：
   - 等 `TitleScreen/MainMenu` visible。
   - 等可互動按鈕數 ≥ 10。
   - 或等 `[啟動] main menu shown` 對應 signal，而不是固定 70 frames。
2. Audit driver 若 `_fail > 0` 應 `quit(1)`；目前即使有 FAIL 仍 exit 0，這不配叫守門。
3. 把 1244×700 / 1515×700 / 1200×900 三解析度加入 CI 或 pre-release script。

### 第 2 優先：清掉 export warning 與 anchor warning（0.5–1 天）

1. `artifact_white` 走 imported/preloaded resource，不走 external raw file。
2. 修 `CharacterPanel` / `MascotSelector` `_ready()` size override warning。
3. 測試：`godot --headless res://tests/TestRunner.tscn` + 三解析度 audit，log 不應出現 export-critical warning。

### 第 3 優先：戰鬥 HUD 視覺降噪（1–2 天）

1. 低頻資訊降權：銀兩、牌庫四區、請神槽 idle 狀態透明度降低。
2. 每回合必讀資訊建立固定視線路徑：敵意圖 → 神力 → 可出牌 → 結束回合。
3. 只讓「本回合可操作 / 變化中」的元素發光；靜態資源不要全部發亮。
4. 戰鬥 toast 目前位置可接受，但需確保不與請神槽 / 敵人 status 疊焦點。

### 第 4 優先：tablet 專屬 layout（1–2 天）

1. `Responsive.is_tablet()` 時不要只 `ts_scale=1.15`。
2. 角色、收藏、新開局三個大面板可採 2-column / 2×2 card grid，保留呼吸空間。
3. 新增 visual contract：1200×900 下主面板核心內容不可只貼手機橫向排版。

### 第 5 優先：美術一致性二輪（設計 + asset pass）

1. 統一 HUD icon 的線寬、亮度、底框材質。
2. 卡牌手牌縮放狀態下，白色敘述框仍略搶眼；可改成更暖的符紙底，不要像空白表單。
3. 角色立繪與 combat sprite 的尺度語言再統一：同一角色在主選單、角色面板、戰鬥內的「身份感」要連續。

---

## 5. 證據路徑

- E2E 截圖：`qa/uiux/e2e/`
- 三解析度 audit 截圖：`qa/uiux/uiux_audit/1244x700/`、`1515x700/`、`1200x900/`
- 最新 1200×900 重跑 log：`/tmp/uiux_1200x900_rerun.log`
- 既有完整 QA 報告：`qa/uiux/UIUX_STRICT_QA_2026-06-10.md`

---

## 6. 最終評語

這版 UI 已經通過功能層 QA；接下來要打的是「商業產品感」。  
現在的問題不是不美，而是**太多東西同時想美**。  
把視覺權力收回來：主次、節奏、呼吸、沉默。美不是把每個元件都鍍金；美是知道哪一個元件此刻應該閉嘴。
