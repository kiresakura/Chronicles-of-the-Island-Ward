#!/usr/bin/env python3
"""批次生成：firework 3 色 + 缺漏敵人底圖 + 11 actors × 5 states 動畫。

策略：
- Firework burst sheets：1024×128 (8 幀 × 128px)，PixFlux 上限 400×400 area =
  160K，1024×128 = 131K 剛好 ✓
- 缺漏敵人底圖（hungry_ghost, paper_soldier）：64×64 PixFlux
- 動畫：每個 (actor, state) 一個 /animate-with-text call，n_frames=6，
  64×64 per frame，combined into 384×64 horizontal sprite sheet，×4 upscale
  到 1536×256 PNG 給 Godot SpriteFrames 使用

用法：
    PIXELLAB_API_KEY=... python3 scripts/tools/pixellab_gen_anim_batch.py [phase]

phase = firework | missing_enemies | animations | all
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

try:
    from PIL import Image
except ImportError:
    print("ERROR: 缺少 Pillow。安裝：python3 -m pip install Pillow", file=sys.stderr)
    sys.exit(1)

ROOT = Path(__file__).resolve().parent.parent.parent
ASSETS = ROOT / "assets" / "generated"
PIXELLAB_DIR = ASSETS / "pixellab"
ANIM_DIR = PIXELLAB_DIR / "anim"
API_ROOT = "https://api.pixellab.ai/v1"

UPSCALE = 4

# ────────────────────────────────────────────────────────────────────────
# Firework variants (3 colors)
# ────────────────────────────────────────────────────────────────────────

FIREWORK_JOBS = [
    {
        "filename": "firework_burst_sheet_red.png",
        "description": (
            "8-frame horizontal sprite sheet of a red firework burst exploding in pixel art. "
            "Frame 1: small bright red dot in center. Frames 2-3: expanding crimson rays "
            "radiating outward. Frames 4-5: peak burst with golden core and red trails. "
            "Frames 6-7: fading rays with floating embers. Frame 8: almost gone, sparse particles. "
            "Pure black background, vivid crimson and orange palette, no border, no text."
        ),
    },
    {
        "filename": "firework_burst_sheet_blue.png",
        "description": (
            "8-frame horizontal sprite sheet of a blue firework burst exploding in pixel art. "
            "Frame 1: small bright cyan dot. Frames 2-3: expanding azure rays. "
            "Frames 4-5: peak burst with white core and indigo trails. Frames 6-7: fading "
            "blue rays with starry sparks. Frame 8: almost gone. "
            "Pure black background, vivid cyan and royal blue palette, no border, no text."
        ),
    },
    {
        "filename": "firework_burst_sheet_green.png",
        "description": (
            "8-frame horizontal sprite sheet of a green firework burst exploding in pixel art. "
            "Frame 1: small bright lime dot. Frames 2-3: expanding emerald rays. "
            "Frames 4-5: peak burst with white-yellow core and jade trails. Frames 6-7: fading "
            "with mint embers. Frame 8: almost gone. "
            "Pure black background, vivid emerald and jade palette, no border, no text."
        ),
    },
]

# ────────────────────────────────────────────────────────────────────────
# Missing enemy base sprites (hungry_ghost + paper_soldier)
# ────────────────────────────────────────────────────────────────────────

MISSING_ENEMIES = [
    {
        "id": "enemy_hungry_ghost",
        "filename": "enemy_hungry_ghost.png",
        "description": (
            "Taiwanese folk religion hungry ghost (餓鬼), pixel art game sprite, "
            "centered character, dark grey-blue ghostly figure with elongated emaciated body, "
            "sunken cheeks, hollow eyes, gaping mouth, tattered black robe, faint green aura, "
            "side view facing right, plain transparent background, no text."
        ),
    },
    {
        "id": "enemy_paper_soldier",
        "filename": "enemy_paper_soldier.png",
        "description": (
            "Taiwanese folk religion paper effigy soldier (紙紮兵), pixel art game sprite, "
            "centered character, paper-craft soldier figure with red and gold painted armor, "
            "stiff posture, ink-drawn face, holding a folded paper spear, slight tilt suggesting "
            "wind, side view facing right, plain transparent background, no text."
        ),
    },
]

# ────────────────────────────────────────────────────────────────────────
# Character animations (11 actors × 5 states)
# ────────────────────────────────────────────────────────────────────────

# Map actor id → source texture path (relative to repo root)
ACTOR_SOURCES = {
    "character_tongji":   "assets/generated/portraits_v3/tongji.png",
    "character_luannu":   "assets/generated/portraits_v3/luannu.png",
    "character_daoshi":   "assets/generated/portraits_v3/daoshi.png",
    "character_jiajiang": "assets/generated/portraits_v3/jiajiang.png",
    "enemy_mountain_boar": "assets/generated/enemies_v3/enemy_mountain_boar.png",
    "enemy_tree_spirit":   "assets/generated/enemies_v3/enemy_tree_spirit.png",
    "enemy_wandering_soul": "assets/generated/enemies_v3/enemy_lost_soul.png",
    "enemy_hungry_ghost":  "assets/generated/pixellab/enemy_hungry_ghost.png",   # ← generated above
    "enemy_paper_soldier": "assets/generated/pixellab/enemy_paper_soldier.png",  # ← generated above
    "enemy_chair_girl":    "assets/generated/enemies_v3/enemy_chair_girl.png",
    "enemy_makanai":       "assets/generated/enemies/enemy_makanai_v1.png",
    "enemy_tiger_aunt":    "assets/generated/enemies/enemy_tiger_aunt_v1.png",
    "enemy_tiger_god":     "assets/generated/enemies_v3/enemy_tiger_god.png",
}

# Brief actor description (used in animate-with-text)
ACTOR_DESCS = {
    "character_tongji":    "young Taiwanese male spirit medium, red headband with trailing tassel, open red-gold ritual vest over bare muscular torso, holding a spirit-brush staff, heroic tall anime proportions",
    "character_luannu":    "young Taiwanese female phoenix maiden, gold phoenix crown with red gem, red-gold embroidered top and pants with jade-green sash, holding a spirit brush, heroic tall anime proportions",
    "character_daoshi":    "young Taiwanese male Taoist priest, dark-blue and white Taoist robe, gold priest crown, holding a peach-wood ritual sword, heroic tall anime proportions",
    "character_jiajiang":  "Taiwanese temple guardian general, horned war helmet, painted guardian opera face, red-gold lamellar plate armor with chest guard and pauldrons, ritual weapon, muscular heroic proportions",
    "enemy_mountain_boar": "fierce wild mountain boar with red eyes and tusks, dark fur, folk-religion demon",
    "enemy_tree_spirit":   "ancient gnarled tree spirit with glowing eyes and twisted bark body",
    "enemy_wandering_soul": "pale floating wandering ghost in tattered white robe, mournful expression",
    "enemy_hungry_ghost":  "emaciated grey-blue hungry ghost with gaping mouth and faint green aura",
    "enemy_paper_soldier": "stiff paper-craft soldier with red gold armor and folded paper spear",
    "enemy_chair_girl":    "small girl spirit attached to wooden chair, pale and unsettling",
    "enemy_makanai":       "trickster mountain spirit (魔神仔), small dark hunched figure with red eyes",
    "enemy_tiger_aunt":    "elderly tiger spirit woman (虎姑婆), grey-white fur and traditional Hakka attire",
    "enemy_tiger_god":     "ferocious centennial tiger god (百年虎爺), gold and orange striped fur, divine aura",
}

# Action descriptions for each state
STATE_ACTIONS = {
    "idle":   "stand idle in ready combat stance, subtle breathing motion",
    "attack": "lunge forward and strike with full force",
    "defend": "raise guard, protective stance",
    "hit":    "stagger backward from being struck",
    "death":  "collapse and fade away",
}

# 個別 actor + state 的覆寫 prompt（若需要更強動感才覆寫）
STATE_ACTIONS_OVERRIDES: dict[tuple[str, str], str] = {
    ("character_luannu", "attack"): (
        "swing spirit brush forward in dramatic arc, robe and sash billowing wildly, "
        "embers and sacred fire trailing from brush tip, large stride forward, "
        "each frame radically different pose"
    ),
}

STATES = ["idle", "attack", "defend", "hit", "death"]
ACTORS = list(ACTOR_SOURCES.keys())

N_FRAMES = 4  # API spec：「the model will always generate 4 frames」(經驗證實 N=6/8 都回 4)
FRAME_SIZE = 64

# ────────────────────────────────────────────────────────────────────────
# API helpers
# ────────────────────────────────────────────────────────────────────────

def get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if not key:
        raise SystemExit("缺少 PIXELLAB_API_KEY 環境變數")
    return key


def _post(path: str, payload: dict, api_key: str, max_retry: int = 3, timeout: int = 600) -> dict:
    """POST with retry on timeout/network errors."""
    last_err = None
    data = json.dumps(payload).encode("utf-8")
    for attempt in range(max_retry):
        try:
            req = urllib.request.Request(
                f"{API_ROOT}{path}",
                data=data,
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except (TimeoutError, urllib.error.URLError) as e:
            last_err = e
            if attempt < max_retry - 1:
                wait = 5 * (attempt + 1)
                print(f"    ↻ retry {attempt+1}/{max_retry} after {wait}s ({e})")
                time.sleep(wait)
                continue
            raise
    raise last_err  # unreachable


def _decode_b64_image(b64_str: str) -> bytes:
    """Handle both raw base64 and data URL prefix."""
    if "," in b64_str:
        b64_str = b64_str.split(",", 1)[1]
    return base64.b64decode(b64_str)


def _encode_image_b64(path: Path, target_size: tuple[int, int] | None = None) -> str:
    img = Image.open(path).convert("RGBA")
    if target_size:
        img = img.resize(target_size, Image.NEAREST)
    buf = BytesIO()
    img.save(buf, "PNG")
    return base64.b64encode(buf.getvalue()).decode("ascii")


def _nearest_upscale(src_png: bytes, factor: int) -> Image.Image:
    src = Image.open(BytesIO(src_png))
    return src.resize((src.width * factor, src.height * factor), Image.NEAREST)


# ────────────────────────────────────────────────────────────────────────
# Phases
# ────────────────────────────────────────────────────────────────────────

FIREWORK_FRAME_SIZE = 64
FIREWORK_N_FRAMES = 8


def phase_firework(api_key: str) -> None:
    print("════════════════════════════════════")
    print("Phase: Firework variants (3 colors × 8 frames)")
    print("════════════════════════════════════")
    PIXELLAB_DIR.mkdir(parents=True, exist_ok=True)
    color_specs = [
        ("red",   "firework_burst_sheet_red.png",   "vivid crimson red and bright orange",
         "exploding red firework: tiny bright dot, then expanding crimson rays radiating outward, "
         "peak burst with white-gold core and red trails, fading with embers, final spark"),
        ("blue",  "firework_burst_sheet_blue.png",  "vivid cyan azure and royal blue",
         "massive blue firework explosion sequence: small ignition flash, then rapidly expanding "
         "bright cyan and electric blue rays radiating outward across the entire frame, peak burst "
         "filling frame with white-hot center and indigo trails, then dissipating into scattered blue "
         "sparks. Each frame must show clear progression and dramatic change."),
        ("green", "firework_burst_sheet_green.png", "vivid emerald and jade green",
         "exploding green firework: tiny bright lime dot, then expanding emerald rays, "
         "peak burst with white-yellow core and jade trails, fading with mint embers, final spark"),
    ]
    # 每個顏色用「黑底 + 中央一顆同色點」作 ref，給模型最大 palette 自由度
    def _make_ref(rgb: tuple[int, int, int]) -> str:
        ref = Image.new("RGBA", (FIREWORK_FRAME_SIZE, FIREWORK_FRAME_SIZE), (0, 0, 0, 255))
        cx, cy = FIREWORK_FRAME_SIZE // 2, FIREWORK_FRAME_SIZE // 2
        for dx in range(-2, 3):
            for dy in range(-2, 3):
                if dx * dx + dy * dy <= 4:
                    ref.putpixel((cx + dx, cy + dy), (*rgb, 255))
        b = BytesIO(); ref.save(b, "PNG")
        return base64.b64encode(b.getvalue()).decode("ascii")

    color_rgb = {"red": (255, 60, 30), "blue": (60, 140, 255), "green": (80, 230, 120)}

    for color, fname, palette_hint, action in color_specs:
        out = PIXELLAB_DIR / fname
        if out.exists():
            print(f"  {fname} → already exists, skip")
            continue
        ref_b64 = _make_ref(color_rgb[color])
        print(f"  {fname}…")
        payload = {
            "description": (
                f"pixel art {palette_hint} firework explosion on pure black background, "
                "8 sequential animation frames showing burst lifecycle, no characters, no text"
            ),
            "action": action,
            "image_size": {"width": FIREWORK_FRAME_SIZE, "height": FIREWORK_FRAME_SIZE},
            "n_frames": FIREWORK_N_FRAMES,
            "view": "side",
            "direction": "east",
            "text_guidance_scale": 9.0,
            "reference_image": {"type": "base64", "base64": ref_b64},
        }
        try:
            resp = _post("/animate-with-text", payload, api_key)
        except urllib.error.HTTPError as e:
            print(f"    ✗ HTTP {e.code}: {e.read().decode('utf-8','ignore')[:300]}")
            continue
        # Combine 8 frames into 512×64 strip, ×2 upscale → 1024×128 (matches existing)
        frames_pngs = [_decode_b64_image(img["base64"]) for img in resp["images"]]
        sheet = Image.new("RGBA",
                          (FIREWORK_FRAME_SIZE * len(frames_pngs), FIREWORK_FRAME_SIZE))
        for i, p in enumerate(frames_pngs):
            sheet.paste(Image.open(BytesIO(p)).convert("RGBA"),
                        (i * FIREWORK_FRAME_SIZE, 0))
        upscaled = sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST)
        out = PIXELLAB_DIR / fname
        upscaled.save(out, "PNG")
        print(f"    ✓ {out} ({upscaled.size}, {len(frames_pngs)} frames)")


def phase_missing_enemies(api_key: str) -> None:
    print("════════════════════════════════════")
    print(f"Phase: Missing enemy bases ({len(MISSING_ENEMIES)} calls)")
    print("════════════════════════════════════")
    PIXELLAB_DIR.mkdir(parents=True, exist_ok=True)
    for job in MISSING_ENEMIES:
        print(f"  {job['filename']}…")
        payload = {
            "description": job["description"],
            "image_size": {"width": 64, "height": 64},
            "text_guidance_scale": 9.0,
            "no_background": True,
        }
        try:
            resp = _post("/generate-image-pixflux", payload, api_key)
        except urllib.error.HTTPError as e:
            print(f"    ✗ HTTP {e.code}: {e.read().decode('utf-8','ignore')[:200]}")
            continue
        png = _decode_b64_image(resp["image"]["base64"])
        out = PIXELLAB_DIR / job["filename"]
        # Upscale ×4 to 256×256 to match portrait scale
        upscaled = _nearest_upscale(png, UPSCALE)
        upscaled.save(out, "PNG")
        print(f"    ✓ {out} ({upscaled.size})")


def phase_animations(api_key: str, actors: list[str] | None = None) -> None:
    actors = actors or ACTORS
    total = len(actors) * len(STATES)
    print("════════════════════════════════════")
    print(f"Phase: Animations ({total} calls)")
    print("════════════════════════════════════")
    ANIM_DIR.mkdir(parents=True, exist_ok=True)

    call_i = 0
    for actor_id in actors:
        actor_dir = ANIM_DIR / actor_id
        actor_dir.mkdir(parents=True, exist_ok=True)
        src_path = ROOT / ACTOR_SOURCES[actor_id]
        if not src_path.exists():
            print(f"⚠ skip {actor_id}: source missing → {src_path}")
            continue
        ref_b64 = _encode_image_b64(src_path, target_size=(FRAME_SIZE, FRAME_SIZE))
        desc = ACTOR_DESCS[actor_id]

        for state in STATES:
            call_i += 1
            out = actor_dir / f"{state}.png"
            if out.exists():
                print(f"[{call_i}/{total}] {actor_id}/{state} → already exists, skip")
                continue
            action = STATE_ACTIONS_OVERRIDES.get((actor_id, state), STATE_ACTIONS[state])
            print(f"[{call_i}/{total}] {actor_id}/{state}: {action[:40]}…")
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
                resp = _post("/animate-with-text", payload, api_key)
            except urllib.error.HTTPError as e:
                print(f"    ✗ HTTP {e.code}: {e.read().decode('utf-8','ignore')[:200]}")
                continue
            except urllib.error.URLError as e:
                print(f"    ✗ URL error: {e}")
                continue

            # Combine N frames into horizontal sprite strip
            frames_pngs = [_decode_b64_image(img["base64"]) for img in resp["images"]]
            sheet = Image.new("RGBA", (FRAME_SIZE * len(frames_pngs), FRAME_SIZE))
            for i, p in enumerate(frames_pngs):
                frame = Image.open(BytesIO(p)).convert("RGBA")
                sheet.paste(frame, (i * FRAME_SIZE, 0))
            upscaled = sheet.resize(
                (sheet.width * UPSCALE, sheet.height * UPSCALE), Image.NEAREST
            )
            upscaled.save(out, "PNG")
            print(f"    ✓ {out} ({upscaled.size})")
            time.sleep(0.5)  # 給 API 喘息


def main() -> None:
    phase = sys.argv[1] if len(sys.argv) > 1 else "all"
    api_key = get_api_key()
    if phase in ("firework", "all"):
        phase_firework(api_key)
    if phase in ("missing_enemies", "all"):
        phase_missing_enemies(api_key)
    if phase in ("animations", "all"):
        # 可選：phase 之後接 actor_id 子集，例如
        #   ... animations character_tongji character_luannu character_daoshi character_jiajiang
        phase_animations(api_key, sys.argv[2:] or None)


if __name__ == "__main__":
    main()
