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

- [x] 產品定位確認
- [x] 技術選型確認（Godot 4 + Slay The Robot fork）
- [x] PRD v0.1 完成
- [x] Claude Code 接手指南完成
- [x] Sprint 0：環境設置（進行中）
  - [x] Fork Slay The Robot 至本機
  - [x] Godot 4.6.1 可載入並 headless 跑通
  - [x] 建立 COTIW 內容資料夾骨架（cards/tongji 等）
  - [x] QUESTIONS.md / i18n CSV 骨架
  - [ ] GitHub private repo（待憲龍指示）
  - [ ] iOS / Android 真機跑通（待真機環境）
  - [ ] export presets（待真機環境）
- [ ] Sprint 1：主題改造（乩童 + 10 張卡）
- [ ] Sprint 2：直向 mobile UI
- [ ] Sprint 3：第一章完整流程
- [ ] Phase 1 驗收

---

## 下一步

請開啟 [CLAUDE.md](./CLAUDE.md)，從 Sprint 0 開始。

---

## 聯絡

- 產品負責人：憲龍 (johnny963214@gmail.com)
- 開發接手：Claude Code
