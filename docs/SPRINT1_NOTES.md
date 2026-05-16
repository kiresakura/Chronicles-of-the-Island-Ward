# Sprint 1 進度筆記

> **日期**：2026-05-16 起手
> **目標**：乩童主題替換 + 第一章敵人 + 10 張卡，能用乩童打通一場山豬精戰鬥

## 已完成

### 資料骨架（commit e149131）

26 個 JSON 資料檔，無載入錯誤：

| 類別 | 數量 | 檔名 |
|---|---|---|
| 色彩 | 2 | color_tongji, color_white |
| 狀態效果 | 3 | damage_increase (神威), vulnerable (驚嚇), weak (怯戰) |
| 動作攔截器 | 3 | divine_might, startled, cowed |
| 關鍵字 | 3 | 同上對應 tooltip |
| 角色 | 1 | character_tongji |
| 玩家原型 | 1 | player_tongji |
| 起手遺物 | 1 | artifact_tongji_amulet (平安符 +5 護身符) |
| 卡牌包 | 1 | card_pack_tongji |
| 遺物包 | 2 | neutral, tongji |
| 乩童卡牌 | 10 | 攻拳, 重擊, 連環攻擊, 護身符, 鐵布衫, 乩童附體, 狂怒一擊, 抽符, 驅鬼, 威靈出陣 |
| 第一章敵人 | 5 | 山豬精, 樹靈, 虎姑婆, 椅仔姑, 魔神仔 |

### 起手卡組（character_tongji 預設 10 張）

- 攻拳 x5（基礎 6 傷害）
- 護身符 x4（基礎 6 護甲）
- 連環攻擊 x1（4×2）

### 設計理念

- **乩童專屬機制**：高風險高報酬，狂怒一擊（自損 2 換 12 傷害）展示典型
- **神威 (status_effect_damage_increase)** ：用 STR 既有 InterceptorDamageIncrease（hardcoded 名稱）
- **驚嚇 (vulnerable) / 怯戰 (weak)** ：標準 STS-like buff/debuff

### Action 引用樣式（資料驅動範例）

```json
"card_play_actions": [
    {
        "res://scripts/actions/meta_actions/ActionAttackGenerator.gd": {
            "damage": 6, "number_of_attacks": 1
        }
    }
]
```

## 已知限制

### 邪氣（poison）未實作

PRD 4.1 詞彙表有「邪氣」對應 poison。STR 框架沒有 built-in poison-like status effect，需自寫 status script 或用 status_effect_player/enemy_actions 配合 ActionDirectDamage。

**Sprint 2 計畫**：寫 `external/sprites/status_effects/status_effect_evil_aura.json`，用 ActionDirectDamage 在每回合自動傷害目標。

### 未產生：run 啟動所需資料

要正式跑通一場戰鬥，還缺以下資料檔：

- `act_1.json`（act_data）
- `event_pool_act1_easy.json`, `_hard.json`, `_miniboss.json`, `_boss.json`, `_non_combat.json`
- 每個 event_pool 內的 EventData JSON（每隻敵人對應一個 combat event）
- `run_start_option_*.json`（run 開始時的選項）
- 至少 1 個 `consumable` (PRD 沒提，看 STR 是否需要)
- `rest_action_*.json`（廟宇休息選項）

**Sprint 1 收尾任務**：寫這些檔案到能進入 1 場戰鬥即可。

### 升級版卡牌（+ 形態）

PRD 4.5「卡牌升級」要求每張卡有升級版。10 張卡的升級版本（card_xxx 加 `card_upgrade_value_improvements`）暫未寫。

### 美術 placeholder

所有資料的 `card_texture_path`、`enemy_texture_path` 都空著——目前用 STR 預設純色方塊渲染。**鐵律 3 第 5 條**：「美術 placeholder 變正式素材」是陷阱，但 Sprint 1 階段只需要能跑通，美術下個階段補。

## 驗證

- ✅ `godot --headless --quit-after 200` 跑 200 幀無 GDScript 錯誤
- ⏳ 編輯器內角色選擇頁面是否看到「乩童」（待手動測試）
- ⏳ 一局戰鬥流程跑通（缺 act_1 等資料）

## Sprint 1 收尾 TODO

1. 寫 act_1 + event_pool + event 資料（5-10 個檔）
2. 寫 run_start_options 至少 1 個
3. 寫 rest_actions（休息點動作）
4. 在編輯器內手動跑一場山豬精戰鬥
5. 真機 iOS Simulator 上跑通（搭配 docs/IOS_EXPORT_SETUP.md）
6. 升級版 10 張卡（card_upgrade_value_improvements）
7. 開始 GUT 測試框架（Sprint 1 後段）

## Sprint 2 前瞻

- 直向 mobile UI 重設計（Q2 ✅ 已批准延後）
- 邪氣 (poison) status effect 實作
- TranslationServer + CSV i18n 介入 UI
- 完整 i18n keys for 10 cards
