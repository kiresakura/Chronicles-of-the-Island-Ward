# Recraft AI 美術素材生成 — 2026-05-20

> **工具**：Recraft v3 + v2 (MCP extension)
> **credits 用**：~140 / 5000
> **耗時**：≈ 40 min
> **總計**：37 個新素材

---

## 1. 產出清單

### Wave 1：狀態 icon（8 個 SVG，`assets/generated/icons/status/`）
| 檔名 | 對應 | 工具 substyle |
|---|---|---|
| status_hp.svg | 氣血 / HP | bold_stroke + roundish_flat |
| status_block_bagua.svg | 護身 / Block（八卦盾）| roundish_flat |
| status_energy_bagua.svg | 神力 / Energy（八卦圖）| roundish_flat |
| status_incense_money.svg | 香火 / Money（香爐）| bold_stroke |
| status_yuanbao.svg | 元寶 / Premium currency | roundish_flat |
| status_pingan_fu.svg | 平安符 / Buff | roundish_flat |
| status_weak.svg | 虛弱 / Weak | roundish_flat |
| status_curse.svg | 業障 / Curse | roundish_flat |

### Wave 1：地圖節點 icon（6 個 SVG，`assets/generated/icons/map_nodes/`）
| 檔名 | 對應 |
|---|---|
| node_combat.svg | 戰鬥（雙刀交叉）|
| node_elite.svg | 精英（魔神面具）⭐⭐⭐ |
| node_event.svg | 事件（求籤竹筒）|
| node_rest.svg | 休息（廟前篝火）|
| node_shop.svg | 商店（夜市紅燈籠）|
| node_boss.svg | 首領（皇冠骷髏）|

### Wave 2：6 神明 badge（`assets/generated/icons/deities/`）⭐ **全套頂級**
所有 6 個都用 `linocut` substyle，傳統黑白木刻版畫風（廟前年畫風 motif）：
- deity_mazu.svg — 媽祖（蓮花冠 + 流蘇）
- deity_guanyin.svg — 觀音（蓮花座菩薩）
- deity_wangye.svg — 王爺（皇冠龍紋 + 鬍）
- deity_chenghuang.svg — 城隍（黑帽 + 算盤）
- deity_tudi.svg — 土地公（拐杖 + 長壽紋）
- deity_huye.svg — 虎爺（兇虎 + 廟章邊框）

### Wave 3：11 乩童卡圖（`assets/generated/cards_v2/`）
全部用 `digital_illustration + engraving_color`（vintage 廟會海報 / 版畫色木刻風）：

| 檔名 | 卡名 | 構圖 |
|---|---|---|
| card_tongji_charge_v2.webp | 威靈出陣 | 乩童舉刀，神光放射 |
| card_tongji_double_strike_v2.webp | 連環攻擊 | 雙刀交叉劈擊 |
| card_tongji_draw_charm_v2.webp | 抽符 | 廟壇取符（藍紅木刻）|
| card_tongji_evil_curse_v2.webp | 邪氣咒 | 骷髏雲飄向亡魂（藍黑）|
| card_tongji_exorcise_v2.webp | 驅鬼 | 乩童擊鬼幻化（藍）|
| card_tongji_fury_strike_v2.webp | 狂怒一擊 | 暴怒特寫（紅黃）⭐ |
| card_tongji_great_talisman_v2.webp | 鐵布衫 | 護身姿勢（西方化偏差，視覺可用）|
| card_tongji_heavy_strike_v2.webp | 重擊 | 大鎚劈地，地裂紋（紅）⭐ |
| card_tongji_possession_v2.webp | 乩童附體 | 入神光環（黃紅）⭐ |
| card_tongji_punch_v2.webp | 攻拳 | 紅頭巾出拳（黃黑紅）|
| card_tongji_talisman_v2.webp | 護身符 | 紙符飄落（粉紅版）|

### Wave 4：UI 系統 icon（6 個 SVG，`assets/generated/icons/ui_v2/`）
- ui_back.svg — 返回箭頭
- ui_settings.svg — 設定（八卦齒輪）⭐⭐
- ui_deck.svg — 牌堆（三符卡）
- ui_draw.svg — 抽牌（持卡 + 閃光）
- ui_discard.svg — 棄牌堆（燒符）
- ui_burn_jin.svg — 燒金紙（紙錢 + 火 + 銅錢）

---

## 2. JSON 接線狀態

✅ 所有 11 個 `external/data/cards/tongji/*.json` 已更新 `card_texture_path`：
```
"card_texture_path": "assets/generated/cards_v2/card_tongji_<id>_v2.webp"
```

✅ Godot 自動 import .webp 成功（`.godot/imported/card_tongji_*_v2.webp-*.ctex` 都存在）

✅ Tests 37/37 pass

✅ APK rebuilt + installed + 走過 NewRunMenu → RSO（修好版）→ CardReward

---

## 3. 已知待解

### CardReward overlay 卡圖顯示淡（待 polish）
實機驗證：v2 webp 已載入但在 CardReward overlay 顯示成 cream/beige 不見原 vibrant 色。可能原因：
- CardRewardButton 場景可能用獨立 render，非 Card.tscn
- Card.tscn 內 art slot 96×96 + frame 蓋上半部
- 需 audit `scenes/ui/rewards/CardRewardButton.tscn` 怎麼 render

**短期 workaround**：先進實戰戰場驗證 — 戰鬥中的 Card.tscn hand 應該正確顯示 v2 art。

### 兩張視覺偏差需重生
- `card_tongji_great_talisman_v2.webp`（鐵布衫）變西方騎士甲冑 → 重生需強調「中式紙符附身」
- `card_tongji_talisman_v2_lantern.webp` 第一版變燈籠（已保留作 fallback）

### 文字 baked in
`engraving_color` substyle 一律在卡圖上印英文標題（"DIVINE MIGHT CHARGE" 等）—— 不影響功能（UI 卡名覆蓋），但 polish 可以後製去除。

---

## 4. Recraft 使用心得

| 用途 | 推薦 substyle | 結果 |
|---|---|---|
| 傳統廟章 / 神明 badge | `vector_illustration + linocut` | ⭐⭐⭐⭐⭐ 完美木刻版畫 |
| 狀態 icon（清晰小符號）| `vector_illustration + bold_stroke` | ⭐⭐⭐ 部分加 scene 背景 |
| 廟會風卡圖 / 海報 | `digital_illustration + engraving_color` | ⭐⭐⭐⭐ vintage 風強烈但有文字 |
| 設定 / UI icon | `vector_illustration + colored_stencil` | ⭐⭐⭐ 概念可用 |

**最佳組合**：神明 badge 用 linocut、卡圖用 engraving_color、純 icon 用 bold_stroke / cutout。

---

## 5. 下一步

1. **CardReward overlay 視覺接線**：audit CardRewardButton.tscn，確保新 v2 art 正確顯示
2. **重生 2 張**：鐵布衫（要中式紙符）+ 護身符（清晰 fu 紙）
3. **進實戰驗證**：戰鬥 hand 卡 art 應正確顯示
4. **狀態 icon 套用**：Combat HUD 八卦 energy ring 替換現 STR ProgressBar
5. **地圖節點 icon 套用**：MapLocation.tscn 用 6 種 node SVG 替換占位圓盤
6. **神明 badge 套用**：Combat top HUD 替換 3 個 STR Godot icon

**Credits remaining**：~4860 / 5000（充足，可後續 polish）
