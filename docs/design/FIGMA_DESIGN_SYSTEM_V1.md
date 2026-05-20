# Figma 設計系統 v1 — 對應交付

> **建立日期**：2026-05-20
> **Figma 檔**：[COTIW 鎮島錄 — Design System & Screens v1](https://www.figma.com/design/retvZAsBjHhkGk4mlCvFA3)
> **file_key**：`retvZAsBjHhkGk4mlCvFA3`
> **作者**：憲龍 + Claude（slash command `/figma:figma-use`）

---

## 1. 總覽

| 類別 | 數量 | 備註 |
|---|---:|---|
| Pages | 4 | 01 設計系統 / 02 元件庫 / 03 主畫面 / 04 審計 |
| Variables (tokens) | 40 | 27 色 + 6 spacing + 4 radii + 3 sizes |
| 元件 Components | 12 | 4 buttons + 4 cards + 4 panel/icon |
| 主畫面 Screens | 9 | 全 1200×700 橫向 |
| 地圖節點 icons | 6 | 戰/猛/?/火/店/王 |
| 狀態符號 | 8 | 心/盾/☯/香/元/符/墉/罪 |

---

## 2. Pages 結構

### Page 01：設計系統 / Design System（page id 0:1）
- 色票 6 group × 27 色（廟會主色 / 基底 / 戰鬥語意 / 神色 / 紙襯 / 輔助）
- 字級 ramp（display 48 → micro 16）
- 間距 / 圓角 / 觸控目標視覺示意

### Page 02：元件庫 / Components（page id 1:2）
- 4 按鈕：Primary（起駕 CTA）/ Secondary（陣型）/ Utility（？圓鈕）/ Danger（結束回合）
- 4 卡牌類型：攻擊（平安拜禮）/ 技能（媽祖庇佑）/ 能力（海上慈光）/ 詛咒（業障）
- 6 地圖節點 icons
- 8 狀態符號（含八卦 = energy / 心 = HP / 盾 = block）
- 2 panel chrome variants（lacquer / wood）

### Page 03：主畫面 / Screens（page id 1:3）
9 個畫面（順序對應遊戲流程）：

| # | 名稱 | 重點 | 修補 Android bug |
|---:|---|---|---|
| 01 | Splash 開機 | 鎮島錄金字 + 5 燈籠 + 木簷 + 紅柱 + 載入「燒香啟壇中…」 | — |
| 02 | MainMenu 主畫面 | 神龕中央 + 鎮島神主牌 + 香爐 + 3 香 + 6 utility slots + 起駕 CTA | — |
| 03 | RunStartOptions 起手 | 置中 panel + 4 起手選項橫向列表 + 風險 badge（輕/中/重度） | **P0-4** 修 SafeFit 擠左下 |
| 04 | CardReward 卡牌獎勵 | 「媽祖賜禮」+ 3 張大卡（潮/盾/耳）+ Skip | **P0-1** 卡圖 art slot 規格化 |
| 05 | CharacterSelect 角色 | 3 角色（乩童啟用 / 道士 鎖 / 家將 鎖）+ 神明緣 affinity | — |
| 06 | Combat 戰鬥 | 童 vs 豬鬼蛇 + 5 手牌 + 八卦 energy + 結束回合 | **P0-1/2/3** 全套修 |
| 07 | Map 地圖 | 5×6 STR-style + 6 種節點 icon 顏色區分 + 玩家位置 + 圖例 | — |
| 08 | Jiaobei 擲筊 | 媽祖立繪 + 對話 + 3 筊型（聖/笑/陰）+ 燒金紙重擲 | Gate 1 核心 |
| 09 | Codex 圖鑑 | 神明好感 tab：6 神 grid + 渡化進度 stats（F2P 3 神 ≥ 60 進度）| GDD_05 對齊 |

### Page 04：審計 / Audit（page id 1:4）
- 40/12/9/4/6/8 inventory stats
- 4 台灣文化 motif 支柱（廟宇 / 祈福符號 / 神明系統 / 陣頭）
- Android P0 阻塞 → 設計層修正狀態表

---

## 3. 台灣文化 motif 4 大支柱（用戶選定全 4 個）

### 3.1 廟宇視覺
- **5 燈籠** 懸掛 wood beam 下，金邊紅燈籠 + 燭金 drop shadow
- **2 紅柱** 左右對稱（廟柱 80px 寬，金 stroke）
- **神龕 + 神主牌**：lacquer_black 神龕內中央木紋牌位「鎮島」金字
- **香爐 + 3 香**：底座金頂 wood body，3 根 paper_warm 香 + glowing orange tips
- **金色欞框**：所有 panel 都帶 incense_gold 金邊

### 3.2 祈福符號 = 遊戲機制
- **八卦 ☯ = energy ring**（左下 combat HUD）— 圓形 + 十字 + 中央數字
- **筊杯（紅木 moon shape）**：聖筊（一上一下）/ 笑筊（兩上）/ 陰筊（兩下）
- **平安符 = block 護身**：六角 polygon + 金邊（非圓非方）
- **香 = money（香火）**：基礎貨幣，250 起手
- **元寶 = premium gem**：高階貨幣

### 3.3 神明系統
- 6 神明（媽祖 / 觀音 / 王爺 / 城隍 / 土地 / 虎爺）
- 各自顏色：neon_cyan / spirit_jade / mystic_purple / lacquer_black / warning_orange / danger_crimson
- 好感量化（0-100）+ 渡化進度條
- F2P 結局「眾神眷顧」= 3 神好感 ≥ 60（GDD_05 修正後）

### 3.4 陣頭文化
- 3 主角：**乩童**（媽祖附身，以血肉承神威）/ **道士**（符籙劾召，以法器役鬼神）/ **家將**（八家神將，以兵刃鎮邪祟）
- 各自核心神明緣：乩童 = 媽祖/觀音/王爺，道士 = 三清/城隍/玄天，家將 = 八將/王爺/土地

---

## 4. Variable Collections（Local）

| Collection | Count | Examples |
|---|---:|---|
| COTIW / Colors | 27 | temple_red / festival_red / incense_gold / hp_red / energy_cyan / paper_warm |
| COTIW / Spacing | 6 | xs=8 / sm=12 / md=16 / lg=24 / xl=32 / xxl=48 |
| COTIW / Radii | 4 | sm=10 / md=12 / lg=16 / pill=999 |
| COTIW / Sizes | 3 | touch_min=88 / touch_comfort=96 / cta_height=112 |

對應 `docs/design/design_tokens.json`，可後續 export 為新版 JSON。

---

## 5. 對 Godot 接線下一步建議

### Phase A：i18n 中文化（P0-2）
1. 從 Figma 撈出所有卡牌名 + 效果敘述（已中文）
2. 寫入 `external/data/translations.csv`（key, zh-TW）
3. CardData / StatusData 全部走 `tr()`
4. 移除 STR 原 hardcoded "Basic Attack" / "Apply 1 weaknesss" 等英文

### Phase B：runtime 美術接線（P0-1）
1. 對齊 `assets/generated/40 張` ↔ Figma art slot 色域 ↔ JSON `art_path`
2. CardData：`art_path: "res://assets/generated/cards/平安拜禮_v1.png"`
3. EnemyData：`sprite_path: "res://assets/generated/enemies/山豬精_v1.png"`
4. PlayerSprite：乩童立繪掛 Combat 左側

### Phase C：HUD 雙顯修正（P0-3）
1. 找左下小頭像 HP label 對應節點（Aida HUD 殘留）
2. 連 `Run.player.hp_changed` signal 或刪除
3. 統一以 Combat 中央大 HP bar 為唯一玩家 HP 顯示

### Phase D：RunStartOptions SafeFit（P0-4）
1. 找 RunStartOptions overlay 實際父節點
2. 移入 SafeFit 之內 OR 對其 apply `SafeFit.bind`
3. 4 選項按 Figma 設計橫向佈局（不再左下）

### Phase E：新元件 — 八卦 energy / 6 種地圖節點
1. 八卦 energy ring：取代 STR 原方型 energy slots
2. 6 種節點 icon：取代地圖占位圓盤；CombatMap 走 `node_type` 配對 `icon_*.svg`

---

## 6. 後續 v2 規劃

- 動畫狀態：擲筊投擲動畫（red wood pieces flying + landing）
- 卡牌打出 motion：drag-up + glow + targeting line
- 戰鬥勝利畫面：金幣噴灑 + 神明好感增量 toast
- 渡化動畫：神明降臨光柱 + 諭詞 dialog

---

**END OF FIGMA DESIGN SYSTEM v1**
