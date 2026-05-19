# COTIW UI/UX 素材清單（給 Aida）

## A. 已存在可沿用
- `assets/ui/boot_splash.png`
- `assets/ui/main_menu_bg.png`
- `assets/ui/icons/*.svg`（14 個系統 icon）
- `assets/ui/smoke_puff.png`

## B. 必補 UI 素材

### B1. 卡牌系統
- common / uncommon / rare / boss / curse 邊框各 1
- 卡背 1
- 費用角標 1
- 升級星 / 印章 1
- 被選取高亮框 1

### B2. 按鈕系統
- primary CTA
- secondary button
- tab button
- icon square button
- disabled state
- pressed state

### B3. 面板系統
- modal panel
- tooltip panel
- shop item panel
- reward choice panel
- status pill
- toast panel

### B4. 戰鬥 HUD
- HP bar
- Armor bar
- Energy counter / orb
- Turn banner
- Enemy intent badge
- hand glow / draggable card highlight

### B5. 地圖系統
- battle node
- elite node
- rest node
- event node
- shop node
- boss node
- selected path glow
- locked node state

### B6. 經濟與 meta
- 香火 icon
- 元寶 / 銀兩 icon
- 等級 / 經驗 icon
- 遺物格 icon
- 收藏 / 圖鑑 icon

### B7. 特效點綴
- 香火粒子
- 金粉高光
- 青藍靈光
- 符紙飛散
- 印章落下

## C. 螢幕交付優先順序
1. Main Menu
2. Combat
3. Map
4. Reward
5. Shop
6. Rest
7. Card Detail Tooltip
8. Pause / Summary

## D. 檔案格式規範
- SVG：線框、icon、面板、按鈕結構
- PNG：像素角色、敵人、卡圖、光效貼圖
- JSON：theme token / 尺寸規格 / 元件 mapping

## E. Aida 開發時注意
- 先從 `docs/design/design_tokens.json` 讀 theme 值
- 按 `docs/design/wireframes/*.svg` 對齊版面
- 施工前先看 `docs/design/production-specs/*.md`
- 接圖與接版面時以 `docs/design/production-specs/ui_asset_registry.json` 為主；若要擴充再參考 `ui_asset_registry.template.json`
- 能共用的按鈕 / panel 必須抽成可重用元件
- Godot scene 裡禁止複製一堆各自為政的 style 覆蓋
