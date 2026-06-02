# COTIW UI 元件規則

本文件是 `CotiwUiTheme` component API 的使用規範。目的不是「多一份文件」，而是把 STR 原始 UI、COTIW token / panel / icon 系統、PixelSkin / PixelFX 氣氛層真正接成同一套視覺語言。

## 核心原則

- Scene 只描述結構與資料，不散落顏色、字級、panel 材質決策。
- 元件樣式統一從 `res://scripts/ui/theme/CotiwUiTheme.gd` 進入。
- token 來源統一為 `res://docs/design/design_tokens.json`。
- 特效與觸控回饋可以由 `TouchFeedback` 負責，但 reward / shop / HUD / map 的外觀語言必須回到 `CotiwUiTheme`。

## Component API

| API | 用途 | 材質規則 |
| --- | --- | --- |
| `style_reward_button(button, kind, rarity)` | Reward 選項與稀有度階層 | `svg_texture` panel + theme stylebox affordance |
| `style_shop_button(target, is_unaffordable)` | 商店項目、價格標籤、不可購買狀態 | `svg_texture` panel |
| `style_hud_badge(panel, accent_token)` | HUD badge、神明 affinity、戰鬥狀態 pill | `stylebox_flat` |
| `style_map_node(node, location_type, label, glow, ...)` | 地圖節點 icon、尺寸、label、reachable/current 狀態 | `svg_icon` |

## Panel 材質鐵律

| 類型 | 使用方式 | 原因 |
| --- | --- | --- |
| reward / shop / rest / card | SVG panel texture | 大型互動卡片，需要保留廟宇雕花、像素邊框與視覺重量。 |
| HUD badge / tooltip / dialogue / system panel | `StyleBoxFlat` | 資料型容器要清楚、輕量、可快速讀取，不應和裝飾 panel 搶戲。 |
| map node | SVG icon | 地圖節點是符號，不是面板；固定 88×88 touch target，避免 1024px icon 撐爆地圖。 |

此規則由 `CotiwUiTheme.PANEL_MATERIAL_RULE_BY_KIND` 寫死；新增 UI 類型時先補規則，再補 Scene。

## UI 元件圖鑑

測試場景：`res://scenes/dev/UIComponentGallery.tscn`

必須集中展示：

- button
- panel
- badge
- tooltip
- reward
- shop item
- map node

任何新增核心 UI 元件，都應先放進圖鑑，確認它和現有語言能站在同一張畫布上。醜東西不要混進正式場景；先在圖鑑裡被審判。
