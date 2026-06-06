# 破煞 / 煞盾系統設計（Ward Break System）

| 欄位 | 內容 |
| --- | --- |
| **文件狀態** | 運算層已實作並通過單元測試；戰鬥流程接線 + UI 屬 PRD Phase 1B 待接 |
| **最後更新** | 2026-06-06 |
| **對應 PRD 章節** | §4.1 戰鬥系統、§4.4 敵人 & Boss 設計 |
| **單一事實來源** | `scripts/systems/ritual/RitualTags.gd`（六道儀法）、`scripts/systems/ritual/WardBreakSystem.gd`（運算）、`data/prototype/EnemyData.gd`（schema） |
| **單元測試** | `tests/unit/test_ward_break_system.gd`、`tests/unit/test_ritual_schema.gd` |

---

## 1. 概述與設計目標

《鎮島錄》的敵人多為「煞氣纏身」的精怪與惡靈。玩家不是單純地砍血，而是先以**對的儀法手段「破煞」**——撕開敵人的邪氣護體——再趁其元氣大亂時集中輸出。這在機制骨架上吸收了《崩壞星穹鐵道》「弱點擊破」的節奏感（先削韌性條、擊破後進入增傷窗口），但**完全轉化為台灣民俗語境**：

- 不叫「韌性 / Toughness」，叫**煞盾**（敵人以煞氣結成的護體）。
- 不叫「擊破 / Break」，叫**破煞**（用法器、符令、神拳破除煞氣）。
- 不叫「弱點 / Weakness」是抽象屬性，而是**該精怪「忌」哪一道儀法**（餓鬼忌符、樹靈忌火、山豬精忌拳……）。

### 設計目標

1. **逼出「對症下藥」的決策**：玩家必須認得每隻敵人忌什麼儀法，組出能命中弱點的牌組與隊伍，而非無腦疊傷害。
2. **製造節奏起伏**：破煞前是「鋪陳」，破煞後的**爆發窗口**是「收割」，一場戰鬥有明確的高低潮。
3. **支撐主祭／護壇的隊伍協同**：單一角色的儀法標籤覆蓋不全，鼓勵跨角色（乩童 + 鸞女）互補弱點覆蓋面。
4. **資料驅動、零硬編碼**：所有弱點、煞盾值、破煞效果都寫在 `external/data/` 的 JSON，運算層純函式可單元測試。

---

## 2. 名詞對照表

| 通用 ARPG / 回合制術語 | 《鎮島錄》民俗用語 | 說明 |
| --- | --- | --- |
| 韌性條 / Toughness | **煞盾**（ward shield） | 敵人以煞氣結成的護體值，歸零即破 |
| Break / 擊破 | **破煞** | 煞盾由正歸零的瞬間事件 |
| Break window / 增傷窗口 | **爆發窗口** | 破煞後敵人元氣大亂、受傷加重的若干回合 |
| Weakness / 弱點 | **忌（弱點儀法）** | 該精怪所忌的儀法標籤 |
| Weakness break bonus | **破煞加成**（命中弱點額外削盾） | 命中弱點時對煞盾的「額外」削減 |
| Blunt / 非弱點打擊 | **鈍擊** | 用錯儀法，僅造成減半的煞盾削減 |
| Element / 屬性 | **六道儀法** | 拳/符/火/鈴/陣/咒 |

---

## 3. 資料 Schema

### 3.1 六道儀法標籤（`RitualTags.gd`）

所有「弱點」「卡牌標籤」「神明請神標籤」共用同一組鍵字串，避免散落硬編碼：

| 鍵 | 顯示 | 意象 |
| --- | --- | --- |
| `fist` | 拳 | 乩童附體、肉身鎮煞 |
| `talisman` | 符 | 道士／鸞女符令 |
| `fire` | 火 | 聖火、香火、化金 |
| `bell` | 鈴 | 法鈴、淨壇、驅邪 |
| `array` | 陣 | 法陣、家將陣型 |
| `curse` | 咒 | 咒術、邪氣、降煞 |

### 3.2 EnemyData 煞盾欄位（`data/prototype/EnemyData.gd`）

| 欄位 | 型別 | 預設 | 說明 |
| --- | --- | --- | --- |
| `enemy_ward_shield` | `int` | `0` | 當前煞盾值 |
| `enemy_max_ward_shield` | `int` | `0` | 最大煞盾；**`0` 表示此敵無破煞機制**（戰鬥行為與原版 STR 完全一致） |
| `enemy_weaknesses` | `Array[String]` | `[]` | 弱點儀法標籤，如 `["fist","fire"]` |
| `enemy_break_effect` | `String` | `""` | 破煞後效果鍵：`break_stun` / `break_vulnerable` / `break_weak` / `break_stun_vulnerable` / `break_invoke_window` |
| `enemy_broken_turns` | `int` | `1` | 破煞後爆發窗口持續回合數 |
| `enemy_is_broken` | `bool` | `false` | **執行期、非序列化**；由 `WardBreakSystem` 維護 |
| `enemy_broken_turns_remaining` | `int` | `0` | **執行期、非序列化**；爆發窗口剩餘回合 |

> **設計鐵律**：`enemy_max_ward_shield = 0` 是「無破煞機制」的開關。任何沒有設定煞盾的舊敵人 JSON 自動退化為純 STR 行為，破煞層對它零影響。

### 3.3 JSON 範例（真實檔：`external/data/enemies/act1_mountain/enemy_tree_spirit.json`）

```json
{
  "patch_data": {},
  "properties": {
    "object_id": "enemy_tree_spirit",
    "enemy_object_id": "enemy_tree_spirit",
    "enemy_name": "樹靈",
    "enemy_health": 18,
    "enemy_health_max": 18,
    "enemy_ward_shield": 6,
    "enemy_max_ward_shield": 6,
    "enemy_weaknesses": ["fire"],
    "enemy_break_effect": "break_vulnerable",
    "enemy_broken_turns": 1
  }
}
```

語意解讀：樹靈以樹皮煞氣結成 **6 點煞盾**，**忌火**；玩家用帶 `fire` 標籤的牌（如鸞女「聖火焚邪」）削盾最有效。煞盾歸零即破煞，使其 **1 回合內易傷**（`break_vulnerable`）。

---

## 4. 破煞規則（1–5 步）

> 對應 `WardBreakSystem.gd` 的純函式邏輯。整合進戰鬥流程後，每當玩家打出一張攻擊牌、結算其對某敵的效果時走這五步。

1. **判定是否有煞盾機制**：若 `enemy_max_ward_shield <= 0`，敵人沒有煞盾，破煞層完全跳過（破煞傷害 0）。
2. **計算本次削盾量** `compute_ward_damage(card, enemy)`：
   - 卡牌 `card_ritual_tags` **命中**敵人任一 `enemy_weaknesses` → 削盾 = `card_break_damage + card_weakness_break_bonus`。
   - **未命中**（用錯儀法）→ **鈍擊**，僅削盾 `floor(card_break_damage / 2)`。
3. **套用削盾** `apply_ward_damage(enemy, amount)`：煞盾減去削盾量並夾在 `>= 0`。**當煞盾由正值歸零的那一刻**回傳 `true`，代表本次造成**破煞**，並設定 `enemy_is_broken = true`、`enemy_broken_turns_remaining = max(1, enemy_broken_turns)`。已破煞的敵人不會被重複觸發破煞。
4. **爆發窗口增傷** `damage_multiplier_for(enemy)`：敵人處於破煞窗口期間，傷害結算端對其**血量傷害**套用 `BROKEN_DAMAGE_MULTIPLIER = 1.5`（即 +50%）；窗口外為 `1.0`。同回合破煞後的後續打擊即可吃到此加成。
5. **回合結束遞減窗口** `tick_broken_state(enemy)`：每個敵人回合結束時窗口 `-1`；歸零時**解除破煞**並**煞盾回滿** `enemy_max_ward_shield`（敵人重新立盾）。玩家若想再度破煞需重新削盾。

> **破煞 vs. 血量傷害是兩條獨立軌道**：`card_break_damage` 削的是**煞盾**，卡牌 `card_play_actions` 內的 `ActionAttackGenerator.damage` 削的是**血量**。一張牌通常兩者都做：例如「攻拳」造成 6 點血量傷害、同時對煞盾削 2（命中拳弱點時 +3）。

---

## 5. WardBreakSystem API 與虛擬碼

### 5.1 API 一覽（`scripts/systems/ritual/WardBreakSystem.gd`，`class_name WardBreakSystem extends RefCounted`，全為 `static`）

| 函式 | 簽章 | 回傳 / 副作用 |
| --- | --- | --- |
| 算削盾 | `compute_ward_damage(card: CardData, enemy: EnemyData) -> int` | 純計算，無副作用 |
| 套用削盾 | `apply_ward_damage(enemy: EnemyData, amount: int) -> bool` | 改 `enemy_ward_shield`；回傳是否「本次破煞」 |
| 窗口增傷倍率 | `damage_multiplier_for(enemy: EnemyData) -> float` | `1.5` 或 `1.0` |
| 遞減窗口 | `tick_broken_state(enemy: EnemyData) -> void` | 窗口 -1；歸零則回盾解破 |
| 戰鬥初始化 | `init_ward(enemy: EnemyData) -> void` | `current = max`、清破煞旗標 |
| 常數 | `const BROKEN_DAMAGE_MULTIPLIER: float = 1.5` | 爆發窗口增傷倍率 |

### 5.2 削盾量計算（虛擬碼，對齊實作）

```gdscript
static func compute_ward_damage(card: CardData, enemy: EnemyData) -> int:
    if card == null or enemy == null:
        return 0
    if enemy.enemy_max_ward_shield <= 0:
        return 0                                  # 無破煞機制
    if RitualTags.hits_weakness(card.card_ritual_tags, enemy.enemy_weaknesses):
        return maxi(0, card.card_break_damage + card.card_weakness_break_bonus)  # 命中弱點
    return int(card.card_break_damage / 2.0)      # 鈍擊（用錯儀法，減半）
```

### 5.3 戰鬥端呼叫範例（Phase 1B 接線時，於攻擊結算流程內）

```gdscript
# 玩家打出 card 命中 enemy 時：
var ward_dmg: int = WardBreakSystem.compute_ward_damage(card, enemy)
var did_break: bool = WardBreakSystem.apply_ward_damage(enemy, ward_dmg)
if did_break:
    _apply_break_effect(enemy)        # 依 enemy_break_effect 掛 stun/vulnerable/weak…
    _spawn_break_vfx(enemy)           # 破煞特效 + 音效（煞盾碎裂）

# 血量傷害結算時，吃爆發窗口增傷：
var mult: float = WardBreakSystem.damage_multiplier_for(enemy)
var final_hp_damage: int = int(round(base_hp_damage * mult))

# 敵人回合結束：
WardBreakSystem.tick_broken_state(enemy)

# 戰鬥開始（每隻敵人）：
WardBreakSystem.init_ward(enemy)
```

> **測試保證**（節錄自 `test_ward_break_system.gd`）：命中弱點（break 3 / bonus 4）→ 削盾 7；非弱點（break 4）→ 鈍擊 2；無煞盾敵人 → 0；煞盾 6 先削 4 剩 2、再削 5 歸零觸發破煞且窗口 = `broken_turns`；破煞窗口倍率 1.5；窗口結束回盾解破。

---

## 6. 弱點 × 卡牌標籤的跨角色協同

破煞系統的策略深度來自**「弱點覆蓋面」**：單一角色的儀法標籤無法命中所有敵人的弱點，必須靠**主祭（出戰角色）+ 護壇隊伍**互補。

### 6.1 角色儀法傾向

| 角色 | 主要儀法標籤 | 擅長破煞的敵人類型 |
| --- | --- | --- |
| **乩童**（主祭） | `fist` 拳（攻拳系）、間接帶 `bell`/`curse`（驅邪、降煞牌） | 忌拳的肉身型精怪（山豬精、虎姑婆） |
| **鸞女**（護壇 / 符火互補） | `talisman` 符（靈筆系）、`fire` 火（聖火焚邪） | 忌火、忌符的怨靈型（樹靈、餓鬼、紙紮兵） |

### 6.2 協同範例

- **餓鬼**忌 `talisman`、**樹靈**忌 `fire`：乩童拳系牌打這兩隻只能**鈍擊**（削盾減半）。若隊伍納入鸞女，其「靈筆」(`talisman`) / 「聖火焚邪」(`fire`) 即可**命中弱點全額削盾**，形成「乩童扛血線輸出、鸞女負責破煞」的分工。
- **虎姑婆**弱點為 `[fist, talisman]`（雙弱點）：乩童與鸞女**任一**都能命中，破煞門檻低，但需要持續火力把 9 點煞盾打穿。
- **百年虎爺（BOSS）**弱點為 `[array, fire]`：拳系完全無法命中（只能鈍擊），逼迫玩家**必帶火（鸞女）或陣（家將／後續角色）**才有效率破煞——這是 act1 末「逼隊伍組合」的關卡設計。

> 設計意圖：弱點表是**隊伍構築的反向約束**。玩家在遶境路上看到前方 boss 忌火忌陣，就該回頭調整護壇、留火系牌——呼應 §4.3 角色系統的主祭/護壇定位。

---

## 7. act1（山關）弱點 / 煞盾表

> 真實資料：`external/data/enemies/act1_mountain/`。已通過 `test_ritual_schema.gd::test_enemy_ward_schema_valid`（有煞盾必有弱點、弱點皆合法、破煞效果已定義、`broken_turns >= 1`）。

| 敵人 | object_id | 弱點儀法 | 煞盾 | 階級 | 破煞效果 | broken_turns |
| --- | --- | --- | --- | --- | --- | --- |
| 孤魂 | `enemy_wandering_soul` | `bell` 鈴 | 4 | 雜兵 | `break_stun` | 1 |
| 樹靈 | `enemy_tree_spirit` | `fire` 火 | 6 | 雜兵 | `break_vulnerable` | 1 |
| 餓鬼 | `enemy_hungry_ghost` | `talisman` 符 | 6 | 雜兵 | `break_weak` | 1 |
| 山豬精 | `enemy_mountain_boar` | `fist` 拳 | 8 | 雜兵 | `break_stun` | 1 |
| 紙紮兵 | `enemy_paper_soldier` | `fire` 火 | 7 | 雜兵 | `break_vulnerable` | 1 |
| 虎姑婆 | `enemy_tiger_aunt` | `fist` 拳, `talisman` 符 | 9 | 雜兵 | `break_weak` | 1 |
| 椅仔姑 | `enemy_chair_girl` | `bell` 鈴, `curse` 咒 | 12 | **菁英** | `break_stun_vulnerable` | 2 |
| 魔神仔 | `enemy_makanai` | `array` 陣, `curse` 咒 | 12 | **菁英** | `break_stun_vulnerable` | 2 |
| 百年虎爺 | `enemy_tiger_god` | `array` 陣, `fire` 火 | 20 | **BOSS** | `break_invoke_window` | 2 |

煞盾值梯度設計：雜兵 4–9（單張對症牌即可破）、菁英 12 / 窗口 2 回合（需 2–3 張對症牌、回報更高）、BOSS 20 / 窗口 2（必須打造「破煞爆發」build 才打得動）。

---

## 8. 破煞效果鍵列表與語意

`enemy_break_effect` 決定破煞瞬間對該敵掛上的負面狀態。**效果掛載屬 Phase 1B 接線**（運算層只負責標記 `is_broken`、開窗口、給 1.5x 增傷；具體掛 stun/vulnerable/weak 由戰鬥端依此鍵實作，重用 STR 既有 status effect）。

| 鍵 | 語意 | 建議掛載（接線時對應 STR status） |
| --- | --- | --- |
| `break_stun` | **暈眩**：敵人下一個行動被打斷 / 跳過 | 跳過下一次攻擊（眩暈標記），或 `status_effect_stun` |
| `break_vulnerable` | **易傷**：受到的血量傷害再加成 | `status_effect_vulnerable`（與 1.5x 窗口疊加，破煞收割更猛） |
| `break_weak` | **虛弱**：敵人攻擊力下降 | `status_effect_weak`，降低其造成的傷害 |
| `break_stun_vulnerable` | **眩暈 + 易傷**（菁英級複合效果） | 同時掛 stun 與 vulnerable |
| `break_invoke_window` | **請神窗口**：破煞同時為玩家開啟「請神」時機（BOSS 專用） | 觸發 `on_enemy_broken` 神明請神條件 / 解鎖該回合請神，連動 `deity_invocation_system`（待寫） |

> `break_invoke_window` 是破煞與**請神系統**的接點：百年虎爺被破煞時，不只它變脆，玩家還獲得一次請神的爆發契機，把「破煞」與「降神」兩大儀式高潮疊在一起。

---

## 9. 平衡旋鈕（Balance Knobs）

調整破煞手感時優先動這些參數，全部資料化、不改程式：

| 旋鈕 | 位置 | 影響 |
| --- | --- | --- |
| 敵人煞盾值 | `enemy_max_ward_shield`（JSON） | 破煞門檻；越高越需要專門牌組 |
| 弱點數量 | `enemy_weaknesses`（JSON） | 單弱點 = 逼特定隊伍；雙弱點 = 寬容 |
| 爆發窗口長度 | `enemy_broken_turns`（JSON） | 收割期長短；菁英/BOSS 設 2 提高回報 |
| 卡牌基礎削盾 | `card_break_damage`（JSON） | 鈍擊（÷2）與命中的絕對效率 |
| 命中弱點額外削盾 | `card_weakness_break_bonus`（JSON） | 「對症」相對於「亂打」的價值差 |
| 爆發窗口增傷倍率 | `BROKEN_DAMAGE_MULTIPLIER`（程式常數，目前 1.5） | 破煞後收割的爽度；唯一非資料化旋鈕 |
| 破煞後是否回滿盾 | `tick_broken_state` 的回盾邏輯（目前：回滿） | 再破煞的難度；可改為部分回盾 |

> 平衡基準線（act1）：命中弱點的單張對症牌應在 1–2 張內破雜兵盾；鈍擊（用錯儀法）破盾效率約為命中的一半，懲罰「亂打」但不至於完全無效。

---

## 10. 落地狀態與後續 Phase

| 區塊 | 狀態 | 位置 / 備註 |
| --- | --- | --- |
| 六道儀法標籤單一事實來源 | **已實作** | `RitualTags.gd` |
| EnemyData 煞盾 schema | **已實作** | `EnemyData.gd`（含執行期非序列化欄位） |
| 破煞運算層（純函式） | **已實作 + 已單元測試** | `WardBreakSystem.gd` + `test_ward_break_system.gd` |
| act1 全敵人弱點/煞盾資料 | **已落地 + 已驗證** | `external/data/enemies/act1_mountain/`、`test_ritual_schema.gd` |
| **戰鬥流程接線**（從 ActionAttack / Hand 呼叫破煞五步） | **Phase 1B 待接** | 需在攻擊結算流程插入 §5.3 呼叫；含 `break_effect` 掛載 |
| **UI 煞盾條顯示**（敵人血條上方的煞盾值 + 破煞動畫 + 弱點圖示） | **Phase 1B 待接** | 重用敵人 HUD；破煞時播煞盾碎裂 VFX/SFX |
| `break_invoke_window` ↔ 請神系統連動 | **待接**（依賴請神系統） | 見 `deity_invocation_system`（待寫） |

**Phase 1B 接線清單（給接手者）**：
1. 戰鬥開始時對每隻敵人呼叫 `init_ward`。
2. 攻擊結算流程：`compute_ward_damage` → `apply_ward_damage` →（破煞則掛 `break_effect` + VFX）。
3. 血量傷害乘上 `damage_multiplier_for`。
4. 敵人回合結束呼叫 `tick_broken_state`。
5. 敵人 HUD 加煞盾條（current/max）、弱點儀法小圖示、破煞態高亮。

---

## 11. 開放問題

1. **鈍擊是否該完全不破煞？** 目前鈍擊仍削盾（÷2），長期亂打也能磨破。是否該設「鈍擊封頂」或「非弱點完全不削盾」以更強硬地逼對症？需打磨手感。
2. **破煞窗口的增傷與 `break_vulnerable` 疊加是否過猛？** 1.5x 窗口 + vulnerable status 可能讓破煞後一輪秒殺。需數值驗證，必要時讓兩者擇一或改為相乘上限。
3. **回合結束回滿盾 vs. 部分回盾**：菁英/BOSS 若每次解破都回滿 20 點盾，長期戰可能拖沓。是否改為「回滿但每次破煞後 max 永久 -X」造成壓力遞增？
4. **多段攻擊牌的削盾結算**：一張牌打多下（如聖火焚邪 4×2），煞盾削減目前以「整張牌的 `card_break_damage`」一次結算，還是該逐下結算？影響破煞瞬間落在第幾下、增傷吃幾下。需與 Phase 1B 攻擊流程一起定。
5. **玩家可見資訊量**：弱點圖示是否一開始就揭露，還是首次「鈍擊 / 命中」後才揭曉（鼓勵試探）？關係到新手引導與圖鑑設計。
6. **`break_invoke_window` 的請神契機具體規則**：是「該回合可免費請一次神」還是「破煞給一筆請神值」？待請神系統定案後對齊。
