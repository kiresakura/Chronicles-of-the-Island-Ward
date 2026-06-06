#!/usr/bin/env python3
"""把 Recraft vector_illustration SVG 的滿版背景 path 剝掉 → 透明底。

Recraft 產的 SVG 第一個（有時數個）path 是覆蓋整個 viewBox 的純色背景矩形，
其 d 由 "M 0 0" 起手。本工具移除所有以 "M 0 0" 起手的 <path>，其餘圖形保留。

用法：python3 scripts/tools/svg_strip_bg.py <a.svg> [<b.svg> ...]
就地覆寫（呼叫端自行決定是否先備份）。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# 比對「整行就是一個以 M 0 0 起手的 path」
_BG_PATH = re.compile(r'^\s*<path\b[^>]*\bd="M\s*0\s+0[ ,]')


def strip_bg(svg_text: str) -> tuple[str, int]:
    out: list[str] = []
    removed = 0
    for line in svg_text.splitlines(keepends=True):
        if _BG_PATH.match(line):
            removed += 1
            continue
        out.append(line)
    return "".join(out), removed


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit("用法：svg_strip_bg.py <a.svg> [<b.svg> ...]")
    for arg in sys.argv[1:]:
        p = Path(arg)
        if not p.exists():
            print(f"!! 缺 {p}")
            continue
        text = p.read_text(encoding="utf-8")
        new_text, removed = strip_bg(text)
        if removed == 0:
            print(f"= {p.name}：未找到 M 0 0 背景 path（未變動）")
            continue
        p.write_text(new_text, encoding="utf-8")
        print(f"✓ {p.name}：移除 {removed} 個背景 path → 透明底")


if __name__ == "__main__":
    main()
