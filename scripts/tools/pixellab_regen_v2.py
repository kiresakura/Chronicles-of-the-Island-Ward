#!/usr/bin/env python3
"""2nd pass regen — Luannu idle/death 改用 attack frame[0] 作 ref（人設鎖更緊）。"""

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
PIXELLAB_DIR = ROOT / "assets" / "generated" / "pixellab"
ANIM_DIR = PIXELLAB_DIR / "anim"
API_ROOT = "https://api.pixellab.ai/v1"
FRAME = 64
N = 4
UP = 4

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


# 用 Luannu attack frame[0] 作 ref（已知正確全身紅袍人設）
attack_path = ANIM_DIR / "character_luannu" / "attack.png"
attack_img = Image.open(attack_path).convert("RGBA")
# attack.png 是 1024×256（4 幀 ×4 upscale），抓第一幀 256×256，downscale 64×64
frame0 = attack_img.crop((0, 0, 256, 256)).resize((FRAME, FRAME), Image.LANCZOS)
buf = BytesIO(); frame0.save(buf, "PNG")
ref_b64 = base64.b64encode(buf.getvalue()).decode()

DESC = ("EXACT SAME young Taiwanese phoenix-maiden spirit medium "
        "as reference: gold phoenix headdress, long black hair, "
        "red and gold floor-length embroidered robe, holding spirit brush. "
        "Full body visible head to feet.")

JOBS = [
    ("idle",  "stand idle full body relaxed, spirit brush held vertical at side, subtle breathing only, "
              "EXACT SAME costume and character"),
    ("death", "fall to knees collapsing, head bowed, brush slipping from hand, faint gold particles fading, "
              "EXACT SAME costume and character"),
]

for state, action in JOBS:
    out = ANIM_DIR / "character_luannu" / f"{state}.png"
    print(f"[{state}]")
    payload = {
        "description": DESC,
        "action": action,
        "image_size": {"width": FRAME, "height": FRAME},
        "n_frames": N,
        "view": "side",
        "direction": "east",
        "text_guidance_scale": 8.0,
        "image_guidance_scale": 2.2,  # 拉高、要更貼 ref
        "reference_image": {"type": "base64", "base64": ref_b64},
    }
    try:
        resp = post("/animate-with-text", payload)
    except urllib.error.HTTPError as e:
        print(f"  ✗ HTTP {e.code}: {e.read().decode()[:200]}")
        continue
    pngs = [b64dec(img["base64"]) for img in resp["images"]]
    sheet = Image.new("RGBA", (FRAME * len(pngs), FRAME))
    for i, p in enumerate(pngs):
        sheet.paste(Image.open(BytesIO(p)).convert("RGBA"), (i * FRAME, 0))
    up = sheet.resize((sheet.width * UP, sheet.height * UP), Image.NEAREST)
    up.save(out, "PNG")
    print(f"  ✓ {out}")
    time.sleep(0.5)
