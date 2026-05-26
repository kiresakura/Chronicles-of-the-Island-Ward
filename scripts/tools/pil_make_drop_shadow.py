#!/usr/bin/env python3
"""生 mascot 地面投影 — 橢圓 + alpha gradient PNG。

512×128 pixel art ellipse，中心黑 alpha ~0.6，邊緣淡出至 0。
擺在 character 腳下，配合 idle 呼吸營造立體感。
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets" / "generated" / "pixellab" / "mascot_drop_shadow.png"

W, H = 512, 128

# 建立黑底 alpha-only ellipse，靠 GaussianBlur 給軟邊
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# 中心橢圓：黑色填滿，inset 20 px 給 blur 空間
inset = 18
draw.ellipse([inset, inset, W - inset, H - inset], fill=(0, 0, 0, 170))

# 高斯模糊讓邊緣淡出
img = img.filter(ImageFilter.GaussianBlur(radius=22))

OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT, "PNG")
print(f"✓ {OUT} ({W}×{H})")
