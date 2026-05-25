#!/usr/bin/env python3
"""一次生成 Act 1 的 3 張背景：node map + 山路 combat + 山廟 combat。

策略：
- PixFlux endpoint 上限 area 400×400 = 160000 px。
- 我們生 344×192（area 66048），再 PIL nearest-neighbor ×4 上採樣到 1376×768
  （與遊戲 1200×700 canvas 在 16:9 螢幕上的 SafeFit 對齊）。

用法：
    PIXELLAB_API_KEY=... python3 scripts/tools/pixellab_gen_act1.py
"""

from __future__ import annotations

import base64
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("ERROR: 缺少 Pillow。安裝：python3 -m pip install Pillow", file=sys.stderr)
    sys.exit(1)

API_ROOT = "https://api.pixellab.ai/v1"
OUTPUT_DIR = Path(__file__).resolve().parent.parent.parent / "assets" / "generated" / "pixellab"

SRC_W, SRC_H = 344, 192  # 生成尺寸（16:9，area 66048 < 160000）
SCALE = 4
DST_W, DST_H = SRC_W * SCALE, SRC_H * SCALE  # 1376×768

JOBS = [
    {
        "filename": "act1_map_node_bg.png",
        "description": (
            "Aerial top-down 45-degree view of a Taiwanese mountain region. "
            "Misty bamboo forest valleys, winding stone paths between hills, "
            "scattered small Taoist temples with red tiled roofs and hanging red lanterns, "
            "distant foggy peaks at horizon, ancient pine trees, golden hour sunset light, "
            "warm orange-purple gradient sky. Painterly pixel art style, atmospheric depth, "
            "no characters, no text. Detailed map illustration for a roguelike game."
        ),
    },
    {
        "filename": "act1_combat_bg_path.png",
        "description": (
            "Side scrolling view of a Taiwanese mountain path scene at dusk. "
            "Cobblestone trail winding between dense bamboo groves and ancient pine trees, "
            "stone lanterns lining the path, distant mountain silhouettes shrouded in evening mist, "
            "fireflies, deep purple twilight sky with scattered stars. "
            "Painterly pixel art combat background, atmospheric depth, no characters, no text."
        ),
    },
    {
        "filename": "act1_combat_bg_shrine.png",
        "description": (
            "Side view of a Taiwanese mountain shrine interior at night. "
            "Wooden temple with carved red pillars, hanging red silk lanterns, "
            "stone altar with smoking incense burners, golden deity statue in alcove, "
            "soft warm candlelight glow, bamboo grove visible through open doorway. "
            "Painterly pixel art combat background, atmospheric warm tones, no characters, no text."
        ),
    },
]


def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if not key:
        raise SystemExit("缺少 PIXELLAB_API_KEY 環境變數。")
    return key


def generate_one(description: str, api_key: str) -> bytes:
    """呼叫 /generate-image-pixflux 並回傳 PNG bytes。"""
    payload = {
        "description": description,
        "image_size": {"width": SRC_W, "height": SRC_H},
        "text_guidance_scale": 9.0,
        "no_background": False,
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        f"{API_ROOT}/generate-image-pixflux",
        data=data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        body = json.loads(resp.read().decode("utf-8"))
    b64 = body["image"]["base64"]
    return base64.b64decode(b64)


def upscale_to_canvas(src_png: bytes, out_path: Path) -> None:
    """nearest-neighbor ×4 上採樣，保 pixel-art crisp，存 PNG。"""
    from io import BytesIO

    src = Image.open(BytesIO(src_png))
    dst = src.resize((DST_W, DST_H), Image.NEAREST)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    dst.save(out_path, "PNG")


def main() -> None:
    api_key = get_api_key()
    print(f"輸出目錄：{OUTPUT_DIR}")
    print(f"源尺寸 {SRC_W}×{SRC_H} → 上採樣 ×{SCALE} → {DST_W}×{DST_H}")
    print(f"任務數：{len(JOBS)}")
    print()

    for i, job in enumerate(JOBS, 1):
        out = OUTPUT_DIR / job["filename"]
        print(f"[{i}/{len(JOBS)}] {job['filename']}")
        print(f"  prompt: {job['description'][:80]}…")
        try:
            src_png = generate_one(job["description"], api_key)
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8", "ignore")
            print(f"  ✗ HTTP {e.code}: {err_body[:300]}", file=sys.stderr)
            continue
        print(f"  ← 收到 {len(src_png)} bytes")
        upscale_to_canvas(src_png, out)
        print(f"  ✓ 存 {out} ({DST_W}×{DST_H})")
        print()


if __name__ == "__main__":
    main()
