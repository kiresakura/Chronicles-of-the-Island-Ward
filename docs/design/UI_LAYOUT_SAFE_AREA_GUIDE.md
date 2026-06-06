# 鎮島錄 — UI Layout / Safe-Area 指南

| 項目 | 內容 |
| --- | --- |
| 文件狀態 | UIQA 修正定案（2026-06-07） |
| 對應 | Aida UI/UX QA 報告修正、`scripts/ui/theme/CotiwUiTheme.gd`、`autoload/Responsive.gd` |
| 目的 | 消除散落 magic `Vector2` / `font_size` / `layer`，建立手機橫向安全區的單一標準 |

---

## 1. Safe content rect 原則

- **單一真相來源 = `Responsive` autoload**（`Responsive.safe_rect`）：裝置安全區（瀏海/動態島/home indicator）換算成邏輯座標後的可用範圍。
- UI 定位**一律**透過 `CotiwUiTheme.get_safe_content_rect(viewport)` 取得，**勿**直接寫死座標。
- 全出血背景用 `CotiwUiTheme.get_stage_size()`（= `Responsive.screen_rect.size`）。
- 任何浮動元素（toast / 按鈕 / overlay）最終都要 `CotiwUiTheme.clamp_rect_to_safe_area(rect, safe)` 夾進安全區。

```gdscript
var safe := CotiwUiTheme.get_safe_content_rect(get_viewport())
var want := Rect2(Vector2(safe.position.x + 24, safe.position.y + 100), Vector2(440, 46))
node.position = CotiwUiTheme.clamp_rect_to_safe_area(want, safe).position
```

## 2. Mobile landscape layout 原則（基準 1200×700）

- 拇指動線：左下 / 右下角是雙手橫持的拇指熱區；主要可點元素優先放此處，但**不可遮手牌中央**。
- 結束回合鈕在右下 → 其他底部鈕（如取消選敵）避開右下，改放**左下**。
- 觸控目標 ≥ 44×44pt（蘋果 HIG）。本專案按鈕最小 160×54。
- 平板（`Responsive.is_tablet()`，AR < 1.6）：safe-rect 等比置中，元素相對 safe-rect 而非絕對座標。

## 3. Toast lane 原則

- 位置：safe-rect **頂部 HUD 下緣**（回合狀態 Label y≈8–42、請神鈕 y≈46–80 之下，y≈safe.top+100），水平置中。
- **不得遮**：敵人 intent（中央）、手牌（底部）、請神槽。
- **單一 toast 節點 + 佇列**：`show_combat_toast()` 若正在顯示則排入 `_combat_toast_queue` 逐則播放 → 不疊字、不無限堆疊。
- 字級走 `get_typography_size("h1", 30)`。
- 實作：`Combat._position_combat_toast()` / `_show_toast_now()` / `_on_combat_toast_finished()`。

## 4. Touch detail overlay positioning 原則

- 尺寸：依 safe-rect **縮放使寬度 ≤ 80%**（panel 內部固定版面 → 用 `scale` 保比例不裁字）。
- 位置：依**目標 `get_global_rect()`** 水平對齊中心，優先放目標**上方**；上方空間不足則**翻到下方**；最終 `clamp_rect_to_safe_area`。
- 實作：`TouchFeedback.position_detail_overlay(overlay, target)`。

## 5. Layer token 規格（取代散落 magic layer / z_index）

```gdscript
CotiwUiTheme.LAYER_BACKGROUND   = 0
CotiwUiTheme.LAYER_WORLD        = 10
CotiwUiTheme.LAYER_HUD          = 20
CotiwUiTheme.LAYER_FX           = 30
CotiwUiTheme.LAYER_OVERLAY      = 60
CotiwUiTheme.LAYER_TOAST        = 80
CotiwUiTheme.LAYER_TOUCH_DETAIL = 90
```
新增 `CanvasLayer.layer` / `z_index` 請引用上列常數；暫留 magic number 須加註原因。

## 6. Typography token 規格

- 字級**一律**走 `CotiwUiTheme.get_typography_size(token_name, fallback)`（token 定義於 `docs/design/design_tokens.json` 的 `typography`）。
- 常用 token：`h1`、`h2`、`h3`、`button`、`caption`。未知 token 自動回 `fallback`。
- **禁止**新增 `add_theme_font_size_override("font_size", 直接數字)`；本任務已轉換 toast / cancel 鈕。

## 7. 產品語意（UI 服務「開壇鎮煞」）

- 合符：可合符卡以**暖金提示**（`Hand.MERGE_HINT_TINT`）讓玩家看見「符令可疊」，非隱藏彩蛋。
- 破煞 / 請神 / 遶境 / Reward 的 UI 應持續強化「儀式」感，而非泛用 deckbuilder。

## 8. 多比例 contract 測試

`tests/unit/test_ui_layout_safe_area.gd` 驗證 16:9 / 19.5:9 / 20:9 / 4:3 下 `clamp_rect_to_safe_area` 皆把元素夾進 safe-rect；`tests/integration/test_combat_flow_smoke.gd::test_uiqa_toast_cancel_merge_affordance` 驗證 toast / cancel 鈕 / 合符提示的真實節點行為。
