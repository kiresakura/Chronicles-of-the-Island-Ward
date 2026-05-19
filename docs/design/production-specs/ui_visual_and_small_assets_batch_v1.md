# UI 視覺素材包 + 小尺寸資產批次 v1

- 產出時間：2026-05-18 22:31:57
- 小尺寸 manifest：`assets/generated/manifest_small_assets_v1.json`
- 場景 batch manifest：`assets/generated/manifest_ui_scene_batch_v1.json`

## UI 視覺素材包
### Card / Stamp
- `assets/ui/cardbacks/ui_card_back_default.svg`
- `assets/ui/stamps/ui_stamp_upgrade_default.svg`
- `assets/ui/stamps/ui_stamp_rarity_rare_default.svg`
- `assets/ui/stamps/ui_stamp_rarity_boss_default.svg`

### Status Icons
- `assets/ui/status/ui_status_divine_might_default.svg`
- `assets/ui/status/ui_status_startled_default.svg`
- `assets/ui/status/ui_status_weak_default.svg`
- `assets/ui/status/ui_status_evil_aura_default.svg`

### Panels
- `assets/ui/panels/ui_panel_reward_choice_default.svg`
- `assets/ui/panels/ui_panel_shop_item_default.svg`
- `assets/ui/panels/ui_panel_rest_action_default.svg`

### Scene Backgrounds
- `assets/generated/scenes/scene_event_folklore_crossroad_v1.png`
- `assets/generated/scenes/scene_shop_night_market_stall_v1.png`
- `assets/generated/scenes/scene_rest_temple_courtyard_v1.png`

## 小尺寸資產
### Character Icon
- `assets/generated/icons/characters/tongji_portrait_icon_v1.png`

### Enemy Icons
- `assets/generated/icons/enemies/*.png`（6 張）

### Card Mobile-safe Crops
- `assets/generated/cards/mobile_safe/*.png`（11 張）

## 用途
- `character_icon`：角色選擇、小頭像、頂欄
- `enemy_icon`：戰鬥列表、圖鑑、intent 鄰近小頭像
- `mobile_safe`：小尺寸卡牌顯示、reward/shop 列表、手牌縮圖
- `scene backgrounds`：event/shop/rest overlay 或章節畫面背景

## 給 Aida 的直接建議
1. 優先把 `mobile_safe` 版本接到小尺寸卡牌列表，而 full art 留給詳情 overlay。
2. `enemy_icon` 用在戰鬥上方或圖鑑列表，避免完整立繪塞太小。
3. `scene_*` 可先作 overlay 背景或模糊底圖，不必一開始就強綁 location system。
4. `status icons` 與 `intent badges` 可以共存：status 顯示持續效果，intent 顯示即將行動。