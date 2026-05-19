# COTIW 素材命名與檔案結構規範

## 目的
避免 Aida、後續美術、切圖、Godot scene 各自亂命名，最後變成墳場。

---

## 1. 根目錄建議

### UI 結構 / 向量
- `assets/ui/frames/`
- `assets/ui/buttons/`
- `assets/ui/panels/`
- `assets/ui/icons/`
- `assets/ui/badges/`
- `assets/ui/map/`
- `assets/ui/fx/`

### 像素圖 / 插圖
- `external/sprites/cards/`
- `external/sprites/enemies/`
- `external/sprites/characters/`
- `external/sprites/relics/`
- `external/sprites/status_effects/`

---

## 2. 命名格式

統一使用：

`ui_<category>_<name>_<variant>_<state>.<ext>`

例如：
- `ui_button_primary_idle.svg`
- `ui_button_primary_pressed.svg`
- `ui_panel_tooltip_default.svg`
- `ui_frame_card_rare_default.svg`
- `ui_badge_intent_attack_default.svg`
- `ui_node_map_elite_selected.svg`
- `ui_fx_incense_glow_loop_01.png`

### 禁止
- `final_final_2.png`
- `newbutton.svg`
- `shopNEW.psd`
- `icon-1.svg`

醜得像事故現場。

---

## 3. category 詞彙表
- `button`
- `panel`
- `frame`
- `icon`
- `badge`
- `node`
- `bar`
- `fx`
- `overlay`
- `banner`
- `tab`

## 4. state 詞彙表
- `idle`
- `hover`
- `pressed`
- `selected`
- `disabled`
- `locked`
- `active`
- `inactive`
- `default`

## 5. variant 詞彙表
- `primary`
- `secondary`
- `danger`
- `reward`
- `shop`
- `common`
- `uncommon`
- `rare`
- `boss`
- `curse`
- `rest`
- `event`
- `battle`
- `elite`

---

## 6. 尺寸標記規則
若同一素材需多版本：
- `@1x`
- `@2x`
- `@3x`

例如：
- `ui_icon_shop_default@1x.png`
- `ui_icon_shop_default@2x.png`

若是 SVG，通常不需要尺寸尾碼。

---

## 7. 匯出規格附註
每個素材對應一個 metadata 註記：
- 用途
- 基準尺寸
- 可拉伸區域
- 錨點
- 是否可變色
- Godot 匯入建議

建議記在同名 `.md` 或集中 `ui_asset_registry.json`。

---

## 8. Godot 對應建議
- 可 9-slice 的 panel / button 優先 SVG 結構稿 + PNG fallback
- 純 icon 優先 SVG
- 像素圖使用 PNG，Import 關閉 filter（若要保持像素清晰）
- 混合風 UI 若要保留乾淨邊緣，UI chrome 可開 filter，sprite 保持 pixel
