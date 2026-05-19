# Aida 最終交接包（COTIW / 鎮島錄）

Aida，從這一刻開始，你接手的是 **UI/UX 與美術資產實裝**，不是重新發明審美。

你的目標很明確：

> 把 `/Users/crimson/Developer/COTIW` 內已經準備好的設計系統、UI 元件、AI 圖像資產，穩定接入 Godot，完成 mobile-first 的可玩介面。

---

## 0. 先讀這些文件

依序讀：

1. `docs/design/COTIW_UI_UX_ART_DIRECTION.md`
2. `docs/design/design_tokens.json`
3. `docs/design/asset_manifest.md`
4. `docs/design/AIDA_HANDOFF.md`
5. `docs/design/production-specs/asset_naming_and_structure.md`
6. `docs/design/production-specs/card_system_spec.md`
7. `docs/design/production-specs/button_and_panel_spec.md`
8. `docs/design/production-specs/hud_and_map_spec.md`
9. `docs/design/production-specs/fx_spec.md`
10. `docs/design/production-specs/b2_component_specs.md`
11. `docs/design/production-specs/b2_ai_art_batch_v1.md`
12. `docs/design/production-specs/b2_ai_art_batch_v2.md`
13. `docs/design/production-specs/ui_visual_and_small_assets_batch_v1.md`
14. `docs/design/production-specs/ui_asset_registry.json`
15. `docs/design/wireframes/*.svg`

---

## 1. 已可直接使用的素材

### UI SVG 元件
- `assets/ui/frames/*.svg`
- `assets/ui/badges/*.svg`
- `assets/ui/map/*.svg`
- `assets/ui/bars/*.svg`
- `assets/ui/cardbacks/*.svg`
- `assets/ui/stamps/*.svg`
- `assets/ui/status/*.svg`
- `assets/ui/panels/*.svg`

### AI 生成大圖
- `assets/generated/characters/tongji_portrait_v1.png`
- `assets/generated/cards/*.png`（11 張已齊）
- `assets/generated/enemies/*.png`（第一章 6 隻已齊）
- `assets/generated/scenes/*.png`

### 小尺寸資產
- `assets/generated/icons/characters/tongji_portrait_icon_v1.png`
- `assets/generated/icons/enemies/*.png`
- `assets/generated/cards/mobile_safe/*.png`

---

## 2. 已經接好的資料檔

這些 JSON 已經有 texture path：

### Character
- `external/data/characters/character_tongji.json`

### Cards
- `external/data/cards/tongji/*.json`（11 張全部已接）

### Enemies
- `external/data/enemies/act1_mountain/*.json`（6 隻全部已接）

你不需要從零補圖路徑，先利用既有資產落畫面。

---

## 3. 你的實作優先順序

### 第一階段：共用元件化
1. 將 `design_tokens.json` 映射成 Godot 可重用常數／theme 資源
2. 抽共用：
   - buttons
   - panels
   - bars
   - badges
   - status icons
3. 確保不要每個 scene 各寫一套 style override

### 第二階段：戰鬥與小尺寸資產整合
1. full art 用在詳情或大卡
2. `mobile_safe` 用在：
   - 手牌縮圖
   - reward 列表
   - shop 列表
3. `enemy_icon` 用在：
   - 戰鬥 HUD
   - 圖鑑 / 清單
4. `intent badges` + `status icons` 分層顯示

### 第三階段：地圖與 overlay
1. `assets/ui/map/*.svg` 接節點
2. `scene_event_*`, `scene_shop_*`, `scene_rest_*` 用作 overlay 背景或 blur 背景
3. reward / shop / rest panel 套用 `assets/ui/panels/*.svg` 視覺語言

### 第四階段：主選單與角色頁
1. 主選單延續 Temple Neon Pixel
2. 角色頭像優先用 `tongji_portrait_icon_v1.png`
3. 大圖可用 `tongji_portrait_v1.png`

---

## 4. full art / mobile-safe / icon 的使用規則

### Full art
用途：
- 卡牌詳情
- 敵人立繪
- 角色頁
- 大型場景背景

### Mobile-safe
用途：
- 手牌縮圖
- reward / shop 卡片小圖
- 小尺寸卡面列表

### Icon
用途：
- 上方頭像
- 小 UI list
- compact HUD

**不要把 full art 硬塞進小 UI。那很醜。**

---

## 5. 目前最重要的實作原則

1. **mobile-first**：1200×700 **橫向**優先（2026-05-19 定案；早期 portrait 1080×2340 作廢）
2. **資訊優先於特效**
3. **不要做回 desktop 版型**（指：不要做滑鼠 hover 才能用、桌機鍵鼠導向的版型；橫向本身是定案方向，觸控優先不變）
4. **不要讓金字壓花背景看不清**
5. **不要把所有東西都發光**
6. **保持 Temple Neon Pixel 的一致語言**

---

## 6. 驗收標準

你交出來的東西至少要達成：

- 小手機上可讀
- full art 與 mobile-safe 分工清楚
- 戰鬥、reward、shop、rest 視覺語言一致
- 敵人 / 卡牌 / status / intent 不互相混淆
- 一眼看得出是台灣廟會題材，不是 generic 和風遊戲

---

## 7. 你現在最該先動的檔案

優先檢查並實裝到這些：

- `scripts/ui/Card.gd`
- `scripts/ui/Combat.gd`
- `scripts/ui/RewardOverlay.gd`
- `scripts/ui/ShopOverlay.gd`
- `scripts/ui/RestOverlay.gd`
- `scripts/ui/Map.gd`
- `scripts/ui/MapLocation.gd`
- `scripts/ui/CharacterButtonContainer.gd`
- `scripts/ui/menus/MainMenu.gd`

對應 scene：
- `scenes/ui/Card.tscn`
- `scenes/ui/MapLocation.tscn`
- `scenes/Root.tscn`
- 各 overlay / shop / reward / rest scene

---

## 8. 最後一句

這批資產已經不是「概念」，而是可以施工的材料。

你現在要做的不是思辨美學，而是：

> **把這套材料變成真的可玩、可讀、可上手機的遊戲介面。**

別做醜。