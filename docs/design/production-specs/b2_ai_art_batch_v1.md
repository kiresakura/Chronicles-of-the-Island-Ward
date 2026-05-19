# B2 首批 AI 美術圖交付紀錄

- 生成工具：Google Gemini `gemini-2.5-flash-image`（直接 API）
- 生成時間：2026-05-18 22:00:57
- 交付批次：`assets/generated/manifest_b2_art_batch_v1.json`

## 本批次輸出

### Characters
- `assets/generated/characters/tongji_portrait_v1.png`

### Cards
- `assets/generated/cards/card_tongji_punch_art_v1.png`
- `assets/generated/cards/card_tongji_talisman_art_v1.png`

### Enemies
- `assets/generated/enemies/enemy_mountain_boar_v1.png`
- `assets/generated/enemies/enemy_tiger_god_v1.png`

### Scenes
- `assets/generated/scenes/act1_mountain_temple_bg_v1.png`

## 已接入資料檔
- `external/data/characters/character_tongji.json`
- `external/data/cards/tongji/card_tongji_punch.json`
- `external/data/cards/tongji/card_tongji_talisman.json`
- `external/data/enemies/act1_mountain/enemy_mountain_boar.json`
- `external/data/enemies/act1_mountain/enemy_tiger_god.json`

## 用途說明
- `tongji_portrait_v1.png`：主角 run 內顯示與角色圖示基礎版
- `card_tongji_punch_art_v1.png`：攻拳卡面插圖首版
- `card_tongji_talisman_art_v1.png`：護身符卡面插圖首版
- `enemy_mountain_boar_v1.png`：山豬精敵方立繪首版
- `enemy_tiger_god_v1.png`：百年虎爺 boss 立繪首版
- `act1_mountain_temple_bg_v1.png`：第一章山路入廟背景圖首版

## 後續建議
1. 以同樣 prompt 結構繼續補完其餘 9 張乩童卡圖。
2. 補 `enemy_tree_spirit`, `enemy_tiger_aunt`, `enemy_chair_girl`, `enemy_makanai`。
3. 針對真正 in-game 呈現，再做一輪裁切與留白微調。
4. 若要更接近「像素味」，第二輪可加入 pixel-grid / limited palette / chunkier shading 限制。
