# Figma Make UI Adoption — 台灣元素卡牌遊戲 UI

> 來源：`https://www.figma.com/make/2quG1FGffZ23PINSJN2bog/...`
> 狀態：採用為 COTIW 橫向 mobile UX 參考，不作為可直接搬入 Godot 的最終設計稿。

## 採用原則

1. **採 UX 結構，不採硬編資料**
   - Figma Make 原型是 React/Vite，角色、商店、抽卡、tips 都寫在 TSX array。
   - COTIW 實作時必須改由 `external/data/**` JSON 或 localization CSV 驅動。
   - 第一個落地點：`external/data/ui/new_run_character_shelf.json`。

2. **採橫向 lobby 骨架，套 COTIW token**
   - 保留「左主角／中舞台／右側或底部 CTA／右上資源」的手遊 lobby 節奏。
   - 色彩仍以 `design_tokens.json` 的 Temple Neon Pixel 為準，不直接使用 Figma 的 slate cyberpunk 色系。

3. **抽卡視覺只轉成 reward / unlock 儀式**
   - PRD 明確禁止販售戰鬥力隨機抽卡。
   - Figma 的祈願結果卡、神龕光效可用於戰鬥獎勵、遺物獲得、meta 解鎖，不做付費 gacha。

4. **互動轉成觸控語言**
   - React `hover` / `whileHover` 只作為桌面 preview。
   - Godot 端使用 `TouchFeedback` 的 pressed / selected / disabled / long-press detail。

## 畫面映射

| Figma Make 畫面 | COTIW 映射 | Phase |
|---|---|---|
| LoadingScreen | 可作 Splash/預載畫面參考；目前尊重既有 v6「直接進 Root」設定，不主動復活 loading | Later |
| MainMenu | 已映射到 `scripts/ui/menus/MainMenu.gd` 的 lobby、資源列、主 CTA、底部功能 slot | Phase 1 |
| CharacterScreen | 映射到 `NewRunMenu` + `CharacterGallery`，作為新局選角與起手資訊 | Phase 1 |
| ShopScreen | 映射到局內夜市商店；保留 tabs/grid/買不起狀態，不賣戰鬥力 | Phase 2 |
| GachaScreen | 不做付費抽卡；拆出 reward reveal / unlock ceremony | Phase 2+ |

## 已落地

- `scripts/ui/menus/NewRunMenu.gd`
  - 角色 gallery 採左資訊、中央神位、底部開局 guide 的布局。
  - 展示文案與玩法 tag 改讀 `external/data/ui/new_run_character_shelf.json`。

- `scripts/ui/menus/MainMenu.gd`
  - Lobby 功能 slot 改讀 `external/data/ui/lobby_actions.json`。
  - 右上工具鈕改讀 `external/data/ui/lobby_utilities.json`。

- `tests/unit/test_character_gallery.gd`
  - 驗證角色展示 JSON 存在、可解析、欄位完整、portrait 檔存在。
  - 驗證所有已註冊可玩角色都出現在 New Run 展示資料中。
  - 驗證 lobby action / utility JSON 的 slot 數量、icon 路徑與 act 類型。

## 後續

1. 建立 `external/data/ui/loading_tips.json`，若恢復 loading 畫面，tips 不再寫死在 GDScript。
2. Shop/Reward 實作時只吸收 Figma 的資訊層級與動效節奏，價格、商品、獎勵全部接 run 資料。
3. 後續 i18n pass 將這些 UI JSON 中的中文文案改為 translation key。
