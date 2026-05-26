#!/usr/bin/env python3
"""v6 改進三件事：
1. 重生 mainmenu_temple bg（更豐富天空）→ mainmenu_temple_v6.png
2. 改寫 bust 去背：閾值降至 220 + auto-crop 角色 bbox（去掉空白）
3. 順便輸出去背預覽以驗證

用法：PIXELLAB_API_KEY=... python3 scripts/tools/pixellab_mainmenu_v6.py
"""

from __future__ import annotations

import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from io import BytesIO
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets" / "generated" / "pixellab"
API_ROOT = "https://api.pixellab.ai/v1"

key = os.environ.get("PIXELLAB_API_KEY", "").strip()
if not key:
    raise SystemExit("缺少 PIXELLAB_API_KEY")


def post(path, payload):
    data = json.dumps(payload).encode()
    for attempt in range(3):
        try:
            req = urllib.request.Request(
                f"{API_ROOT}{path}", data=data,
                headers={"Authorization": f"Bearer {key}",
                         "Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=600) as r:
                return json.loads(r.read().decode())
        except (TimeoutError, urllib.error.URLError) as e:
            print(f"  ↻ retry: {e}")
            time.sleep(5 * (attempt + 1))
    raise RuntimeError("max retries")


def b64dec(s):
    if "," in s:
        s = s.split(",", 1)[1]
    return base64.b64decode(s)


# ═════════════════════════════════════════════════════════════
# 1. 重生 mainmenu temple bg（更豐富天空）
# ═════════════════════════════════════════════════════════════

TEMPLE_BG_PROMPT = (
    "Wide-screen Taiwanese temple main menu background scene. The temple façade "
    "in the bottom 60% with red and gold ornate roofs, layered green glazed tiles, "
    "carved dragon ridges, hanging crimson lanterns lining the eaves, and tall red "
    "pillars. The TOP 40% is a dramatic dusk sky: deep blue zenith fading to "
    "burning orange and crimson at the horizon, scattered pink and violet "
    "cloud bands, a few distant swallows in silhouette. Lantern glow lights the "
    "courtyard, faint stars and a crescent moon high in the sky, gentle haze. "
    "Detailed atmospheric pixel art, painterly, no characters, no text. "
    "Composition designed for character mascot to stand in foreground."
)


def gen_temple_bg() -> None:
    out = OUT / "mainmenu_temple_v6.png"
    print(f"[1/2] {out.name}")
    if out.exists():
        print(f"   already exists, skip")
        return
    # PixFlux 上限：每邊 ≤ 400，area ≤ 160000
    # 寬螢幕 16:9 → 400×224 = 89600 ✓，upscale ×4 = 1600×896
    payload = {
        "description": TEMPLE_BG_PROMPT,
        "image_size": {"width": 400, "height": 224},
        "text_guidance_scale": 9.0,
        "no_background": False,
    }
    try:
        resp = post("/generate-image-pixflux", payload)
    except urllib.error.HTTPError as e:
        print(f"   ✗ HTTP {e.code}: {e.read().decode()[:300]}")
        return
    png = b64dec(resp["image"]["base64"])
    img = Image.open(BytesIO(png)).convert("RGBA")
    up = img.resize((img.width * 4, img.height * 4), Image.NEAREST)
    up.save(out, "PNG")
    print(f"   ✓ {out} ({up.size})")


# ═════════════════════════════════════════════════════════════
# 2. 改寫 bust 去背：閾值 220 + auto-crop bbox
# ═════════════════════════════════════════════════════════════

BUST_FILES = [
    "mascot_tongji_bust_v2.png",
    "mascot_luannu_bust_v2.png",
]

# 先從原檔生（萬一被 v1 PIL 處理過已破壞），再應用更嚴的閾值
# 但實際我們已有處理過的檔了；改用更低閾值 220 加處理 + auto-crop

WHITE_THRESHOLD = 220  # 降低（v1 是 240）


def clean_bust(path: Path) -> None:
    print(f"[2/2] {path.name}")
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    pixels = img.load()

    # 第一輪：白底→透明
    removed = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if r >= WHITE_THRESHOLD and g >= WHITE_THRESHOLD and b >= WHITE_THRESHOLD:
                pixels[x, y] = (r, g, b, 0)
                removed += 1
    print(f"   removed {removed}px (threshold {WHITE_THRESHOLD})")

    # 第二輪：找非透明像素 bbox（用 PIL 內建的 getbbox 較快）
    # 但 getbbox 需要 alpha-only 圖；複製出 alpha channel 找
    alpha = img.split()[3]
    bbox = alpha.getbbox()
    if bbox is None:
        print("   ✗ no opaque pixels — 全透明？")
        return
    left, top, right, bottom = bbox
    print(f"   bbox = ({left}, {top}, {right}, {bottom}) "
          f"→ char size = {right-left}×{bottom-top}")
    cropped = img.crop(bbox)
    cropped.save(path, "PNG")
    print(f"   ✓ saved cropped {cropped.size}")


# ═════════════════════════════════════════════════════════════
# 主流程
# ═════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("════════════════════════════════════")
    print("v6 main menu polish")
    print("════════════════════════════════════")
    gen_temple_bg()
    print()
    for f in BUST_FILES:
        p = OUT / f
        if p.exists():
            clean_bust(p)
        else:
            print(f"   ✗ {p} not found")
