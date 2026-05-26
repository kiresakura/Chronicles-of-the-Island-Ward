#!/usr/bin/env python3
"""生 v2 看板娘素材：高解析半身像 + 天空背景。

- Tongji 半身：256×384 PixFlux + no_background
- Luannu 半身：256×384 PixFlux + no_background
- 天空背景：400×280 PixFlux（黃昏雲彩，給左側看板娘 layer）

Upscale ×4 → 角色 1024×1536，天空 1600×1120，給 Godot 用。
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
OUT_DIR = ROOT / "assets" / "generated" / "pixellab"
API_ROOT = "https://api.pixellab.ai/v1"
UPSCALE = 4

key = os.environ.get("PIXELLAB_API_KEY", "").strip()
if not key:
    raise SystemExit("缺少 PIXELLAB_API_KEY")


def post(payload):
    data = json.dumps(payload).encode()
    for attempt in range(3):
        try:
            req = urllib.request.Request(
                f"{API_ROOT}/generate-image-pixflux",
                data=data,
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


def gen_and_save(name: str, prompt: str, w: int, h: int, no_bg: bool):
    out = OUT_DIR / name
    if out.exists():
        print(f"  {name} → exists, skip")
        return
    print(f"  generating {name} ({w}×{h})…")
    payload = {
        "description": prompt,
        "image_size": {"width": w, "height": h},
        "text_guidance_scale": 9.0,
        "no_background": no_bg,
    }
    try:
        resp = post(payload)
    except urllib.error.HTTPError as e:
        print(f"  ✗ HTTP {e.code}: {e.read().decode()[:300]}")
        return
    png = b64dec(resp["image"]["base64"])
    img = Image.open(BytesIO(png)).convert("RGBA")
    up = img.resize((img.width * UPSCALE, img.height * UPSCALE), Image.NEAREST)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    up.save(out, "PNG")
    print(f"  ✓ {out} ({up.size})")


# ── 256×384 半身像（W×H = 98304 < 160000 ✓）─────────────────────────

TONGJI_PROMPT = (
    "Half body bust pixel art game sprite of '乩童 Tongji' — young Taiwanese male "
    "spirit medium with red headband and bare muscular chest. Centered, "
    "head and upper torso visible (chest up). Intense determined expression, "
    "ceremonial red silk headband with knot trailing, holding a shark-tooth "
    "ceremonial sword at chest. Red folk-religion tattoos on shoulders and chest. "
    "Transparent background, no text, high detail pixel art, "
    "facing slightly to viewer's right."
)

LUANNU_PROMPT = (
    "Half body bust pixel art game sprite of '鸞女 Luannu' — young Taiwanese "
    "phoenix maiden spirit medium. Centered, head and upper torso visible (chest up). "
    "Elaborate gold phoenix headdress with crimson silk tassels, long flowing black hair, "
    "embroidered crimson and gold robe with phoenix patterns, jade-green sash, "
    "holding a long spirit-brush with red tassel at chest. Serene confident expression. "
    "Transparent background, no text, high detail pixel art, "
    "facing slightly to viewer's right."
)

SKY_PROMPT = (
    "Detailed pixel art scenic sky background. Dusk Taiwanese mountain sunset with "
    "warm orange and purple cloud bands across the sky, distant mountain silhouettes "
    "at the bottom, soft golden sun on the horizon, a few scattered swallows in flight, "
    "atmospheric haze. No characters, no text, painterly pixel art, smooth gradient. "
    "Wide horizontal composition designed to sit behind a character bust on the left."
)


print("════════════════════════════════════")
print("v2 mascot assets: bust + sky")
print("════════════════════════════════════")
gen_and_save("mascot_tongji_bust_v2.png", TONGJI_PROMPT, 256, 384, True)
gen_and_save("mascot_luannu_bust_v2.png", LUANNU_PROMPT, 256, 384, True)
# 天空：400×280 = 112000 < 160000 ✓
gen_and_save("mascot_sky_bg.png", SKY_PROMPT, 400, 280, False)
