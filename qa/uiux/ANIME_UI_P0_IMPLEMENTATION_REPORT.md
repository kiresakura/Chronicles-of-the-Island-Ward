# 鎮島錄 COTIW — 動漫化 UI P0 實作報告（2026-06-07）

> 方向：**Temple Neon Pixel（Q 版廟會像素 × 夜市霓光 × 神壇金漆）**
> 原則：additive / wrapper、不破壞可玩流程、不刪舊素材、無 secrets、繁中、改後跑測試。

---

## 1. 修改摘要

| P0 | 項目 | 狀態 | 做法 |
|---|---|---|---|
| P0-1 | 起手選項「神示供桌」 | ✅ 完成 | RunStartOptions 加供桌背景（取代 debug 紅黑底）+ 四選項改「籤詩/供品牌」（紙金卡面、≥88 觸控、深字可讀） |
| P0-2 | 遶境地圖背景 v6 | ✅ 背景完成 / ⚠️ 節點 icon 留待 | 換 map_bg_v6（島嶼進香路）+ 移除不透明灰板（修一個跨畫面背景滲入的疊層 bug） |
| P0-3 | 卡牌框 v2 | ✅ 素材 + opt-in + 預覽 | 5 稀有度 SVG（符印費角/大插圖窗/職業色）+ CotiwUiTheme opt-in getter（未動 live Card，保護測試） |
| P0-4 | 合符 FX | ✅ 完成 | FuheFX helper（CanvasLayer+Tween）：符飛合金光爆 + 漫畫「合符！」，節流、~0.6s、接 Hand.merge_cards |

## 2. 生成工具使用情況

- **Recraft**（recraftv3 / digital_illustration / **pixel_art**）：供桌背景、遶境地圖、合符 burst —— **可用 ✓**（多輪挑選，候選存 `qa/uiux/anime_p0/*_cand*.webp`）。
- **PIL**：合符漫畫字（NotoSansTC 渲染）、卡框 v2 SVG 程式產生、burst 亮度去底、before/after montage —— **可用 ✓**。
- **NBP / PixelLab / Gemini**：本輪未使用。
- **SVG**：卡框 v2（向量、縮放清晰）。

## 3. 新增素材清單

```
assets/generated/pixellab/run_start_offering_bg_v1.png   神示供桌（Recraft）
assets/generated/pixellab/map_bg_v6.png                  遶境島嶼進香路（Recraft）
assets/generated/fx/fuhe_burst_v1.png                    合符金光符爆（Recraft + PIL 去底）
assets/generated/fx/fuhe_manga_text_v1.png               漫畫「合符！」（PIL/NotoSansTC）
assets/ui/frames_v2/ui_frame_card_common_anime.svg       共通卡框
assets/ui/frames_v2/ui_frame_card_uncommon_anime.svg     進階卡框（青藍靈光）
assets/ui/frames_v2/ui_frame_card_rare_anime.svg         稀有卡框（金箔紫氣）
assets/ui/frames_v2/ui_frame_card_boss_anime.svg         神威卡框（黑紅神門金）
assets/ui/frames_v2/ui_frame_card_curse_anime.svg        咒煞卡框（暗紫破符）
```
舊素材一律保留（map_bg_v5、frames/ 舊框皆未刪）。

## 4. 修改檔案清單（tracked）

```
scripts/ui/RunStartOptions.gd     +供桌 chrome（_apply_offering_chrome）+籤詩卡樣式（_apply_offering_card_style）
scripts/ui/Map.gd                 map_bg_v6 子節點承載 + 灰板透明（_apply_pilgrimage_backdrop）
scripts/ui/Hand.gd                merge_cards 接 FuheFX.play + _merge_fx_position
scripts/ui/fx/FuheFX.gd           （新）合符 FX helper：CanvasLayer + TextureRect + Tween + 節流
scripts/ui/theme/CotiwUiTheme.gd  卡框 v2 opt-in：CARD_FRAME_V2_BY_RARITY + get_card_frame_v2_path()
qa/uiux/e2e_driver.gd             （qa/，不入版控）截圖驅動擴充：合符 FX + 卡框預覽
```

## 5. before / after 截圖

- **after**（本輪產物）：
  - `qa/uiux/anime_p0/02_run_start_after.png`（神示供桌）
  - `qa/uiux/anime_p0/03_map_after.png`（遶境地圖 v6）
  - `qa/uiux/anime_p0/04_combat_after.png`（戰鬥）
  - `qa/uiux/anime_p0/05_fuhe_fx_after.png`（合符 FX）
  - `qa/uiux/anime_p0/06_card_frames_v2_after.png`（卡框 v2 五稀有度）
  - `qa/uiux/anime_p0/anime_p0_after_montage.png`（四宮格 montage）
- **before**：文字化於 `qa/uiux/ANIME_STYLE_UI_AUDIT_2026-06-07.md` §3（起手選項=debug overlay、地圖=白灰面板、合符=純文字）。舊 e2e 截圖已被本輪新截圖取代。

## 6. 測試命令與結果

| 命令 | 結果 |
|---|---|
| `godot --headless --import` | ✅ 無 SCRIPT ERROR；新素材/FuheFX 皆匯入 |
| `godot --headless res://tests/TestRunner.tscn` | ✅ **161 / 161 通過**（零回歸） |
| 實機 E2E（`qa/uiux/e2e_driver.tscn`，非 headless 渲染） | 14/15 斷言；唯一 FAIL=「手牌抽出」輪詢競態（async 抽牌時序，非回歸；合符以注入卡驗證成功） |

## 7. 未完成項目與原因

1. **P0-2 節點 icon 重繪**（6 類 Q 版地標：戰/事/商/休/菁/Boss）：背景已換、灰板已除，但節點仍是舊三角 icon。屬 6+ 張素材 + 多狀態（reachable/visited/locked）批次，留下一輪。
2. **P0-3 卡框 v2 接入 live Card**：目前為 opt-in getter + 預覽板；未改 `Card.gd`，以**保護 161 測試**與整條卡牌鏈。接入需加 opt-in flag + Gallery 正式預覽。
3. **P1 四角色 cohort preview**：本輪未做（時間/範圍）。
4. **合符 FX 與既有 toast 並存**：目前同時出現 toast「合符！」與 FX 漫畫字，可擇一（建議保留 FX、弱化 toast）。

## 8. 後續建議

1. 節點 icon 批次（6 類 × 3 狀態）+ 接 `MAP_NODE_BY_LOCATION_TYPE`，並讓節點貼合島嶼路線。
2. `Card.gd` 加 `use_frame_v2` opt-in → 接 `get_card_frame_v2_path()`，UIComponentGallery 正式預覽五稀有度。
3. 四角色 cohort normalization（同畫布/腳線/描邊/光源）→ 只生 preview，不動正式鏈。
4. 敵人 sprite Q 版重繪（清楚 silhouette、厚描邊）。
5. RunStartOptions 再加：角色半身/神明小像在側 + 筊杯落地金光動畫。
6. 主選單活動 banner（右側「限時擲筊」）實體化。

---

## 附錄：P1 五項跟進（2026-06-07，續）

| # | 項目 | 狀態 | 做法 |
|---|---|---|---|
| 1 | 節點 icon 批次 | ✅ | 6 張 v2 SVG 地標 badge（戰=紅符令/事=籤筒/商=古錢/休=香爐/菁=虎爪/Boss=神門）+ repoint `MAP_NODE_BY_LOCATION_TYPE`；舊 icon 保留。節點仍走生成器格狀路線（未逐像素貼合 bg 道路，留後續）。 |
| 2 | Card v2 接入 + Gallery | ✅ | `CotiwUiTheme.use_card_frame_v2` 全域 opt-in（live 預設 false）+ `get_active_card_frame_path()`，Card.gd 統一走它；Gallery `_ready` 開旗標 + 加 v2 卡框預覽列。戰鬥手牌示範用 v2（卡圖不透明→框主要呈現為金邊；完整框見預覽板/Gallery）。 |
| 3 | 四角色 cohort preview | ✅ 只 preview | `assets/generated/recraft/anime_cohort_preview_v1/montage.png`（乩童/鸞女/道士/家將同畫布）。**未動正式角色鏈**。 |
| 4 | 敵人 Q 版重繪 | ✅（先做山豬精） | `enemy_mountain_boar.png` 重生為 Q 版山豬精（Recraft + remove_background 去底），舊圖備份 `qa/uiux/backups/`。其餘敵人留批次。 |
| 5 | 供桌側邊角色 + 筊杯金光 | ✅ | RunStartOptions 加乩童立繪 presenter（右側「你的起手命格」）+ 神示金光脈動（供桌出現時播一次、自我清理）。 |

### P1 新增素材
```
assets/generated/icons/map_nodes_v2/node_{combat,event,shop,rest,elite,boss}_anime.svg
assets/generated/recraft/anime_cohort_preview_v1/montage.png（+ variantB.webp）
assets/generated/enemies_v3/enemy_mountain_boar.png（Q版重生；舊圖備份於 backups/）
assets/generated/fx/offering_omen_glow_v1.png
```
### P1 修改檔案
```
scripts/ui/theme/CotiwUiTheme.gd   節點 icon repoint v2 + use_card_frame_v2 旗標 + get_active_card_frame_path
scripts/ui/Card.gd                 改走 get_active_card_frame_path（opt-in）
scripts/dev/UIComponentGallery.gd  Gallery 開 v2 旗標 + v2 卡框預覽列
scripts/ui/RunStartOptions.gd      presenter 立繪 + 神示金光 _play_offering_omen
tests/unit/test_ui_theme.gd        節點映射斷言更新為 v2 路徑（隨 mapping 變更）
```
### P1 測試
- `TestRunner`：**161/161**（節點映射測試已隨 mapping 更新；零回歸）。
- E2E：15/15 全 PASS（含合符 + v2 卡框 + 卡框預覽板）。

### P1 仍待
- 節點逐像素貼合 bg 道路（需把節點座標對齊 map_bg_v6 路線藝術，屬地圖佈局重構）。
- v2 卡框「透明插圖窗」版本（讓不透明卡圖透出框窗，目前框於戰鬥主要呈現金邊）。
- 其餘 act1 敵人 Q 版批次；四角色 cohort 正式 normalization 後再接鏈。
