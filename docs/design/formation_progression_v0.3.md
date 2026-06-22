# 五營陣型 × 神明養成（formation & progression）— v0.3「換骨」設計

> **文件狀態**：方向提案，待 `憲龍` 拍板（屬 `QUESTIONS.md` 級決策）
> **定位**：這不是 Phase 3 打磨，是把戰鬥核心從「卡牌」換成「陣」的 **v0.3 重新立柱**。請先讀 `PRD.md` §3–5、`docs/design/ritual_combat_system.md`，再讀本文。
> **一句話**：把玩的單位從「一個拿牌的英雄」換成「一個鎮守五營的壇主」——這是徹底擺脫殺戮尖塔「骨架」（抽牌／能量／單體英雄／爬塔／解卡）的方案。

---

## 0. 為什麼要這份文件

`v0.2` 已經把 StS 的**皮**換掉了（破煞／合符／請神／遶境／修廟）。但戰鬥**骨架**仍是 StS：抽一手牌、花神力、單體英雄打敵人意圖。本文提的兩個系統，是換骨的兩刀：

| StS 骨頭 | v0.3 換成 | 屬性 |
|---|---|---|
| 抽手牌 · 花神力 · 單體英雄（無走位） | **五營佈陣**：空間軸 + 時間軸 | 陣型 |
| 戰後抽卡 · meta 解卡池（抽到才強） | **神格 / 敕封 / 緣分** 三層養成 | 養成 |

> ⚠️ **複雜度紅旗**：`PRD §13` 已自評「系統過度複雜」為高風險。本案的鐵則是 **「換，不是加」**——五營要*取代*抽牌花神力的認知負擔，不是疊上去；並用既有 `修廟` 解鎖做**漸進揭露**。

---

## 1. 系統一：五營陣型

### 1.1 棋盤：五營羅盤（資料驅動）

戰場是一張 **五營** 羅盤：東營（青／木）、南營（紅／火）、西營（白／金）、北營（黑／水）、中營（黃／土，中壇元帥哪吒坐鎮）。這是台灣民俗現成的「五方位軍陣」，StS 結構上沒有我方棋盤，抄不走。

新資料類別 `data/prototype/FormationCampData.gd`（`extends PrototypeData`），資料放 `external/data/formation_camps/*.json`，沿用既有 `{patch_data, properties}` 信封：

```json
{
  "patch_data": {},
  "properties": {
    "object_id": "camp_south",
    "camp_name": "南營",
    "camp_direction": "south",
    "camp_element": "fire",
    "camp_color": "red",
    "camp_general": "朱雀",
    "camp_unlock_feature": "formation_camp_south"
  }
}
```

固定 5 筆（東南西北中）。`camp_direction` 五者唯一、`camp_element` ∈ 五行、`camp_unlock_feature` 對映 `修廟` 解鎖鍵（見 §3）。

### 1.2 空間軸（擺哪）— StS 完全沒有的維度

- **方位 lane**：煞／妖從某個方位來，沿該 lane 推進；該方位的營去攔。營空了或被破，那道煞 **直擊母壇**（`altar_integrity` 取代「玩家元神」當作敗北條件）。
- **得位 / 失位（五行，選用、可漸進開啟）**：把單位的 `unit_element` 與所在 `camp_element` 比對——同行＝**得位（旺）**，效果／請神值加成；相剋＝**失位（衰）**。為向後相容，於 `DeityData` 增 `@export var deity_element: String = ""`（預設空＝中性、零影響，吃**鐵律 1 資料驅動 + 不破既有測試**）。
- 「該把誰擺哪」第一次成為真決策：火神放南營旺、放北營衰；空北營則水煞長驅直入。

### 1.3 時間軸（何時）— 把回合從「抽牌」換成「編陣 + 調度」

每回合的主要動詞不再是「抽 5 張、花 3 點神力打掉」，而是：

1. **佈陣 / 調營**：把神明・家將部署到營、在營間移防（複用 `RitualLoadout.resolve_deity_queue()` 作為開場佈陣初值）。
2. **儀式序列**：請神 → 合符 → 降乩 → 鎮煞，依序釋放（複用 `DeityInvocationSystem` 的觸發鍵 `on_enemy_broken / on_block_gained / …`）。
3. **擲筊節奏閘**：複用既有 `scripts/systems/ritual/FortuneSticks.gd`——聖筊＝加速（多一個動作）、笑筊＝卡住（無效）、陰筊＝反噬（某 lane 煞氣暴衝）。這是取代「能量曲線」的 push-your-luck 心跳。
4. **犒軍**：花「香」刷新疲勞／被破的營（中營哪吒為調度中樞）。

符令卡（`fu_ling`）保留，但降格為「下給某個營的號令」，不是「一手要打掉的牌」。**手牌／神力從核心降為輔助層**——這是換骨的判準動作。

### 1.4 與既有系統的接點（fork-first，不重造）

| 既有 | 五營如何接 |
|---|---|
| `building_main_hall`（正殿）`unlocks: ["deity_slot"]` | **直接複用**：正殿等級＝可開的**營位數**（§3 漸進揭露） |
| `RitualLoadout.resolve_deity_queue(guardian, tool, slots)` | `slots` 改解讀為「開場可佈陣的營位數」，回傳隊列＝初始佈陣 |
| `DeityInvocationSystem` / `DeityChargeController` | 降乩仍走原觸發路由；差別是「在哪個營降乩」會吃得位加成 |
| `FortuneSticks`（擲筊） | 直接當序列節奏閘，不必新寫 |

---

## 2. 系統二：神明養成（三層、三個時間尺度）

StS 養成只有兩薄層（局內抽卡、meta 解卡池）。換成三層，成就感與策略縱深才出得來。**統一原則：戰力來自「餵誰的神格、敕封誰的位階、把誰跟誰合祀」，不是抽卡 RNG。**

### 2.1 局內 — 神格 / 神蹟（餵出來的 build）

神明不靠經驗值升級，靠 **靈驗**：在破煞窗口／命中弱點時成功降乩，該神「神格」充能 → 當局解鎖逐階 **神蹟**（取代「卡牌升階」）。直接複用 `DeityData.deity_charge_tags` / `card_deity_charge` 管線，新增（向後相容、預設空）：

```gdscript
## 局內神格門檻 → 神蹟效果（當局有效，不持久）
@export var deity_efficacy_feats: Array[Dictionary] = []
# 例：[{ "threshold": 2, "effect": "tiger_roar_aoe_up", "desc": "虎爺咬煞波及範圍 +1" }]
```

你選擇**餵哪個神** → 每局長出不同流派。

### 2.2 跨局 — 敕封位階（長線骨幹、封神榜）

`香火`（`ProfileData.profile_incense_balance`）除了修廟，還能 **敕封**：把神明／家將位階往上抬 **將 → 帥 → 神 → 帝**。每升一階永久解鎖**選項**（新招式／加一個可佈陣營位資格／開一條緣分），而非單純堆數值。

- 持久層：`ProfileData` 增 `profile_deity_rank: Dictionary[String, int]`（deity_id → 0..3）。
- 新系統 `scripts/systems/ritual/CanonizationSystem.gd`（仿 `RitualTemple` 靜態函式風格）：`can_canonize(profile, deity_id)` / `canonize(profile, deity_id)`，扣 `profile_incense_balance`。
- 階級成本／解鎖資料化：`external/data/canonization/rank_tiers.json`（成本遞增、每階 `grants` 功能鍵）。

> **變現紅線**：敕封 **只花香火（玩出來的）**，元寶永遠碰不到（同 `RitualTemple` 註解的鐵則）。
> **防 grind-wall 設計原則**：敕封盡量給「**選項 / 側向**」而非碾壓數值，讓勝負仍靠當局操作（像 StS 解鎖卡池，不像 gacha 練等）。
> **策略張力（刻意）**：`修廟` 與 `敕封` 共用同一池香火 → 「廣度（多開選項）vs 深度（養精一神）」的 meta 抉擇。

### 2.3 配對 — 緣分 / 合祀（開局前的解謎）

神明與家將有神話 **緣分**：媽祖配千里眼＋順風耳、關帝配周倉＋關平、哪吒鎮中營。把有緣分的單位 **合祀** 在**相鄰的營**，解鎖 **合擊** 與陣眼加成。養成從「一條數值」變成「一張你拼湊的神話關係網」，且**直接餵給陣型**（你把誰擺誰旁邊有差）。

資料 `external/data/affinities/*.json`：

```json
{
  "patch_data": {},
  "properties": {
    "object_id": "affinity_mazu_eyes_ears",
    "affinity_name": "媽祖·千里眼順風耳",
    "affinity_member_ids": ["deity_mazu", "general_qianliyan", "general_shunfenger"],
    "affinity_adjacency_required": true,
    "affinity_combo_effect": "combo_sea_watch",
    "affinity_combo_description": "相鄰合祀時，每回合預警一道煞 lane 並先制削煞。"
  }
}
```

由 `FormationSystem` 在佈陣時判定鄰接 → 觸發合擊。

---

## 3. 漸進揭露（複雜度緩解，對映既有修廟解鎖）

新手不能一次面對 五營×五行×敕封×緣分。用既有 `RitualTemple.feature_open(profile, feature)` 閘控，**逐步開**：

| 階段 | 開放 | 對映既有解鎖 |
|---|---|---|
| 前 2 場 | 只有 **中營 + 1 營**（2 營）、無五行、無緣分；動詞只剩「擺神、守 lane」 | 基線 |
| 正殿 Lv1→3 | 每級多開營位（2→4→5 營） | `building_main_hall` 的 `deity_slot`（已存在，重新解讀為「營位」） |
| 首次破大醮後 | 開 **封神榜（敕封）** | 新增解鎖鍵 `canonization` |
| 擁有 ≥2 有緣單位 | 顯示 **緣分**提示與合祀 | 新增解鎖鍵 `affinity_hint` |
| （選用）裝旗後 | 開 **五行得位** | 新增 `building_five_camp_banner`（meta_buildings 增一棟）或掛 `籤詩亭` |

新手前兩場「關閉請神槽」的既有作法（`PRD §13`）延用到五營：先給空間直覺，再層層加深。

---

## 4. 資料 schema 與 validator（鐵律 1 的回歸防線）

於 `tests/unit/test_ritual_schema.gd` 既有風格新增常數與測試（新資料一旦欄位不合法即紅燈）：

```gdscript
const VALID_ELEMENTS: Array[String] = ["wood", "fire", "earth", "metal", "water"]
const VALID_DIRECTIONS: Array[String] = ["east", "south", "west", "north", "center"]
const MAX_DESC_LEN: int = 60   # 描述長度上限：從源頭杜絕 UI 截斷（呼應新一局批判）
```

新增測試（命名沿用 `test_*_schema_valid`）：

- `test_formation_camp_schema_valid()`：恰 5 營、`camp_direction` 唯一且 ∈ VALID_DIRECTIONS、`camp_element` ∈ VALID_ELEMENTS、`camp_unlock_feature` 非空。
- `test_deity_element_valid()`：`deity_element` ∈ VALID_ELEMENTS 或 `""`。
- `test_affinity_schema_valid()`：`affinity_member_ids` 全部存在於 deities／generals；`affinity_combo_effect` 非空。
- `test_canonization_rank_tiers()`：成本嚴格遞增；**禁止出現任何元寶／IAP 欄位**（變現紅線的測試化）。
- `test_descriptions_within_length()`：deities / camps / affinities 的描述 ≤ `MAX_DESC_LEN`（**把「新一局」的文字截斷問題在資料層卡死**）。

---

## 5. 三感對照（直接回答趣味／成就／策略）

| 需求 | 由哪些機制供給 |
|---|---|
| **趣味性** | 五營佈陣 + 五行得位 + 擲筊節奏 + 神話合擊 = 四個 StS 沒有的動詞；發現緣分連段的驚喜 |
| **成就感** | 敕封 將→帝、封神榜收集、緣分網填滿、修廟成長——**死了不歸零**的長線 |
| **策略性** | 空間（五營/五行）× 時間（序列/擲筊）兩條正交軸相乘；緣分配對是**開局前**解謎、遶境路由是**宏觀**、調營犒軍是**微觀**——三個時間尺度都要想 |

---

## 6. 紅線自檢

- **變現**：敕封／緣分／修廟皆只花**香火**；元寶仍只買外觀。無戰力 Gacha、無抽卡。✅
- **名詞**：用 五營／得位／調營／犒軍／敕封／位階／神格／神蹟／合祀／緣分／合擊／降乩／破煞／煞盾；**禁** 韌性／弱點擊破／升階／終結技。✅
- **fork-first**：新增資料類別 + 系統腳本 + JSON，複用 正殿/Loadout/Invocation/FortuneSticks/Temple；不大改 framework 核心。✅
- **mobile-first**：五營羅盤需專為 1200×700 橫向設計，營位點擊區 ≥ 88×88，長按看營詳情。（UI 細節另開）

---

## 7. 落地分期與「去留決策」

這比目前 Phase 3 排程大一級，建議**分流、先驗手感再 all-in**：

1. **原型分支**（throwaway，不碰主線）：最小可玩切片——3 營 + 佈陣/調營 + lane 煞 + 母壇 HP + 擲筊節奏。**單一目的：驗證「壇主鎮守五營」手感是否勝過「抽牌花神力」。** 見 `FIVE_CAMP_PROTOTYPE_PROMPT.md`。
2. **真機 A/B**：同一場戰鬥，現行卡牌版 vs 五營原型版，iPhone/Android 各跑一次，記錄手感。
3. **決策點（`憲龍`）**：手感過關才把五營升為主線 v0.3；不過關則保留為「家將/道士的進階陣位」局部機制，主線續守 v0.2 換皮版穩定出第一章。
4. 過關後依序：完整五行得位 → 敕封封神榜 → 緣分合祀 → 漸進揭露關卡 → 三解析度/真機驗收。

---

## 8. 開放問題（請進 QUESTIONS.md）

1. **要不要為徹底擺脫 StS 而換骨？**（高風險高回報）還是守 v0.2 換皮版穩出第一章？— 建議：分流原型先驗手感。
2. 五營戰鬥要保留多少「手牌」？（純佈陣 / 佈陣+小手牌 混合）— 影響換骨是否徹底。
3. 得位用**五行相生相剋**（深但重）還是**單一儀法 tag 命中**（輕但淺）？原型建議用最輕的二元加成。
4. 敕封給「選項」還是「數值」？比例多少不致變 grind-wall。
5. 家將／部將（千里眼等）要不要獨立資料類別 `FormationUnitData`，還是掛在 `DeityData`／`GuardianData` 下？

---

**END — formation_progression_v0.3.md**
