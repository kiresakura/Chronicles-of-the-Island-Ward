# 鎮島錄 — 待決策問題清單

> 本檔案累積 Claude Code 在開發過程中需要憲龍決策的問題。
> 每週末 / 每 Sprint 結束彙整一次，不要逐題打斷。

---

## 2026-05-16 Sprint 0 起手問題清單

### Q1: Godot 版本選擇（4.4 vs 4.6.1）

**情境**：
- CLAUDE.md / PRD 指定 Godot 4.4 stable。
- 本機已安裝 4.6.1.stable.official，STR 也聲明需 4.4。
- 我已用 4.6.1 載入 STR 並 headless 跑 100 幀，無錯誤。

**選項 A**：留 4.6.1（已驗證可跑）
- 優：少裝一份 Godot，4.6 內含更多 mobile 渲染優化。
- 缺：未知後續是否會踩 4.4 → 4.6 不相容（特別是 GDScript 細節）。

**選項 B**：另裝 4.4 stable 並切回
- 優：完全符合 STR/PRD 指定版本。
- 缺：手動切版本、CI/CD 也要鎖 4.4。

**我的建議**：A。Godot 4 系列強調向後相容，4.6 已是穩定且能跑 STR；若日後 sprint 真的踩到問題再切回 4.4。把版本鎖在 CI 設定即可。

### Q2: 直向 mobile UI 切換時機（Sprint 0 vs Sprint 2）

**情境**：
- 鐵律 2 要求 mobile-first；但 STR 原生是 1200×700 橫向。
- Sprint 1 還要做主題替換（乩童 / 山豬精）；如果先切直向，STR 既有 UI 會立刻錯位，無法驗證資料替換是否正確。

**選項 A**：保留橫向直到 Sprint 2 才切換
- 優：Sprint 1 可在 STR 原生 UI 上驗證資料替換有效。
- 缺：違反 mobile-first 心智、Sprint 1 真機驗收會發現一堆 UI 問題。

**選項 B**：Sprint 0 馬上切直向
- 優：強迫早期面對 mobile UI 問題。
- 缺：STR 既有 UI 全錯位，Sprint 1 主題替換無從驗收，可能要連帶重寫 UI。

**我的建議**：A。先用橫向驗證資料管線通暢，Sprint 2 再做完整直向重設計。Sprint 1 真機測試用「橫向應急版」即可。

### Q3: GitHub Private Repo 建立

**情境**：
- CLAUDE.md 指示 fork STR → push 到 GitHub private repo。
- 本機 gh CLI 登入帳號為 `MusesCraft`（憲龍 johnny963214@gmail.com 對應的 GH 帳號？另一個帳號 `rush8787` 的 token 失效）。
- 目前已 rename `origin` → `upstream`（指向 STR 原 repo），尚未推送。

**問**：
1. 用哪個 GH 帳號？`MusesCraft` 還是另開？
2. Repo 名稱：`cotiw`、`COTIW`、或別的？
3. 是否現在就建立並推送？我需要明確的「請建立」指令才會動作。

### Q4: 素材調查文件位置

**情境**：CLAUDE.md / README.md 引用 `../鎮島錄 - 開源倉庫與台灣文化素材調查.md`，但 `/Users/crimson/Developer/` 與 COTIW 同層找不到。

**問**：檔案在哪？或是 Notion / Google Docs 連結？

### Q5: 卡牌/敵人術語對應 — STR vs PRD

**情境**：
- PRD 用「遺物」、「邪氣」、「神力」等台灣文化詞。
- STR 框架用 `artifact`、`status_effect`、`energy` 等英文 code-level 命名。

**決策（暫定，請確認）**：
- **程式碼層**：沿用 STR 命名（artifact, status_effect, energy, etc.）—— 不改框架。
- **資料層**：JSON 內 name/description 用 i18n key 引用。
- **UI 顯示**：用 i18n 翻譯為「遺物 / 邪氣 / 神力」。

**理由**：改框架 = 失去追 upstream 能力（違反鐵律 3）。

### Q6: i18n 機制 — STR Keyword 系統 vs Godot TranslationServer

**情境**：
- PRD 7.6 指定使用 Godot 內建 `TranslationServer` + CSV。
- STR 已有 `KeywordData` 系統處理戰鬥詞彙（例：邪氣、神威）。

**選項 A**：兩者並用 — TranslationServer 處理介面 UI、KeywordData 處理戰鬥詞彙。
**選項 B**：只用 TranslationServer，把 keyword 也走 i18n key。
**選項 C**：只用 STR 的 keyword system。

**我的建議**：A。Sprint 1 先試 KeywordData 處理戰鬥詞彙，Sprint 2 加 TranslationServer 處理 UI。Sprint 3 評估是否合併。

### Q7: 真機測試與 Apple Developer Account

**情境**：
- Sprint 0 驗收條件之一是 iPhone 真機跑 STR 原版。
- Apple Developer Account 每年 US$99；尚未確認憲龍是否已有。
- Android 真機免費，需 Android Studio + USB debug。

**問**：
1. 是否已有 Apple Developer Account？
2. 沒有的話，可先用 iOS Simulator + Android 真機（其中一個是真機就符合 PRD 鐵律「真機」精神）？

### Q8: macOS 開發環境 — Xcode 26.5 與 Godot iOS export

**情境**：本機已裝 Xcode 26.5（最新版）。Godot 4.6 iOS export 對 Xcode 26 的支援尚未廣泛驗證。

**我的建議**：先試打包 iOS Simulator 版（.zip）驗證 export pipeline 通；若失敗再評估降版 Xcode。Sprint 0 結束前產出第一份 iOS Simulator 可運行成品。

---

## 標記用法

每個問題請以下列三種之一回覆：
- ✅ **採納建議**：接受 Claude 提的方向。
- ❌ **不接受**：請註明替代方案。
- ⏸️ **暫緩**：先擱置，下個 Sprint 再決定。
