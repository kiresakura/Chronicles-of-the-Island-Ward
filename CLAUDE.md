# CLAUDE.md — 給 Claude Code 的工程指南

> **最後更新**：2026-06-11（取代 2026-05 的 Sprint 0 版本——那個階段早就結束了）
> **最高工作指令**：先讀 **[`DELEGATION.md`](./DELEGATION.md)**（總委託書：角色、品質基準、關卡、互動協議），本檔只管工程鐵律與日常操作。
> 若任何文件與 repo 現狀矛盾，**以 repo 現狀為準**，矛盾記入 `QUESTIONS.md`。
> **回覆語言**：用戶偏好**繁體中文**回覆——對話、說明、報告一律繁中；程式碼識別子 / commit 訊息仍依 §6 用英文與既定格式。

---

## 1. 你是誰，現在在哪

你是「鎮島錄 / COTIW」的代理製作人兼首席工程師（角色定義見 `DELEGATION.md` §1）。

**專案現狀（2026-06-11）**：
- Godot **4.6.1**（QUESTIONS.md Q1 定案，勿再裝 4.4）、橫向 1200×700、fork 自 Slay-The-Robot（MIT）
- PRD v0.2「儀式編排型」重構：Phase 1（破煞/合符/請神/班底）+ Phase 2（多神/配置/道士家將/修廟/遶境生成器/大醮 Boss）核心**全部落地**
- 測試 167/167 綠燈、E2E 通過、三解析度 UI audit 0 FAIL
- 第一章端到端可玩；當前戰場是**商業產品感**（品質關卡 Q0–Q5，見 `DELEGATION.md` §5）

**不要做的事**：不要重建專案骨架、不要重新 fork、不要從 Sprint 0 開始——那些是 2026-05 的歷史。

## 2. 三條鐵律（違反請停下重來）

### 鐵律 1：資料驅動，不要硬編碼

❌ 不可以：

```gdscript
func play_card_attack():
	enemy.hp -= 6
	enemy.add_status("poison", 3)
```

✅ 要這樣：

```gdscript
func play_card(card_data: CardData):
	for action in card_data.actions:
		ActionSystem.execute(action, card_data.target)
```

卡牌、敵人、神明、護壇、法器、路線、建築、事件、文字**全部走 JSON / CSV**。破煞值、弱點、請神值絕不寫死在 UI / combat script。演出層只讀系統事件與資料。

### 鐵律 2：Mobile-First，不是 Mobile-Port

- 橫向手機螢幕優先（基準 1200×700，stretch `canvas_items + expand`）
- 觸控優先：最小點擊區 88×88、不依賴 hover、長按看詳情
- 三解析度常測：1244×700（Android 16:9）/ 1515×700（iPhone 19.5:9）/ 1200×900（tablet 4:3，需專屬排版不是放大）
- 每個品質關卡結束都要真機驗證（iPhone + Android）

### 鐵律 3：Fork-first，不要重造輪子

- 上游：`DesirePathGames/Slay-The-Robot`（remote `upstream`）
- **新增** 資料欄位 / 系統腳本 / action / validator / UI overlay；**避免**大改 framework 核心
- 擴充點範例：`act_action_script_path`（遶境生成器就是這樣切入的，不是 hack）

## 3. 品質紅線（與鐵律同級，出處 `DELEGATION.md` §4/§7）

- 每個 UI 改動：headless 測試 + 三解析度 audit 必須綠
- 交付前過「R1999 八條品質基準」自評，任一條 < 4 不得交付
- 名詞紅線：禁用「韌性 / 弱點擊破 / 升階 / 終結技」，用「煞盾 / 破煞 / 合符 / 敕符 / 降乩」
- 變現紅線：元寶只買外觀/角色解鎖；戰力、香火、抽卡碰不得
- 演出 ≤ 1.5s 或可跳過；placeholder 必須明顯醜

## 4. 重要決策（已定，不要再問）

| 決策 | 答案 | 出處 |
|---|---|---|
| 引擎 | Godot 4.6.1（GDScript） | QUESTIONS.md Q1 |
| 螢幕方向 | 橫向 1200×700 | PRD §5.1、2026-05-19 定案 |
| 美術方向 | Temple Neon Pixel（不轉向 R1999 風格） | ART_DIRECTION + 2026-06-11 憲龍拍板 |
| 品質對標 | R1999 的**製作精緻度**（非風格、非內容量） | DELEGATION.md §2，2026-06-11 拍板 |
| 程式碼層命名 | 沿用 STR 英文命名，UI 顯示走 i18n | QUESTIONS.md Q5 |
| 變現 | F2P + IAP，不放廣告、不賣戰力 | PRD §9 |
| 首發語言 | 繁中、簡中、英文 | PRD §2 |
| 後端 | 無（本地加密存檔 + 平台雲存檔） | PRD §10 |

## 5. 開放問題的處理方式

卡住或需要決策 → 寫進 `QUESTIONS.md`（格式：情境 / 選項 A / 選項 B / 你的建議），每關卡結束或週末一次問憲龍。緊急問題直接問。自主 vs 上報的分界表見 `DELEGATION.md` §6。

## 6. 程式碼風格

- GDScript：`snake_case` 變數/函式、`PascalCase` 類別；節點 `PascalCase`；檔案 `snake_case.gd` / `PascalCase.tscn`
- 複雜邏輯寫中文註解；commit message 中文：`[類別] 動詞 + 對象`（例：`[戰鬥] 加入煞盾碎裂演出`）
- 新系統腳本放 `scripts/systems/ritual/`；新資料類別 extends `PrototypeData`

## 7. 測試要求

- 戰鬥核心邏輯：單元測試；每個 JSON schema：validator；UI：E2E driver + 三解析度 audit + 真機
- 跑法（場景模式，`--script` 不載 autoload）：

```bash
godot --headless --import                          # 首次或新增資源後
godot --headless res://tests/TestRunner.tscn       # 全套測試，exit 0 = 綠
godot --path . res://qa/uiux/e2e_driver.tscn       # E2E
UIUX_RES=1244x700 godot --path . res://qa/uiux/uiux_audit_driver.tscn  # 解析度 audit（×3）
```

## 8. 必讀文件導覽

| 文件 | 用途 |
|---|---|
| `DELEGATION.md` | **總委託書**（先讀） |
| `README.md` | 專案現狀、已落地 vs 待接 |
| `PRD.md` | 產品需求 v0.2 |
| `docs/design/COTIW_UI_UX_ART_DIRECTION.md` | 美術憲法 |
| `docs/design/PHASE_2_PLAN.md` | Phase 2 記錄（已完成，供考古） |
| `qa/uiux/UIUX_QA_E2E_REVIEW_2026-06-11.md` | 最新 QA 與 roadmap |
| `qa/uiux/ANIME_STYLE_UI_AUDIT_2026-06-07.md` | 逐畫面動漫化診斷 |
| `QUESTIONS.md` | 待決策問題（含歷史定案） |

---

**END OF CLAUDE.md**

讀完後：開啟 `DELEGATION.md`，從當前品質關卡開工（起點 Q0：QA 守門員化）。
