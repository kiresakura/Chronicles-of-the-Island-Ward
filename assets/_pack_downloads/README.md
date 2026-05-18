# Asset Pack Downloads

> 從 itch.io 下載的 zip 丟這裡，然後跑 `python3 scripts/import_asset_packs.py`

## 待下載清單（請從 itch.io 取得）

| 用途 | Pack 名稱 | URL | 預期 zip 命名（盡量保留關鍵字） |
|---|---|---|---|
| ⭐ 卡牌邊框 + UI | Card Frame Template Prototype | <https://piposchpatz.itch.io/card-frame-template> | `*piposchpatz*.zip` 或 `*card-frame*.zip` |
| 卡牌 + 圖示 | Pixel Fantasy Cards | <https://itch.io/game-assets/tag-deck-building/tag-pixel-art> | `*pixel-fantasy-cards*.zip` |
| ⭐ 妖怪 + UI + Tile | Yokai Realm | <https://etahoshi.itch.io/yokai-realm-etahoshi> | `*yokai-realm*.zip` 或 `*etahoshi*.zip` |
| 30 隻妖怪 | CP32 Pixel Yokai | <https://pixelartmaterial.itch.io/cp32-30-pixel-yokai-urban-legends-png-smlll> | `*cp32*.zip` 或 `*pixel-yokai*.zip` |
| Boss 暗黑妖怪 | Graveyard & Undead Yokai | <https://megentarou.itch.io/japanese-dark-fantasy-enemies-graveyard-undead-yokai> | `*graveyard*.zip` 或 `*megentarou*.zip` |

## 流程

1. 你登入 itch.io，逐一下載這 5 個 zip（多數 USD 3-10）
2. 把 zip 丟到本資料夾，**檔名不用改**
3. 終端機跑：

   ```bash
   python3 scripts/import_asset_packs.py
   ```

4. 腳本會：
   - 解壓到 `external/sprites/<分類>/`（依檔名關鍵字自動分類）
   - 蒐集 license / readme 寫到 `docs/THIRD_PARTY_LICENSES.md`
   - 跑 `godot --headless --import` 讓 Godot 認新 texture
5. 跟我說「import 完成」，我會：
   - 改 Card.tscn 引用新卡牌邊框
   - 改 MapLocation.tscn 引用新節點 icon
   - 改 BaseCombatant.tscn 引用新敵人 sprite
   - 改主畫面神龕背景
   - 重 export Android APK 真機驗證
