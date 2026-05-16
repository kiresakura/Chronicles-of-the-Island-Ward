# Sprint 0 進度筆記

> **日期**：2026-05-16 起手
> **狀態**：本機環境就緒，待真機與 GitHub 設定

## 已完成

### 環境驗證
- Godot 4.6.1.stable.official 已安裝（本機）
- Xcode 26.5 已安裝（iOS export 預備）
- git 2.50.1, gh 2.83.1 已設定，登入 `MusesCraft` 帳號

### 專案結構
- Fork `DesirePathGames/Slay-The-Robot` 至 `COTIW/`
- 將 STR 原 git 歷史扁平化至專案根（保留 commit 史）
- `origin` rename 為 `upstream`，指向 STR upstream
- STR 原 README → `docs/UPSTREAM_README.md`
- 加入 COTIW 文件：CLAUDE.md, PRD.md, README.md, QUESTIONS.md

### COTIW 內容骨架（`external/data/`）
- `cards/{tongji,daoshi,family_general}/`
- `enemies/{act1_mountain,act2_water,act3_evil}/`
- `artifacts/{tongji,daoshi,family_general,common}/`
- `events/{act1_mountain,act2_water,act3_evil}/`
- `characters/`, `localization/`

### i18n
- `external/data/localization/zh_TW.csv` 骨架（含 ui/keyword/currency/battle/map keys）
- 支援語系：zh_TW, zh_CN, en, ja

### 引擎驗證
- `godot --headless --import` 通過
- `godot --headless --quit-after 100` 通過（無 GDScript parse 錯誤）

### CI/CD 起手
- `.github/workflows/ci.yml`：godot-ci docker image 跑 import 驗證
- iOS / Android build pipeline 註解（等 secrets 與真機環境）

### 專案 metadata
- `project.godot` config/name → `鎮島錄`
- 加入 `config/name_localized` (en/ja/zh_CN/zh_TW)
- 加入 `config/description`

## 待憲龍決策（見 QUESTIONS.md）

- Q1: Godot 4.4 vs 4.6.1 版本鎖定
- Q2: 直向 UI 切換時機
- Q3: GitHub private repo 建立指示
- Q4: 素材調查文件位置
- Q5: STR vs PRD 術語對應（已暫定）
- Q6: i18n 機制（已暫定）
- Q7: Apple Developer Account 狀態
- Q8: Xcode 26.5 iOS export 風險

## 待真機環境

- iPhone 真機跑通 STR 預設範例
- Android 真機跑通 STR 預設範例
- iOS / Android export presets 完成設定

## 下一步

收到 Q3 指示後 → 建 GH private repo → push → 開始 Sprint 1（乩童主題替換）。
