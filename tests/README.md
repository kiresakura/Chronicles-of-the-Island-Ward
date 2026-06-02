# 鎮島錄 測試說明

> **狀態**：可運行。零依賴 headless 測試框架，CI 已接。

## 規範（依 CLAUDE.md §7）

- **戰鬥核心邏輯**：單元測試 — `tests/unit/test_combat_math.gd`
- **資料載入**：每個 JSON schema 要有 validator — `tests/unit/test_data_validation.gd`
- **UI**：手動 + 真機測試（不在自動化範圍）
- **CI/CD**：每次 push 自動跑（`.github/workflows/ci.yml`）

## 為何不用 GUT

CLAUDE.md §7 點名 GUT，但 GUT 需另外 clone/啟用 addon，離線 CI 不穩。
本專案改用零依賴的自製 runner（`tests/test_case.gd` 提供 GUT 風格 assert_*），
日後若要導入 GUT，測試方法命名（`test_` 前綴）與 assert 介面可低成本平移。

## 目錄

```
tests/
├── test_case.gd          # 測試基底（assert_eq / assert_true / assert_has ...）
├── run_all.gd            # 執行器（掃 unit/ + integration/，回傳 exit code）
├── TestRunner.tscn       # 入口場景（必須以場景跑，autoload 才會載入）
├── unit/
│   ├── test_combat_math.gd       # 確定性 RNG、加權選擇、ArtifactFilter
│   └── test_data_validation.gd   # 角色/卡牌/遺物交叉引用、敵人 status、action 路徑
├── integration/          # （預留）整局 dry-run
└── README.md
```

## 跑測試

```bash
# 重要：必須以「場景」方式跑。--script 不會載入 autoload，
# Global / Random 等 singleton 會找不到。
godot --headless --import
godot --headless res://tests/TestRunner.tscn
echo $?   # 0 = 全過，1 = 有失敗
```

## 新增測試

1. 在 `tests/unit/` 新增 `test_xxx.gd`，第一行 `extends "res://tests/test_case.gd"`。
2. 方法名以 `test_` 開頭；用 `assert_*` 斷言（失敗會收集，不中斷）。
3. runner 自動發現，無需註冊。

## 涵蓋重點（截至 2026-05-26）

- P1 回歸：只有鎮島錄角色（乩童、鸞女）被註冊，STR 測試角色不再外漏。
- P2 回歸：run_modifier i18n patch（object_id 對齊 STR）已套用。
- 關鍵回歸：FileLoader 遞迴載入子資料夾（cards/tongji、cards/luannu 等）—— 防止整批內容漏載重演。
- B3 類：敵人攻擊狀態的 status 引用必須存在。
- Schema：所有 JSON 內 `res://*.gd` action 路徑必須是存在的資源。
