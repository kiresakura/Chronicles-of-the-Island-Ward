#!/usr/bin/env python3
"""生 mainmenu temple 3 時段 BG 變體：早晨 / 黃昏 / 夜晚。

每個 400×224 PixFlux ×4 = 1600×896。
與既有 mainmenu_temple_v6 (黃昏) 並存作不同時段切換。
"""

import base64, json, os, sys, time, urllib.error, urllib.request
from io import BytesIO
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets" / "generated" / "pixellab"
API = "https://api.pixellab.ai/v1"
key = os.environ.get("PIXELLAB_API_KEY", "").strip()
if not key:
    raise SystemExit("缺 PIXELLAB_API_KEY")


def post(payload):
    data = json.dumps(payload).encode()
    for a in range(3):
        try:
            req = urllib.request.Request(
                f"{API}/generate-image-pixflux", data=data,
                headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
                method="POST")
            with urllib.request.urlopen(req, timeout=600) as r:
                return json.loads(r.read().decode())
        except (TimeoutError, urllib.error.URLError) as e:
            print(f"  ↻ {e}"); time.sleep(5 * (a + 1))
    raise RuntimeError("max retries")


def b64dec(s):
    if "," in s: s = s.split(",", 1)[1]
    return base64.b64decode(s)


BASE_TEMPLE = (
    "Wide-screen Taiwanese temple main menu background. Red and gold ornate roofs "
    "with green glazed tiles, carved dragon ridges, crimson lanterns lining eaves, "
    "tall red pillars in the temple façade. Two side wings on left and right. "
    "Detailed atmospheric pixel art, painterly, no characters, no text. "
)

VARIANTS = [
    ("mainmenu_temple_day.png",
     BASE_TEMPLE +
     "Time of day: BRIGHT MORNING. Sky is clear cerulean blue with soft white cumulus "
     "clouds, sunlight streams from upper right, warm golden glow on temple roofs, "
     "courtyard well-lit, birds in flight, mountains visible in distance with mist."),
    ("mainmenu_temple_dusk.png",
     BASE_TEMPLE +
     "Time of day: DRAMATIC DUSK SUNSET. Sky burning orange, crimson, and violet "
     "with pink cloud bands, sun low at horizon casting long warm shadows, "
     "lanterns starting to glow, swallows in flight, distant purple mountains."),
    ("mainmenu_temple_night.png",
     BASE_TEMPLE +
     "Time of day: STARRY NIGHT. Deep indigo sky with bright crescent moon, "
     "many stars visible, lanterns glow warm orange, soft moonlight on courtyard, "
     "subtle fog at ground level, distant mountains silhouetted in darkness."),
]

print("════════════════════════════════════")
print("Day/Dusk/Night BG variants (3)")
print("════════════════════════════════════")
for fname, desc in VARIANTS:
    out = OUT / fname
    print(f"[{fname}]")
    if out.exists():
        print("  exists, skip"); continue
    payload = {
        "description": desc,
        "image_size": {"width": 400, "height": 224},
        "text_guidance_scale": 9.0,
        "no_background": False,
    }
    try:
        resp = post(payload)
    except urllib.error.HTTPError as e:
        print(f"  ✗ HTTP {e.code}: {e.read().decode()[:200]}"); continue
    png = b64dec(resp["image"]["base64"])
    img = Image.open(BytesIO(png)).convert("RGBA")
    up = img.resize((img.width * 4, img.height * 4), Image.NEAREST)
    up.save(out, "PNG")
    print(f"  ✓ {out} ({up.size})")
    time.sleep(0.5)
