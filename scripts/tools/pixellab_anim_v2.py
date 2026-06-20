#!/usr/bin/env python3
"""PixelLab 敵人動畫 v2（修正版產線）。金鑰讀 PIXELLAB_API_KEY（或 .env.local）。

修正舊版（已隔離）的四個致命病：
  1. 髒參考圖（烤入草皮）→ 模型複製草皮。本版先「清參考」：去草、alpha 裁邊、置中放大。
  2. 8 幀拼接（兩次獨立呼叫不連戲）→ 改「單次 4 幀」(API 連戲上限，且對齊 ANIM_FRAME_COUNT=4)。
  3. 無 negative → 幻覺背景/光暈。本版強 negative + 「floating, nothing beneath」。
  4. image_guidance 太低 → off-model。本版拉到 2.2 鎖角色一致。
  64px native → NEAREST ×4 → 1024×256 strip（對齊 BaseCombatant 切幀契約）。

用法：
  PIXELLAB_API_KEY=... python3 scripts/tools/pixellab_anim_v2.py idle [actor_id ...]
  states: idle | attack | hit | death（可多個，逗號分隔或多參數）
輸出 staging：qa/art_regen/enemy_anim/<actor_id>/<state>.png（人工過目後再 promote）
"""
from __future__ import annotations
import os, sys, json, base64, time, urllib.request, urllib.error
from io import BytesIO
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
API = "https://api.pixellab.ai/v1/animate-with-text"
STAGING = ROOT / "qa" / "art_regen" / "enemy_anim"
FRAME, NF, UP = 64, 4, 4

# 主角立繪細節多、易跳姿；用更強 image_guidance + 反飄移 negative 鎖住造型
HERO_NEG = ("grass, ground, floor, shadow, scenery, text, watermark, border, motion lines, "
            "speed lines, streaks, swoosh, crouching, hunching, lying down, different poses, multiple characters")

# 每個 actor：來源、是否去綠草、角色描述、各 state 動作
ENEMIES = {
  "enemy_mountain_boar": dict(src="assets/generated/enemies_v3/enemy_mountain_boar.png", green=True,
    desc="a single fierce wild mountain boar demon, dark bristly fur, red mane, white tusks",
    actions=dict(idle="stand almost still with only the faintest breathing, feet firmly planted",
                 attack="lower head and charge forward goring with tusks",
                 hit="recoil and flinch backward from a blow",
                 death="collapse onto the ground and fade")),
  "enemy_tree_spirit": dict(src="assets/generated/enemies_v3/enemy_tree_spirit.png", green=False,
    desc="a single upright walking tree-monster creature with a gnarled bark body, glowing eyes, and root legs, full body centered",
    neg="grass, ground, floor, water, soil, shadow, chains, smoke, text, watermark, border, frame, "
        "motion lines, speed lines, streaks, swoosh",
    actions=dict(idle="sway gently in place, only slight bark creaking, standing still",
                 attack="lash forward with a thorny branch arm",
                 hit="shudder and shed bark from impact",
                 death="wither, slump and crumble apart")),
  "enemy_wandering_soul": dict(src="assets/generated/enemies_v3/enemy_lost_soul.png", green=False,
    desc="a single pale floating wandering ghost in a tattered white robe, mournful face",
    actions=dict(idle="float and bob gently, robe drifting",
                 attack="lunge forward with grasping spectral claws",
                 hit="waver and distort from being struck",
                 death="dissipate into wisps and vanish")),
  "enemy_chair_girl": dict(src="assets/generated/enemies_v3/enemy_chair_girl.png", green=False,
    desc="a single small pale ghost girl sitting on an old wooden chair, holding a doll, unsettling",
    actions=dict(idle="sit with subtle eerie sway, hair and doll shifting",
                 attack="lurch forward off the chair reaching out",
                 hit="jerk back against the chair from impact",
                 death="go limp and fade on the chair")),
  "enemy_tiger_god": dict(src="assets/generated/enemies_v3/enemy_tiger_god.png", green=True,
    desc="a single ferocious tiger god with gold and orange striped fur and a divine red aura",
    actions=dict(idle="stand almost still in a low crouch, only faint breathing, no leaping",
                 attack="pounce forward swiping with a clawed paw",
                 hit="snarl and recoil from a blow",
                 death="fall to the ground and fade")),
  # ── 主角立繪（戰鬥用像素，選單仍用 portraits_v3 當 key-art）──
  "character_tongji": dict(src="assets/generated/portraits_v3/tongji.png", green=False, igs=2.8, tgs=6.5, neg=HERO_NEG,
    desc="a young Taiwanese male spirit-medium hero, red headband with tassel, bare muscular torso with open red-gold ritual vest, red pants, standing upright facing right",
    actions=dict(idle="stand almost perfectly still upright, only the faintest breathing, feet firmly planted, holding the same pose",
                 attack="throw one powerful straight punch forward",
                 hit="recoil and flinch backward from a blow",
                 death="collapse to the ground")),
  "character_daoshi": dict(src="assets/generated/portraits_v3/daoshi.png", green=False, igs=2.8, tgs=6.5, neg=HERO_NEG,
    desc="a young Taiwanese male Taoist priest hero, dark-blue and white Taoist robe, gold priest crown, holding a peachwood ritual sword, standing upright facing right",
    actions=dict(idle="stand almost perfectly still upright, only the faintest breathing, feet firmly planted, holding the same pose",
                 attack="thrust the peachwood ritual sword forward",
                 hit="stagger backward from a blow",
                 death="collapse to the ground")),
  "character_luannu": dict(src="assets/generated/portraits_v3/luannu.png", green=False, igs=2.8, tgs=6.5, neg=HERO_NEG,
    desc="a young Taiwanese phoenix-maiden hero, gold phoenix crown with red gem, red-gold embroidered robe with jade-green sash, holding a spirit brush, standing upright facing right",
    actions=dict(idle="stand almost perfectly still upright, only the faintest breathing, feet firmly planted, holding the same pose",
                 attack="sweep the spirit brush forward trailing sacred fire",
                 hit="flinch backward from a blow",
                 death="sink down to the ground")),
  "character_jiajiang": dict(src="assets/generated/portraits_v3/jiajiang.png", green=False, igs=2.8, tgs=6.5, neg=HERO_NEG,
    desc="a Taiwanese temple guardian general hero, horned war helmet, painted opera guardian face, red-gold lamellar plate armor, holding a ritual weapon, standing upright facing right",
    actions=dict(idle="stand almost perfectly still upright in armor, only the faintest breathing, feet firmly planted, holding the same pose",
                 attack="swing the armored ritual weapon forward",
                 hit="recoil in armor from a blow",
                 death="fall heavily to the ground")),
}


def _key() -> str:
    k = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if k:
        return k
    f = ROOT / ".env.local"
    if f.exists():
        for ln in f.read_text().splitlines():
            if ln.startswith("PIXELLAB_API_KEY="):
                return ln.split("=", 1)[1].strip()
    sys.exit("缺 PIXELLAB_API_KEY")


def prep_ref(cfg: dict) -> str:
    """清參考圖：去綠草(可選) → alpha 裁邊 → 置中於 64 方框。"""
    im = Image.open(ROOT / cfg["src"]).convert("RGBA")
    a = np.asarray(im).astype(int).copy()
    if cfg["green"]:
        r, g, b = a[..., 0], a[..., 1], a[..., 2]
        a[(g > 70) & (g - r > 25) & (g - b > 25)] = [0, 0, 0, 0]
    im = Image.fromarray(a.astype("uint8"), "RGBA")
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)                       # 裁掉透明邊 → 主體放大
    im.thumbnail((FRAME, FRAME), Image.LANCZOS)
    ref = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    ref.paste(im, ((FRAME - im.width) // 2, (FRAME - im.height) // 2), im)
    buf = BytesIO(); ref.save(buf, "PNG")
    return base64.b64encode(buf.getvalue()).decode()


def animate(actor: str, state: str, key: str) -> bool:
    cfg = ENEMIES[actor]
    payload = {
        "description": cfg["desc"] + ", isolated floating pixel game sprite with nothing beneath it, side view",
        "negative_description": cfg.get("neg",
            "grass, ground, floor, platform, water, pond, scenery, landscape, soil, base, shadow, "
            "chains, smoke, text, watermark, border, frame, "
            "motion lines, speed lines, streaks, swoosh, aura trails, glow trails"),
        "action": cfg["actions"][state],
        "image_size": {"width": FRAME, "height": FRAME},
        "n_frames": NF, "start_frame_index": 0, "view": "side", "direction": "east",
        "text_guidance_scale": cfg.get("tgs", 7.5), "image_guidance_scale": cfg.get("igs", 2.2),
        "reference_image": {"type": "base64", "base64": prep_ref(cfg)},
    }
    req = urllib.request.Request(API, data=json.dumps(payload).encode(),
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"}, method="POST")
    try:
        resp = json.loads(urllib.request.urlopen(req, timeout=600).read())
    except urllib.error.HTTPError as e:
        print(f"  ✗ {actor}/{state}: HTTP {e.code} {e.read().decode('utf-8','ignore')[:160]}")
        return False
    frames = [Image.open(BytesIO(base64.b64decode(i["base64"].split(",")[-1]))).convert("RGBA")
              for i in resp["images"]]
    strip = Image.new("RGBA", (FRAME * len(frames), FRAME), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        strip.paste(f, (i * FRAME, 0))
    out = STAGING / actor / f"{state}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    strip.resize((strip.width * UP, strip.height * UP), Image.NEAREST).save(out)
    print(f"  ✓ {out.relative_to(ROOT)} ({len(frames)} frames)")
    return True


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("用法：pixellab_anim_v2.py <state[,state2]> [actor_id ...]")
    states = sys.argv[1].split(",")
    actors = [a for a in sys.argv[2:]] or list(ENEMIES.keys())
    key = _key()
    n = 0
    for actor in actors:
        for st in states:
            if animate(actor, st, key):
                n += 1
            time.sleep(0.4)
    print(f"完成 {n} 條動畫 → staging {STAGING.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
