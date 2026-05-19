# B2 詳細成品規格：卡框 / Intent Badge / Map Node / HUD 元件

## 目標
本文件是 Aida 與美術的「成品級規格」，不是抽象概念。

所有元件都要符合：
- 直向手機優先
- 台灣廟會語言
- Temple Neon Pixel 色票
- 可直接落地到 Godot

---

## 1. 卡框（Card Frames）

### 尺寸
- Base：`200 x 320`
- Safe inset：四邊 `12 px`
- Cost badge 安全區：左上 `52 x 52`
- 標題條高度：`28 px`
- 內文區：底部 `74 px`

### 視覺結構
- 外框：厚 4px，做神壇框感
- 內襯：暖紙底，避免資訊讀不清
- 插圖窗：圓角內窗，避免硬直切割
- 名稱條：深色底，淺字

### 稀有度視覺規則
- common：低彩木黑 + 舊金
- uncommon：加玉綠點綴
- rare：加青藍發光邊
- boss：紅紫祭壇壓迫感
- curse：暗紫黑，低明度高危險

### 檔案
- `assets/ui/frames/ui_frame_card_common_default.svg`
- `assets/ui/frames/ui_frame_card_uncommon_default.svg`
- `assets/ui/frames/ui_frame_card_rare_default.svg`
- `assets/ui/frames/ui_frame_card_boss_default.svg`
- `assets/ui/frames/ui_frame_card_curse_default.svg`

---

## 2. Intent Badges

### 尺寸
- Base：`96 x 96`
- 小尺寸 fallback：`64 x 64`

### 通用規則
- 外圈一定要清楚
- 中央 pictogram 不可過細
- 顏色即訊息，但不能只靠顏色，要有圖形差異

### 類型
- attack：劍 / 斬痕
- defend：盾 / 廟牌護符
- buff：上升符光
- debuff：下壓咒印
- multi_hit：雙刃 / 連斬
- summon：香火召喚圈

### 檔案
- `assets/ui/badges/ui_badge_intent_attack_default.svg`
- `assets/ui/badges/ui_badge_intent_defend_default.svg`
- `assets/ui/badges/ui_badge_intent_buff_default.svg`
- `assets/ui/badges/ui_badge_intent_debuff_default.svg`
- `assets/ui/badges/ui_badge_intent_multi_hit_default.svg`
- `assets/ui/badges/ui_badge_intent_summon_default.svg`

---

## 3. Map Nodes

### 尺寸
- Visual node：`128 x 128`
- Click/tap area：至少 `88 x 88`

### 類型色彩
- battle：紅金
- elite：橘金
- event：青藍
- rest：玉綠
- shop：暖金木牌
- boss：深紅紫金

### 狀態
- default
- reachable：外圈發光
- selected：內圈高亮 + 外發光
- cleared：降低飽和
- locked：低對比灰棕

### 檔案
- `assets/ui/map/ui_node_map_battle_default.svg`
- `assets/ui/map/ui_node_map_elite_default.svg`
- `assets/ui/map/ui_node_map_event_default.svg`
- `assets/ui/map/ui_node_map_rest_default.svg`
- `assets/ui/map/ui_node_map_shop_default.svg`
- `assets/ui/map/ui_node_map_boss_default.svg`

---

## 4. HUD Bars

### 尺寸
- 標準資源條：`320 x 44`
- 緊湊版：`220 x 32`

### 規則
- track 必須比 fill 暗
- 左側 icon 區固定
- 數字標示必須可獨立閱讀
- HP / Armor / Energy 三者不可只靠標籤，視覺就要能立刻分辨

### 檔案
- `assets/ui/bars/ui_bar_hp_default.svg`
- `assets/ui/bars/ui_bar_armor_default.svg`
- `assets/ui/bars/ui_bar_energy_default.svg`

---

## 5. 驗收標準
- 不看文字也能辨識大部分元件類型
- 50% 縮小後仍保持結構
- 深色背景與複雜背景上都不消失
- Aida 能直接引用或切為 Godot 主題資源
