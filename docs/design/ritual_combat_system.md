# 鎮煞儀式戰鬥總覽（Ritual Combat System）

| 項目 | 內容 |
| --- | --- |
| 文件狀態 | 總覽文件；四大支柱落地進度不一（見 §9 落地總表） |
| 最後更新 | 2026-06-06 |
| 對應 PRD 章節 | §戰鬥系統（總綱）；§主祭／護壇／法器 |
| 程式碼 | `scripts/systems/ritual/RitualTags.gd`、`data/prototype/{DeityData,GuardianData,RitualToolData}.gd`、`data/readonly/CharacterData.gd` |
| 子系統文件 | [ward_break_system.md](ward_break_system.md)、[talisman_merge_system.md](talisman_merge_system.md)、[deity_invocation_system.md](deity_invocation_system.md)、[pilgrimage_route_system.md](pilgrimage_route_system.md)、[meta_temple_progression.md](meta_temple_progression.md) |

---

## 1. 一頁看懂：一場戰鬥＝完成一次鎮煞儀式

《鎮島錄》是台灣民俗「儀式編排型」roguelike 卡牌遊戲。**它不把戰鬥包裝成「攻擊怪物」，而是包裝成「主持一場鎮煞法事」**：敵人是附了煞氣的妖邪，你的牌是拳、符、火、鈴、陣、咒六道儀法，你的目標是按正確順序「削煞盾 → 破煞 → 趁爆發窗口收掉 → 順勢請神」。

每一回合不是「我打多少傷害」，而是「我這一步把儀式推進到哪」。一場戰鬥的勝利＝一次完整的儀式鏈跑通。

四大支柱讓這套「儀式感」成立：

| 支柱 | 一句話 | 子系統文件 |
| --- | --- | --- |
| **破煞** | 命中敵人弱點削掉煞盾，破盾後進入傷害 ×1.5 的爆發窗口 | [ward_break_system.md](ward_break_system.md) |
| **合符** | 戰鬥中把同族卡合成更高階敕符（現在打 vs 升階的決策） | [talisman_merge_system.md](talisman_merge_system.md) |
| **請神** | 用打法累積請神值，擇時降乩放神明大招 | [deity_invocation_system.md](deity_invocation_system.md) |
| **主祭 / 護壇 / 法器** | 開局三件配置決定你的儀式體質（職業 / 隊友 / 起始遺物變體） | 本文件 §6 |

---

## 2. 四大支柱如何咬合成「儀式鏈」

四大支柱不是平行清單，而是一條互相餵養的迴圈。儀式鏈的標準跑法：

```
        合符（升階手牌）
             │ 更兇的破煞卡 / 更高 deity_charge
             ▼
   命中弱點 ──► 破煞 ──► 爆發窗口（傷害 ×1.5）
        │          │              │
        │          │ on_enemy_broken│ 窗口內傷害最大化
        │          ▼              ▼
        │       請神值累積 ──► 降乩（神明大招）
        │          ▲              │
        │          │              │ 虎爺降乩：再延長窗口 1 回合
        └──────────┴──────────────┘
              主祭 / 護壇 / 法器：全程改寫上面每一段的數值與規則
```

逐段說明：

1. **合符 → 破煞**：戰鬥中合成出的高階敕符，往往帶更高 `card_break_damage` 與 `card_deity_charge`，讓破煞更快、請神更猛。但合符要消耗手牌且當回合少打一張——這是「現在打 vs 升階」的核心張力。
2. **破煞 → 爆發窗口**：命中敵人弱點（`card_ritual_tags ∩ enemy_weaknesses`）削煞盾，盾破後敵人進入 `broken_turns` 回合的爆發窗口，期間我方傷害 **×1.5**，並附帶該敵的 `enemy_break_effect`（如驚嚇 / 暈眩）。
3. **破煞 → 請神**：破煞事件 `on_enemy_broken` 直接餵虎爺請神槽；施減益 `on_debuff_applied` 餵城隍；獲護身符 `on_block_gained` 餵媽祖。**你「怎麼破、怎麼控、怎麼守」決定「哪位神願意降乩」。**
4. **請神 → 破煞**：虎爺降乩 `tiger_roar` 造成全體大傷並**再延長破煞窗口 1 回合**，把爆發鏈接得更長——迴圈閉合。
5. **主祭 / 護壇 / 法器**：開局三件配置不是被動加成，而是「改寫迴圈規則」：虎牌法器讓全卡破煞 +1、窗口 +1 回合；鸞女護壇把守護變請神來源並契合媽祖；乩童主祭用自損換請神節奏。

> 設計目標：玩家每回合都在「四個齒輪該先轉哪個」之間做有意義的取捨，而不是無腦疊傷害。

---

## 3. 戰鬥資源詞彙表

民俗主題詞 ↔ 卡牌遊戲通用機制的對照。**資料與程式碼一律用左欄民俗詞命名**（避免「HP / Block」散落）。

| 民俗詞彙 | 對應機制 | 說明 |
| --- | --- | --- |
| 神力 | 能量（Energy） | 每回合打牌的資源 |
| 元神 | 生命（HP） | 主祭 / 隊伍生命；歸零＝儀式失敗 |
| 護身符 | 格擋（Block） | 當回合抵擋傷害的護盾 |
| 神威 | 力量（Strength） | 增益：提升攻擊傷害 |
| 邪氣 | 中毒（Poison） | 減益：每回合扣血、可被引爆 |
| 驚嚇 | 易傷（Vulnerable） | 減益：受到傷害增加 |
| 怯戰 | 虛弱（Weak） | 減益：造成傷害降低 |

> 另有「香火」作為跑圖 / 戰後經濟資源（見土地公 `incense_gain`、七星令旗法器、[meta_temple_progression.md](meta_temple_progression.md)），非戰鬥內即時資源故未列入上表。

---

## 4. 一個回合的決策流

```
┌─ 抽手牌
│
├─ ① 現在打出 vs 合符升階？
│     現在打：立即削煞盾 / 施毒 / 補符 → 推進本回合
│     合符：消耗手牌換更高階敕符 → 投資後續回合（少打一張的代價）
│
├─ ② 命中弱點削煞盾
│     選 ritual_tags ∩ enemy_weaknesses 的卡，優先打掉煞盾
│
├─ ③ 破煞 → 進入爆發窗口（傷害 ×1.5）
│     盾破！把高傷 / 降乩留到這個窗口收益最大
│
├─ ④ 累積 / 釋放請神
│     看哪位神快滿 / 已滿；滿槽不自動放，擇時降乩
│     （壓著等爆發窗口內放虎爺？還是先放城隍打斷敵人？）
│
├─ 結束回合
│
└─ tick 破煞窗口（窗口回合 −1；歸零則敵人煞盾 / 狀態回復）
```

決策層的張力來源：

- **時間窗口稀缺**：爆發窗口只有 `broken_turns` 回合，逼玩家「把好牌排到窗口內」。
- **資源三角**：神力（這回合打幾張）、手牌（合符要不要花）、請神槽（放不放）三者互相擠壓。
- **節奏壓槽**：滿槽不自動釋放，鼓勵玩家忍住、等對的一刻——但忍太久可能錯過窗口或先暴斃。

---

## 5. 與同類作品的差異化

| 作品 | 它的核心迴圈 | 鎮島錄怎麼不一樣 |
| --- | --- | --- |
| 《殺戮尖塔》 | 出牌 → 疊 buff / 傷害；遺物 build。**沒有「弱點削盾後的限時爆發窗口」，也沒有「打法決定哪個大招」** | 破煞把「命中正確標籤」變成節奏門檻；請神把「打法」綁定到神明降乩 |
| 《崩壞：星穹鐵道》 | 弱點擊破 → 進入擊破狀態增傷。**接近破煞，但它是即時隊伍戰、無手牌經濟、無『現在打 vs 升階』的合成決策** | 鎮島錄是回合制卡牌 + 合符升階 + 滿槽壓放，決策層更靠近 deckbuilder |
| 《重返未來：1999》 | 同階卡合成升階、共鳴 build。**合成是它的招牌，但無『削弱點盾 → 限時爆發窗口』這層** | 鎮島錄把合符（合成）與破煞（限時窗口）**綁進同一條儀式鏈**——合符是為了餵破煞與請神，不是獨立加值 |

**鎮島錄的差異化定位：把「弱點擊破的限時爆發（星鐵）＋戰鬥內合成升階（1999）＋牌組經濟與遺物變體（殺戮尖塔）」三者，用台灣民俗鎮煞儀式的外殼串成一條互相餵養的『儀式鏈』，再加上『打法決定降乩』的請神層。** 沒有任何單一支柱是原創，原創的是它們咬合的方式與主題包裝。

---

## 6. 主祭 / 護壇 / 法器配置

開局玩家選定三件配置，決定本局的「儀式體質」。類比：主祭＝職業，護壇＝起始隊友 / 支援卡池，法器＝起始遺物的職業變體。

### 6.1 配置 schema

| 配置位 | 資料類別 | 角色 | 關鍵欄位 |
| --- | --- | --- | --- |
| `main_ritualist` | `CharacterData`（沿用既有角色，如 `character_tongji` 乩童） | 主祭 / 職業 | 牌庫、起始元神、職業機制（乩童自損） |
| `guardian` | `GuardianData` | 護壇 / 支援 | `guardian_passive_effect`、`guardian_support_card_ids`、`guardian_affinity_deity_id` |
| `ritual_tool` | `RitualToolData` | 法器 / 規則變體 | `tool_rule_domain` ∈ `ward_break`/`deity`/`economy`/`draw`/`merge`、各 bonus 欄位 |

#### GuardianData 重點欄位

| 欄位 | 說明 |
| --- | --- |
| `guardian_passive_effect` / `guardian_passive_description` | 護壇常駐被動 |
| `guardian_support_card_ids` | 注入主祭牌庫的支援卡（object_id） |
| `guardian_affinity_deity_id` | 與哪位神明契合（請神加成鉤點） |
| `guardian_character_id` | 可選：護壇由某 CharacterData 兼任 |

#### RitualToolData 重點欄位（依 `tool_rule_domain` 生效）

| rule_domain | 生效欄位 | 效果 |
| --- | --- | --- |
| `ward_break` | `tool_bonus_break_damage`、`tool_extra_broken_turns` | 全卡破煞削減 +N、破煞窗口 +N 回合 |
| `deity` | `tool_bonus_deity_charge`、`tool_affinity_deity_id` | 每命中卡請神值 +N、契合神明 |
| `economy` | `tool_bonus_incense_money` | 戰後香火 / 銀兩加成 |
| `draw` | `tool_bonus_draw` | 開局多抽 N |
| `merge` |（合符相關，見 talisman_merge_system.md） | 影響合符規則 |

### 6.2 已落地的配置元件

| 配置位 | 已建元件 | 摘要 |
| --- | --- | --- |
| 主祭 | `character_tongji`（乩童）、`character_luannu` | 乩童＝自損換請神；鸞女可主祭或護壇 |
| 護壇 | `guardian_luannu`（鸞女，契合媽祖）、`guardian_jiajiang_front`（家將前鋒，契合城隍） | 鸞女：首破回血＋護身符；家將：陣型 / 控場 |
| 法器 | `tool_tiger_token` 虎牌（`ward_break`，+1 破煞 / +1 窗口）、`tool_incense_censer` 香爐（`deity`，+3 請神）、`tool_seven_star_flag` 七星令旗（`economy`，+10 香火 / +1 抽） | 三領域各一範例 |

### 6.3 配置範例 JSON

```json
{
  "main_ritualist": "character_tongji",
  "guardian": "guardian_luannu",
  "ritual_tool": "tool_tiger_token"
}
```

> 讀法：乩童（自損換請神）＋ 鸞女（守護變請神來源、契合媽祖）＋ 虎牌（破煞 +1、窗口 +1）。這套偏「拚命破煞 → 爆發窗口拉長 → 順勢養虎爺 / 媽祖」的高節奏 build。

範例組合的設計意圖對照：

| 組合 | 偏向 |
| --- | --- |
| 乩童 + 虎牌 + 香爐 | 極限破煞爆發，虎爺速降乩 |
| 乩童 + 家將前鋒 + 七星令旗 | 控場 / 城隍審判 + 經濟滾雪球 |
| 鸞女（主祭）+ 鸞女護壇空出 + 任意 | 守護回復流，媽祖支柱 |

---

## 7. 六道儀法標籤（共用詞彙）

破煞、請神、合符、敵人弱點、法器修正全部引用同一組標籤（單一事實來源：`scripts/systems/ritual/RitualTags.gd`）：

| 鍵 | 繁中 | 意象 |
| --- | --- | --- |
| `fist` | 拳 | 乩童附體、肉身鎮煞 |
| `talisman` | 符 | 道士 / 鸞女符令 |
| `fire` | 火 | 聖火、香火、化金 |
| `bell` | 鈴 | 法鈴、淨壇、驅邪 |
| `array` | 陣 | 法陣、家將陣型 |
| `curse` | 咒 | 咒術、邪氣、降煞 |

這組標籤是四大支柱的「共同語言」：一張卡的 `card_ritual_tags` 同時決定它**能破哪種敵人**（破煞）、**餵哪位神明**（請神）、**屬哪個合成族群傾向**（合符）。

---

## 8. 交叉連結

| 文件 | 涵蓋 | 落地狀態 |
| --- | --- | --- |
| [ward_break_system.md](ward_break_system.md) | 破煞運算：煞盾 / 弱點 / 爆發窗口 / ×1.5 | `WardBreakSystem` 已實作 + 單元測試 |
| [talisman_merge_system.md](talisman_merge_system.md) | 合符：戰鬥內同族卡升階、三階敕符 | 合符資料已落地 |
| [deity_invocation_system.md](deity_invocation_system.md) | 請神：請神值累積 / 滿槽壓放 / 降乩 | Schema + 4 神已落地；wiring 屬 Phase 1D |
| [pilgrimage_route_system.md](pilgrimage_route_system.md) | 遶境路線：地圖節點、危險 / 污染評級 | 路線資料 schema 已落地（`route_traits`） |
| [meta_temple_progression.md](meta_temple_progression.md) | 修廟 meta：香火經濟、永久建築升級 | 建築資料 schema 已落地（`meta_buildings`） |

---

## 9. 落地狀態總表

| 支柱 / 元件 | 資料 / Schema | 程式碼 wiring | 測試 | 對應 Phase |
| --- | --- | --- | --- | --- |
| 六道儀法標籤 `RitualTags` | 已建立（單一事實來源） | 已可用（`intersects` / `hits_weakness`） | 間接覆蓋 | — |
| **破煞** WardBreakSystem | 敵人煞盾 / 弱點 / 破煞效果已落地 | **已實作** | **單元測試通過** | 已完成 |
| **合符** Talisman Merge | 合成圖（group / tier / result_id）已落地並驗證 | 戰鬥內合成 wiring 部分 / 進行中 | `test_card_merge_graph_consistent` 通過 | Phase 1B/1D |
| **請神** Deity Invocation | `DeityData` + 4 神 JSON 已落地 | **未接**（請神槽累積 / 降乩釋放） | `test_deity_schema_valid` 通過 | **Phase 1D** |
| 主祭（CharacterData） | 乩童 / 鸞女已落地 | 角色載入已可用；乩童自損機制部分 | — | Phase 1 |
| 護壇（GuardianData） | 鸞女 / 家將前鋒已落地並驗證 | **未接**（隊伍 / 支援卡注入 / 契合加成） | `test_guardian_schema_valid` 通過 | Phase 2 |
| 法器（RitualToolData） | 虎牌 / 香爐 / 七星令旗已落地並驗證 | **未接**（規則修正 wiring） | `test_ritual_tool_schema_valid` 通過 | Phase 1B/1D |
| 卡牌儀式欄位 | `card_ritual_tags` / `card_break_damage` / `card_deity_charge` / 合成欄位已注入 | 載入器 roundtrip 已驗證 | `test_ritual_fields_roundtrip_through_loader` 通過 | Phase 1 |
| 戰鬥資源詞彙（民俗命名） | 已定義（本文件 §3） | 隨各系統 wiring 落地 | — | 跨 Phase |

> 誠實標註：**破煞是目前唯一「資料 + 運算 + 測試」三者俱全的支柱**；合符已有資料與圖一致性驗證，戰鬥內合成 wiring 進行中；**請神、護壇、法器目前是「資料 + schema 驗證」齊備，但戰鬥端 wiring（尤其請神的累積 / 降乩）尚未接，屬 PRD Phase 1D / Phase 2**。效果鍵（`tiger_roar`、`judgment` 等）目前為資料佔位字串，待 Phase 1D 綁定到 `scripts/actions/` 的具體行為。
