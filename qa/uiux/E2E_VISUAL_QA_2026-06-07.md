# 鎮島錄 COTIW — 實機 E2E / 視覺 QA 報告（2026-06-07）

## 方法
- **非 headless 實際渲染**（OpenGL API 4.1 Metal — Apple M4 Pro），1280×720。
- `qa/uiux/e2e_driver.tscn`（+ `e2e_driver.gd`）以遊戲 API + **真實 UI signal** 驅動全流程，每階段存 viewport 截圖 + console 斷言。
- **真實導航路徑**（非 mock）：主畫面 → `start_run` → 起手選項（emit `DialogueOption.dialogue_option_clicked`）→ 遶境地圖 `show_map()` → 點「戰」節點（`ActionGenerator.generate_visit_location`）→ `map_location_selected` → 戰鬥 → 輪詢等手牌抽出 → `show_combat_toast`。

## 結果：**14 / 14 斷言通過**
| # | 斷言 | 結果 |
|---|---|---|
| 1 | Root 載入（主畫面） | ✅ |
| 2 | `start_run` → `is_run` | ✅ |
| 3 | 乩童出戰神明 = 虎爺（loadout 解析） | ✅ |
| 4 | 遶境地圖節點數 = 52 | ✅ |
| 5 | 地圖含鎮煞大醮（BOSS） | ✅ |
| 6 | 節點帶遶境路線 flavor | ✅ |
| 7 | 起手選項（RunStartOptions）顯示中 | ✅ |
| 8 | 選起手選項後 → 遶境地圖顯示 | ✅ |
| 9 | 找到可進入的『戰』節點（location_1_3） | ✅ |
| 10 | 戰鬥生成敵人 = 1 | ✅ |
| 11 | 牌庫/手牌就緒 | ✅ |
| 12 | 戰鬥畫面顯示中 | ✅ |
| 13 | 敵人頭頂煞盾指示（破煞 UI）存在 | ✅ |
| 14 | 玩家回合手牌已抽出 | ✅ |

## 截圖（`qa/uiux/e2e/`）
| 檔 | 內容 |
|---|---|
| 01_main_menu | 乩童立繪 + 廟宇 BG + 看板娘對話泡 + 頂部 HUD + 繼續鈕 |
| 02_run_start_boon | 起手選項「選一個起手選項 / 願擲筊問神，得吉凶起手」4 選項 |
| 03_pilgrimage_map | 遶境地圖：戰節點格陣 + 頂部大醮 BOSS + 神力 dial |
| 04_combat_enter | 進戰首幀（行動處理中，手牌尚未抽出） |
| 05_combat_hand | 我方回合：乩童 vs 昌-煞圈敵人、底部符令手牌、結束回合鈕 |
| 06_combat_toast | combat toast「合符！」顯示於頂部 lane（底部手牌仍完整可見） |

## UIQA 修正 — 實機視覺確認 ✅
- **Combat toast lane**：「合符！」顯示在 safe-area **頂部 lane**（HUD 下緣、水平置中），**不在畫面死中央、不遮底部手牌**。05↔06 對比：toast 出現時底部卡牌完整可見 → **toast-lane 修正在實機生效**。
- **分區不互遮**：結束回合鈕固定右下、HUD 固定頂部、神力 dial 左下，分區正確。
- **破煞 UI**：敵人以**綠色法陣圈**呈現煞盾（on-identity）。
- **產品辨識度**：戰鬥畫面（廟宇牌坊 BG + 乩童 vs 煞圈敵人 + 符令卡）30 秒內可辨識為「台灣民俗鎮煞儀式」，非泛用 deckbuilder。

## ⚠️ 實機新發現觀察
1. **【已追查 + 已修正】大型八卦盤壓到乩童立繪** — 追查確認該大八卦盤 = **玩家「護盾(Block)」狀態 icon**（`scenes/combatants/Player.tscn` 的 `Visible/Block` Sprite2D，runtime 由 `BaseCombatant.gd` 指派 `block_bagua.svg`）。
   - **根因**：`block_bagua.svg` 原生 render **1024×1024**，但場景 Block 節點 `scale=0.25` 是為 ~256px 素材設計 → 實際顯示 **256px**（4× 過大），蓋住乩童。敵人 Block 同源、同樣過大。
   - **修正**：`block_bagua.svg.import` 的 `svg/scale` 由 `1.0` → `0.25`（原生降為 256px）。`BlockAmount` 數字為 Block 子節點隨之等比，數值仍正確；狀態列 icon 為 `TextureRect`（顯式尺寸）不受影響。
   - **驗證**：dump 由 `256px → 64px`；實機截圖（05）乩童完整露出、不再被遮；headless 161/161、E2E 14/14 全綠。**單一 tracked 變更**：`block_bagua.svg.import`。
2. **遶境地圖背景為大片白灰面板** — 功能完整（戰節點 + 大醮可達），但缺「進香遶境」氛圍；屬美術 polish。
3. **進戰首幀顯示「行動處理中」** — combat 與 visit-location 動作鏈視覺重疊，手牌約 0.x 秒後抽出，屬正常時序（非 bug）。

## 結論
四支柱戰鬥（破煞煞圈 / 合符符令卡 / 請神 / 班底乩童）+ 遶境地圖 + 起手選項，在**實機渲染**下全鏈路**可玩、可導航、可進戰**，14/14 斷言綠燈，**UIQA toast-lane 修正肉眼確認生效**。最值得後續處理的是觀察 #1（八卦盤遮擋）。
