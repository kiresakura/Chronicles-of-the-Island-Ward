# 鎮島錄 — Phase 2 規劃：完整第一章遶境

| 項目 | 內容 |
| --- | --- |
| 文件狀態 | 規劃草案（待憲龍確認順序 / 決策點） |
| 最後更新 | 2026-06-06 |
| 對應 PRD | §11 Phase 計畫「2 完整第一章遶境」 |
| 前置 | Phase 1（1A 文件/schema · 1B 破煞 · 1C 合符 · 1D 請神）✅ 已完成、測試 126/126 |

---

## 0. 目標

讓**第一章端到端可玩**：出巡 → 配置班底 → 遶境路線 → 巡境遇煞（破煞/合符/請神）→ 鎮煞大醮 → 結算香火 → 修廟。
延續 Phase 1 的工作模式：**純系統 → 執行接線 → UI → 測試**，每個子階段可獨立 ship、測試綠燈、不破壞 framework 核心。

## 1. 現況盤點（Phase 2 觸及的既有系統）

| 系統 | 既有 | 對 Phase 2 的意義 |
|---|---|---|
| 地圖 | `Map.gd` `populate_locations(Array[LocationData])` + `LOCATION_TYPES` + 故事層/route 狀態/boss omen | **資料驅動** → 遶境是 relabel + route_traits 套用，非重寫生成 |
| 存檔 | `data/mutable/ProfileData.gd`（@export 序列化 profile） | 修廟 meta 直接擴充欄位，持久化已就緒 |
| 開局 | `NewRunMenu` / `RunStartOptions` / `CharacterGallery` / `Signals.character_selected` | 主祭已可選；加護壇/法器 picker |
| run 規則 | `BaseRunModifier` + 難度/自訂 modifier | 籤詩亭（修廟）→ run modifier 天然對應 |
| Boss | `enemy_tiger_god`（enemy_type=2, 120 HP） | 鎮煞大醮素材已在；多階段機制待加 |
| 四支柱 | 破煞/合符/請神（虎爺）已接線 + 測試 | 多神 / guardian / tool 規則待接 |
| 資料 | deities×4 / guardians×2 / ritual_tools×3 / route_traits×4 / meta_buildings×6 已落地 + 驗證 | Phase 2 接線即可，無須重造資料 |

## 2. 子階段（每個獨立可交付）

### 2A — 多神請神效果（完成請神支柱）
- **目標**：城隍 / 媽祖 / 土地公 三神降乩效果 + 觸發條件接線。
- **範圍**：Combat `_execute_deity_invocation` 加 `judgment` / `merciful_tide` / `land_blessing` 分派；補觸發鉤——媽祖 `on_block_gained`（既有 `combatant_block_added` 可用）、城隍 `on_debuff_applied`（需新 debuff 訊號或借 status 套用點）、土地公 `manual`。
- **依賴**：1D ✅。**風險**：低（純擴充 1D 架構）。**估**：小。
- **落地檢核**：3 神整合測試（累積→降乩→效果）＋既有綠燈。
- **狀態**：✅ **已完成（2026-06-06）**——4 神觸發路由（on_enemy_broken/on_block_gained/on_debuff_applied）+ 降乩效果（judgment/merciful_tide/land_blessing）接線；新增 `Signals.debuff_applied` 鉤；真實樹整合測試通過，128/128。

### 2B — 主祭 / 護壇 / 法器 配置（解除「固定虎爺」）
- **目標**：開局三件配置；套用 guardian 被動 + 支援卡 + tool 規則；**出戰神明由配置決定**。
- **範圍**：`NewRunMenu`/`RunStartOptions` 加 護壇 + 法器 picker（資料已備）；`Global.start_run` 接收 loadout；套 `guardian_support_card_ids` 進起手牌庫、`tool_*` 規則（破煞 +1 / 請神 +N / 香火 +N 已資料化）、active deity = guardian/tool 的 affinity。
- **依賴**：2A（多神才有選神意義）。**風險**：中（觸 run-start + 角色選擇 UI）。**估**：中。
- **落地檢核**：loadout 套用整合測試（guardian 支援卡入庫、tool 破煞 +1 生效、active deity 正確）。
- **狀態**：✅ **完成（2026-06-06）**——系統（`RitualLoadout` + `start_run`：護壇卡入庫、法器加成、affinity 解析出戰神明）+ **選擇器 UI**（NewRunMenu 護壇/法器 OptionButton → start_run，選項資料驅動）。⏳ UI 視覺版位待真機微調。

### 2C — 道士 + 家將 角色與卡組
- **目標**：兩新角 + 各 ~10 張卡（帶 ritual 欄位）。**先復用既有機制**（武訣/護壇/符令 + 破煞/合符/請神）。
- **範圍**：character JSON ×2 + cards ×~20 + 註冊角色表 + 立繪（已有 portraits_v3 daoshi/jiajiang）。專屬機制（道士「符位/法陣」、家將「前鋒/中壇/後衛陣型」）→ 拆 **2C-2** 後續（或 Phase 3）。
- **依賴**：無（內容，可與 2B 平行）。**風險**：低-中。**估**：中（內容量）。
- **落地檢核**：新角 schema 測試（起手卡/合成圖/弱點協同）＋角色表測試更新。
- **狀態**：✅ **完成（2026-06-06）**——道士/家將 各 8 基礎卡（每角 2 條合符鏈）+ 完整生態（color/pack/player/角色）+ 預設班底（道士→媽祖、家將→虎爺）；角色表 4 角、142/142。符位/法陣、陣型專屬機制留 Phase 3；卡面美術待生成。

### 2D — 修廟 meta（香火經濟 + 永久解鎖）
- **目標**：戰後結算香火 → 修廟 → 解鎖內容（神明位/法器池/籤詩/商店/被動）。
- **範圍**：`ProfileData` 加 `incense_balance` + `building_id_to_level`；修廟 screen（新 UI）；建築 `unlocks` 套進 run-start（deity slot 數、tool 進選池、run modifier、shop stock）。**變現鐵則**：只花香火、元寶純外觀。
- **依賴**：2A-2C（要有可解鎖內容）。**風險**：中（持久化 + 新 screen + run-start 鉤子）。**估**：中-大。
- **落地檢核**：修廟存讀檔測試（香火扣除 + 等級持久）＋解鎖套用測試。
- **狀態**：✅ **系統完成（2026-06-06）**——`RitualTemple`（load/repair_cost 遞增/can_repair/repair/unlocked_features）+ `ProfileData` 加 incense + building_levels（序列化持久）+ `end_run` 結算香火（勝 200 / 敗 50）；152/152。⏳ **修廟 screen UI 留後續**；解鎖實際套進 run-start（deity_slot/tool pool/run modifier）為後續接線。

### 2E — 遶境地圖（新生成器，憲龍 2026-06-06 選定）
- **目標**：照遶境設計**另寫地圖生成器**，取代 STS 分支圖。節點型別（遇煞 / 惡煞據點 / 夜市香鋪 / 入廟安神 / 民俗問事 / 鎮煞大醮）+ route_traits（污染/香火/危險）**驅動分支結構、獎勵與危險度**。
- **範圍**：新 `PilgrimageMapGenerator`（產 `Array[LocationData]` 路線圖）+ Map.gd 接新生成器；route_trait 套節點獎勵；保留 LocationData/Map 既有渲染層。**以 feature flag / 並存方式切換**，contract 測試保護既有地圖直到新生成器就緒。
- **依賴**：建議排 2A-2C 之後（系統穩定再動地圖核心）。**風險**：高（重寫生成 + 觸 framework map）。**估**：大。
- **落地檢核**：生成器單元測試（分支結構合法、節點分佈、route_trait 套用）+ 地圖渲染整合 smoke + 既有地圖 contract 不破。
- **狀態**：✅ **完成（2026-06-06）**——`ActionGeneratePilgrimage`（沿用網格+鄰接+末端 Boss 的有效圖、疊加遶境路線：山路→夜市路→廟路→荒宅路、route_trait 標記到 LocationData、危險度決定遇煞難度池）；act_1 經 `act_action_script_path` 切換（框架擴充點，非 hack）。整合測試驗證圖有效（起點/大醮/可達/route_flavor），既有 smoke/contract 不破，146/146。⏳ 路線視覺主題、香火回報實際套用為後續。

### 2F — 鎮煞大醮（Boss）+ 第一章整合
- **目標**：百年虎爺多階段 Boss + 第一章端到端可玩 + 平衡 pass。
- **範圍**：Boss 多階段攻擊圖（既有 enemy_attack_states 可擴）+ 破煞窗口 boss 調參（broken_turns=2 已備）；第一章流程串接；難度平衡。
- **依賴**：2A-2E。**風險**：中。**估**：中-大。
- **落地檢核**：Boss 戰整合 smoke + 第一章可通關（headless 流程驗）。
- **狀態**：✅ **完成（2026-06-06）**——百年虎爺 HP 150、多階段（phase1 → 覺醒 → phase2 盛怒，9 attack states）；破煞 fist/fire 弱點 + break_invoke_window 窗口 2；第一章鏈完整（遶境 BOSS 節點 → boss pool → event_act_1_boss_1 → 虎爺），154/154。⏳ Boss 專屬演出 / 數值平衡為後續。

## 3. 推薦順序與理由

```
2A 多神請神 ─▶ 2B 配置 ──▶ 2D 修廟 ──▶ 2F Boss+整合
   (低/小)      (中/中)  ╲   (中/中大)    (中/中大)
                          ╲
2C 道士家將 ───────────────▶（可與 2B 平行）
   (低中/中)
2E 遶境地圖 ──────────────▶（獨立，任意插入）
   (中/中)
```

**理由**：先把「請神支柱」補完整（2A，低風險高值）→ 能組隊（2B，解鎖選神 + guardian/tool）→ 同時鋪內容（2C）與地圖皮（2E，獨立）→ 修廟（2D）綁長線、需前面有可解鎖內容 → Boss + 整合（2F）封頂。每階段獨立 ship + 測試，符合既有 pause-between-phases 節奏。

## 4. 決策（憲龍 2026-06-06 拍板）

1. **起手順序**：✅ 從 **2A 多神請神** 開始。
2. **道士/家將專屬機制**：✅ 2C **只上基礎卡**；符位/法陣、前鋒/中壇/後衛陣型留 **Phase 3**。
3. **修廟持久化**：擴充既有 `ProfileData`（@export 序列化）——待 2D 開工時最終確認。
4. **遶境地圖**：✅ **另寫遶境生成器**（非 reskin）。⚠️ 影響：2E 升為**高風險/大工程**、觸 framework map 核心；
   排在 2A→2B→2C 之後、系統穩定時再做，並以 feature flag 並存 + contract 測試保護既有地圖。

**據此定案的執行序**：**2A → 2B →（2C 內容平行）→ 2E 遶境生成器 → 2D 修廟 → 2F Boss+整合**。

## 5. Phase 2 Definition of Done

- [ ] 第一章可從出巡 → 大醮 → 結算香火 → 修廟 端到端跑通（headless 流程綠燈 + 真機不閃退）
- [ ] 四支柱 + 多神 + loadout 全資料驅動，無硬編碼戰鬥/神明數值
- [ ] 既有測試維持綠燈，每新系統有 validator / 單元 / 整合測試
- [ ] 橫向 1200×700 mobile UI 不遮卡、可觸控
- [ ] **辨識度**：玩家試玩能說出「破煞 + 請神 + 合符 + 遶境 + 修廟」，而非 STS 換皮

## 6. 風險與緩解

| 風險 | 緩解 |
|---|---|
| 系統疊加複雜（破煞×合符×請神×多神×loadout） | 漸進揭露；新手前場關閉部分支柱；2A→2B 一次只加一層 |
| 修廟持久化破壞既有 ProfileData 存檔 | 新欄位給預設值、向後相容；存讀檔測試先行 |
| 遶境改 Map.gd 觸 framework | 只 relabel + route_trait 套用，不動生成演算法；contract 測試保護 |
| 內容量（2 新角 + Boss 平衡） | 先深做、後平衡；道士/家將專屬機制可延 Phase 3 |
| Q-R1~R5 未決策卡住數值 | 先用已實作簡化版跑通，數值平衡併入 2F |
