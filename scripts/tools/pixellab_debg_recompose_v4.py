#!/usr/bin/env python3
"""把 characters_v4 的 *_raw.png 做乾淨去背 + 重新合成直幅（不呼叫 API）。

去背策略：邊界 flood-fill region-growing。
- 只從「低飽和（灰/淡紫）」的邊界像素當種子 → 火焰（高飽和橘黃）不會被當背景吃掉。
- 以鄰格色差容忍度成長 → 處理灰→淡紫的漸層背景與地面陰影橢圓。
- 角色深色描邊（與灰底色差大）自然擋住 flood，不會滲入角色。

用法：python3 scripts/tools/pixellab_debg_recompose_v4.py tongji
"""

from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
STAGING = ROOT / "assets" / "generated" / "pixellab" / "characters_v4"

CANVAS_W, CANVAS_H = 896, 1200
TARGET_CHAR_H = 1040
FOOT_BASELINE_Y = 1150

SAT_BG_MAX = 46        # 種子：max-min 通道差 < 此值 視為低飽和背景
GROW_TOL = 30          # region-grow 鄰格色差容忍
BRIGHT_MIN = 95        # 背景亮度下限（避免把深色描邊當種子）


def _sat(p) -> int:
    return max(p[0], p[1], p[2]) - min(p[0], p[1], p[2])


def remove_bg_floodfill(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    visited = bytearray(w * h)
    q: deque = deque()

    def is_bg_seed(p) -> bool:
        return _sat(p) <= SAT_BG_MAX and p[3] > 0 and max(p[0], p[1], p[2]) >= BRIGHT_MIN

    # 種子：四邊低飽和像素
    for x in range(w):
        for y in (0, h - 1):
            if is_bg_seed(px[x, y]):
                q.append((x, y)); visited[y * w + x] = 1
    for y in range(h):
        for x in (0, w - 1):
            if is_bg_seed(px[x, y]):
                q.append((x, y)); visited[y * w + x] = 1

    while q:
        x, y = q.popleft()
        cr, cg, cb, _ = px[x, y]
        px[x, y] = (cr, cg, cb, 0)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny * w + nx]:
                np_ = px[nx, ny]
                if np_[3] == 0:
                    visited[ny * w + nx] = 1
                    continue
                # 低飽和 + 與當前背景色相近 → 視為背景續成長
                if _sat(np_) <= SAT_BG_MAX + 14 and abs(np_[0] - cr) + abs(np_[1] - cg) + abs(np_[2] - cb) <= GROW_TOL * 3:
                    visited[ny * w + nx] = 1
                    q.append((nx, ny))
    return img


def autocrop(img: Image.Image) -> Image.Image:
    bbox = img.convert("RGBA").getbbox()
    return img.crop(bbox) if bbox else img


def compose_portrait(cut: Image.Image) -> Image.Image:
    cut = autocrop(cut)
    scale = TARGET_CHAR_H / cut.height
    cut = cut.resize((max(1, round(cut.width * scale)), TARGET_CHAR_H), Image.NEAREST)
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    x = (CANVAS_W - cut.width) // 2
    canvas.alpha_composite(cut, (x, max(0, FOOT_BASELINE_Y - cut.height)))
    return canvas


def main() -> None:
    keys = sys.argv[1:] or ["tongji"]
    for key in keys:
        raw = STAGING / f"{key}_raw.png"
        if not raw.exists():
            print(f"!! 缺 {raw}")
            continue
        cut = autocrop(remove_bg_floodfill(Image.open(raw)))
        cut.save(STAGING / f"{key}_cut.png", "PNG")
        compose_portrait(cut).save(STAGING / f"{key}.png", "PNG")
        print(f"✓ {key} → cut + portrait（去背 flood-fill）")


if __name__ == "__main__":
    main()
