# 請神系統（Deity Invocation System）

| 項目 | 內容 |
| --- | --- |
| 文件狀態 | Schema + 資料已落地、驗證通過；戰鬥 wiring 屬 PRD Phase 1D 尚未接 |
| 最後更新 | 2026-06-06 |
| 對應 PRD 章節 | §戰鬥系統 → 請神系統；§主祭／護壇／法器 |
| 程式碼 | `data/prototype/DeityData.gd`、`scripts/systems/ritual/RitualTags.gd` |
| 資料 | `external/data/deities/*.json`（4 神） |
| 測試 | `tests/unit/test_ritual_schema.gd::test_deity_schema_valid` |
| 相關文件 | [ritual_combat_system.md](ritual_combat_system.md)、ward_break_system.md、talisman_merge_system.md |

---

## 1. 概述與設計定位

**請神不是「集滿能量按大招」，它是整場戰鬥的節奏儀表板。**

《鎮島錄》的一場戰鬥＝完成一次鎮煞儀式。玩家打牌的同時，會持續對某幾位神明「累積香火 / 請神值」。請神系統把「我這幾回合在做什麼」量化成槽位：你一直打拳，虎爺的槽就漲；你一直下符施毒，城隍的槽就漲。**請神值的歸屬由你的打法決定，而非由神明單方面決定**——這是它跟一般 RPG「能量條」最大的不同。

三條設計準則：

1. **請神值是打法的副產品，不是獨立資源**：玩家不會「為了攢神力而打牌」，而是「正常打牌，順勢養出某位神明」。請神值的累積來源綁定六道儀法標籤（拳/符/火/鈴/陣/咒），所以它天然反映 build 走向。
2. **滿槽不自動釋放**（`deity_auto_release = false`）：降乩（大招）的時機是一個獨立的戰術決策層。攢滿之後玩家可以「壓著不放」，等破煞爆發窗口或敵人關鍵回合再降乩，把神明效果疊到收益最大的一刻。
3. **請神與其他三大支柱（破煞 / 合符 / 主祭護壇法器）互相餵養**，不是平行的獨立系統。詳見「儀式鏈」章節（[ritual_combat_system.md](ritual_combat_system.md)）。

> 一句話定位：**請神＝把「你怎麼打」翻譯成「哪位神明願意降乩」的轉換層。**

---

## 2. DeityData schema

神明資料類別位於 `data/prototype/DeityData.gd`（繼承 `PrototypeData`），資料驅動樣本位於 `external/data/deities/*.json`。

### 2.1 欄位定義

| 欄位 | 型別 | 說明 |
| --- | --- | --- |
| `deity_name` | String | 神明名稱（UI 顯示） |
| `deity_description` | String | 神明描述 / 定位文案 |
| `deity_texture_path` | String | 立繪 / 神像貼圖路徑 |
| `deity_charge_tags` | Array[String] | **可為此神累積請神值的儀法標籤**（與卡牌 `card_ritual_tags` 取交集；鍵見 `RitualTags.gd`） |
| `deity_max_charge` | int | 請神槽滿值 |
| `deity_starting_charge` | int | 開戰時初始請神值 |
| `deity_trigger_condition` | String | 觸發 / 額外累積來源鍵（合法值見 §6） |
| `deity_auto_release` | bool | `false` = 滿槽後由玩家擇時降乩（本作全部為 false） |
| `deity_invocation_effect` | String | 降乩（大招）效果鍵 |
| `deity_invocation_description` | String | 降乩效果文案 |
| `deity_passive_effect` | String | 常駐被動效果鍵 |
| `deity_passive_description` | String | 常駐被動文案 |
| `deity_charge_per_self_loss` | int | **自損換請神**：每失去 1 點元神累積的請神值（乩童專屬節奏，多數神明為 0） |

### 2.2 JSON 範例（真實資料：虎爺 `deity_tiger_god`）

```json
{
  "patch_data": {},
  "properties": {
    "object_id": "deity_tiger_god",
    "deity_name": "虎爺",
    "deity_description": "鎮守廟埕、專破邪煞的猛將型守護神。破煞與爆發的節奏核心。",
    "deity_texture_path": "assets/generated/deities/deity_tiger_god.png",
    "deity_charge_tags": ["fist"],
    "deity_max_charge": 100,
    "deity_starting_charge": 0,
    "deity_trigger_condition": "on_enemy_broken",
    "deity_auto_release": false,
    "deity_invocation_effect": "tiger_roar",
    "deity_invocation_description": "虎爺咬煞：對所有敵人造成大量傷害，並延長其破煞爆發窗口 1 回合。",
    "deity_passive_effect": "bonus_damage_on_break",
    "deity_passive_description": "敵人處於破煞窗口時，你對其造成的傷害再 +25%。",
    "deity_charge_per_self_loss": 0
  }
}
```

> 讀法：虎爺只吃 `fist`（拳）標籤累積請神值，且每次「破煞」（`on_enemy_broken`）會額外灌注。被動讓破煞窗口傷害更兇，降乩則直接造成全體大傷並把窗口再延一回合——典型的「破煞 → 爆發 → 再爆發」滾雪球。

---

## 3. 請神規則（凍結規格 ①–④）

> 以下四條為凍結規格，引擎實作須與此一字對齊。

### ① 卡牌請神值歸屬：標籤交集

卡牌的 `card_deity_charge` 在其 `card_ritual_tags` 與某神明的 `deity_charge_tags` **有交集**時，為該神累積請神值。

- 判定函式：`RitualTags.intersects(card_ritual_tags, deity_charge_tags)`
- 一張卡可同時餵多位神明：例如 `card_ritual_tags = [talisman]` 的符卡，會同時餵城隍（`[curse, talisman]`）與媽祖（`[fire, bell, talisman]`）與土地公（`[talisman, array]`）。
- 真實範例：攻拳 `card_tongji_punch` 帶 `card_ritual_tags = ["fist"]`、`card_deity_charge = 8` → 出一張，虎爺 +8。

```gdscript
# 概念碼（Phase 1D 待接）：打出卡牌時，對每位在場神明結算請神值
for deity in active_deities:
    if RitualTags.intersects(card.card_ritual_tags, deity.deity_charge_tags):
        deity_charge[deity] += card.card_deity_charge
```

### ② 三類事件觸發來源（由 `trigger_condition` 表達）

除了「出牌」這個基礎來源外，**破煞、受傷／自損、合成三階敕符**皆可作為額外的請神累積來源。哪一類事件對某神生效，由該神的 `deity_trigger_condition` 決定：

| 來源 | trigger_condition 鍵 | 代表神明 |
| --- | --- | --- |
| 敵人被破煞 | `on_enemy_broken` | 虎爺 |
| 對敵施加減益 | `on_debuff_applied` | 城隍爺 |
| 我方獲得護身符 | `on_block_gained` | 媽祖 |
| 我方受到傷害 / 自損 | `on_self_damage` | （乩童 build 取向） |
| 合成出三階敕符 | `on_merge_tier3` | （合符 build 取向） |
| 純手動 / 無額外事件 | `manual` | 土地公 |

### ③ 滿槽不自動釋放，玩家擇時降乩

`deity_auto_release = false`。請神槽攢滿後**停在滿值**，等玩家主動降乩。這讓「何時降乩」成為一個獨立的戰術選擇：

- 壓著等破煞爆發窗口（傷害 ×1.5）再放虎爺，傷害最大化。
- 等敵人準備大招的前一回合放城隍，用驚嚇 / 怯戰打斷節奏。
- 元神告急時才放媽祖回血，不浪費溢出治療。

### ④ 乩童：自損換請神節奏

乩童透過 `deity_charge_per_self_loss` 把「自損」轉成請神累積。乩童的玩法核心是「附身 / 操肉身鎮煞」——主動扣自己元神來換取爆發或卡片效益，這些自損會經由此欄位回灌成請神值，形成「越拚命 → 神越快降乩」的高風險高節奏循環。詳見 §5。

---

## 4. 四神明詳表

| 神明 | object_id | charge_tags | max / start | trigger_condition | 降乩（invocation） | 被動（passive） | 定位 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 虎爺 | `deity_tiger_god` | `[fist]` | 100 / 0 | `on_enemy_broken` | **虎爺咬煞** `tiger_roar`：全體大量傷害＋延長破煞窗口 1 回合 | `bonus_damage_on_break`：破煞窗口對該敵傷害 +25% | 破煞 / 爆發核心 |
| 城隍爺 | `deity_chenghuang` | `[curse, talisman]` | 120 / 0 | `on_debuff_applied` | **城隍夜審** `judgment`：全體驚嚇＋怯戰、引爆目標所有邪氣層 | `curse_spread`：施加邪氣時相鄰敵人 +1 層 | 審判 / 控場 |
| 媽祖 | `deity_mazu` | `[fire, bell, talisman]` | 100 / 0 | `on_block_gained` | **慈航普渡** `merciful_tide`：回復大量元神＋主祭與護壇各獲護身符 | `heal_on_break`：每次破煞回復 3 元神 | 守護 / 回復 |
| 土地公 | `deity_tudigong` | `[talisman, array]` | 80 / **10** | `manual` | **福德降臨** `land_blessing`：本場香火回報提升＋立即抽 2 | `incense_gain`：每場戰鬥結束額外香火 | 資源 / 穩定 |

設計註記：

- **虎爺**槽最快滿（max 100、純 `fist`、破煞回灌），是 aggro / 破煞流的引擎。
- **城隍**槽最高（max 120）以平衡「審判」的強控場；雙標籤 `curse + talisman` 讓毒流與符流都能養。
- **媽祖** `on_block_gained` 觸發，把「防守」也變成請神來源——守護流不再是純被動。
- **土地公**唯一 `manual`、唯一有 `starting_charge = 10`，槽小（max 80）、偏資源/開局穩定；降乩偏向「滾雪球本場經濟」而非戰鬥爆發。

---

## 5. 與角色 / 護壇的互動

請神系統不是孤立的——它與開局的「主祭 / 護壇 / 法器」配置深度咬合。

### 5.1 乩童：自損換請神（`deity_charge_per_self_loss`）

主祭乩童（`character_tongji`）的核心玩法是「肉身鎮煞」：許多乩童卡片以扣自身元神為代價換取高爆發（例如附身、操刀類）。`deity_charge_per_self_loss` 讓這些自損**不只是代價，也是請神的燃料**：

- 每失去 1 點元神 → 累積 `deity_charge_per_self_loss` 點請神值。
- 搭配 `trigger_condition = on_self_damage` 的神明（乩童 build 取向），自損會雙重回灌。
- 形成節奏：**越敢拚命掉血，神越快降乩**——但若沒算好，可能還沒降乩就先暴斃。這是乩童的高風險高回報張力來源。

### 5.2 鸞女護壇契合媽祖

護壇位（`GuardianData`）有一個 `guardian_affinity_deity_id` 欄位，標記「此護壇與哪位神明特別契合」。已落地的鸞女護壇：

```json
{
  "object_id": "guardian_luannu",
  "guardian_name": "鸞女（護壇）",
  "guardian_passive_effect": "heal_on_first_break",
  "guardian_passive_description": "每場戰鬥第一次破煞時，回復 5 點元神並獲得 1 個護身符。",
  "guardian_support_card_ids": ["card_luannu_protection", "card_luannu_prayer"],
  "guardian_affinity_deity_id": "deity_mazu"
}
```

- 鸞女契合媽祖：她的被動「首破回復＋護身符」會觸發媽祖的 `on_block_gained`，把「守護」變成請神來源；她注入的支援卡（`card_luannu_protection`、`card_luannu_prayer`）多帶 `talisman` / `fire` / `bell` 標籤，正好餵媽祖的 `charge_tags = [fire, bell, talisman]`。**護壇與神明的契合是一條設計好的請神高速公路。**
- `guardian_affinity_deity_id` 是「請神值加成」的鉤點（Phase 2 接線）：契合時對該神的請神累積給予加成。
- 另一護壇 `guardian_jiajiang_front`（家將前鋒）契合城隍（`deity_chenghuang`），對應控場 / 陣型 build。

### 5.3 法器對請神的修正

法器位（`RitualToolData`）中，`tool_rule_domain = deity` 的法器會調整請神節奏：

- `tool_bonus_deity_charge`：每張命中卡的請神值 +N。
- `tool_affinity_deity_id`：法器專屬契合的神明。
- 已落地範例：香爐 `tool_incense_censer`（`deity` 領域，每命中卡 +3 請神）。

---

## 6. `trigger_condition` 合法值表

引擎據此判斷「除出牌外，還有哪些事件為此神額外累積請神值」。合法值定義於 `DeityData.gd` 註解，並由 `test_ritual_schema.gd` 的 `VALID_DEITY_TRIGGERS` 強制校驗（任何 JSON 用了表外的鍵，測試即失敗）。

| 鍵 | 觸發時機 | 設計意圖 |
| --- | --- | --- |
| `on_enemy_broken` | 敵人煞盾被打破、進入破煞窗口時 | 獎勵破煞流（虎爺） |
| `on_debuff_applied` | 對敵成功施加減益（邪氣 / 驚嚇 / 怯戰）時 | 獎勵控場 / 毒流（城隍） |
| `on_block_gained` | 我方獲得護身符時 | 獎勵守護流（媽祖） |
| `on_self_damage` | 我方受到傷害或主動自損時 | 獎勵乩童高風險玩法 |
| `on_merge_tier3` | 合成出三階敕符（合符系統最高階）時 | 獎勵合符 build |
| `manual` | 無額外事件，僅靠出牌的 `card_deity_charge` 累積 | 穩定 / 資源神（土地公） |

---

## 7. 落地狀態與 Phase 1D 接線計畫

### 7.1 目前已落地

| 項目 | 狀態 |
| --- | --- |
| `DeityData.gd` 類別與全欄位 | 已建立 |
| 4 神 JSON（虎爺 / 城隍 / 媽祖 / 土地公） | 已建立 |
| 六道儀法標籤單一事實來源 `RitualTags.gd` | 已建立（含 `intersects()`） |
| 卡牌 `card_deity_charge` 欄位 + 全乩童 / 鸞女卡資料 | 已注入（見 `external/data/cards/`） |
| Schema 驗證（`test_deity_schema_valid`） | 通過 |
| 破煞運算層 `WardBreakSystem` | 已實作 + 單元測試（見 ward_break_system.md） |
| 合符資料層 | 已落地（見 talisman_merge_system.md） |

### 7.2 Phase 1D 待接（戰鬥 wiring）

請神槽的「累積 → 滿槽 → 降乩釋放」整條戰鬥端管線屬 **PRD Phase 1D，尚未實作**。預計接線步驟：

1. **DeityChargeSystem（新節點 / 自動載入）**：持有本場在場神明的當前請神值字典 `{deity_id: int}`。
2. **出牌掛鉤**：卡牌結算後，依規則 ① 對每位神明 `intersects` 判定後加 `card_deity_charge`。
3. **事件掛鉤**：訂閱 `on_enemy_broken` / `on_debuff_applied` / `on_block_gained` / `on_self_damage` / `on_merge_tier3` 對應信號，依各神 `trigger_condition` 額外灌注。
4. **自損掛鉤**：受傷 / 自損事件 × `deity_charge_per_self_loss` 回灌。
5. **降乩釋放 API**：`request_invocation(deity_id)`——檢查 `charge >= max_charge`，執行 `deity_invocation_effect`，歸零槽位（`auto_release = false`，由玩家觸發）。
6. **被動常駐**：開戰時依在場神明掛上 `deity_passive_effect`（如虎爺破煞 +25%、媽祖破煞回血）。
7. **法器 / 護壇加成接線**：`tool_bonus_deity_charge`、`guardian_affinity_deity_id` 的請神加成鉤點。

> 接線前，效果鍵（`tiger_roar`、`judgment`、`merciful_tide`、`land_blessing`、各 passive）為**資料層佔位字串**，尚未對應到實際 Action 實作。Phase 1D 需把每個鍵綁到 `scripts/actions/` 下的具體行為。

---

## 8. 開放問題（待設計決議）

1. **滿槽 UI 呈現**：四位神明同時在場時，槽位如何在有限的戰鬥畫面排版？是否只顯示「最接近滿 / 已滿」的 1–2 位？滿槽的視覺強度（發光 / 神像浮現）要多搶眼才不會干擾讀牌？
2. **釋放時機 UX**：降乩是「點神像」還是「拖一張專屬降乩卡」？要不要加二次確認，避免誤觸把壓著不放的滿槽提前放掉？
3. **多神同滿的取捨提示**：當兩位以上同時滿槽，是否給玩家「先放誰收益較高」的弱提示，還是純靠玩家判斷？
4. **溢出處理**：滿槽後繼續累積是否完全捨棄，或保留少量溢出（鼓勵壓槽但設上限）？目前規格為停在滿值。
5. **`on_self_damage` / `on_merge_tier3` 取向神明**：目前 4 神未用到這兩個 trigger，未來擴充乩童流 / 合符流專屬神明時再補（規格已預留）。
6. **降乩與破煞窗口的數值疊乘**：虎爺降乩在破煞窗口（×1.5）內施放，與被動 +25% 如何結算（相加 vs 相乘）需在 Phase 1D 定案並寫進測試。
