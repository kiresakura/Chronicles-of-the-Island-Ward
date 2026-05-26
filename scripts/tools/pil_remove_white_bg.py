#!/usr/bin/env python3
"""把 mascot bust v2 的白底 / 近白底像素轉成透明。

PixelLab no_background=true 不是真正透明，會給接近 #FFFFFF 的白底。
用 PIL 把 RGB >= threshold 的像素設為 alpha=0。

用法：python3 scripts/tools/pil_remove_white_bg.py
"""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
DIR = ROOT / "assets" / "generated" / "pixellab"

# 想處理的檔案
FILES = [
    "mascot_tongji_bust_v2.png",
    "mascot_luannu_bust_v2.png",
]

# RGB 亮度閾值（>= 此值的像素視為背景）
WHITE_THRESHOLD = 240


def remove_white_bg(path: Path) -> None:
    img = Image.open(path).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    removed = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r >= WHITE_THRESHOLD and g >= WHITE_THRESHOLD and b >= WHITE_THRESHOLD:
                pixels[x, y] = (r, g, b, 0)
                removed += 1
    img.save(path, "PNG")
    pct = removed * 100.0 / (w * h)
    print(f"  ✓ {path.name}: removed {removed} px ({pct:.1f}% of {w}×{h})")


for f in FILES:
    p = DIR / f
    if p.exists():
        print(f"processing {f}…")
        remove_white_bg(p)
    else:
        print(f"  ✗ {p} not found")
