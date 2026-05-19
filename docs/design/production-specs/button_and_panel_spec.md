# 按鈕與面板系統規格

## 1. 主按鈕（Primary CTA）
- 用途：起駕、確認、購買、收下
- 尺寸基準：`min 320 x 112`
- 背景：Festival Red
- 邊框：Incense Gold 4px
- 文字：Paper Warm
- 狀態：idle / pressed / disabled

### pressed
- 整體下壓 2~4 px 視覺差
- 飽和略降低
- 邊框與陰影同步收斂

### disabled
- 不透明度不可直接一刀砍到 30%
- 改採灰棕 + 降亮，仍保有結構可辨識

---

## 2. 次按鈕（Secondary）
- 用途：返回、次級操作、非關鍵確認
- 尺寸基準：`min 240 x 92`
- 背景：Lacquer Black
- 邊框：Old Gold 3px
- 文字：Incense Gold

---

## 3. Icon Square Button
- 用途：底部宮格、快捷操作
- 尺寸基準：`140 x 168`
- icon 區佔上方約 55%
- label 置底居中
- locked 狀態需有小 badge 或褪色文字

---

## 4. Tab Button
- 用途：角色 / 卡牌 / 遺物 / 分頁
- 高度：72~80
- selected 狀態：高亮底 + 金邊
- inactive 狀態：深底 + 金字

---

## 5. Panel 類型

### modal panel
- 大型資訊承載
- 圓角 24~36
- 大邊框 + 深背景 + 清楚標題區

### tooltip panel
- 小型訊息層
- 內容優先，背景盡量單純
- 禁止紋理過多

### reward panel
- 應有可選取 / 選中 / 不可選 清楚差異

### shop item panel
- 左內容、右 CTA、價格區清楚拆層

---

## 6. 9-slice 建議
若 Aida 要做可延展 panel/button：
- 邊角固定
- 邊線可延展
- 中央可平鋪或純色

建議每個 panel/button 都附：
- 可拉伸標記圖
- 安全內容區
- 內距建議
