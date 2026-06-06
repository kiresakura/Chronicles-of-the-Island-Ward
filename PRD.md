# 鎮島錄 / Chronicles of the Island Ward (COTIW)
## Product Requirements Document — v0.2（儀式編排型重構版）

> **文件狀態**：產品方向重構定案，逐步落地中
> **最後更新**：2026-06-06
> **負責人**：憲龍
> **接手者**：Claude Code
> **目標平台**：iOS App Store + Google Play Store
> **引擎**：Godot 4.4+（實測 4.6.1，GDScript 主、C# 備援）

---

## 0. 給接手者的話（Claude Code，請先讀這段）

這份 PRD 描述「**鎮島錄**」的產品輪廓。**v0.2 是一次定位重構**：把原本「殺戮尖塔換台灣民俗皮」的風險，改寫成一款有自身辨識度的 **「儀式編排型 roguelike 卡牌手遊」**。

**v0.1 → v0.2 改了什麼？**

- 戰鬥不再只是「出牌打數值」，而是 **完成一場鎮煞儀式**：合符 → 破煞 → 請神 → 護壇。
- 地圖不再是「爬塔」，而是 **遶境出巡**。
- 長線進度不再只是「解卡」，而是 **修復鎮島廟**。
- 開局不再只選一個職業，而是 **主祭 / 護壇 / 法器** 三件配置。

**你要遵守的三條鐵律（不變）**：

1. **資料驅動優先**：卡牌、敵人、神明、護壇、法器、路線、建築、本地化全部走 JSON / 設定檔，**不要硬編碼**在 GDScript。新系統的數值（弱點、破煞值、請神值）絕不寫死在 UI / combat script。
2. **mobile-first，不是 mobile-port**：橫向手機螢幕、觸控優先，基準 `project.godot` 1200×700。
3. **Slay The Robot fork-first**：以 `DesirePathGames/Slay-The-Robot`（MIT）為基底擴充。**新增**資料欄位 / 系統腳本 / action / validator / UI overlay，**避免**大改 framework 核心或破壞既有測試。

開發中「PRD 沒講清楚」的地方累積到 `QUESTIONS.md`，週末一次問憲龍。

**設計文件導覽**（本 PRD 是總綱，細節在這裡）：

| 系統 | 文件 |
|---|---|
| 戰鬥總覽（四支柱如何咬合） | [docs/design/ritual_combat_system.md](docs/design/ritual_combat_system.md) |
| 破煞 / 煞盾 | [docs/design/ward_break_system.md](docs/design/ward_break_system.md) |
| 符階合成 | [docs/design/talisman_merge_system.md](docs/design/talisman_merge_system.md) |
| 請神 | [docs/design/deity_invocation_system.md](docs/design/deity_invocation_system.md) |
| 遶境地圖 | [docs/design/pilgrimage_route_system.md](docs/design/pilgrimage_route_system.md) |
| 修廟 meta | [docs/design/meta_temple_progression.md](docs/design/meta_temple_progression.md) |

---

## 1. 產品願景

### 一句話定位

> 一款台灣民俗題材的 **「儀式編排型 roguelike 卡牌手遊」**。玩家透過 **合符、破煞、請神、護壇** 與 **遶境路線**，在每一場戰鬥中完成一次鎮煞儀式，而不是單純爬塔打牌。

**英文定位**：

> A ritual-driven roguelike card battler where players merge talismans, break evil wards, and invoke deities to protect a haunted island.

### 核心賣點（為什麼玩家會留下來）

1. **每場戰鬥＝一場儀式**：不是「把怪打死」，是「破煞 → 請神 → 鎮壓」的編排。命中妖怪弱點削「煞盾」，破煞後開「爆發窗口」，趁勢請神降乩。
2. **合符的當下決策**：手牌可以「現在打出」也可以「合成升階」（一劃符 → 二劃符 → 三劃敕符），每回合都在賭節奏。
3. **主祭 / 護壇 / 法器的輕量小隊感**：開局三件配置決定流派，不是單一 STS 職業。
4. **遶境而非爬塔**：山路、廟路、夜市路、荒宅路，污染度越高香火回報越豐、危險越大。
5. **修廟的長線目標**：香火拿去修復鎮島廟（正殿、虎爺殿、籤詩亭…），廟越完整，未來出巡的選項越多——但**永遠不賣戰力**。

### 與競品的差異化

#### vs《殺戮尖塔》（去除「換皮」嫌疑的關鍵）

| 維度 | 殺戮尖塔 | 鎮島錄 |
|---|---|---|
| 戰鬥目標 | 把敵人 HP 打到 0 | 破煞 → 爆發窗口 → 鎮壓的**儀式編排** |
| 手牌 | 打出後進棄牌堆 | 可**合符升階**（打出 vs 合成的決策） |
| 大招 | 多為被動 / 能量卡 | **請神降乩**：累積請神值、擇時釋放 |
| 開局 | 單一職業 | **主祭 / 護壇 / 法器** 三件配置 |
| 地圖 | 爬塔 | **遶境出巡**（污染度 / 香火回報 / 危險度） |
| 長線 | 解鎖卡片池 | **修復鎮島廟** |

#### 融合參考（吸收精神，**不照抄名詞**）

- **《重返未來 1999》**：手牌合成 / 技能升階、大招累積節奏、「現在打 vs 升階」的每回合抉擇、高品質 mobile 角色展示
  → 轉化為 **「符階合成」**（一劃符 / 二劃符 / 三劃敕符）。
- **《崩壞：星穹鐵道》**：弱點擊破、韌性條 / break window、終結技節奏、手機玩家可快速理解的弱點資訊
  → 轉化為 **「煞盾 / 破煞 / 爆發窗口」**，妖怪弱點＝拳 / 符 / 火 / 鈴 / 陣 / 咒。

> ⚠️ 名詞紅線：**禁止**直接出現「韌性」「弱點擊破」「升階」「終結技」等 R1999/HSR 原詞。我們用「煞盾 / 破煞 / 合符 / 敕符 / 降乩」。

---

## 2. 目標市場與用戶

**主要市場**：台灣（主場）、港澳、新馬華人圈（民俗信仰共鳴）。
**次要市場**：日本（妖怪文化）、英語圈獨立遊戲玩家（roguelike deckbuilder + 文化獵奇）。

**用戶畫像（主要 70%）**：18–35 歲中文母語、玩過《殺戮尖塔》/《月圓之夜》、通勤碎片遊玩、對台灣廟會 / 妖怪有興趣。

**平台優先級**：iOS 首發（台灣高滲透、付費意願高）→ Android 同步 → 平板 Phase 2 → PC（Steam）Phase 3。

---

## 3. 核心遊戲循環

```
[新一局出巡 Run]
   ↓
[配置儀式班底] → 主祭(main_ritualist) + 護壇(guardian) + 法器(ritual_tool)
   ↓
[進入遶境路線] ← 分支路線圖，每段標示 污染度 / 香火回報 / 危險度
   ↓
[節點選擇]
   ├── 巡境遇煞（普通戰）→ 破煞 → 爆發 → 戰後抽符
   ├── 惡煞據點（菁英）  → 高煞盾強敵 → 法器 / 遺物
   ├── 夜市香鋪 / 法器攤（商店）→ 銀兩買卡 / 法器
   ├── 入廟安神（休息）→ 回元神 OR 升符
   ├── 民俗問事 / 禁忌遭遇（事件）→ 抉擇
   └── 鎮煞大醮（Boss）→ 通關進入下一章節遶境
   ↓
[通關 / 倒下] → 結算「香火」
   ↓
[修廟 Meta] → 香火修復鎮島廟，解鎖神明位 / 法器 / 籤詩 / 商店 / 外觀
   ↓
[新一局出巡]
```

**每局時長**：20–40 分鐘（通勤友善）。**戰鬥內的儀式節奏**：抽手牌 →（打出 vs 合符 的決策）→ 命中弱點削煞盾 → **破煞進入爆發窗口（傷害 ×1.5）** → 累積 / 釋放請神 → 結束回合 → 敵方行動。

---

## 4. 戰鬥系統（四大支柱）

戰鬥的核心是「**儀式鏈**」：合符備牌 → 破煞開窗 → 請神降乩 → 護壇續航。總覽見 [ritual_combat_system.md](docs/design/ritual_combat_system.md)。

### 4.0 戰鬥資源（台灣文化詞彙化，沿用 v0.1）

| 通用詞 | 鎮島錄 | 說明 |
|---|---|---|
| 能量 | **神力** | 出牌費用 |
| 生命 | **元神** | 角色血量 |
| 護甲 | **護身符** | 一回合內擋傷害 |
| 攻擊 Buff | **神威** | 提升傷害 |
| 毒 | **邪氣** | 每回合扣血 |
| 易傷 | **驚嚇** | 受擊加成 |
| 虛弱 | **怯戰** | 降低傷害 |

### 4.1 破煞系統（Ward Break）— 差異化核心

每個敵人除 HP 外，新增 **煞盾**（`enemy_ward_shield` / `enemy_max_ward_shield`）與 **弱點**（`enemy_weaknesses`，六道儀法標籤）。

**六道儀法標籤**（單一事實來源 `scripts/systems/ritual/RitualTags.gd`）：

| fist 拳 | talisman 符 | fire 火 | bell 鈴 | array 陣 | curse 咒 |
|---|---|---|---|---|---|

**規則**：卡牌帶 `card_ritual_tags`；命中弱點 → 大幅削煞盾（`break_damage + weakness_break_bonus`），未命中 → 鈍擊（僅 `floor(break_damage/2)`）；煞盾歸零 → 觸發 `enemy_break_effect`，敵人進入 **爆發窗口**（受傷 ×1.5、可能跳過行動），窗口結束煞盾回滿。

**狀態**：✅ 運算層 `WardBreakSystem.gd` 已實作、已單元測試；act1 全 9 敵的煞盾 / 弱點已資料化。✅ **戰鬥接線已落地**（`scripts/combatants/Enemy.gd`：出牌結算削煞盾 + 破煞套 status + 爆發窗口 ×1.5 + 頭頂煞盾指示），整合測試在真實戰鬥樹驗證通過。⏳ 弱點 icon 化 / AoE 破煞 / 數值平衡為後續打磨。細節見 [ward_break_system.md](docs/design/ward_break_system.md)。

### 4.2 符階合成系統（Talisman Merge）

手牌中兩張同 `card_merge_group` 且同 `card_merge_tier` 的卡可合成為 `card_merge_result_id` 指向的高階符。

| Tier | 名稱 | 說明 |
|---|---|---|
| 1 | 一劃符 / 初符 | 基礎效果 |
| 2 | 二劃符 / 成符 | 數值提升或加副效果 |
| 3 | 三劃敕符 / 敕符 | 強化效果，可觸發請神 / 破煞爆發 |

**乩童合成圖**（已資料化）：攻拳→重擊→狂怒一擊（敕符頂階）、連環攻擊→威靈出陣、護身符→鐵布衫。合成消耗先用簡化版（一次「合符」行動）。

**狀態**：✅ 卡牌合成欄位 + 合成圖已落地、完整性已驗證。✅ **合成運算 + 執行已接線**（`TalismanMergeSystem` + `Hand.merge_cards`：右鍵可合符的卡 → `transform_card` 升階 + `banish` 夥伴 + 每回合 1 次限額），整合測試於真實樹通過。⏳ 合符 UI 視覺提示 / 手機手勢 / 神力消耗規則為後續打磨。細節見 [talisman_merge_system.md](docs/design/talisman_merge_system.md)。

### 4.3 請神系統（Deity Invocation）— 戰鬥節奏核心

神明不是普通大招，而是「把你的打法翻譯成降乩」的轉換層。資料型態 `external/data/deities/*.json`（`DeityData.gd`）。

| 神明 | 累積標籤 | 觸發 | 降乩 | 被動 | 定位 |
|---|---|---|---|---|---|
| **虎爺** | 拳 | 破煞時 | 虎爺咬煞（全體大傷+延長窗口） | 破煞窗口傷害 +25% | 破煞 / 爆發 |
| **城隍爺** | 咒・符 | 施加 debuff | 城隍夜審（全體驚嚇+怯戰、引爆邪氣） | 邪氣擴散 | 審判 / 控場 |
| **媽祖** | 火・鈴・符 | 獲得護身符 | 慈航普渡（回元神+全隊護身符） | 破煞回元神 | 守護 / 回復 |
| **土地公** | 符・陣 | 手動 | 福德降臨（香火加成+抽牌） | 戰後額外香火 | 資源 / 穩定 |

**規則**：卡牌 `card_deity_charge` 在 `ritual_tags` 與神明 `deity_charge_tags` 交集時累積請神值；破煞、自損、合成三階敕符皆可為觸發來源；滿槽**不自動釋放**，玩家擇時降乩。乩童透過 `deity_charge_per_self_loss` 把自損轉成請神節奏。

**狀態**：✅ `DeityData` + 4 神 JSON + schema 已驗證。✅ **4 神請神閉環已接線**（`DeityInvocationSystem` + `DeityChargeController` + Combat：虎爺 tiger_roar / 城隍 judgment / 媽祖 merciful_tide / 土地公 land_blessing，觸發路由 on_enemy_broken·on_block_gained·on_debuff_applied），整合測試於真實樹通過。⏳ 請神槽視覺、數值平衡、出戰神明由 loadout 決定（Phase 2B）為後續。細節見 [deity_invocation_system.md](docs/design/deity_invocation_system.md)。

### 4.4 主祭 / 護壇 / 法器配置

開局三件配置取代「只選一個角色」：

```json
{ "main_ritualist": "character_tongji", "guardian": "guardian_luannu", "ritual_tool": "tool_tiger_token" }
```

- **主祭** `main_ritualist`（沿用 `CharacterData`）：決定主牌庫與核心機制。
- **護壇** `guardian`（`GuardianData`）：提供被動與少量支援卡池（已建 `guardian_luannu` 契合媽祖、`guardian_jiajiang_front` 契合城隍）。
- **法器** `ritual_tool`（`RitualToolData`）：改變破煞 / 請神 / 資源規則（已建 虎牌 / 香爐 / 七星令旗）。

**狀態**：✅ 三類資料 + schema。✅ **班底系統已接線**（`RitualLoadout` + `Global.start_run`：護壇支援卡入庫、法器破煞/請神加成、出戰神明由 affinity 解析——乩童→虎爺、鸞女→城隍，**非固定**），整合測試通過。⏳ 配置選擇器 UI 屬後續增量。

---

## 5. 角色重構（從 STS 對照關係解放）

四角各有專屬節奏，**不再對應 STS 職業**。

### 5.1 乩童（附體破煞型）— ✅ 已有 11 張卡
核心：自損、拳系、快速破煞、請神爆發。
> **專屬規則**：乩童每次失去元神，獲得請神值；若在附體狀態下破煞，該回合第一張拳系卡升一階。

### 5.2 鸞女（護壇治癒 / 聖火符令型）— ✅ 已有 7 張卡，保留並重新定位
核心：治癒、護壇、聖火（fire 破煞）、支援、保護主祭。
> **專屬規則**：每場戰鬥第一次破煞時，回復少量元神並獲得護身符（已資料化為 `guardian_luannu` 的 `heal_on_first_break`）。

### 5.3 道士（符印法陣型）— ⏳ 設計，未建卡
核心：符印、法陣、延遲觸發、精準破煞。
> **專屬規則**：道士能疊加「符位」，當符位形成指定組合（如 鎮 + 火 + 雷）觸發法陣效果。

### 5.4 家將（陣型協同型）— ⏳ 設計，未建卡
核心：前鋒 / 中壇 / 後衛三陣位、召喚家將、陣型組合、多段支援。
> **專屬規則**：不同家將卡進入不同陣位，形成陣型效果（前鋒護壇 `guardian_jiajiang_front` 已先行樣本化）。

---

## 6. 卡牌重構

新分類語言（與 STS `card_type` 並存，存於 `card_ritual_card_type`）：

| 舊分類 | 新分類 | 鍵 |
|---|---|---|
| Attack | 武訣 | `wu_jue` |
| Skill | 護壇 | `hu_tan` |
| Power | 開壇 | `kai_tan` |
| Spell | 符令 | `fu_ling` |
| Special | 神諭 | `shen_yu` |
| Consumable | 供品 | `gong_pin` |
| Curse / 高風險 | 禁忌 | `jin_ji` |

每張卡新增欄位（`CardData.gd`，✅ 已實作並驗證 round-trip）：`card_ritual_tags`、`card_break_damage`、`card_weakness_break_bonus`、`card_merge_group`、`card_merge_tier`、`card_merge_result_id`、`card_deity_charge`、`card_ritual_card_type`。既有卡效果保留，新欄位預設空 / 0 → 對既有戰鬥行為零影響。

---

## 7. 地圖重構：遶境

語言轉換（去 STS 換皮感）：

| 舊 | 新 |
|---|---|
| Run | 一次出巡 / 巡境 |
| Act | 章節遶境 |
| Map | 遶境路線 |
| Combat | 巡境遇煞 |
| Elite | 惡煞據點 |
| Shop | 夜市香鋪 / 法器攤 |
| Rest | 入廟安神 |
| Event | 民俗問事 / 禁忌遭遇 |
| Boss | 鎮煞大醮 |

路線特徵 `route_traits/*.json`：`pollution_level`（污染度）、`incense_reward_modifier`（香火回報倍率）、`danger_rating`（危險度）、`route_flavor`（山路 / 廟路 / 夜市路 / 荒宅路）。

**狀態**：✅ 路線特徵資料已落地。⏳ 地圖生成演算法（把 STS 分支圖換成遶境）屬 **Phase 2**——**未宣稱地圖已重寫**。細節見 [pilgrimage_route_system.md](docs/design/pilgrimage_route_system.md)。

---

## 8. Meta Progression：修廟

香火（meta 貨幣）的長線用途＝修復與擴張鎮島廟（`meta_buildings/*.json`）：

| 建築 | 解鎖 |
|---|---|
| 正殿 | 神明位（請神可上場神明數） |
| 虎爺殿 | 破煞法器進開局選池 |
| 籤詩亭 | 開局籤詩改變 run 規則 |
| 夜市香鋪 | 商店商品更豐富 |
| 戲台 | 外觀 / 劇情 / 音樂（純美觀） |
| 鐘鼓樓 | 溫和開局被動 |

**狀態**：✅ 建築資料已落地。⏳ 修廟 UI / 存檔屬 **Phase 2**。細節見 [meta_temple_progression.md](docs/design/meta_temple_progression.md)。

---

## 9. 變現邊界（F2P + IAP，不放廣告）

三貨幣：**銀兩**（局內，戰後歸零）/ **香火**（meta，完局結算，修廟用）/ **元寶**（IAP）。

**可賣（元寶）**：角色解鎖、外觀 / 皮膚、卡背、主畫面裝飾、神明降臨動畫 skin、支持者包、季度通行證（純外觀）。
**絕不販售（紅線）**：

❌ 戰鬥力（卡 / 法器 / 數值）　❌ 戰力 Gacha / 隨機抽卡含戰鬥優勢　❌ 體力 / 進入次數限制　❌ Pay-to-skip

> 修廟只花「香火」（玩出來的），元寶碰不到戰力。總付費上限 US$30 內可解鎖全部內容。MVP 不放廣告。

---

## 10. 技術架構（重點）

- **引擎**：Godot 4.4+（實測 4.6.1）。**框架**：fork `Slay-The-Robot`（MIT）。
- **資料驅動**：cards / enemies / **deities / guardians / ritual_tools / route_traits / meta_buildings** / localization 全 JSON。新系統腳本置於 `scripts/systems/ritual/`（`RitualTags.gd`、`WardBreakSystem.gd`）。
- **新資料類別**：`data/prototype/{DeityData,GuardianData,RitualToolData}.gd`（extends `PrototypeData`，與既有 `CardData`/`EnemyData` 同模式）。
- **mobile-first**：橫向 1200×700，觸控優先，iOS 15+ / Android 8+。
- **i18n**：`TranslationServer` + CSV，程式不出現中文字串（漸進導入）。
- **存檔 / IAP / 後端**：本地加密存檔 + Apple/Google 雲端；StoreKit / Play Billing；MVP 無自建後端。

> 工程守則：新增 > 改 framework 核心。所有新數值資料化。既有測試必須維持綠燈（目前 **101/101**）。

---

## 11. MVP / Phase 計畫

| Phase | 目標 | 狀態 |
|---|---|---|
| **1A 文件與 schema** | PRD/README 重構、6 份設計文件、CardData/EnemyData 擴充、DeityData/GuardianData/RitualToolData、RitualTags、資料注入、validator + 測試 | ✅ **本輪完成** |
| **1B 破煞 MVP** | `WardBreakSystem` 接進戰鬥流程（Enemy.gd 監聽 card_played）、頭頂煞盾指示、破煞套 status、爆發窗口 ×1.5 | ✅ **核心落地**（視覺/AoE/平衡續調） |
| **1C 符階合成 MVP** | 合符動作（右鍵兩張同組同階 → transform 升階 + banish 夥伴）、每回合限額 | ✅ **核心落地**（UI 提示/手機手勢/神力消耗續調） |
| **1D 請神 MVP** | 虎爺請神槽（出牌標籤交集 + 破煞累積）、降乩按鈕、tiger_roar AoE + 重置 | ✅ **核心落地**（多神/視覺/平衡續調） |
| **2 完整第一章遶境** | 遶境地圖生成、主祭/護壇/法器配置 UI、修廟 meta、道士 / 家將卡組、鎮煞大醮 | ⏳ |

---

## 12. Definition of Done

每個 Phase 結束必須：

- [ ] 可在 iPhone / Android 真機運行不閃退
- [ ] 該 Phase 內容**全資料驅動**（神明 / 弱點 / 破煞值不得硬編碼在 UI / combat）
- [ ] 該 Phase UI 在 4.7"–6.7" 橫向螢幕正常
- [ ] 既有測試維持綠燈，新系統有 validator / 單元測試
- [ ] 已加入 i18n 框架（繁中、英文至少）
- [ ] **辨識度檢查**：新玩家試玩後能說出「這是破煞 + 請神 + 合符」，而非「殺戮尖塔換皮」

---

## 13. 風險與緩解

| 風險 | 影響 | 緩解 |
|---|---|---|
| **宗教文化敏感性** | 🔴 高 | 神明以「守護者」非「鬥爭」呈現；避免真實儀軌的不敬挪用；事前諮詢宗教研究者；原住民元素 MVP 暫不納入 |
| **系統過度複雜**（破煞×合符×請神×護壇疊加） | 🔴 高 | 漸進揭露：Phase 1B 只開破煞，玩家熟悉後再開合符 / 請神；新手前兩場關閉請神槽 |
| **mobile UI 資訊負擔**（煞盾條 + 弱點 + 請神槽 + 手牌） | 🟡 中 | 弱點用六枚 icon、煞盾條貼敵人、請神槽收在側欄；資訊分層、長按看詳情 |
| **與參考遊戲過度相似** | 🟡 中 | 名詞紅線（禁用韌性 / 弱點擊破 / 升階 / 終結技原詞）；機制轉化而非搬運；美術 / 音樂走廟會語彙 |
| **App Store 賭博判定** | 🟡 中 | 不做戰力 Gacha、不賣隨機抽卡；對標《殺戮尖塔》合規 |
| **內容量**（4 角 × 卡組） | 🟡 中 | 先深做乩童 + 鸞女（已有 18 卡），道士 / 家將 Phase 2 |

---

## 14. 附錄：詞彙表（給 i18n）

| 中文 | 英文 | 備註 |
|---|---|---|
| 鎮島錄 | Chronicles of the Island Ward | 副標 Formosa: The Warding |
| 煞盾 | Ward Shield | 取代 HSR「韌性」 |
| 破煞 | Ward Break | |
| 合符 / 敕符 | Talisman Merge / Edict Talisman | 取代 R1999「升階」 |
| 請神 / 降乩 | Deity Invocation | |
| 主祭 / 護壇 / 法器 | Main Ritualist / Guardian / Ritual Tool | |
| 遶境 / 鎮煞大醮 | Pilgrimage / Grand Warding Rite | |
| 香火 | Incense | meta 貨幣 |
| 六道儀法 | fist 拳 / talisman 符 / fire 火 / bell 鈴 / array 陣 / curse 咒 | 弱點標籤 |

---

**END OF PRD v0.2**

下一步：Claude Code 讀 `README.md` + `docs/design/ritual_combat_system.md`，從 **Phase 1B（破煞接進戰鬥流程）** 開工。
