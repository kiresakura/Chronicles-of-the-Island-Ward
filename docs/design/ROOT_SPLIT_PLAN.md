# Root.tscn 拆分前置計畫

> 狀態：拆分前 guard 文件。現階段**不直接拆 `scenes/Root.tscn`**，先固定 ownership、測試契約與可搬移邊界，避免一次性重構破壞 STR 原始接線。

## 目標

`Root.tscn` 目前同時承載 title、run、combat、shop、reward、map、pause 等畫面。後續拆分的目標不是改變 runtime 行為，而是把大型場景逐步拆成可測、可復用的子場景。

## 不變契約

- 主入口仍為 `res://scenes/Root.tscn`。
- `RunScreen/Combat` 在第一階段仍保留原路徑，避免既有腳本與 smoke test 失效。
- `Combat._ready()` 掛載的 additive overlays（`CombatHudOverlay`、`CombatFxOverlay`）維持在 `RunScreen/Combat` 底下。
- 拆分時不改戰鬥核心數值、不改卡牌資料、不改 signal 語意。

## Ownership / 邊界分組

| 分組 | Root 內目前路徑 | 建議後續子場景 | 說明 |
|---|---|---|---|
| Title Shell | `TitleScreen` | `scenes/ui/title/TitleScreen.tscn` | 主選單、新局選單、圖鑑入口的外殼。 |
| Main Menu | `TitleScreen/MainMenu` | `scenes/ui/menus/MainMenu.tscn` | 角色展示、主選單按鈕、資源 HUD。 |
| New Run | `TitleScreen/NewRunMenu` | `scenes/ui/menus/NewRunMenu.tscn` | 選角色、難度、seed。 |
| Run Shell | `RunScreen` | `scenes/ui/run/RunScreen.tscn` | Run 期間所有 overlay 的共同容器。 |
| Combat | `RunScreen/Combat` | `scenes/ui/combat/CombatScreen.tscn` | 戰鬥主畫面；先只搬視覺節點，不改 `Combat.gd` signal 接線。 |
| Reward | `RunScreen/RewardOverlay` | `scenes/ui/run/RewardOverlay.tscn` | 獎勵領取與 continue。 |
| Shop | `RunScreen/ShopOverlay` | `scenes/ui/run/ShopOverlay.tscn` | 商店商品、NPC info、離開按鈕。 |
| Map | `RunScreen/Map` | `scenes/ui/run/MapScreen.tscn` | 分支地圖與 location container。 |
| Pause | `RunScreen/PauseOverlay` | `scenes/ui/run/PauseOverlay.tscn` | 暫停、返回 title、放棄 run。 |
| Dialogue / Event | `RunScreen/DialogueOverlay` | `scenes/ui/run/DialogueOverlay.tscn` | 事件文字與選項。 |
| Card Selection | `RunScreen/CardSelectionOverlay` / `RunScreen/CardDraftSelectionOverlay` | `scenes/ui/run/CardSelectionOverlay.tscn` | 選卡、draft、skip。 |

## 建議拆分順序

1. **文件 + 測試契約**：保證上表路徑存在，且 overlay 不漏到主畫面。
2. **純展示 overlay 先拆**：Reward / Pause / Dialogue。這些對 combat core 依賴較低。
3. **Map / Shop 拆分**：保留 container node name，讓既有 scripts 仍能 `get_node()`。
4. **Combat 視覺節點拆分**：先拆背景與 HUD 容器，最後才碰 `Combat.gd`。
5. **RunScreen shell**：全部子場景穩定後，才把 `RunScreen` 本身 scene 化。

## Guard 測試

- `tests/unit/test_root_split_contract.gd` 讀取 `Root.tscn` 與本文件，檢查每個拆分邊界仍被明確記錄。
- `tests/integration/test_combat_flow_smoke.gd` 保證 `Root.tscn → RunScreen/Combat → CombatHudOverlay` 的 runtime 路徑仍可啟動。

## 禁止事項

- 不在同一個 PR/任務裡同時拆 `Root.tscn` 與改 combat core。
- 不把 CanvasLayer overlay 掛到全域 root；它們必須跟著 `host.is_visible_in_tree()` 同步顯隱。
- 不移除既有穩定 node name，除非先更新 tests 與所有 `get_node()` 呼叫點。
