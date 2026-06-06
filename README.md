# 鎮島錄 / Chronicles of the Island Ward (COTIW)

> **一款台灣民俗題材的「儀式編排型 roguelike 卡牌手遊」。**
> 玩家透過 **合符、破煞、請神、遶境、修廟**，守護一座被妖煞侵擾的島嶼。
> Godot 4 · iOS + Android · F2P + IAP（不放廣告）

> *A ritual-driven roguelike card battler where players merge talismans, break evil wards, and invoke deities to protect a haunted island.*

---

## 30 秒理解這個專案

**這不是「殺戮尖塔換台灣皮」。** 它是一款以「儀式編排」為核心的卡牌 roguelike——每一場戰鬥都是一次鎮煞儀式：

| 支柱 | 你在做什麼 | 靈感轉化（非照抄） |
|---|---|---|
| 🪬 **合符** | 手牌兩張同階符可合成升階：一劃符 → 二劃符 → 三劃敕符 | 《重返未來 1999》手牌合成 |
| 💥 **破煞** | 用對「儀法」（拳/符/火/鈴/陣/咒）命中妖怪弱點，削「煞盾」，破煞後開爆發窗口 | 《崩壞：星穹鐵道》弱點擊破 |
| ⛩️ **請神** | 累積請神值、擇時降乩（虎爺破煞、城隍審判、媽祖守護、土地公資源） | 民俗信仰原創 |
| 🏮 **遶境** | 不是爬塔，是出巡遶境：山路 / 廟路 / 夜市路 / 荒宅路，污染越高香火越豐、越危險 | roguelike 路線 |
| 🛕 **修廟** | 香火拿去修復鎮島廟，解鎖神明位 / 法器 / 籤詩——**但永遠不賣戰力** | meta progression |

**開局**不是只選一個職業，而是配置 **主祭 / 護壇 / 法器** 三件班底。
**變現**只賣外觀 / 角色解鎖 / 支持者內容，**絕不賣戰力、不做戰力 Gacha、不放廣告**。

> 想一句話判斷重構是否成功？讀完本 README 與 PRD 後，你應該說得出「這是破煞 + 請神 + 合符」，而不是「STS 換皮」。

---

## 當前開發狀態

> 最後更新：2026-06-06 — **儀式編排型重構 Phase 1A 完成**

**✅ Phase 1A（文件與 schema）已完成**：
- PRD v0.2 + README 重定位為儀式編排型；6 份系統設計文件
- `CardData` / `EnemyData` 擴充儀式欄位（破煞 / 合符 / 請神 / 分類），新增 `DeityData` / `GuardianData` / `RitualToolData`
- `RitualTags`（六道儀法單一事實來源）+ `WardBreakSystem`（破煞純函式運算，已單元測試）
- 資料注入：乩童 11 卡 + 鸞女 7 卡帶儀式欄位、act1 全 9 敵帶煞盾 / 弱點、4 神明 / 2 護壇 / 3 法器 / 4 路線 / 6 建築
- 測試 **101 / 101 綠燈**（含新 schema validator + 破煞單元 + 載入 round-trip 證明）

**⏳ 下一步**：Phase 1B 把破煞接進戰鬥流程（`WardBreakSystem` ← `ActionAttack`/`Hand`，煞盾條 UI）。

**既有可玩基礎**（重構前）：乩童 + 鸞女兩角、第一章敵人 + 百年虎爺、橫向 mobile UI、戰鬥 / 地圖 / 商店 / 休息流程、Android 真機跑通。

---

## 已落地 vs 設計待接（誠實標註）

| 系統 | 資料 / schema | 運算層 | 戰鬥 / UI 接線 |
|---|---|---|---|
| 破煞 | ✅ | ✅ `WardBreakSystem` + 單元測試 | ✅ **接線 + 煞盾指示（Enemy.gd）**；AoE/視覺/平衡續調 |
| 合符 | ✅ 合成圖已驗證 | ✅ `TalismanMergeSystem` + 單元測試 | ✅ **接線（右鍵合符 + 每回合限額）**；UI 提示/手機手勢續調 |
| 請神 | ✅ 4 神 | ✅ `DeityInvocationSystem` + 單元測試 | ✅ **虎爺請神槽（出牌+破煞累積）+ 降乩 AoE**；多神/平衡/手機版位續調 |
| 主祭/護壇/法器 | ✅ 樣本 | — | ⏳ Phase 2 |
| 遶境地圖 | ✅ 路線特徵 | — | ⏳ Phase 2（地圖**尚未**重寫） |
| 修廟 meta | ✅ 6 建築 | — | ⏳ Phase 2 |

---

## 跑專案 / 跑測試

```bash
# 匯入（首次或新增資源後）
godot --headless --import

# 跑全套 headless 測試（exit 0 = 全過；目前 101/101）
godot --headless res://tests/TestRunner.tscn

# 開編輯器 / 跑遊戲
godot -e          # 編輯器
godot             # 直接執行
```

詳見 [tests/README.md](./tests/README.md)。新系統測試：`tests/unit/test_ritual_schema.gd`、`tests/unit/test_ward_break_system.gd`。

---

## 文件導覽

| 檔案 | 用途 |
|---|---|
| [PRD.md](./PRD.md) | **產品需求文件 v0.2**（儀式編排型定位、四大支柱、角色、遶境、修廟、變現、Phase 計畫） |
| [docs/design/ritual_combat_system.md](./docs/design/ritual_combat_system.md) | **戰鬥總覽**：四支柱如何咬合成儀式鏈（先讀這份） |
| [docs/design/ward_break_system.md](./docs/design/ward_break_system.md) | 破煞 / 煞盾系統 |
| [docs/design/talisman_merge_system.md](./docs/design/talisman_merge_system.md) | 符階合成系統 |
| [docs/design/deity_invocation_system.md](./docs/design/deity_invocation_system.md) | 請神系統 |
| [docs/design/pilgrimage_route_system.md](./docs/design/pilgrimage_route_system.md) | 遶境地圖系統 |
| [docs/design/meta_temple_progression.md](./docs/design/meta_temple_progression.md) | 修廟 meta progression |
| [CLAUDE.md](./CLAUDE.md) / [AGENTS.md](./AGENTS.md) | 工程接手指南（三鐵律） |
| [QUESTIONS.md](./QUESTIONS.md) | 開發過程累積問題 → 憲龍 |

**新資料目錄**：`external/data/{deities,guardians,ritual_tools,route_traits,meta_buildings}/`
**新系統腳本**：`scripts/systems/ritual/{RitualTags,WardBreakSystem}.gd`
**新資料類別**：`data/prototype/{DeityData,GuardianData,RitualToolData}.gd`

---

## 給接手工程師 / Claude Code 的注意事項

1. **三鐵律**：資料驅動（神明 / 弱點 / 破煞值全 JSON，不硬編碼）、mobile-first 橫向 1200×700、Slay-The-Robot fork-first（新增 > 改核心）。
2. **名詞紅線**：機制吸收 R1999 / HSR，但**禁用**「韌性 / 弱點擊破 / 升階 / 終結技」原詞——我們用「煞盾 / 破煞 / 合符 / 敕符 / 降乩」。
3. **新欄位向後相容**：卡 / 敵的儀式欄位預設空 / 0，對既有戰鬥行為零影響；接 Phase 1B 時才讓 `WardBreakSystem` 生效。
4. **測試必綠**：改動後跑 `TestRunner`，維持 101/101；新系統請補 validator / 單元測試。
5. **下一步**：破煞(1B)/合符(1C)/請神(1D 虎爺) 四支柱核心已落地（`scripts/systems/ritual/` + `Enemy.gd`/`Hand.gd`/`Combat.gd`）；接續 **Phase 2（主祭/護壇/法器配置 + 完整第一章遶境 + 城隍/媽祖/土地公請神）**。

---

## 聯絡

- 產品負責人：憲龍（johnny963214@gmail.com）
- 開發接手：Claude Code
