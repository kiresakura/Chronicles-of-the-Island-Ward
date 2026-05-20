# 鎮島錄 — 元件型錄（COTIW UI Components）

> 全專案唯一可重用 UI 元件 API 參考。設計系統＝ `design_tokens.json`（27 色票
> + 字級 + 間距 + 圓角 + 邊框 + 陰影 + 觸控目標 + 元件 + z-layer）+
> `scripts/ui/theme/CotiwUiTheme.gd`（Godot 端 token 讀取與 helper）。
>
> **原則**：UI scene/腳本**禁止**自寫 StyleBox 工廠或硬編色——用此文件列出的 helper。
> 若需要新樣式，先看是否能用 `make_stylebox` + `get_color` 組合；不夠再加新 helper
> 進 `CotiwUiTheme.gd` 並更新本表。

## 快速索引

| 用途 | API |
|---|---|
| 任何 StyleBoxFlat 建構 | `CotiwUiTheme.make_stylebox(fill, border, radius, bw, shadow_alpha=0.30)` |
| 主 CTA 按鈕 | `CotiwUiTheme.apply_primary_button_style(button)` |
| 次要按鈕 | `CotiwUiTheme.apply_secondary_button_style(button)` |
| 通用面板（讀 tokens.components.panel） | `CotiwUiTheme.apply_panel_style(panel)` |
| Tooltip（讀 tokens.components.tooltip） | `CotiwUiTheme.apply_tooltip_style(panel_or_label)` |
| 可見 focus ring（金邊+微光） | `CotiwUiTheme.apply_focus_style(button)`（primary/secondary 已預設套用） |
| 面板背景貼圖（SVG） | `CotiwUiTheme.apply_panel_texture(texture_rect, panel_kind)` |
| Overlay scrim/panel 底色 | `CotiwUiTheme.style_overlay_backdrop(scrim, panel)` |
| 讀 design_tokens 色票 | `CotiwUiTheme.get_color(token_name, fallback)` |
| 卡稀有度 → 邊框 SVG | `CotiwUiTheme.get_card_frame_path(rarity)` |
| 地圖節點 type → SVG | `CotiwUiTheme.get_map_node_path(location_type)` |
| 面板 kind → SVG | `CotiwUiTheme.get_panel_asset_path(panel_kind)` |
| 地圖節點短標籤 | `CotiwUiTheme.get_location_short_label(location_type)` |
| mobile-safe 卡圖解析 | `CotiwUiTheme.get_mobile_safe_card_art_path(path)` |

---

## 1. `make_stylebox(fill, border, radius, bw, shadow_alpha=0.30)`

**全專案唯一 StyleBoxFlat 建構入口**。確保圓角/邊框/陰影語言一致。

```gdscript
const COTIW_UI_THEME := preload("res://scripts/ui/theme/CotiwUiTheme.gd")
var box := COTIW_UI_THEME.make_stylebox(
    COTIW_UI_THEME.get_color("panel_bg"),
    COTIW_UI_THEME.get_color("incense_gold"),
    10, 2)
panel.add_theme_stylebox_override("panel", box)
```

| 參數 | 型別 | 預設 | 說明 |
|---|---|---|---|
| `fill_color` | Color | — | 底色（含 alpha） |
| `border_color` | Color | — | 邊框色 |
| `radius` | int | — | 圓角（建議用 `radii.sm=10` / `md=12` / `lg=16`） |
| `border_width` | int | — | 邊框粗（建議 `borders.default=2` / `strong=3` / `cta=4`） |
| `shadow_alpha` | float | 0.30 | 黑色陰影 alpha，預設與設計系統 panel shadow 一致 |

**Do**：所有 panel/button/pill/toast 都走這個。
**Don't**：自己 `StyleBoxFlat.new()` 然後手寫 bg/border/corner/shadow。

---

## 2. `apply_primary_button_style(button)`

**主要 CTA**（起駕、開始、確認…）。token 驅動 normal/hover/pressed/disabled
四態與字色。

- **fill**：`festival_red`（hover lighten 0.08 / pressed → `temple_red`）
- **border**：`incense_gold`（hover/pressed 同；disabled → `smoke_gray`）
- **font**：`paper_warm`（disabled → `ash_beige`）
- **radius**：tokens `components.primary_button.radius=lg(16)`
- **border_width**：tokens `borders.cta=4`
- **height**：tokens `touch_targets.cta_height=112`

**何時用**：每個畫面**最多一顆**主要動作鈕（起駕、開始一局、確認購買…）。

**Don't**：用在次要動作（會搶焦點）。多顆並列時改用 secondary + 一顆 primary。

---

## 3. `apply_secondary_button_style(button)`

**次要按鈕**（取消、放棄此局、設定…）。

- **fill**：`lacquer_black`（hover → `wood_brown` / pressed → `night_ink`）
- **border**：`old_gold`（hover → `incense_gold`）
- **font**：`incense_gold`（disabled → `smoke_gray`）
- **radius**：tokens `components.secondary_button.radius=md(12)`
- **border_width**：tokens `borders.strong=3`
- **height**：tokens `touch_targets.comfortable=96`

---

## 4. `apply_panel_style(panel: Control)`

通用 Panel 樣式，直接讀 `design_tokens.components.panel`：

- **fill**：`#261310EE`（dark lacquer with alpha；可改 token 名）
- **border**：`old_gold` token
- **radius**：`tokens.radii.lg=16`
- **border_width**：`tokens.borders.strong=3`

```gdscript
var p := Panel.new()
COTIW_UI_THEME.apply_panel_style(p)
```

**何時用**：任何 Panel/Control 需要主面板表面（reward overlay、shop overlay、
資訊框…）。要套貼圖背景則用 `apply_panel_texture`。

## 5. `apply_tooltip_style(panel_or_label: Control)`

Tooltip 專用樣式，讀 `design_tokens.components.tooltip`：

- **fill**：`#1A100DF2`（更深更不透明）
- **border**：`incense_gold` token
- **radius**：`tokens.radii.md=12`
- **font_color**：`paper_warm` token（自動覆寫）

## 6. `apply_focus_style(button)` / `make_focus_stylebox()`

提供**可見 focus ring**（incense_gold 半透明邊+微光暈），鍵盤/搖桿 a11y 基本要求。
`apply_primary_button_style` 與 `apply_secondary_button_style` 已**預設套用**。

**Opt-out 兩種**（觸控優先畫面適用）：
1. `button.focus_mode = Control.FOCUS_NONE` —— 完全停用 focus（主選單採此法）
2. `button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())` —— 保留 focus 但隱藏視覺

## 7. `apply_panel_texture(texture_rect, panel_kind)`

把 `assets/ui/panels/` 內的 SVG 套到 `TextureRect` 並設定 stretch/mouse_filter。

| `panel_kind` | SVG |
|---|---|
| `"reward"` | `ui_panel_reward_choice_default.svg` |
| `"shop"`   | `ui_panel_shop_item_default.svg` |
| `"rest"`   | `ui_panel_rest_action_default.svg` |

---

## 8. `style_overlay_backdrop(scrim, panel=null)`

統一 overlay 的半透明遮罩 + 內面板底色。

- **scrim color**：`Color(0.07, 0.04, 0.04, 0.74)`（與 night_ink 一致）
- **panel color**（若傳入）：token `panel` 或 fallback

---

## 9. `get_color(token_name, fallback)` — 27 個顏色 token

讀 `design_tokens.json` `colors.*`，帶 fallback。

### 品牌主色
`temple_red` `#A62F1F` ／ `festival_red` `#D94A2B` ／ `incense_gold` `#E8C56A` ／
`old_gold` `#A47D2A` ／ `lacquer_black` `#1B0F0D` ／ `wood_brown` `#4B2D22`

### 夜市對比
`neon_cyan` `#57C7D4` ／ `sign_blue` `#2D4F8B` ／ `spirit_jade` `#4FA56D` ／ `mystic_purple` `#6E4AA8`

### 戰鬥語意（**HUD 必用**）
`hp_red` `#D64646`（元神）／ `armor_gold` `#E7B94C`（護身符）／
`energy_cyan` `#4EC8E5`（神力）／ `heal_green` `#5BC777` ／
`warning_orange` `#FF9F43` ／ `danger_crimson` `#8E1E1E`

### 中性
`paper_warm` `#F5E7CF` ／ `ash_beige` `#D7C4A5` ／ `smoke_gray` `#8B7C73` ／ `night_ink` `#120A09`

### 表面 / 陰影 / 狀態（2026-05-19 補）
`panel_bg` ／ `panel_bg_hover` ／ `panel_bg_lock`（主畫面 chrome 表面）／
`text_shadow_strong` (#000000E5) ／ `text_shadow_soft` (#000000A6) ／
`boot_splash_red` (#C92020FF；與 `project.godot` boot_splash bg 一致) ／
`disabled_tint` (#999999D9)

**Do**：HUD/戰鬥/UI **必用 token**，不要 inline `Color(...)`。
**Don't**：在 .tscn 內塞硬編色——交給程式從 token 讀。

---

## 10. 狀態（States）

所有按鈕**必須**提供至少 `normal` / `hover` / `pressed` / `disabled` 四態，
透過 `apply_primary/secondary_button_style` 一次完成。

| State | 視覺 | 行為 |
|---|---|---|
| normal | 預設 fill+border | — |
| hover | fill 變亮一檔、border 加亮 | scale 1.05 微動（手機觸控可省略） |
| pressed | fill 變暗一檔 | scale 0.95 下沉 |
| disabled | 暗化 + smoke_gray 邊 | 不可點 |
| focus | **incense_gold 半透明邊 + 微光暈**（apply_primary/secondary 預設）| 鍵盤/搖桿 a11y |

**Focus a11y**：`apply_primary_button_style` 與 `apply_secondary_button_style` 已**預設套用** focus ring。
觸控優先畫面（如主選單 slot/util）以 `focus_mode = FOCUS_NONE` 或 `StyleBoxEmpty` 顯式 opt-out。

---

## 11. 觸控目標（Touch Targets）

依 `design_tokens.touch_targets`：

| 等級 | px | 用於 |
|---|---|---|
| **minimum** | **88** | 一般可點按鈕、卡牌槽、地圖節點。**強制最小** |
| **comfortable** | **96** | 次要按鈕（NewRun/Codex 等選單） |
| **cta_height** | **112** | 主 CTA（起駕、開始、確認）。比 minimum 拔高 24px 強化視覺權重 |

### "small auxiliary" 例外條款

`assets/ui/icons/` 系列做的右上工具列（設定/信件/成就）與 ✕ 關閉鈕，
作為**輔助級**（小尺寸 corner-area），可不強制 88×88：

| 元件 | 規格 | 條件 |
|---|---|---|
| 右上 utility（設定/信件/成就）| 48×48 | 限角落工具列、間距 ≥6px |
| 右上 ✕ 關閉 | 44×44 | 限最右上角單顆、視覺與其他工具列區隔 |

> 例外不擴大解釋。一般 slot/CTA/卡片操作鈕**必須**達 88 起。

---

## 12. 路徑映射 helper

| API | 輸入 → 輸出 |
|---|---|
| `get_card_frame_path(rarity)` | `CardData.CARD_RARITIES.UNCOMMON` → `res://assets/ui/frames/ui_frame_card_uncommon_default.svg` |
| `get_map_node_path(loc_type)` | `LocationData.LOCATION_TYPES.SHOP` → `res://assets/ui/map/ui_node_map_shop_default.svg` |
| `get_panel_asset_path(kind)` | `"reward"` → `res://assets/ui/panels/ui_panel_reward_choice_default.svg` |
| `get_location_short_label(loc_type)` | `MINIBOSS` → `"菁"` |
| `get_mobile_safe_card_art_path(p)` | `..._art_v1.png` → mobile-safe 變體（若存在），否則原圖 |

---

## 13. 命名規範（asset_naming）

**所有 UI 資產**遵循 `ui_<type>_<concept>_default.<ext>`：

- `ui_frame_card_common_default.svg`
- `ui_node_map_battle_default.svg`
- `ui_panel_reward_choice_default.svg`
- `ui_icon_character_default.svg` ← icon 系列亦同（2026-05-19 統一）
- `ui_status_evil_aura_default.svg`
- `ui_bar_hp_default.svg`
- `ui_stamp_rarity_rare_default.svg`
- `ui_badge_intent_attack_default.svg`
- `ui_card_back_default.svg`

非 UI 資產（角色立繪、敵人、場景）走 `assets/generated/` 的 `<concept>_<variant>_v<n>.<ext>` 自由命名。

---

## 14. 採用率 / 待補（2026-05-19）

- **53 個 UI .gd**，**11 採用** `CotiwUiTheme`（核心畫面齊；STR-runtime 內部邏輯 scripts 多數不需要主題）。
- ✅ 已完成（commit `2ca0902`）：72 處硬編色 token 化、Combat HUD 語意色、design_tokens 補 7 token。
- ✅ 已完成（icon/觸控/型錄 commit）：icon 命名統一、觸控目標補修、本元件型錄。
- ✅ 已完成（focus/panel/tooltip commit）：`apply_focus_style`、`apply_panel_style`、`apply_tooltip_style` 補齊；apply_primary/secondary 預設套用 focus ring；測試 23→26。
- 設計系統 audit 全部 priority action 落地完畢。後續優化由各 sprint 內容驅動。
