# 圖鑑／收編錄 — 佈局契約（Godot 移植）

> 移植自 `docs/design/mockups/codex_baseline.html`（視覺基準）。
> 引擎：Godot 4.6.1。原型位置：`prototypes/codex_layout/`。
> 跑法：`godot --path . res://prototypes/codex_layout/runner.tscn`
> 截圖落在 `prototypes/codex_layout/shots/`（gitignore，不進 git）。

## 契約三條（嚴守）

1. **只用自動佈局容器，零硬座標。**
   VBox / HBox / Grid / Margin / Scroll / Panel / Center + `size_flags` + anchor 比例。
   全檔唯一的「數字」是 token 化的 `custom_minimum_size`（尺寸提示，非座標）與
   由 viewport／safe-area 推導的邊距。**沒有任何 `position = Vector2(x, y)`。**

2. **一開始就響應式 + 尊重安全區。**
   - 欄數由「網格可用寬」推導：`cols = clamp(可用寬 / 210, 3, 6)`，不寫死斷點。
   - 側欄寬依寬高比收放（平板 4:3 收窄讓位給網格）。
   - bg 全出血；內容走 `MarginContainer`，邊距 = 基礎呼吸(lg) + safe inset（四邊）。
   - bottom sheet 寬讓左右 inset、底部抬離 home indicator。

3. **鍵盤／手把焦點導航。**
   tab、卡位、篩選 chip、搜尋、關閉、CTA 全部 `FOCUS_ALL`；
   靠 Godot 幾何自動鄰接 → D-pad 可在側欄 ↔ 網格間巡覽；初始焦點落在「返回」。

## 元件（kit）

| 檔案 | 類別 | 角色 |
|---|---|---|
| `kit/CdxCardSlot.gd` | `CdxCardSlot`（extends Button） | 卡位四態：collected／locked／skeleton（脈動）。稀有度框＋費用／稀有度角標＋型別 glyph＋名條。 |
| `kit/CdxCategoryTab.gd` | `CdxCategoryTab`（extends Button） | 側欄分類：名＋計數＋mini 進度＋選中態。 |
| `kit/CdxDetailSheet.gd` | `CdxDetailSheet`（extends Control） | 底部詳情卡：scrim 點擊／ui_cancel 關閉、開啟移焦關閉鈕、safe-area 內縮。 |
| `CodexScreenV2.gd` | （extends Control） | 組裝：TopBar＋側欄＋內容（header＋四態）＋ sheet。 |

## 四態

`demo_state`：`grid`（成功網格）／`loading`（骨架＋脈動）／`error`（重試 CTA）／`empty`（引導 CTA）／`detail`（開詳情卡）。
篩選／搜尋後空集合 → 即時 inline 提示。

## 自查結果（移植契約驗收）

**Q1：有沒有任何硬座標？** — 無。
`grep -E "position\s*=\s*Vector2|set_position|\.position\.[xy]\s*="` → 0 命中。
唯一的 `offset_*` 在 `CdxDetailSheet`，三行皆由 `safe`／viewport 推導（安全區內縮，非座標）。

**Q2：換解析度會不會崩？** — 不會。
| 解析度 | 欄數 | 側欄 | 結果 |
|---|---|---|---|
| 1244×700（16:9 手機） | 4 | 248 | ✓ |
| 1515×700（19.5:9 手機） | 5 | 248 | ✓ |
| 1200×900（4:3 平板） | 4 | 200（收窄） | ✓ |
| 1244×700 + 瀏海(64/20/64/44) | 3（自動收欄） | 248 | ✓ 四邊內縮、sheet 抬離底 |

欄數隨可用寬自動增減、側欄隨寬高比收放、瀏海下內容全部內縮無裁切。

## 接線 live（下一步）

`scripts/ui/menus/CodexMenu.gd` 目前硬寫欄數（6/4/3）且無空／載入／鎖定態。
整合方向：把上述 kit ＋ `_apply_safe`／`_recompute_columns` 模式接進 CodexMenu，
資料源換成真實 collection／符令／家將／神明，補四態，跑 167 測試 + 三解析度 audit。
