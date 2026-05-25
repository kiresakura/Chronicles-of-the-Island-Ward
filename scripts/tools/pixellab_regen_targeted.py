#!/usr/bin/env python3
"""針對性重生：weak anim 條 + 補生 Luannu 全身 base。

問題：
1. Luannu source portrait 是 bust → 5 state 動畫都 bust，沒身體
2. Tongji death 變成 devil with staff（人設跑掉）
3. Chair girl idle 後 3 幀變翼魔（不一致）
4. Tiger god idle 飛/躺 pose 不是站立

策略：
- 先生 Luannu full-body base (PixFlux 64×64)
- 用該 base 重生 Luannu 5 state
- Tongji death + Chair girl idle + Tiger god idle 重生（強化 prompt）

用法：PIXELLAB_API_KEY=... python3 scripts/tools/pixellab_regen_targeted.py
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
PIXELLAB_DIR = ROOT / "assets" / "generated" / "pixellab"
ANIM_DIR = PIXELLAB_DIR / "anim"
API_ROOT = "https://api.pixellab.ai/v1"
FRAME_SIZE = 64
N_FRAMES = 4
UPSCALE = 4


def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if not key:
        raise SystemExit("缺少 PIXELLAB_API_KEY")
    return key


def post(path: str, payload: dict, api_key: str, timeout: int = 600) -> dict:
    data = json.dumps(payload).encode("utf-8")
    last = None
    for attempt in range(3):
        try:
            req = urllib.request.Request(
                f"{API_ROOT}{path}", data=data,
                headers={"Authorization": f"Bearer {api_key}",
                         "Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode("utf-8"))
        except (TimeoutError, urllib.error.URLError) as e:
            last = e
            wait = 5 * (attempt + 1)
            print(f"  ↻ retry ({e}) wait {wait}s")
            time.sleep(wait)
    raise last


def b64_decode(s: str) -> bytes:
    if "," in s:
        s = s.split(",", 1)[1]
    return base64.b64decode(s)


def img_to_b64(path: Path, target: tuple[int, int]) -> str:
    img = Image.open(path).convert("RGBA").resize(target, Image.NEAREST)
    b = BytesIO(); img.save(b, "PNG")
    return base64.b64encode(b.getvalue()).decode("ascii")


def upscale_strip(frames: list[bytes], factor: int = UPSCALE) -> Image.Image:
    sheet = Image.new("RGBA", (FRAME_SIZE * len(frames), FRAME_SIZE))
    for i, p in enumerate(frames):
        sheet.paste(Image.open(BytesIO(p)).convert("RGBA"), (i * FRAME_SIZE, 0))
    return sheet.resize((sheet.width * factor, sheet.height * factor), Image.NEAREST)


# ────────────────────────────────────────────────────────────────────────
# Step 1: Generate Luannu full-body base (replaces source for animations)
# ────────────────────────────────────────────────────────────────────────

LUANNU_BASE = PIXELLAB_DIR / "character_luannu_base.png"
LUANNU_BASE_PROMPT = (
    "FULL BODY full-length pixel art game sprite of a young Taiwanese phoenix-maiden "
    "spirit medium (鸞女), standing centered on a transparent background, visible from "
    "head to feet. Ornate gold phoenix headdress with crimson tassels, long flowing "
    "black hair, embroidered crimson and gold floor-length robe with phoenix patterns "
    "and jade-green sash, holding a long spirit-brush with red tassel, side view facing "
    "right (east), serene confident expression. Plain transparent background, no text, "
    "no border."
)


def gen_luannu_base(api_key: str) -> None:
    if LUANNU_BASE.exists():
        print(f"  {LUANNU_BASE.name} → exists, skip")
        return
    payload = {
        "description": LUANNU_BASE_PROMPT,
        "image_size": {"width": FRAME_SIZE, "height": FRAME_SIZE},
        "text_guidance_scale": 9.0,
        "no_background": True,
    }
    print(f"  generating {LUANNU_BASE.name}…")
    resp = post("/generate-image-pixflux", payload, api_key)
    png = b64_decode(resp["image"]["base64"])
    # Upscale ×4 to 256×256
    up = Image.open(BytesIO(png)).convert("RGBA")
    up = up.resize((up.width * UPSCALE, up.height * UPSCALE), Image.NEAREST)
    up.save(LUANNU_BASE, "PNG")
    print(f"  ✓ {LUANNU_BASE}")


# ────────────────────────────────────────────────────────────────────────
# Step 2: Regen list
# ────────────────────────────────────────────────────────────────────────

REGEN_JOBS = [
    # Luannu 全身 anim — 用新 base 作 ref，全 5 state
    ("character_luannu", "idle", LUANNU_BASE,
     "young Taiwanese phoenix maiden spirit medium with gold headdress and flowing robe, full body visible",
     "stand idle full body visible head to feet, subtle breathing, spirit brush at side"),
    ("character_luannu", "attack", LUANNU_BASE,
     "young Taiwanese phoenix maiden spirit medium with gold headdress and flowing robe, full body visible",
     "swing spirit brush forward in dramatic arc, robe billowing wildly, "
     "each frame radically different pose, full body visible"),
    ("character_luannu", "defend", LUANNU_BASE,
     "young Taiwanese phoenix maiden spirit medium with gold headdress and flowing robe, full body visible",
     "raise spirit brush horizontally as shield, protective stance with knees bent, full body visible"),
    ("character_luannu", "hit", LUANNU_BASE,
     "young Taiwanese phoenix maiden spirit medium with gold headdress and flowing robe, full body visible",
     "stagger backward from impact, hair and robe flying wildly, dropped brush, full body visible"),
    ("character_luannu", "death", LUANNU_BASE,
     "young Taiwanese phoenix maiden spirit medium with gold headdress and flowing robe, full body visible",
     "kneel falling forward, headdress askew, fade glow particles dissipating, full body visible"),
    # Tongji death — 重新用 portraits_v3 ref，強化「same character」
    ("character_tongji", "death",
     ROOT / "assets/generated/portraits_v3/tongji.png",
     "SAME young Taiwanese male spirit medium with red headband and bare chest and red pants",
     "SAME tongji character falling backward to ground, eyes closed, body limp, "
     "no morphing into different character, keep red headband and bare chest"),
    # Chair girl idle — 強化人設一致
    ("enemy_chair_girl", "idle",
     ROOT / "assets/generated/enemies_v3/enemy_chair_girl.png",
     "small pale girl spirit sitting on a wooden chair, ghostly white robe",
     "sit on chair, only small head and shoulder movement, "
     "DO NOT grow wings, DO NOT transform, keep same pose throughout"),
    # Tiger god idle — 強制站立
    ("enemy_tiger_god", "idle",
     ROOT / "assets/generated/enemies_v3/enemy_tiger_god.png",
     "ferocious centennial tiger god with gold and orange striped fur, four legs on the ground",
     "stand on four paws on the ground, breathing motion, head turning slightly, "
     "DO NOT levitate, DO NOT fly, DO NOT lie down"),
]


def regen_one(job: tuple, api_key: str) -> None:
    actor_id, state, ref_path, desc, action = job
    out = ANIM_DIR / actor_id / f"{state}.png"
    print(f"[{actor_id}/{state}]")
    print(f"  ref: {ref_path.name}")
    if not ref_path.exists():
        print(f"  ✗ ref missing")
        return
    ref_b64 = img_to_b64(ref_path, (FRAME_SIZE, FRAME_SIZE))
    payload = {
        "description": desc,
        "action": action,
        "image_size": {"width": FRAME_SIZE, "height": FRAME_SIZE},
        "n_frames": N_FRAMES,
        "view": "side",
        "direction": "east",
        "text_guidance_scale": 8.0,
        "image_guidance_scale": 1.4,
        "reference_image": {"type": "base64", "base64": ref_b64},
    }
    try:
        resp = post("/animate-with-text", payload, api_key)
    except urllib.error.HTTPError as e:
        print(f"  ✗ HTTP {e.code}: {e.read().decode('utf-8','ignore')[:200]}")
        return
    pngs = [b64_decode(img["base64"]) for img in resp["images"]]
    upscaled = upscale_strip(pngs)
    out.parent.mkdir(parents=True, exist_ok=True)
    upscaled.save(out, "PNG")
    print(f"  ✓ {out} ({upscaled.size})")
    time.sleep(0.5)


def main():
    api_key = get_api_key()
    print("════════════════════════════════════")
    print("Step 1: Generate Luannu full-body base")
    print("════════════════════════════════════")
    gen_luannu_base(api_key)
    print()
    print("════════════════════════════════════")
    print(f"Step 2: Regen {len(REGEN_JOBS)} anim sheets")
    print("════════════════════════════════════")
    for i, job in enumerate(REGEN_JOBS, 1):
        print(f"--- [{i}/{len(REGEN_JOBS)}] ---")
        regen_one(job, api_key)


if __name__ == "__main__":
    main()
