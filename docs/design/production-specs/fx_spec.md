# 特效與微動效素材規格

## 1. 目標
特效不是煙火秀。它是拿來讓操作更有手感、神異感更成立。

---

## 2. 特效類型

### 香火系
- 緩慢上升粒子
- 偏暖白 / 金粉 / 灰煙
- 用於 loading、祭壇、buff 出現

### 靈光系
- 青藍 / 玉綠外發光
- 用於 selectable、rare、summon、map reachable

### 符紙系
- 紙片飛散、印章落下
- 用於出牌、獎勵獲得、升級

### 打擊系
- 小面積震動高光
- 用於 attack hit / multi-hit

---

## 3. 幀數與輸出
### PNG sprite sheet
- 建議 6 / 8 / 12 幀
- 單幀尺寸統一優先：64 / 96 / 128

### 單張貼圖
- glow, smoke, spark 可獨立一張透明 PNG

---

## 4. 命名
- `ui_fx_incense_glow_loop_01.png`
- `ui_fx_talisman_burst_once_01.png`
- `ui_fx_gold_dust_loop_01.png`
- `ui_fx_hit_flash_once_01.png`

---

## 5. 使用原則
- 戰鬥中：特效持續時間短，資訊優先
- 主選單：特效可慢，營造氛圍
- Loading：可作為品牌感建立

---

## 6. 驗收
- 深色背景上可見
- 不遮住文字
- 不造成低階手機過重負擔
