# 鎮島錄 測試說明

> **狀態**：Sprint 0 — 結構建立中，尚未實際寫測試。

## 規範

依 CLAUDE.md：
- **戰鬥核心邏輯**：強制單元測試（使用 [GUT framework](https://github.com/bitwes/Gut)）
- **資料載入**：每個 JSON schema 要有 validator
- **UI**：手動 + 真機測試
- **CI/CD**：每次 push 自動跑單元測試

## 目錄

```
tests/
├── unit/          # GUT 單元測試（戰鬥邏輯、傷害計算、status_effect 等）
├── integration/   # 跨系統整合測試（一場完整戰鬥 dry-run）
└── README.md
```

## Sprint 引入時程

| Sprint | 計畫加入 |
|---|---|
| Sprint 0 | 目錄結構（本檔案） |
| Sprint 1 | 安裝 GUT addon、寫第一個測試（卡牌 JSON schema 驗證） |
| Sprint 2 | 戰鬥傷害計算、status_effect 單元測試 |
| Sprint 3 | 整局 dry-run 整合測試 |

## 跑測試

```bash
# 待 Sprint 1 加入 GUT 後可用：
# godot --headless --script res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit
```
