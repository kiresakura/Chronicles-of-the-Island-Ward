# AGENTS.md — 給 Codex 的接手指南

> 這個檔案告訴你（Codex）如何接手「鎮島錄 / COTIW」這個專案。
> **務必先讀完這份文件，再讀 `PRD.md`。**

---

## 1. 你是誰，你要做什麼

你是接手「鎮島錄」開發的 Codex agent。專案剛通過企劃階段，你的任務是：

1. **建立 Godot 4.4 專案骨架**
2. **Fork 並整合 `DesirePathGames/Slay-The-Robot`** 作為核心戰鬥框架
3. **按 PRD 的 Phase 1 → Phase 5 推進開發**

你不是被要求一次寫完所有東西。你是要**先把 Phase 1（Prototype）做好**，每完成一個里程碑就停下來等開發者（憲龍）驗收。

---

## 2. 三條鐵律（違反請停下重來）

### 鐵律 1：資料驅動，不要硬編碼

❌ 不可以這樣寫：
```gdscript
func play_card_attack():
	enemy.hp -= 6
	enemy.add_status("poison", 3)
```

✅ 要這樣寫：
```gdscript
func play_card(card_data: CardData):
	for action in card_data.actions:
		ActionSystem.execute(action, card_data.target)
```

卡牌、敵人、事件、文字**全部走 JSON / CSV**。理由：日後做平衡調整、本地化、Mod 都靠這個。

### 鐵律 2：Mobile-First，不是 Mobile-Port

- 所有 UI 設計**從橫向手機螢幕開始**（基準解析度 1200×700；2026-05-19 定案橫向，見 PRD §5.1 / QUESTIONS）
- 所有互動**設計給觸控**，不要有「需要滑鼠 hover」才能用的功能
- 在 Godot Editor 把 Display 設成 mobile preset
- 每個 Sprint 結束都要在**真機**測試（iPhone SE 模擬器最低標，理想是真 iPhone + 真 Android）

### 鐵律 3：Fork-first，不要重造輪子

**Phase 1 起手**：
```bash
git clone https://github.com/DesirePathGames/Slay-The-Robot.git COTIW-base
cd COTIW-base
git remote rename origin upstream
# 在 GitHub 建立私人 repo: cotiw
git remote add origin <your-private-repo>
git push -u origin main
```

之後你的修改提交到自己的 repo，但保留 upstream 以追原作更新。

---

## 3. 推薦的開發順序（Phase 1 細節）

### Sprint 0: 環境設置（1 週）

- [ ] 安裝 Godot 4.4 stable
- [ ] Fork Slay The Robot，跑通預設範例
- [ ] 設定 GitHub Actions（iOS + Android build pipeline）
- [ ] 設定 Godot project export presets（iOS、Android）
- [ ] 在 iPhone + Android 真機跑通 Slay The Robot 原版

**驗收問題**：Slay The Robot 預設範例能不能在 iPhone 真機跑起來？能完成一場戰鬥嗎？

### Sprint 1: 主題改造（2 週）

- [ ] 替換 Slay The Robot 預設機器人主題 → 乩童
- [ ] 建立 `data/cards/tongji/` 目錄，寫 10 張卡的 JSON
- [ ] 替換 5 個預設敵人 → 山豬精、樹靈、虎姑婆等
- [ ] 替換戰鬥資源文字（Energy → 神力，HP → 元神，etc.）
- [ ] 美術全部用 placeholder（純色方塊 + 中文字）

**驗收問題**：能不能用乩童打完一場「山豬精」戰鬥？資料是不是全部從 JSON 載入？

### Sprint 2: 橫向 Mobile UI（2 週）

- [ ] 重新設計戰鬥場景 UI 為橫向
- [ ] 實作觸控手勢（拖曳出卡、長按看詳情）
- [ ] 適配多種螢幕尺寸（iPhone SE 至 iPhone Pro Max）
- [ ] 加入 i18n 框架（即使只支援繁中）

**驗收問題**：UI 在 iPhone SE 和 iPhone 15 Pro Max 兩個極端尺寸下都正常嗎？

### Sprint 3: 地圖與單章節（3 週）

- [ ] 實作分支地圖系統（複用 Slay The Robot Act 系統）
- [ ] 第一章 15 層地圖（戰鬥、菁英、商店、休息、事件、Boss）
- [ ] 商店、休息（廟宇）、隨機事件節點
- [ ] **章節王「百年虎爺」**戰鬥（簡化版即可，Phase 4 再打磨）

**Phase 1 驗收（M2 結束）**：能從新一局開始 → 跑完第一章 → 打敗百年虎爺。1 個角色、30 張卡、15 個敵人，能在 iPhone 真機完整跑通。

---

## 4. 重要決策（已定，不要再問）

| 決策 | 答案 | 理由 |
|---|---|---|
| 引擎 | Godot 4.4+ | MIT、STS2 同款、行動匯出成熟 |
| 主要語言 | GDScript | 開發快、社群大、效能瓶頸再換 C# |
| 起手框架 | Slay The Robot (MIT) | 省 6+ 月開發時間 |
| 螢幕方向 | 橫向 | R1999 lobby 風、沿用 STR 橫向基底（2026-05-19 定案，早期直向作廢）|
| 變現模式 | F2P + IAP | 已定，**不放廣告**（MVP） |
| 首發語言 | 繁中、簡中、英文 | 主要市場 |
| 後端 | 無（MVP） | 純本地 + 雲端存檔 |

---

## 5. 等決策的開放問題（請邊做邊問）

把你做的時候卡住或需要決策的問題，**累積寫到 `COTIW/QUESTIONS.md`**，每週末（或每個 Sprint 結束）一次問憲龍，**不要每個問題都打斷他**。

範本：
```markdown
## 2026-XX-XX Sprint X 結束問題清單

### Q1: [問題標題]
**情境**：[你遇到什麼]
**選項 A**：[做法 A + 優缺點]
**選項 B**：[做法 B + 優缺點]
**你的建議**：[傾向哪個 + 為什麼]
```

---

## 6. 程式碼風格

- **GDScript 命名**：`snake_case` 變數與函式、`PascalCase` 類別
- **節點命名**：`PascalCase`（Godot 慣例）
- **檔案命名**：`snake_case.gd`、`PascalCase.tscn`
- **註解**：複雜邏輯一律寫中文註解（後續其他人接手較友善）
- **無註解的 commit**：不接受
- **commit message**：用中文，格式 `[類別] 動詞 + 對象`，例如 `[戰鬥] 加入邪氣狀態效果`

---

## 7. 測試要求

- **戰鬥核心邏輯**：必須有單元測試（用 GUT framework）
- **資料載入**：每個 JSON schema 要有 validator
- **UI**：手動測試 + 真機驗證
- **CI/CD**：每次 push 自動跑單元測試 + 自動 build

---

## 8. 你必須避免的陷阱

| 陷阱 | 後果 | 避免方式 |
|---|---|---|
| 一次想做完所有 Phase | 死於完美主義 | 嚴守 Phase 1 範圍，Phase 2 前不碰 |
| 自己改 Slay The Robot 核心 | 失去追上游能力 | 改 framework 用 monkey patch / 繼承，不直接編輯 addon |
| 硬編碼數值 | 後期平衡 hell | JSON 第一，所有 magic number 入設定檔 |
| 寫了再說（無設計） | 重構地獄 | 每 Sprint 開始先寫一頁設計筆記 |
| 忽略真機測試 | 上架前才發現 UI 爆炸 | 每週至少一次 iPhone + Android 真機跑 |
| 美術 placeholder 變正式素材 | 上線醜陋 | placeholder 階段就用「明顯醜」的純色方塊，逼自己後期換掉 |

---

## 9. 與憲龍的溝通

- **每週**：1 次同步（書面 OK），報告本週進度 + 下週計畫
- **每 Sprint 結束**：交付驗收影片（30 秒-2 分鐘真機錄影）+ 開放問題清單
- **緊急問題**：直接問，不要等
- **平衡問題**：你不負責，蒐集數據給憲龍決策

---

## 10. 快速指令參考

```bash
# 啟動 Godot 編輯器
godot --editor

# 命令列建 iOS 版
godot --headless --export-release "iOS" build/cotiw.ipa

# 命令列建 Android 版
godot --headless --export-release "Android" build/cotiw.apk

# 跑單元測試（場景模式；--script 不會載入 autoload，Global/Random 會找不到）
godot --headless res://tests/TestRunner.tscn
```

---

## 11. 重要連結

- **PRD**：`./PRD.md`
- **Slay The Robot 原 repo**：https://github.com/DesirePathGames/Slay-The-Robot
- **Godot 4 mobile 匯出文件**：https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- **GUT 測試框架**：https://github.com/bitwes/Gut

---

**END OF AGENTS.md**

讀完後請開始 Sprint 0。第一個任務：fork Slay The Robot，把預設範例跑在 iPhone 真機上。
