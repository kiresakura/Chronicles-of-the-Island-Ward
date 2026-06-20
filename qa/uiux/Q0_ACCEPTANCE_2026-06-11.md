# Q0 驗收包 — 把 QA 工具變成可信守門員
**日期**：2026-06-11 ｜ **關卡出處**：DELEGATION.md §5 Q0 ／ UIUX_QA_E2E_REVIEW_2026-06-11.md 第 1、2 優先

## 1. 驗收問題回答

> **「連跑三次三解析度 audit，log 是否零警告、零假失敗？FAIL 時 CI 是否真的紅？」**

| 驗收項 | 結果 | 證據 |
|---|---|---|
| 連跑 3 輪全套守門（測試+三解析度+E2E） | **3/3 全綠，exit 0** | `/tmp/q0_final{1,2,3}.out` |
| log 零非白名單警告 | **✓**（tests / audit×3 / e2e 五份 log 全過契約掃描） | `/tmp/cotiw_prerelease/*.log` |
| 零假失敗（啟動競態） | **✓** ready 輪詢取代固定 70 幀；3 輪 ×5 關卡無一 flake | 同上 |
| FAIL 時 CI 真的紅 | **✓** `UIUX_SELFTEST_FAIL=1` 注入合成失敗 → `exit=1` 實測 | `/tmp/q0_selftest.log` |

## 2. 交付清單

### 2.1 守門員可信化
- **`uiux_audit_driver.gd`**：`_wait_main_menu_ready()`（MainMenu visible + 可互動鈕 ≥10 輪詢，900 幀上限）取代固定 `_frames(70)`；`_fail > 0 → quit(1)`；`UIUX_SELFTEST_FAIL` 自測旋鈕（CI 可隨時驗證紅燈路徑）；退場前釋放 Root。
- **`e2e_driver.gd`**：同款 ready 輪詢；手牌輪詢 240→900 幀 + 先等 action pipeline 靜止（曾 1/3 機率 flake，修後連續 5 輪綠）；退場釋放 Root。
- **`tools/pre_release_check.sh`**（新）：四關（headless 測試 → log 乾淨契約 → 三解析度 audit → E2E），任一關敗 → exit 非 0。**log 乾淨契約**：除已知良性退場簽名外，任何 WARNING/ERROR 一律紅。

### 2.2 警告清零
- **export warning**：`artifact_white` 入 `CardArtRegistry.ARTIFACTS` preload + 三處 data 路徑改 bundled 相對路徑 + `resolve_artifact_texture()` 補「檔名 stem 反查 preload」一層（object_id miss 不再落到 raw 載圖）。
- **anchor warning ×12+2**：CharacterPanel / MascotSelector 由 FULL_RECT 非等錨改 TOP_LEFT 等錨＋手動幾何；e2e 預覽板移除 FULL_RECT 後直設 size。
- 守門契約掃描在驗收期間**抓到兩條真 bug**（`res://res://` 雙前綴載圖失敗、e2e 板 anchor warning）— 守門員第一天上班就有產出。

### 2.3 exit leak 處置（誠實申報）
- 系統性定位：洩漏=跑局期物件圖 RefCounted 循環引用（minimal boot 0、start_run-only 0、僅完整戰鬥流程出現；清四層快取簽名不動）。
- 根治需 STR 核心 weakref 重構（觸鐵律 3、估 1–2 天）→ **超出 Q0 範圍，砍範圍保品質**：白名單契約精確放行兩行已知簽名，其他全紅；嘗試過的安慰劑式「清快取 API」已撤除不留死碼。
- 決策請示：`QUESTIONS.md` Q0-A（建議：現狀 B + Q4 效能 pass 排根治）。

## 3. §4 基準自評（Q0 為工具關卡，僅 Q-8 適用）

| 基準 | 分數 | 證據 |
|---|---|---|
| Q-8 技術品質（CI log 乾淨、audit 常綠、守門可紅） | **5** | 三連跑全綠 + selftest exit 1 + 契約抓到 2 真 bug |
| Q-1～Q-7 | N/A | 畫面/演出/聽覺類基準不適用工具關卡，Q1 起逐條納入 |

錄影：N/A（工具關卡無畫面變更；log 與 exit code 即證據）。

## 4. 重跑方式
```bash
tools/pre_release_check.sh                 # 全套守門（exit 0 = 放行）
UIUX_SELFTEST_FAIL=1 UIUX_RES=1244x700 \
  godot --path . res://qa/uiux/uiux_audit_driver.tscn; echo $?   # 紅燈路徑自測（預期 1）
```

## 5. 等待放行
Q0 完成，依 §5 規則**停在關卡口**。Q1（戰鬥畫面：降噪 + 三大演出）開工前問題將另行提出。
