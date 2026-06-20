#!/usr/bin/env python3
"""art_lint.py — 美術強制鏈 / QA 守門員（像素版 SSOT）

把「像素必須服從單一真相」從口號變成可被 CI 擋下的檢查，呼應 audit_color_sprawl.py
對硬寫色做的事。掃 assets/ 下所有 raster，依路徑判定「期望類型」，套用規則，
吐出分級報告 + 機器可讀 JSON。任一 🔴 致命項存在 → exit 1（可接 pre_release_check）。

偵測的罪狀（對應美術審判八宗罪）：
  NO_CUTOUT   實心背景沒去乾淨（四角不透明 + 透明像素比例過低）        → 罪 6
  HALO        去背毛邊/光暈（半透明像素比例異常高，像素圖應趨近 0）     → 罪 1
  NOT_PIXEL   不是像素圖（唯一色數爆量 + 軟邊）— 平滑動漫混進像素世界    → 罪 3
  OFF_GRID    尺寸不在像素階梯上（非 32 倍數 / 怪尺寸如 759×996）        → 罪 4
  FAKE_ANIM   動畫條每幀完全相同（零動作）                              → 罪 2
  CHOPPY_ANIM 動畫條幀數過少（< 6）或幀間跳動過大（不連戲）              → 罪 2

用法：
  python3 tools/art_lint.py                 # 掃 assets/，印報告
  python3 tools/art_lint.py --json out.json  # 另存 JSON
  python3 tools/art_lint.py --root assets/generated/cards_v3   # 只掃子目錄
"""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
GRID = 32          # 像素階梯基準：邊長須為 32 的倍數
PIXEL_MAX_COLORS = 256   # 真像素圖唯一色上限（超過 → 疑似平滑渲染）
HALO_MAX_PARTIAL = 0.02  # 像素圖半透明像素比例上限（2%）
ANIM_MIN_FRAMES = 4      # 動畫條最少幀數（PixelLab animate 連戲上限＝4，對齊 ANIM_FRAME_COUNT）

# 期望「該去背成透明」的類型（依路徑關鍵字）。場景背景不在此列（本就滿版）。
CUTOUT_HINTS = ("enemies", "cards", "character", "portrait", "deities", "deity",
                "jiajiang", "artifacts", "icons", "icon", "status", "frames",
                "badges", "stamps", "map_nodes")
BG_HINTS = ("scenes", "scene", "background", "_bg", "mainmenu", "temple_buildings")
ANIM_HINTS = ("pixellab/anim", "combat_sheet", "_sheet")

SKIP_DIRS = ("_pack_downloads", "art_archive", "/qa/", "qa_artifacts")


def classify(p: Path) -> str:
    s = str(p).replace("\\", "/").lower()
    if any(h in s for h in ANIM_HINTS):
        return "anim"
    if any(h in s for h in BG_HINTS):
        return "bg"
    if any(h in s for h in CUTOUT_HINTS):
        return "cutout"
    return "other"


def load_rgba(p: Path):
    im = Image.open(p).convert("RGBA")
    return np.asarray(im), im.size


def analyse(p: Path) -> dict:
    flags: list[str] = []
    try:
        arr, (w, h) = load_rgba(p)
    except Exception as e:  # noqa
        return {"path": str(p.relative_to(ROOT)), "flags": ["UNREADABLE"], "err": str(e)}
    a = arr[..., 3].astype(np.float32)
    rgb = arr[..., :3]
    n = a.size
    opaque = float((a >= 250).sum()) / n
    transparent = float((a <= 5).sum()) / n
    partial = float(((a > 5) & (a < 250)).sum()) / n
    corners = [a[0, 0], a[0, -1], a[-1, 0], a[-1, -1]]
    corners_opaque = all(c >= 250 for c in corners)
    # 唯一色（只算可見像素，量化到 4-bit 抑制壓縮雜訊不影響量級判斷）
    vis = rgb[a > 16]
    if len(vis):
        q = (vis.astype(np.uint16) >> 2)
        uniq = len(np.unique(q[:, 0].astype(np.uint32) * 65536 +
                             q[:, 1] * 256 + q[:, 2]))
    else:
        uniq = 0
    kind = classify(p)

    # --- 尺寸階梯 ---
    if (w % GRID) or (h % GRID):
        flags.append("OFF_GRID")

    # --- 去背 / 媒材 ---
    if kind == "cutout":
        if corners_opaque and transparent < 0.06:
            flags.append("NO_CUTOUT")
        if partial > HALO_MAX_PARTIAL and uniq <= PIXEL_MAX_COLORS:
            flags.append("HALO")
        if uniq > PIXEL_MAX_COLORS and partial > 0.05:
            flags.append("NOT_PIXEL")

    # --- 動畫條 ---
    if kind == "anim" and w >= h * 2:
        # FX 爆破（firework/burst/fx）天生少幀且幀間爆跳，不套角色動畫的連戲/幀數標準
        is_fx = any(k in str(p).replace("\\", "/").lower()
                    for k in ("firework", "burst", "/fx", "_fx"))
        nf = max(1, round(w / h))
        fw = w // nf
        frames = [arr[:, i * fw:(i + 1) * fw, :] for i in range(nf)]
        if len(frames) > 1:
            diffs = [float(np.abs(frames[i].astype(np.int16) -
                                  frames[i + 1].astype(np.int16)).mean())
                     for i in range(len(frames) - 1)]
            if max(diffs) < 0.5:
                flags.append("FAKE_ANIM")          # 每幀相同（FX 也不該）
            elif max(diffs) > 40 and not is_fx:
                flags.append("CHOPPY_ANIM")        # 幀間爆跳 → 不連戲
        if nf < ANIM_MIN_FRAMES and not is_fx:
            flags.append("CHOPPY_ANIM")
        # 動畫條也檢去背光暈
        if partial > HALO_MAX_PARTIAL:
            flags.append("HALO")

    return {"path": str(p.relative_to(ROOT)), "kind": kind, "w": w, "h": h,
            "uniq": uniq, "partial": round(partial, 4),
            "transparent": round(transparent, 3), "flags": sorted(set(flags))}


SEV = {"FAKE_ANIM": "🔴", "CHOPPY_ANIM": "🔴", "HALO": "🔴", "NO_CUTOUT": "🟠",
       "NOT_PIXEL": "🟠", "OFF_GRID": "🟡", "UNREADABLE": "🔴"}
FATAL = {"FAKE_ANIM", "CHOPPY_ANIM", "HALO", "UNREADABLE"}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default="assets")
    ap.add_argument("--json", default="")
    args = ap.parse_args()
    root = (ROOT / args.root)
    files = [p for p in root.rglob("*")
             if p.suffix.lower() in (".png", ".webp")
             and not any(s in str(p).replace("\\", "/").lower() for s in SKIP_DIRS)]
    results = [analyse(p) for p in sorted(files)]

    by_flag: dict[str, list[str]] = {}
    for r in results:
        for f in r["flags"]:
            by_flag.setdefault(f, []).append(r["path"])

    print(f"\n=== art_lint：掃描 {len(results)} 個 raster（root={args.root}）===\n")
    if not by_flag:
        print("✅ 零旗標。乾淨。")
    for flag in sorted(by_flag, key=lambda f: (SEV.get(f, "🟡"), -len(by_flag[f]))):
        hits = by_flag[flag]
        print(f"{SEV.get(flag,'🟡')} {flag:<12} × {len(hits):>3}")
        for h in hits[:6]:
            print(f"      {h}")
        if len(hits) > 6:
            print(f"      … 還有 {len(hits)-6} 個")
    fatal_n = sum(1 for r in results if FATAL & set(r["flags"]))
    print(f"\n--- 總計：{sum(len(v) for v in by_flag.values())} 旗標 / "
          f"{sum(1 for r in results if r['flags'])} 張有問題 / {len(results)} 張 ---")
    print(f"--- 🔴 致命張數：{fatal_n} ---")
    if args.json:
        Path(args.json).write_text(json.dumps(results, ensure_ascii=False, indent=2))
        print(f"--- JSON → {args.json} ---")
    return 1 if fatal_n else 0


if __name__ == "__main__":
    sys.exit(main())
