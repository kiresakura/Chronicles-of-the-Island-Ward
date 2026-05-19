# 鎮島錄 / Chronicles of the Island Ward (COTIW)

> 一款台灣民俗主題的肉鴿卡牌戰鬥手機遊戲
> Godot 4 · iOS + Android · F2P + IAP

---

## 專案文件導覽

| 檔案 | 用途 | 給誰看 |
|---|---|---|
| [PRD.md](./PRD.md) | 完整產品需求文件（13 章節） | 全部人 |
| [CLAUDE.md](./CLAUDE.md) | Claude Code 接手指南 | Claude Code、其他工程師 |
| [QUESTIONS.md](./QUESTIONS.md) | 開發過程累積問題 | Claude Code → 憲龍 |
| [docs/UPSTREAM_README.md](./docs/UPSTREAM_README.md) | Slay The Robot 上游 README | 框架開發者 |

---

## 30 秒理解這個專案

**做什麼**：類《殺戮尖塔》的肉鴿卡牌遊戲，但題材是台灣民俗——乩童、道士、八家將對抗妖怪邪神。

**為什麼**：肉鴿卡牌類型市場成熟，但台灣文化題材是個被忽略的縫隙。中文圈玩家對廟會、家將、妖怪意象有強烈共鳴。

**技術選擇**：Godot 4 + fork [Slay The Robot](https://github.com/DesirePathGames/Slay-The-Robot)（MIT）作為核心戰鬥框架。

**目標**：13 個月內上架 App Store + Google Play。

**變現**：F2P + IAP（角色解鎖、皮膚、Battle Pass），**不放廣告**。

---

## 開發狀態

> 最後更新：2026-05-18

- [x] 產品定位確認
- [x] 技術選型確認（Godot 4 + Slay The Robot fork）
- [x] PRD v0.1 完成
- [x] Claude Code 接手指南完成
- [x] **Sprint 0：環境設置** ✅
  - [x] Fork Slay The Robot 至本機
  - [x] Godot 4.6.1 可載入並 headless 跑通
  - [x] 建立 COTIW 內容資料夾骨架（cards/tongji 等）
  - [x] QUESTIONS.md / i18n CSV 骨架
  - [x] GitHub repo（已推送 origin/main）
  - [x] export presets（Android pipeline 通過）
  - [~] 真機：Android 跑通；iOS Simulator 受限於 Apple Silicon（見 docs/IOS_EXPORT_SETUP.md）
- [x] **Sprint 1：主題改造** ✅（乩童 + 10 張卡 + 第一章敵人 + 百年虎爺）
- [~] **Sprint 2：橫向 mobile UI**（進行中；2026-05-19 定案橫向）
  - [x] 主選單 V1→V5 重構（V4 起切橫向 R1999 lobby 風）、廟會夜市美術
  - [x] 戰鬥 HUD / 卡牌 / 血條 / 地圖節點視覺升級、載入畫面
  - [x] UI 字串繁中化（Sprint 2 後段轉 tr() 機制）
  - [ ] 觸控手勢（上滑出牌 / 拖曳 / 長按）、音效
- [ ] Sprint 3：第一章完整流程
- [ ] Phase 1 驗收（乩童完整跑通一局，真機）

### 2026-05-18 修復批次（見 docs/AUDIT_2026-05-18.md）

- 🔴 修復 FileLoader 不遞迴 → 鎮島錄子資料夾內容（卡牌/遺物/敵人/事件）原本整批漏載
- 🟠 修復角色選單預設選到 STR character_red（改為乩童唯一且預設）
- 🟡 修復 run_modifier 自訂項英文（object_id 對齊 STR）
- 🟢 建立零依賴 headless 測試框架（14 項全綠）+ CI 串接

---

## 跑測試

```bash
godot --headless --import
godot --headless res://tests/TestRunner.tscn   # exit 0 = 全過
```

詳見 [tests/README.md](./tests/README.md)。

## 下一步

接手指南見 [CLAUDE.md](./CLAUDE.md)。當前在 Sprint 2（橫向 UI / 觸控 / 音效），
並待真機跑通乩童完整一局以達 Phase 1 驗收。

---

## 聯絡

- 產品負責人：憲龍 (johnny963214@gmail.com)
- 開發接手：Claude Code
