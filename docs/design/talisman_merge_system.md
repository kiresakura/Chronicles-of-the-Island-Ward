# 符階合成系統設計（Talisman Merge System）

| 欄位 | 內容 |
| --- | --- |
| **文件狀態** | 合成資料欄位與合成圖已落地並驗證完整性；合成「動作 + UI」屬 PRD Phase 1C 待接 |
| **最後更新** | 2026-06-06 |
| **對應 PRD 章節** | §4.5 卡牌系統、§4.1 戰鬥系統 |
| **單一事實來源** | `data/prototype/CardData.gd`（schema）、`scripts/systems/ritual/RitualTags.gd`（六道儀法） |
| **資料完整性測試** | `tests/unit/test_ritual_schema.gd::test_card_merge_graph_consistent`、`test_card_ritual_tags_and_type_valid` |

---

## 1. 概述與設計目標

在《鎮島錄》裡，乩童與鸞女的儀法不是「升級」出來的，而是**「畫」出來的**——一道符從**一劃（初符）**起手，疊成**二劃（成符）**，最終成就**三劃敕符**（最高階、由神明敕令加持）。玩家在戰鬥手牌中把同源的符令**合符**疊寫，換取更強的一張。

這在機制骨架上吸收了《重返未來1999》「手牌合成升階」的精神——**戰鬥中即時把多張同類卡合成一張更強的卡**，製造「攢牌再爆發」的節奏——但**完全轉化為民俗畫符語境**：

- 不叫「升階 / Tier-up」，叫**畫符疊劃**（一劃 → 二劃 → 三劃）。
- 不叫「合成 / Merge」，叫**合符**（把兩道同源符令合寫為一道更高階的符）。
- 最高階不叫「滿級」，叫**敕符**（受神明敕令的頂階符，本身可成為請神 / 破煞爆發的扳機）。

### 設計目標

1. **手牌即資源**：低階符既能單獨打出，也能囤起來合符。製造「現在用掉 vs. 攢著疊劃」的張力。
2. **獎勵「同源構築」**：合符要求同族群（`merge_group`）同階（`merge_tier`），鼓勵玩家圍繞一條符線深耕，而非雜牌。
3. **頂階敕符作為儀式高潮**：三劃敕符不只是數值更高，更是**請神 / 破煞爆發的觸發點**（連動 `on_merge_tier3`）。
4. **資料驅動、可驗證**：整張合成圖寫在 JSON，圖的完整性（產物存在、族群一致、階級 +1）由單元測試守住。

---

## 2. 名詞對照表

| 通用卡牌術語 | 《鎮島錄》民俗用語 | 說明 |
| --- | --- | --- |
| Merge / 合成 | **合符** | 兩道同源符令合寫為一道高階符 |
| Tier 1 / 低階 | **初符（一劃）** | `card_merge_tier = 1` |
| Tier 2 / 中階 | **成符（二劃）** | `card_merge_tier = 2` |
| Tier 3 / 頂階 | **敕符（三劃）** | `card_merge_tier = 3`，頂階、不可再合 |
| Merge group | **符線 / 同源族群** | `card_merge_group`，決定哪些符可互相合 |
| Tier-up result | **合符產物** | `card_merge_result_id` 指向的下一階卡 |

---

## 3. CardData 合成欄位 Schema

### 3.1 欄位定義（`data/prototype/CardData.gd`）

| 欄位 | 型別 | 預設 | 說明 |
| --- | --- | --- | --- |
| `card_ritual_tags` | `Array[String]` | `[]` | 六道儀法標籤（破煞用），如 `["fist"]` |
| `card_break_damage` | `int` | `0` | 對敵方煞盾的基礎削減量（見破煞文件） |
| `card_weakness_break_bonus` | `int` | `0` | 命中弱點時「額外」削減的煞盾量 |
| `card_merge_group` | `String` | `""` | 合成族群（符線）；**`""` 表示不可合成** |
| `card_merge_tier` | `int` | `0` | **`0` 不可合成 / `1` 初符 / `2` 成符 / `3` 敕符（頂階）** |
| `card_merge_result_id` | `String` | `""` | 合符產物 `object_id`；**頂階敕符留空** |
| `card_deity_charge` | `int` | `0` | 請神值：本卡儀法標籤與某神明 charge 標籤有交集時累積 |
| `card_ritual_card_type` | `String` | `""` | 鎮島錄卡牌七分類（見 §8） |

> **設計鐵律**：`card_merge_group = ""` 且 `card_merge_tier = 0` 是「不可合成」的預設。任何沒有設定合成欄位的舊卡 JSON 自動退化為普通卡，合符層對它零影響。

### 3.2 JSON 範例（真實檔：`external/data/cards/tongji/card_tongji_punch.json`）

```json
{
  "patch_data": {},
  "properties": {
    "object_id": "card_tongji_punch",
    "card_name": "攻拳",
    "card_description": "造成 6 點傷害。",
    "card_type": 0,
    "card_energy_cost": 1,
    "card_play_actions": [
      { "res://scripts/actions/meta_actions/ActionAttackGenerator.gd":
        { "damage": 6, "number_of_attacks": 1 } }
    ],
    "card_ritual_tags": ["fist"],
    "card_break_damage": 2,
    "card_weakness_break_bonus": 3,
    "card_merge_group": "merge_tongji_fist",
    "card_merge_tier": 1,
    "card_merge_result_id": "card_tongji_heavy_strike",
    "card_deity_charge": 8,
    "card_ritual_card_type": "wu_jue"
  }
}
```

語意解讀：「攻拳」是乩童拳線的**初符（tier 1）**，屬族群 `merge_tongji_fist`；手牌中**兩張攻拳**可合符為 `card_tongji_heavy_strike`（重擊）。它同時是一張可直接打出的攻擊牌（6 傷 + 對拳弱點敵人削盾）。

---

## 4. 三符階定義表

| 符階 | `card_merge_tier` | 意象 | 規則 |
| --- | --- | --- | --- |
| **初符（一劃）** | `1` | 入門符令，數值樸素，常見 | 兩張同族群初符 → 合成成符 |
| **成符（二劃）** | `2` | 疊劃強化，數值與破煞顯著提升 | 兩張同族群成符 → 合成敕符 |
| **敕符（三劃）** | `3` | 神明敕令加持的頂階符 | **不可再合**（`merge_result_id` 留空），可觸發 `on_merge_tier3` 儀式爆發 |
| **不可合成** | `0` | 一般卡 / 功能卡 / 獨立破煞牌 | 無 `merge_group`；例：鸞女「聖火焚邪」 |

> 並非每條符線都通到三劃。act1 多數符線目前止於二劃（成符），只有乩童拳線「攻拳 → 重擊 → 狂怒一擊」打通完整三階，作為頂階敕符的範例。

---

## 5. 合成規則與消耗

### 5.1 合成條件

**手牌中存在兩張卡，滿足全部下列條件，即可合符：**

1. 兩張卡的 `card_merge_group` 相同且**非空**。
2. 兩張卡的 `card_merge_tier` 相同且 `>= 1`。
3. 該 tier 的 `card_merge_result_id` 非空（即此符線在此階有合成產物；敕符 tier 3 留空 → 不可再合）。

合成結果：兩張來源卡離開手牌，生成一張 `card_merge_result_id` 指向的新卡進入手牌。

### 5.2 合成消耗（簡化版 → 完整版待 PRD 定）

| 版本 | 消耗 | 狀態 |
| --- | --- | --- |
| **簡化版（先落地）** | 消耗一次「**合符**」行動（每回合限定次數，類似一次性操作；不另耗能量） | Phase 1C 接線採用 |
| **完整版（待定）** | 合符可能改為消耗**神力 / 請神值**或特定資源；不同符線消耗不同 | 待 PRD §4.5 / §4.6 經濟系統定案 |

> 先以「一次合符行動」落地，把合成圖跑通；資源消耗規則留待經濟系統定案後掛上，不阻塞 Phase 1C。

### 5.3 合成的請神連動

當合成產物為 **tier 3 敕符**時，合符動作本身應觸發 `on_merge_tier3` 事件（神明請神條件之一，見 `test_ritual_schema.gd` 的 `VALID_DEITY_TRIGGERS`）。亦即：**畫成一道三劃敕符 = 一次儀式高潮**，可為對應神明灌請神值 / 開請神窗口。詳見 §7。

---

## 6. 乩童 / 鸞女完整合成圖

> 真實資料：`external/data/cards/tongji/`、`external/data/cards/luannu/`。已通過 `test_ritual_schema.gd::test_card_merge_graph_consistent`（產物存在、族群一致、產物階級 = 來源 +1）。
> 表中數值格式：`break_damage / +weakness_break_bonus`（破煞用，見破煞文件）。

### 6.1 乩童（Tongji）

**拳線（`merge_tongji_fist`）— 唯一打通三劃敕符的符線：**

| 階 | 卡名 | object_id | 標籤 | 破煞 | 分類 | 合成去向 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 初符 | 攻拳 | `card_tongji_punch` | `fist` | 2 / +3 | `wu_jue` | → 重擊 |
| 2 成符 | 重擊 | `card_tongji_heavy_strike` | `fist` | 3 / +4 | `wu_jue` | → 狂怒一擊 |
| 3 **敕符** | 狂怒一擊 | `card_tongji_fury_strike` | `fist` | 4 / +5 | `wu_jue` | **頂階**（`merge_result_id` 留空） |

**連環線（`merge_tongji_combo`）：**

| 階 | 卡名 | object_id | 標籤 | 破煞 | 分類 | 合成去向 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 初符 | 連環攻擊 | `card_tongji_double_strike` | `fist` | 2 / +2 | `wu_jue` | → 威靈出陣 |
| 2 成符 | 威靈出陣 | `card_tongji_charge` | `fist` | 3 / +3 | `wu_jue` | 線末（`merge_result_id` 留空） |

**護身線（`merge_tongji_ward`）— 護壇類，無破煞：**

| 階 | 卡名 | object_id | 標籤 | 破煞 | 分類 | 合成去向 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 初符 | 護身符 | `card_tongji_talisman` | — | 0 / +0 | `hu_tan` | → 鐵布衫 |
| 2 成符 | 鐵布衫 | `card_tongji_great_talisman` | — | 0 / +0 | `hu_tan` | 線末（`merge_result_id` 留空） |

### 6.2 鸞女（Luannu）

**靈筆線（`merge_luannu_brush`）：**

| 階 | 卡名 | object_id | 標籤 | 破煞 | 分類 | 合成去向 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 初符 | 靈筆 | `card_luannu_spirit_brush` | `talisman` | 2 / +2 | `wu_jue` | → 靈符擊 |
| 2 成符 | 靈符擊 | `card_luannu_talisman_strike` | `talisman` | 2 / +3 | `wu_jue` | 線末（`merge_result_id` 留空） |

**獨立破煞牌（不可合成）：**

| 卡名 | object_id | 標籤 | 破煞 | 分類 | 說明 |
| --- | --- | --- | --- | --- | --- |
| 聖火焚邪 | `card_luannu_holy_fire` | `fire` | 3 / +5 | `wu_jue` | `merge_group=""`、`merge_tier=0`；4 傷 ×2，**鸞女的火系破煞主力**（補乩童拳線打不到的火弱點敵人，見破煞文件 §6 跨角色協同） |

### 6.3 合成圖（文字版）

```
乩童 Tongji
  merge_tongji_fist :  攻拳(1) ──合符──▶ 重擊(2) ──合符──▶ 狂怒一擊(3 敕符) ◀ 頂階，可觸發 on_merge_tier3
  merge_tongji_combo:  連環攻擊(1) ─合符─▶ 威靈出陣(2)
  merge_tongji_ward :  護身符(1) ──合符──▶ 鐵布衫(2)                （護壇 hu_tan，無破煞）

鸞女 Luannu
  merge_luannu_brush:  靈筆(1) ───合符───▶ 靈符擊(2)
  （獨立）             聖火焚邪  fire 破煞牌，不可合成
```

---

## 7. 與破煞 / 請神的儀式鏈

符階合成不是孤立的數值升級，而是**儀式鏈**的一環，與破煞、請神三者扣在一起：

```
攢初符 ──合符──▶ 成符 ──合符──▶ 三劃敕符
                                   │
                  on_merge_tier3 ──┼──▶ 為對應神明灌請神值 / 開請神窗口（請神系統）
                                   │
                                   └──▶ 高破煞數值的敕符攻擊牌（如狂怒一擊 break 4/+5）
                                          └──▶ 命中弱點大幅削敵煞盾 ──▶ 破煞爆發窗口（1.5x 增傷）
```

- **合成 → 破煞**：符階越高，`card_break_damage` / `card_weakness_break_bonus` 越大（拳線 2/+3 → 3/+4 → 4/+5）。把符疊到敕符，等於把破煞效率拉滿，一張就能撕開菁英/BOSS 的厚煞盾。
- **合成 → 請神**：tier 3 敕符的誕生觸發 `on_merge_tier3`，是請神條件之一；同時敕符自身 `card_deity_charge` 也最高（狂怒一擊 18）。「畫成敕符」因此是把請神值衝高、逼近降神的關鍵動作。
- **三高潮疊合**：理想 combo 是——本回合合出敕符（請神窗口開）→ 用敕符命中弱點破煞（爆發窗口開）→ 在雙窗口下請神降下重擊。這是《鎮島錄》戰鬥的設計理想型。

> 破煞細節見 `ward_break_system.md`；請神系統見 `deity_invocation_system`（待寫）。本系統只負責「合出敕符」並發出 `on_merge_tier3` 事件，下游連動由各自系統實作。

---

## 8. `card_ritual_card_type` 七分類對照

`card_ritual_card_type` 與 STR 原生 `card_type`（ATTACK/SKILL/POWER…）**並存**，供 UI 篩選、圖鑑分類與敘事用。合法值由 `test_ritual_schema.gd::VALID_RITUAL_CARD_TYPES` 守住。

| 鍵 | 中文 | 語意 | 範例 |
| --- | --- | --- | --- |
| `wu_jue` | 武訣 | 攻擊型儀法（拳、符擊、火） | 攻拳、重擊、靈筆、聖火焚邪 |
| `hu_tan` | 護壇 | 防禦 / 護體（格擋、減傷） | 護身符、鐵布衫 |
| `kai_tan` | 開壇 | 開場 / 增益鋪場（戰鬥起手布局） | （後續角色 / 遺物連動） |
| `fu_ling` | 符令 | 功能型符令（抽牌、操作、debuff） | （道士符令類） |
| `shen_yu` | 神諭 | 請神 / 神明相關牌 | （請神系統卡） |
| `gong_pin` | 供品 | 供奉 / 資源類（消耗換效益） | （經濟連動卡） |
| `jin_ji` | 禁忌 | 高風險高回報 / 詛咒類 | （咒術、自損強攻） |

> act1 現有卡集中在 `wu_jue`（武訣）與 `hu_tan`（護壇）；其餘五類為後續角色（道士、家將）、請神系統與經濟系統預留的分類槽，schema 已支援。

---

## 9. 落地狀態與後續 Phase

| 區塊 | 狀態 | 位置 / 備註 |
| --- | --- | --- |
| CardData 合成 schema | **已實作** | `CardData.gd`（含七分類、破煞、請神欄位） |
| 乩童 / 鸞女合成圖資料 | **已落地** | `external/data/cards/tongji/`、`external/data/cards/luannu/` |
| 合成圖完整性驗證 | **已驗證** | `test_ritual_schema.gd`：產物存在、族群一致、階級 +1、tier ∈ 0..3、標籤/分類合法 |
| **合成動作**（手牌偵測可合對、執行合符、消耗一次合符行動、發 `on_merge_tier3`） | **Phase 1C 待接** | 需新增「合符」操作 / Action；先用 §5.2 簡化版消耗 |
| **合成 UI**（標示可合的手牌、合符按鈕 / 拖曳手勢、合成動畫） | **Phase 1C 待接** | 重用手牌 UI；合符時播畫符疊劃動畫 |
| 完整合成消耗（神力 / 請神值） | **待 PRD 定** | 依 §4.5 / §4.6 經濟系統 |
| `on_merge_tier3` ↔ 請神連動 | **待接**（依賴請神系統） | 見 `deity_invocation_system`（待寫） |

**Phase 1C 接線清單（給接手者）**：
1. 手牌變動時掃描可合對（同 `merge_group` + 同 `merge_tier` + 該 tier `merge_result_id` 非空），標示「可合符」。
2. 合符操作：移除兩張來源卡、由 `merge_result_id` 生成新卡入手牌、扣一次合符行動。
3. 若產物 `merge_tier == 3` → 發出 `on_merge_tier3` 事件（供請神系統 / 神明灌值）。
4. UI：合符按鈕 / 拖曳手勢、可合高亮、畫符疊劃動畫 + 音效。
5. （可選，建議）抽出 `TalismanMergeSystem.gd` 純函式層（`can_merge(card_a, card_b) -> bool`、`merge_result_for(card_a, card_b) -> String`），比照 `WardBreakSystem` 做 headless 單元測試，再由 UI/Action 呼叫。

---

## 10. 開放問題

1. **合符消耗到底掛什麼？** 簡化版「一次合符行動」最快落地，但完整版要不要綁神力 / 請神值、要不要每回合可合多次？關係到合符的節奏與經濟壓力，待經濟系統定案。
2. **合符是否消耗能量 / 打牌數？** 目前傾向「合符不耗能量、僅耗一次合符行動」，避免與打牌爭能量。但若太廉價會導致每回合無腦疊符，需手感驗證。
3. **手牌不足 / 合不出來的挫折感**：合符要求湊到兩張同源同階，運氣不好整局合不出敕符。是否需要「保底」機制（如固定起手帶一對初符、或抽牌池傾斜）？
4. **敕符之外是否有四劃？** 目前 tier 上限為 3（schema 驗證 `0..3`）。若未來要更高階儀式，需同步放寬驗證與 `CardData` 註解。
5. **合成產物的能量/數值平衡**：以拳線為例，攻拳(1能/6傷) → 重擊(2能/12傷) → 狂怒一擊(1能/12傷但自損2)。能量曲線非單調（敕符降能但加自損），是否符合「越高階越強但有代價」的直覺？需整體曲線校準。
6. **合成是否可逆 / 可拆？** 合錯了能不能拆回兩張初符？多數合成 roguelike 不可逆以強化決策重量，但需確認與本作容錯定位一致。
7. **跨角色符線是否互通？** 目前 `merge_group` 以角色前綴隔離（`merge_tongji_*` vs `merge_luannu_*`），乩童與鸞女的符不能互合。未來雙角色同場時是否開放混合符線，影響構築自由度。
