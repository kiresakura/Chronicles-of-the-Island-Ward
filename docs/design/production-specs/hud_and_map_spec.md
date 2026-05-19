# 戰鬥 HUD 與地圖節點規格

## 1. 戰鬥 HUD

### 頂部資訊區
- 敵人名、Intent、回合資訊為第一層
- 不可被背景插圖吃掉

### 資源條
- HP：紅
- Armor：金
- Energy：青藍
- 每條都有 track / fill / numeric label

### 手牌區
- 中央選取卡可上浮 40~60 px
- 被拖曳卡需要獨立 glow
- 不可只靠縮放表示選取，還需亮邊或發光

### 回合 CTA
- 結束回合鈕需極明確
- 不可與背景色太接近

---

## 2. Enemy Intent Badge
至少準備：
- attack
- defend
- buff
- debuff
- unknown
- multi-hit
- summon

命名例：
- `ui_badge_intent_attack_default.svg`
- `ui_badge_intent_buff_default.svg`

---

## 3. 地圖節點

### 節點類型與配色
- battle：金邊 / 中性紅底
- elite：橘金 / 危險感
- rest：玉綠
- event：青藍
- shop：暖金 / 木牌感
- boss：深紅紫 + 金

### 節點狀態
- default
- reachable
- selected
- cleared
- locked

### 點擊區
- 可視圓可小，但點擊 hit area 至少 `88 x 88`

---

## 4. 路徑線
- default path：煙灰色
- selectable / chosen：青藍或金色高亮
- 不要做太粗，避免像捷運圖錯版

---

## 5. 驗收
- 一眼能分辨節點類型
- 選取狀態與可達狀態不可混淆
- 路線不會因背景太花而消失
