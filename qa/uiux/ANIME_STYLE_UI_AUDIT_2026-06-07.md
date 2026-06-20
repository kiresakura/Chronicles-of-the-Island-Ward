# 鎮島錄 COTIW — UI 測試與「動漫化」視覺改進審查（2026-06-07）

> 角色：UI 設計師 / 視覺美術顧問  
> 專案：`/Users/crimson/Developer/COTIW`  
> 目標：在現有 **Temple Neon Pixel（Q 版廟會像素 × 夜市霓光 × 神壇金漆）** 方向上，判斷 UI 是否已達商業動漫手遊質感，並提出改進建議與需重新產生的素材清單。

---

## 1. 測試基線

| 項目 | 結果 |
|---|---|
| Godot | `4.6.1.stable.official.14d19694e` |
| 主場景 | `res://scenes/Root.tscn` |
| 測試 | `godot --headless res://tests/TestRunner.tscn` → **161 / 161 PASS** |
| 工作區 | `M assets/generated/icons_v2/status/block_bagua.svg.import`、`?? qa/` |
| 實機/非 headless 截圖依據 | `qa/uiux/e2e/*.png`（既有 E2E 視覺 QA 產物） |

重要：功能層現在是健康的；這份報告針對 **視覺品質、動漫化、素材一致性**，不是說系統不能玩。

---

## 2. 總評

目前 COTIW 已經不是醜陋的 STR 換皮。它有台灣民俗辨識、符令卡、乩童、破煞圈、廟宇背景，也有手機化 safe-area / touch feedback 的基礎。

但如果目標是「更動漫、更像可上市的手機遊戲」，現在最大的問題不是缺特效，而是：

1. **角色魅力還沒有成為畫面核心**：主選單乩童很醒目，但角色選擇 / 地圖 / reward 等流程仍像工程 UI 疊在背景上。
2. **背景與 UI chrome 不是同一套美術密度**：背景有像素手繪感，UI 面板多為深色矩形 / SVG 工程框，彼此不夠像同一張圖。
3. **地圖畫面最不像動漫手遊**：大面積白灰面板、節點格陣、節點圖示重複，削弱「遶境」敘事。
4. **卡牌很有方向，但框架與資訊層仍偏原型**：卡圖可用，費用牌角與卡框缺少動漫卡牌的稀有度、職業、發動感。
5. **提示與演出太文字化**：「合符！」現在位置正確，不擋手牌，但缺少漫畫式 cut-in、符紙燃起、速度線等情緒峰值。

一句毒舌版：現在是「會做法事的工程原型」。要變動漫手遊，得讓每個畫面都像一格會呼吸的分鏡，而不是在漂亮背景上放表格。

---

## 3. 分畫面 UI 分析

### 3.1 主選單 / Lobby

證據：`qa/uiux/e2e/01_main_menu.png`

**做得好的地方**
- 乩童立繪大、姿勢明確，第一眼知道主角與題材。
- 廟宇背景 + 天空 + 山景具備輕鬆、明亮的動漫感，比陰暗地牢好很多。
- CTA「繼續」夠大，手機橫向點擊友善。
- 頂部資源條、側邊功能按鈕已有手遊 lobby 的基本架構。

**問題**
- 主角立繪與背景像素密度不完全一致：角色更銳利、更動漫，背景更像柔和像素插圖；兩者接合處略像貼圖。
- 右側活動卡「限時擲筊」太像空白占位卡，沒有角色、供品、籤筒或動態視覺，不像商業活動 banner。
- CTA 的紅橘色很亮，但造型仍是矩形按鈕；缺少神轎牌匾、紅布、金邊、陰影層次。
- 左下/右下功能按鈕圖示與文字層級偏小，icon 仍是通用 SVG 感，不夠像遊戲圖標。

**動漫化建議**
- 主選單要採「角色主視覺 + 前景小物 + 活動 banner」三層構圖：乩童在左、右側 banner 放鸞女/虎爺/籤筒 cut-in，底部功能像供桌上的符牌。
- CTA 改成「紅布神匾」或「金漆令牌」造型，不要只是一塊平面矩形。
- 功能 icon 全部重繪成 64×64/96×96 Q 版圖標：角色、開壇、收藏、陣型、商店、招募，要有厚描邊與金紅材質。

---

### 3.2 起手選項 / Run Start Boon

證據：`qa/uiux/e2e/02_run_start_boon.png`

**做得好的地方**
- 文案「願擲筊問神，得吉凶起手」方向正確。
- 選項功能可讀，流程可跑。

**問題**
- 這是全遊戲目前最不美的畫面之一。整體像 debug overlay：大紅黑背景、四條細長選項，空間巨大但沒有儀式舞台。
- 沒有角色、沒有神明、沒有筊杯、沒有籤詩、沒有供桌。玩家看不到「擲筊問神」。
- 選項條太細，手機點擊感與卡牌選擇感都弱。
- 左下神力 dial 巨大但孤立，像從戰鬥 HUD 漏進來。

**動漫化建議**
- 改為「供桌四選一」：四個選項是四張籤詩/供品牌，放在紅布桌上。
- 中央加入筊杯落地/神光決定的演出；選項 hover/selected 時用金光、香煙、籤詩展開。
- 讓目前角色半身像或神明小像站在一側，提供「這是你的起手命格」的動漫敘事。

---

### 3.3 遶境地圖

證據：`qa/uiux/e2e/03_pilgrimage_map.png`

**做得好的地方**
- 程式已有 pilgrimage route、boss omen、reachable flow line 的語意基礎。
- 節點數與流程功能正確。

**問題**
- 視覺上仍像「白灰大面板 + 格狀節點」，不是遶境路線。
- 背景島嶼圖其實不差，但被灰白面板蓋掉，等於把最有世界觀的東西關在外面。
- 節點圖示重複且灰粉，缺乏類型辨識；「戰 / ???」文字像工程標籤。
- BOSS 在遠方沒有壓迫感：上方虎爺符號太小，不像目的地，也不像動畫分鏡中的遠方神門。

**動漫化建議**
- 地圖應改為「島嶼俯視遶境路線」：把節點直接嵌入島嶼道路，移除白灰大底板或改成半透明羊皮/符紙地圖。
- 每種節點重繪為 Q 版地標 icon：戰鬥=煞氣鳥居/紅符，事件=籤筒，商店=夜市攤，休息=廟埕香爐，菁英=虎爪封印，Boss=黑紅神門。
- 讓可達路線有青藍流光；已走路線留金紅餘燼；未走路線淡墨，不要只是灰線。

---

### 3.4 戰鬥畫面

證據：`qa/uiux/e2e/04_combat_enter.png`、`05_combat_hand.png`、`06_combat_toast.png`

**做得好的地方**
- 乩童 vs 煞圈敵人 + 廟宇牌坊背景，台灣民俗辨識很強。
- 手牌已經有符令卡圖與費用角標，方向對。
- Toast lane 修正後不再遮手牌，功能上比舊版好。
- 神力八卦 dial、破煞圈、合符回饋都有獨特系統語彙。

**問題**
- HUD 太多層：頂部資源、左上 HP/護/預兆、左下神力、右上三個黑 icon、右下結束回合；畫面像同時貼了幾套系統。
- 角色與敵人相對偏小，背景過於搶戲；動漫戰鬥應該先看角色、敵人、行動預兆，而不是先看背景建築。
- 敵人煞圈好，但敵人本體偏灰糊，缺少可愛/可怕的動漫 silhouette。
- 卡牌底部資訊文字太小，插圖與卡框一體感不足；費用角標像貼紙，缺少符令/印章感。
- 「合符！」只有文字，情緒不足。這是核心差異化動作，不該只是一行紅字。

**動漫化建議**
- 戰鬥舞台降低背景對比，加一道暗場/霧層，把角色和敵人推出來。
- 敵人全部重繪為清楚 silhouette 的 Q 版妖怪/煞體，保留煞圈，但本體要更像可收集的敵方角色。
- 合符演出加「兩張符飛起 → 金線相接 → 火光一閃 → 新符落下」；toast 改成短暫漫畫擬聲字 + 斜切光條，而非純文字。
- 卡牌框改成職業符令系統：乩童卡紅金、鸞女卡玉綠、道士卡藍白、家將卡赤金黑；同時保留稀有度外框。

---

## 4. 需重新產生 / 重繪的素材清單

### P0 — 最高優先，直接影響「動漫手遊感」

| 類別 | 檔案 / 範圍 | 問題 | 建議規格 |
|---|---|---|---|
| 起手選項背景 / 供桌 | 新增 `assets/generated/pixellab/run_start_offering_bg_v1.png` | 現在是大紅黑 debug 面板 | 1376×768，橫向，紅布供桌、筊杯、籤筒、香煙、神光；中間留 4 張選項卡位置 |
| 起手選項卡框 | 新增 `assets/ui/panels/ui_panel_boon_choice_anime.svg/png` | 四條細線不像可選獎勵 | 4 張籤詩卡 / 供品牌，96px 以上觸控高度，selected/pressed/disabled 三態 |
| 地圖主背景 | 重生 `assets/generated/pixellab/map_bg_v5.png` 或新增 v6 | 被白灰面板蓋掉後缺氛圍 | 島嶼俯視 + 遶境路線可直接疊節點；低對比背景、道路清楚、Boss 遠方神門 |
| 地圖節點 icon | `assets/ui/map/*.svg` 或 `assets/generated/icons/map_nodes/*` | 圖示重複、工程感 | 六類 Q 版地標 icon，battle/event/shop/rest/elite/boss，各 96×96，含 reachable/visited/locked 狀態 |
| 戰鬥敵人 sprite | `assets/generated/pixellab/enemy_*.png` / combatants | 敵人本體灰糊、吸引力弱 | Q 版妖怪/煞體，256/512px，清楚輪廓、厚描邊、3 狀態：idle/hit/break |
| 合符演出素材 | 新增 `assets/generated/fx/fuhe_*` | 目前只有文字 | 符紙飛起、金線、火花、合符爆光、漫畫字「合符！」PNG/SVG 序列 |
| 卡牌框 v2 | `assets/ui/frames/ui_frame_card_*_default.svg` | 現有 SVG 像工程 placeholder | 200×320 或更高解析；費用角標改符印，職業色 + 稀有度雙層，插圖窗更大 |

### P1 — 角色魅力與一致性

| 類別 | 檔案 / 範圍 | 問題 | 建議規格 |
|---|---|---|---|
| 四角色 lobby / 選角大立繪 | `assets/generated/portraits_v3/*.png` | 角色可用但同 cohort 魅力和像素密度不完全一致 | 同一畫布、同一腳底線、同一描邊厚度、同一光源；角色應有表情差異與姿勢個性 |
| 角色卡圖 | `assets/generated/characters_v2/*_card.png` | 比 portrait 更動漫，但與 portrait 不是同一批語言 | 角色卡圖與立繪統一，保留卡牌用誇張 pose；輸出透明底 + 卡片裁切版 |
| 主選單活動 banner | 新增 `assets/generated/ui/banner_limited_jiaobei_v1.png` | 右側活動卡空、像 placeholder | 橫幅含筊杯、籤詩、角色 cut-in、限時標籤；至少 normal/pressed |
| 功能 icon | `assets/ui/icons/ui_icon_*_default.svg` | 多數是白線通用 icon，不像遊戲 | 64/96px Q 版厚描邊 icon，紅金主色，locked 版有封條 |
| 神明 affinity icon | `assets/generated/icons/deities/*` | 右上黑 icon 辨識差 | 媽祖/虎爺/城隍/王爺等小神像徽章，亮底可讀，充能狀態有金光 |

### P2 — 潤飾與商業完成度

| 類別 | 檔案 / 範圍 | 問題 | 建議規格 |
|---|---|---|---|
| Reward 供桌 | `assets/ui/panels/ui_panel_reward_choice_default.svg` | 只有文字「戰利品」，像長面板 | 供品盤、金紙、籤詩三層高度；稀有度用香火與金箔層級 |
| Shop item panel | `assets/ui/panels/ui_panel_shop_item_default.svg` | 工程 SVG 感 | 夜市攤/廟口販售框，價格區像香油錢牌 |
| Rest panel | `assets/ui/panels/ui_panel_rest_action_default.svg` | 還不夠像休息點 | 廟埕長椅、香爐、補血/升級/祈福三動作 icon |
| 狀態 icon | `assets/ui/status/*.svg` | 可讀但缺角色世界觀 | 煞氣、驚嚇、神威、虛弱等改成厚描邊符印/妖氣 icon |
| App / splash anime key visual | `assets/ui/icons/app_icon_master_1024.*`、`splash_bg_v5.png` | 可用但可再商業化 | 統一中心女主/乩童 + 廟宇光，強 silhouette，64px 仍可讀 |

---

## 5. PixelLab / 生成 Prompt 方向

### 共通負面限制
- no text, no watermark, no logo unless explicitly requested
- no realistic horror, no western medieval fantasy, no Japanese shrine-only aesthetic
- avoid blurry painterly poster, avoid generic fantasy card frame
- keep mobile game readability, strong silhouette, clean foreground/background separation

### 地圖 v6 prompt 範本
```text
Pixel anime mobile game overworld map, Taiwanese island pilgrimage route, cute supernatural temple festival style, bird-eye view island with winding incense road, red-gold temple gates, night market cyan glow accents, boss shrine gate looming in the far top, clear empty spaces for 52 map nodes, readable on 1200x700 landscape phone screen, chunky 16-bit pixel art, thick clean shapes, warm festival lighting, no text, no UI labels
```

### 起手供桌 prompt 範本
```text
Pixel anime mobile game ritual offering table screen, Taiwanese temple interior, red velvet table cloth, jiaobei moon blocks, fortune sticks, incense smoke, gold paper, four empty card slots on the table for player choices, warm red and incense gold, cyan spirit rim light, cute but mystical, 1200x700 landscape composition, UI-safe center, no text, no logo
```

### 合符 FX prompt 範本
```text
Sprite sheet for pixel anime talisman fusion effect, two yellow Taoist talismans flying together, golden thread connection, red-orange fire burst, cyan spirit sparks, final manga-style impact shape without text, transparent background, 8 frames, mobile card battler VFX, Taiwanese temple magic, chunky pixel art
```

### 敵人 sprite prompt 範本
```text
Pixel anime enemy sprite for Taiwanese supernatural card battler, cute but eerie sha spirit monster, strong silhouette, thick outline, temple exorcism theme, readable at 256px, idle pose, transparent background, red-gold/cyan supernatural accents, no text, no frame
```

---

## 6. 建議執行順序

1. **先重做 RunStartOptions**：因為它現在最像 debug UI，且成本相對低。做出供桌四選一卡，就能立刻提升「動漫儀式」感。
2. **再重做地圖背景與節點**：地圖是第二大破口；把白灰面板移除，遊戲的世界感會大幅提升。
3. **接著做卡牌框 v2 + 合符 FX**：這是高頻戰鬥體驗，能把系統差異化變成肉眼可見的快感。
4. **最後統一四角色 cohort**：角色已經可用，不急著推倒；但正式展示前要做 cohort-level normalization / regeneration。

---

## 7. 附件

- 主要 E2E 截圖：`qa/uiux/e2e/01_main_menu.png` ~ `06_combat_toast.png`
- 素材 montage：`qa/uiux/current_asset_montage_for_anime_audit.jpg`

