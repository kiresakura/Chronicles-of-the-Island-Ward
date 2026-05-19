# 卡牌系統素材規格

## 1. 目標
卡牌是 COTIW 最常被觀看的核心元件。它必須同時滿足：
- 一眼辨識費用 / 類型 / 稀有度
- 保留廟會世界觀
- 手機小尺寸仍可讀

---

## 2. 卡牌結構

### 必備區塊（由上到下）
1. 左上費用角標
2. 稀有度框 / 主邊框
3. 插圖區
4. 名稱條
5. 內文說明區
6. 類型 / tag / 升級標記

---

## 3. 基準尺寸
設計基準（直向手機）：
- 卡牌實際顯示：`200 x 320`
- 詳情放大：`360 x 576`
- 比例固定 `5:8`

可接受誤差：±4 px 內，不可亂改比例。

---

## 4. 邊框分級

### common
- 主色：木黑 + 舊金
- 視覺感：樸素符紙木框

### uncommon
- 主色：金 + 玉綠
- 感覺比 common 多一層神力感

### rare
- 主色：金 + 青藍霓光
- 需帶細微光暈，不要俗氣爆光

### boss
- 主色：深紅 + 金 + 紫
- 帶祭典壓迫感，像神壇主位

### curse
- 主色：髒紅黑 + 暗紫
- 讀感仍需清楚，不可整張烏成一團

---

## 5. 狀態需求
每種卡框至少要有：
- `default`
- `selected`
- `disabled`（若會出現）
- `upgrade`（可用附加章，不一定重做全框）

---

## 6. 費用角標
- 位置：左上，外縮 12~16 px
- 基準尺寸：`52 x 52`
- 神力數字需是卡牌第一視覺層級之一
- 數字底盤建議採：青藍 / 金邊 / 深底

---

## 7. 名稱條
- 高度：卡高的 12~14%
- 字級要能容納 4~8 個中文字
- 長名稱需有縮放規則，但不可壓縮到變蟲

---

## 8. 內文區
- 內文底色：暖紙色 `#F5E7CF` 或更深一階
- 黑字優先，不要金字
- 關鍵字可加功能色高亮

---

## 9. 輸出檔案
- `ui_frame_card_common_default.svg`
- `ui_frame_card_common_selected.svg`
- `ui_frame_card_uncommon_default.svg`
- `ui_frame_card_rare_default.svg`
- `ui_frame_card_boss_default.svg`
- `ui_frame_card_curse_default.svg`
- `ui_badge_cost_energy_default.svg`
- `ui_card_back_default.svg`
- `ui_stamp_upgrade_default.svg`

---

## 10. 驗收
- 50% 縮小後仍可看清邊界與費用位置
- 放在暖色或深色背景都不會消失
- 三張卡並排時，rare 必須比 common 更顯眼，但不搶過選取高亮
