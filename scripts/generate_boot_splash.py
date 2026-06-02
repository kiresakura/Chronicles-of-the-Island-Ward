#!/usr/bin/env python3
"""生成鎮島錄 engine boot splash placeholder。

用途：
- 輸出 `assets/ui/boot_splash_v5.png`
- 僅供 Godot engine boot splash / export 啟動畫面素材使用
- 目前遊戲 runtime 已改為 `Root.tscn` 內建 loading overlay，
  不再使用獨立 SplashScreen scene/script

尺寸維持 1200×700，便於與現行 Root 啟動畫面視覺語氣對齊。
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "ui" / "boot_splash_v5.png"
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

# 廟會紅 + 漸暈
W, H = 1200, 700
BG = (201, 32, 32)  # #c92020 廟會紅
img = Image.new("RGB", (W, H), color=BG)

# 簡單漸暈效果（中間亮一點）
draw = ImageDraw.Draw(img, "RGBA")
for r in range(min(W, H) // 2, 0, -10):
    alpha = max(0, 30 - r // 20)
    draw.ellipse(
        [(W // 2 - r * 1.4, H // 2 - r), (W // 2 + r * 1.4, H // 2 + r)],
        fill=(255, 200, 100, alpha),
    )

# 主標題 鎮島錄
CJK_FONT = "/System/Library/Fonts/STHeiti Medium.ttc"
title_font = ImageFont.truetype(CJK_FONT, 200)
title = "鎮島錄"
bbox = draw.textbbox((0, 0), title, font=title_font)
tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
title_x = (W - tw) // 2 - bbox[0]
title_y = (H - th) // 2 - 60 - bbox[1]

# 文字陰影
draw.text((title_x + 6, title_y + 6), title, fill=(0, 0, 0, 180), font=title_font)
draw.text((title_x, title_y), title, fill=(255, 250, 240), font=title_font)

# 副標 Chronicles of the Island Ward
EN_FONT = "/System/Library/Fonts/Helvetica.ttc"
sub_font = ImageFont.truetype(EN_FONT, 38)
subtitle = "Chronicles of the Island Ward"
bbox2 = draw.textbbox((0, 0), subtitle, font=sub_font)
sw = bbox2[2] - bbox2[0]
sub_x = (W - sw) // 2 - bbox2[0]
sub_y = title_y + th + 50
draw.text((sub_x, sub_y), subtitle, fill=(255, 230, 180), font=sub_font)

# 底部裝飾線
line_y = H - 60
draw.line(
    [(W // 2 - 200, line_y), (W // 2 + 200, line_y)],
    fill=(255, 230, 180),
    width=2,
)

img.save(OUTPUT, "PNG")
print(f"✅ Engine boot splash saved to {OUTPUT}")
print(f"   尺寸：{W}×{H}")
