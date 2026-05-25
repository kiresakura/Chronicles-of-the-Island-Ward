# PixelLab 角色戰鬥動畫實作計畫

> **For Hermes:** 這份計畫用來把 COTIW 現有靜態角色圖，擴充成 PixelLab 生產的戰鬥動畫資產與 Godot 接線方案。

**Goal:** 為目前已實作的 2 名可玩角色 + 8 名 Act 1 敵人建立可落地的 PixelLab 動畫生產與接線流程，涵蓋 idle / attack / defend / hit / death。

**Architecture:** 先不粗暴重寫 STR 核心，而是沿用現有 `BaseCombatant` / `Player` / `Enemy` 架構，新增「外部 SpriteFrames 動畫資產」資料欄位與 fallback 機制。若動畫資產不存在，仍回退到現有靜態立繪 + 程序化 `SpriteProcAnim`，維持可執行狀態。

**Tech Stack:** Godot 4.6.1、GDScript、外部 PNG 序列幀、`SpriteFrames`、`AnimatedSprite2D`、`FileLoader.load_animation()`。

---

## 0. 現況審計（已完成）

### 目前已知事實

- 現在戰鬥員使用的是單張 `Sprite2D`：
  - `Player.gd` 讀 `character_texture_path`
  - `Enemy.gd` 讀 `enemy_texture_path`
- `BaseCombatant.gd` 已有 `FileLoader.load_animation()` 可把外部圖片序列組成 `SpriteFrames`。
- 目前資料模型裡 **沒有** `character_animation_data` / `enemy_animation_data` 欄位。
- 目前戰鬥動畫來源分兩種：
  1. `AnimationPlayer`：老的 attack / death
  2. `SpriteProcAnim`：呼吸、前刺、受擊 squash & stretch
- 本機 **沒有** `pixellab` / `pixel-lab` / `pixflux` CLI；但已確認可直接走 `https://api.pixellab.ai/v1` HTTP API。

### 目前角色範圍（manifest 已寫好）

見：`assets/generated/pixellab/character_animation_manifest_v1.json`

- 可玩角色：乩童、鸞女
- Act 1 敵人：孤魂、餓鬼、魔神仔、山豬精、紙紮兵、椅仔姑、虎姑婆、樹靈、百年虎爺

---

## 1. 生產規格

### Task 1: 建立動畫資產命名規範

**Objective:** 讓 PixelLab 輸出能直接被 Godot 載入，不再靠人工猜路徑。

**Files:**
- Create: `assets/generated/pixellab/character_animation_manifest_v1.json`
- Create: `docs/plans/2026-05-23-pixellab-character-animation-plan.md`

**規範：**

- 每名角色一個資料夾：
  - `assets/generated/animations/<actor_id>/`
- 每個狀態用連號 PNG：
  - `<actor_id>__idle__f01.png`
  - `<actor_id>__attack__f01.png`
  - `<actor_id>__defend__f01.png`
  - `<actor_id>__hit__f01.png`
  - `<actor_id>__death__f01.png`
- 背景：透明
- 畫布：512×512
- 同一角色所有狀態的地板基準線一致
- 不可烘字、不加 UI 外框、不加背景場景

---

## 2. Godot 資料模型擴充

### Task 2: 為 CharacterData 增加動畫欄位

**Objective:** 讓角色 JSON 可直接描述動畫幀序列。

**Files:**
- Modify: `data/readonly/CharacterData.gd`
- Modify: `external/data/characters/character_tongji.json`
- Modify: `external/data/characters/character_luannu.json`

**新增欄位建議：**

```gdscript
@export var character_animation_data: Dictionary[String, Array] = {}
```

**JSON 範例：**

```json
"character_animation_data": {
  "idle": [
    "assets/generated/animations/character_tongji/character_tongji__idle__f01.png",
    "assets/generated/animations/character_tongji/character_tongji__idle__f02.png"
  ],
  "attack": [
    "assets/generated/animations/character_tongji/character_tongji__attack__f01.png"
  ]
}
```

**注意：** 若動畫欄位空，應維持舊靜態圖 fallback。

---

### Task 3: 為 EnemyData 增加動畫欄位

**Objective:** 讓敵人 JSON 也能走同一套動畫管線。

**Files:**
- Modify: `data/prototype/EnemyData.gd`
- Modify: `external/data/enemies/act1_mountain/*.json`

**新增欄位建議：**

```gdscript
@export var enemy_animation_data: Dictionary[String, Array] = {}
```

同樣保留 `enemy_texture_path` 當 fallback。

---

## 3. Runtime 顯示層改造

### Task 4: 在 BaseCombatant 場景加入 AnimatedSprite2D

**Objective:** 讓戰鬥員可在靜態圖與序列動畫之間切換。

**Files:**
- Modify: `scenes/combatants/BaseCombatant.tscn`
- Modify: `scripts/combatants/BaseCombatant.gd`

**做法：**

1. 在 `Visible` 下新增 `AnimatedSprite2D`，與現有 `Sprite2D` 同層。
2. 預設：
   - 若有 animation_data → 顯示 `AnimatedSprite2D`
   - 否則 → 顯示 `Sprite2D`
3. `SelectionButton` / `LayeredHealthBar` 要跟隨新的可視 sprite anchor，不能漂移。

**關鍵 helper：**

```gdscript
func set_combatant_animation(animation_id: String, animation_data: Dictionary) -> void:
    var frames: SpriteFrames = FileLoader.load_animation(animation_id, animation_data)
    animated_sprite.sprite_frames = frames
    animated_sprite.play("idle")
```

---

### Task 5: 將攻擊 / 防禦 / 受擊 / 死亡事件映射到動畫狀態

**Objective:** 讓現有戰鬥事件驅動新動畫，而不是只有程序化變形。

**Files:**
- Modify: `scripts/combatants/BaseCombatant.gd`
- Modify: `scripts/combatants/Enemy.gd`
- Modify: `scripts/combatants/Player.gd`

**狀態映射建議：**

- `play_attack_animation()` → `attack`
- `Signals.combatant_block_added` / 或 block 行為 → `defend`
- `Signals.combatant_damaged` → `hit`
- HP <= 0 → `death`
- 其他時間 → `idle`

**原則：**
- 若狀態不存在，fallback 回 `SpriteProcAnim` / `AnimationPlayer`
- `death` 播完後再發 `enemy_death_animation_finished` / `player_death_animation_finished`

---

## 4. PixelLab 生產批次

### Task 6: 先做 1 名角色 + 1 名敵人的試產

**Objective:** 先驗證 PixelLab 視覺一致性，不一次把全專案拖進泥沼。

**Files:**
- Create externally: `assets/generated/animations/character_tongji/*`
- Create externally: `assets/generated/animations/enemy_mountain_boar/*`

**建議試產對象：**
- `character_tongji`
- `enemy_mountain_boar`

**理由：**
- 一個人形、一個獸形
- 動作辨識明確
- 最容易驗證 attack / hit / death 是否成立

---

### Task 7: 用去背工具清理 PixelLab 輸出

**Objective:** 若 PixelLab 不是輸出真透明，而是純色背景，就走既有去背工具。

**Files:**
- Existing tool: `scripts/tools/pixellab_debg.py`

**Run:**

```bash
python3 scripts/tools/pixellab_debg.py assets/generated/animations/character_tongji/*.png
python3 scripts/tools/pixellab_debg.py assets/generated/animations/enemy_mountain_boar/*.png
```

---

## 5. 測試與驗證

### Task 8: 加動畫資料驗證測試

**Objective:** 防止 JSON 寫了不存在的動畫路徑。

**Files:**
- Modify: `tests/unit/test_data_validation.gd`

**測試要點：**
- 若 `character_animation_data` 存在，所有路徑都必須存在
- 若 `enemy_animation_data` 存在，所有路徑都必須存在
- 至少 `idle` 要存在，否則視為不完整動畫包

---

### Task 9: 實機驗證戰鬥動畫切換

**Objective:** 確認播放不卡、定位不漂、死亡後事件照常發。

**Run:**

```bash
godot --headless res://tests/TestRunner.tscn
```

之後必須做：
- Android 實機：進戰鬥、出牌、受擊、死亡
- iOS 真機或 simulator：至少驗證閒置與攻擊切換

---

## 6. 現在的阻塞點

### 目前不能直接完成「用 PixelLab 做出所有動畫」的原因

1. 本機沒有 PixelLab / pixflux CLI，但可直接走 PixelLab HTTP API。
2. 目前帳號餘額為 0 USD；在未儲值前，無法實際呼叫生成或動畫端點。
3. 專案 runtime 也尚未有 animation_data schema；就算有 PNG 序列，還缺正式接線層。

### 因此，現在最合理的落地順序

1. 用本計畫固定規格
2. 先讓 Godot 支援 animation_data
3. 試產 `乩童 + 山豬精`
4. 驗證 OK 後再擴到全部角色

---

## 7. 建議下一步

如果要我直接繼續，我建議下一刀切這個：

**A. 我先幫你把 Godot 動畫資料結構與 runtime 接線實作完**  
這樣你一丟 PixelLab 輸出的 PNG 序列進來，就能立刻播。

或

**B. 你提供 PixelLab 的可用方式（CLI / 網頁流程 / 匯出規格 / 帳號）**  
我再把實際產圖流程也一起接上。
