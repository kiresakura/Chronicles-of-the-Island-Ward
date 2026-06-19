#!/usr/bin/env python3
# 鎮島錄 — 硬寫色稽核（設計忠實 P1）。
# 掃 scripts/**.gd、**.tscn、**.tres 的 Color(r,g,b[,a]) 與 #hex，
# 對每個值找最近的 design_tokens.json token，輸出「高頻硬寫色 → 最近 token」報告。
# 目的：指出哪些硬寫色該收編進 CotiwUiTheme.get_color()，並建立「不得淨增」基線。
# 用法：python3 tools/audit_color_sprawl.py
import json, re, os, sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOKENS_PATH = os.path.join(ROOT, "docs/design/design_tokens.json")
OUT_DIR = os.path.join(ROOT, "qa_artifacts")
OUT_PATH = os.path.join(OUT_DIR, "color_sprawl_report.txt")

def hex_to_rgb(h):
    h = h.lstrip("#")
    if len(h) in (8,): h = h[:6]
    if len(h) == 3: h = "".join(c*2 for c in h)
    if len(h) != 6: return None
    return tuple(int(h[i:i+2], 16)/255.0 for i in (0, 2, 4))

def load_tokens():
    cols = json.load(open(TOKENS_PATH))["colors"]
    out = {}
    for name, v in cols.items():
        if isinstance(v, str) and v.startswith("#"):
            rgb = hex_to_rgb(v)
            if rgb: out[name] = rgb
    return out

def nearest(rgb, tokens):
    best, bd = None, 9.9
    for name, t in tokens.items():
        d = sum((a-b)**2 for a, b in zip(rgb, t)) ** 0.5
        if d < bd: bd, best = d, name
    return best, bd

COLOR_RE = re.compile(r"Color\(\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)")
HEX_RE = re.compile(r"#[0-9a-fA-F]{6,8}")

def scan():
    tokens = load_tokens()
    counts = defaultdict(int)          # rounded rgb -> count
    where = defaultdict(set)           # rounded rgb -> files
    total = 0
    exts = (".gd", ".tscn", ".tres")
    for dp, _, fs in os.walk(ROOT):
        if "/.godot" in dp or "/qa_artifacts" in dp or "/art_archive" in dp:
            continue
        for f in fs:
            if not f.endswith(exts):
                continue
            p = os.path.join(dp, f)
            rel = os.path.relpath(p, ROOT)
            try:
                txt = open(p, encoding="utf-8", errors="replace").read()
            except Exception:
                continue
            for m in COLOR_RE.finditer(txt):
                try:
                    rgb = tuple(round(float(x), 3) for x in m.groups())
                except ValueError:
                    continue
                counts[rgb] += 1; where[rgb].add(rel); total += 1
            for m in HEX_RE.finditer(txt):
                rgb = hex_to_rgb(m.group(0))
                if rgb is None: continue
                rgb = tuple(round(x, 3) for x in rgb)
                counts[rgb] += 1; where[rgb].add(rel); total += 1
    lines = ["# 硬寫色稽核 — %d 個出現點、%d 個相異值" % (total, len(counts)), ""]
    lines.append("freq | rgb                        | 最近 token (距離)        | 檔數")
    lines.append("-" * 78)
    for rgb, c in sorted(counts.items(), key=lambda kv: -kv[1])[:60]:
        name, d = nearest(rgb, tokens)
        flag = "  ←已是token" if d < 0.02 else ("  ←收編" if c >= 4 else "")
        lines.append("%4d | %-26s | %-14s (%.3f) | %d%s" % (c, str(rgb), name, d, len(where[rgb]), flag))
    os.makedirs(OUT_DIR, exist_ok=True)
    open(OUT_PATH, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("total hardcoded color occurrences:", total)
    print("distinct values:", len(counts))
    print("report:", os.path.relpath(OUT_PATH, ROOT))
    # 前 12 高頻 → 收編候選
    print("\ntop high-freq (收編候選):")
    for rgb, c in sorted(counts.items(), key=lambda kv: -kv[1])[:12]:
        name, d = nearest(rgb, tokens)
        print("  %4d× %-24s → %s (%.3f)" % (c, str(rgb), name, d))
    return total

if __name__ == "__main__":
    scan()
