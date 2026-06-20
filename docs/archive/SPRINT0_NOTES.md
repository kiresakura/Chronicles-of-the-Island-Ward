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

## QUESTIONS.md Q1-Q8 已回覆（2026-05-16）

| Q | 決策 | 後續 Action |
|---|---|---|
| Q1 | ✅ 留 Godot 4.6.1 | CI 也鎖 4.4.1 / 4.6 都可 |
| Q2 | ✅ Sprint 2 才切直向 | Sprint 1 用 STR 原橫向驗證資料管線 |
| Q3 | 帳號 `kiresakura`，repo `Chronicles of the Island Ward` | 等憲龍給 token 後 push（注意：keyring 已有 kiresakura token） |
| Q4 | 移除素材調查引用 | ✅ 已從 CLAUDE.md / PRD.md / README.md 移除 |
| Q5 | ✅ 確認術語對應策略 | 程式碼用 STR 命名，UI 用 i18n 翻譯 |
| Q6 | ✅ TranslationServer + KeywordData 並用 | Sprint 1 試 KeywordData 戰鬥詞彙 |
| Q7 | ✅ 有 Apple Developer Account | Sprint 1 末試 iOS Simulator 打包 |
| Q8 | ✅ 採納先試 iOS Simulator | 進行中：背景下載 export templates |

## 進行中

- Godot 4.6.1 export templates 背景下載（~1GB）
- 完成後可設定 iOS Simulator export preset 並試打包

## 待真機環境

- iPhone 真機跑通 STR 預設範例（憲龍動作 — 在 Godot 編輯器中 deploy）
- Android 真機跑通 STR 預設範例
- iOS / Android export presets 完成設定（templates 下載完後可進）

## 下一步建議

1. 待憲龍給 kiresakura token → `gh auth switch kiresakura` → 建 private repo → push
2. 開始 Sprint 1（乩童主題替換 + 10 張卡）
3. iOS Simulator export 驗證（不需要憲龍指示，等 templates 下載完）
