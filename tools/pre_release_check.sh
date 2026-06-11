#!/usr/bin/env bash
# 鎮島錄 — pre-release 守門腳本（DELEGATION.md Q0）
#
# 四關：headless 測試 → log 乾淨契約 → 三解析度 UI/UX audit → E2E。
# 任一關失敗 → exit 非 0（CI 紅）。log 存 /tmp/cotiw_prerelease/。
#
# log 乾淨契約：除「已知良性退場簽名」外，任何 WARNING/ERROR 都紅。
# 已知良性 = run-combat 物件圖循環引用的退場報告（根治需 STR 核心 weakref 重構，
# 見 QUESTIONS.md Q0 條目）：
#   WARNING: ObjectDB instances leaked at exit
#   ERROR: N resources still in use at exit
#
# 用法：
#   tools/pre_release_check.sh
#   GODOT=/path/to/godot tools/pre_release_check.sh
set -u
GODOT="${GODOT:-/opt/homebrew/bin/godot}"
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
OUT="/tmp/cotiw_prerelease"
mkdir -p "$OUT"
FAILED=0

note() { printf '\n\033[1m%s\033[0m\n' "$*"; }

BENIGN_RE='ObjectDB instances leaked at exit|resources still in use at exit'

check_log_clean() {
  local log="$1" label="$2"
  local noise
  noise=$(grep -aE 'WARNING:|ERROR:' "$log" | grep -avE "$BENIGN_RE" | wc -l | tr -d ' ')
  if [ "$noise" -gt 0 ]; then
    echo "✗ $label：非白名單 WARNING/ERROR ×$noise"
    grep -aE 'WARNING:|ERROR:' "$log" | grep -avE "$BENIGN_RE" | head -5
    FAILED=1
  else
    echo "✓ $label：log 乾淨（僅已知良性退場簽名）"
  fi
}

note "[1/4] Headless 測試套件"
if timeout 420 "$GODOT" --headless --path "$PROJ" res://tests/TestRunner.tscn > "$OUT/tests.log" 2>&1; then
  grep -a "結果" "$OUT/tests.log" || true
else
  echo "✗ 測試套件失敗（exit≠0）"; FAILED=1
fi
check_log_clean "$OUT/tests.log" "tests"

note "[2/4] 三解析度 UI/UX audit（FAIL → 紅）"
for RES in 1244x700 1515x700 1200x900; do
  if UIUX_RES=$RES timeout 420 "$GODOT" --path "$PROJ" res://qa/uiux/uiux_audit_driver.tscn > "$OUT/audit_$RES.log" 2>&1; then
    grep -a "=====" "$OUT/audit_$RES.log" | tail -1
  else
    echo "✗ audit $RES 失敗（exit≠0）"
    grep -a '\[UIUX\]\[FAIL\]' "$OUT/audit_$RES.log" | head -5
    FAILED=1
  fi
  check_log_clean "$OUT/audit_$RES.log" "audit_$RES"
done

note "[3/4] E2E 全流程"
if timeout 420 "$GODOT" --path "$PROJ" res://qa/uiux/e2e_driver.tscn > "$OUT/e2e.log" 2>&1; then
  grep -a "=====" "$OUT/e2e.log" | tail -1
else
  echo "✗ E2E 失敗（exit≠0）"
  grep -a '\[E2E\]\[FAIL\]' "$OUT/e2e.log" | head -3
  FAILED=1
fi
check_log_clean "$OUT/e2e.log" "e2e"

note "[4/4] 結果"
if [ "$FAILED" -eq 0 ]; then
  echo "✅ pre-release 全綠（log: $OUT/）"
else
  echo "❌ pre-release 未過（log: $OUT/）"
fi
exit $FAILED
