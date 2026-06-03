#!/usr/bin/env python3
"""鎮島錄 — 用 PixelLab 重生 4 角色一致性立繪（v4 / 英雄比例版）。

設計目標：風格一致 + 角色一致 + 逼近現有「英雄高瘦 anime」比例（非 chibi）。
做法：
- 風格骨架改寫為 HEROIC_STYLE（8 頭身、athletic、full-length、寫實 anime 像素），
  反向詞明確排除 chibi / 大頭 / 超變形。
- 保留 character_prompt_batch_v1.json 每角的 identity_lock + palette（鎖角色一致性）。
- PixelLab Pixflux 文生圖（≤400px，直幅取全身）→ flood-fill 去背 + 中性灰清理
  → autocrop → 置中於 896×1200 直幅、統一腳底基準線（cohesive）。
- 輸出 staging，**不直接覆蓋** portraits_v3，待人工確認後再 promote。

用法：
    PIXELLAB_API_KEY=... python3 scripts/tools/pixellab_gen_characters_v4.py tongji
    PIXELLAB_API_KEY=... python3 scripts/tools/pixellab_gen_characters_v4.py            # 全 4 角
"""

from __future__ import annotations

import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request
from collections import deque
from io import BytesIO
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
PROMPT_MANIFEST = ROOT / "assets" / "generated" / "pixellab" / "character_prompt_batch_v1.json"
STAGING = ROOT / "assets" / "generated" / "pixellab" / "characters_v4"
API_ROOT = "https://api.pixellab.ai/v1"

GEN_W, GEN_H = 288, 400          # 直幅取全身（PixelLab 上限 400/邊）
CANVAS_W, CANVAS_H = 896, 1200   # 對齊現有 portraits_v3
TARGET_CHAR_H = 1060
FOOT_BASELINE_Y = 1155

# ── 英雄比例風格骨架（取代 manifest 的 "bright chibi"）──
HEROIC_STYLE = (
    "High-resolution HD-2D anime pixel-art character sprite for a Taiwanese folk roguelike "
    "card battler. Tall heroic adult proportions, roughly 8 heads tall, lean athletic "
    "full-length body shown head to toe, dynamic heroic three-quarter combat stance, "
    "detailed handsome anime face with sharp eyes, crisp pixel shading and clean dark "
    "outlines, bold festival-red temple lacquer with incense-gold rim light and small "
    "neon-cyan spirit sparks, strong readable silhouette, cinematic key-art energy, "
    "single centered character, plain flat background, no scene, no text, no UI, no border."
)
HEROIC_NEG = (
    "chibi, super deformed, big head, toddler proportions, cartoon baby, funko, short stubby body, "
    "cute mascot, no western medieval armor, no Japanese shrine maiden drift, no photorealism, "
    "no soft painterly poster, no background scene, no logo, no text, no card frame, no cropped body, "
    "no extra characters, no gore"
)

SAT_BG_MAX = 46
GROW_TOL = 30
BRIGHT_MIN = 95


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
                headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=timeout) as r:
                return json.loads(r.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            raise SystemExit(f"PixelLab HTTP {e.code}: {e.read().decode('utf-8','ignore')}")
        except (TimeoutError, urllib.error.URLError) as e:
            last = e
            wait = 5 * (attempt + 1)
            print(f"  ↻ retry ({e}) wait {wait}s")
            time.sleep(wait)
    raise last


def b64_decode(s: str) -> bytes:
    return base64.b64decode(s.split(",", 1)[1] if "," in s else s)


def _sat(p) -> int:
    return max(p[0], p[1], p[2]) - min(p[0], p[1], p[2])


def remove_bg(img: Image.Image) -> Image.Image:
    """邊界 flood-fill（保留高飽和火焰）+ 中性灰/淡紫全域清理（吃封閉殘留）。"""
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    visited = bytearray(w * h)
    q: deque = deque()

    def is_seed(p) -> bool:
        return _sat(p) <= SAT_BG_MAX and p[3] > 0 and max(p[0], p[1], p[2]) >= BRIGHT_MIN

    for x in range(w):
        for y in (0, h - 1):
            if is_seed(px[x, y]):
                q.append((x, y)); visited[y * w + x] = 1
    for y in range(h):
        for x in (0, w - 1):
            if is_seed(px[x, y]):
                q.append((x, y)); visited[y * w + x] = 1
    while q:
        x, y = q.popleft()
        cr, cg, cb, _ = px[x, y]
        px[x, y] = (cr, cg, cb, 0)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not visited[ny * w + nx]:
                np_ = px[nx, ny]
                if np_[3] == 0:
                    visited[ny * w + nx] = 1
                    continue
                if _sat(np_) <= SAT_BG_MAX + 14 and abs(np_[0]-cr)+abs(np_[1]-cg)+abs(np_[2]-cb) <= GROW_TOL*3:
                    visited[ny * w + nx] = 1
                    q.append((nx, ny))

    # 第二遍：清封閉殘留的中性灰 / 淡紫地影（保護亮白眼、暖膚、彩色火焰）
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            bright = max(r, g, b)
            sat = max(r, g, b) - min(r, g, b)
            neutral = sat <= 30 and 100 <= bright <= 200 and abs(r-g) < 18 and abs(g-b) < 24
            lavender = sat <= 40 and b >= r and b >= g and 120 <= bright <= 210 and (b - min(r, g)) <= 42
            if neutral or lavender:
                px[x, y] = (r, g, b, 0)
    return img


def autocrop(img: Image.Image) -> Image.Image:
    bbox = img.convert("RGBA").getbbox()
    return img.crop(bbox) if bbox else img


def compose_portrait(cut: Image.Image) -> Image.Image:
    cut = autocrop(cut)
    scale = TARGET_CHAR_H / cut.height
    cut = cut.resize((max(1, round(cut.width * scale)), TARGET_CHAR_H), Image.NEAREST)
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    x = (CANVAS_W - cut.width) // 2
    canvas.alpha_composite(cut, (x, max(0, FOOT_BASELINE_Y - cut.height)))
    return canvas


# 個別角色 prompt 覆蓋（manifest 的 identity_lock 不足以帶出概念時）
DESC_OVERRIDES = {
    # 八家將：強化「盔甲武將 + 角盔 + 凶面臉譜」，避免變成紅袍法師
    "jiajiang": (
        HEROIC_STYLE + " Character: 八家將 (Bajiajiang temple guardian general), a fierce Taiwanese "
        "temple martial guardian deity. Ornate horned war helmet, bold painted demon-warrior opera "
        "face paint, layered festival-red and incense-gold lamellar plate armor with heavy chest "
        "guard, shoulder pauldrons and armored war skirt, muscular imposing build, wide martial "
        "guardian stance, gripping a ritual guardian weapon. Identity lock: horned war helmet, "
        "painted guardian opera face, red-gold lamellar armor with chest guard and pauldrons, "
        "martial general stance. Palette: festival red, incense gold, deep black lacquer, small cyan spirit sparks."
    ),
}


def build_description(actor: dict) -> str:
    key = actor.get("id", "").replace("character_", "")
    if key in DESC_OVERRIDES:
        return DESC_OVERRIDES[key]
    name = actor.get("name", "")
    english = actor.get("english", "")
    identity = actor.get("identity_lock", "")
    palette = actor.get("palette", "")
    return (f"{HEROIC_STYLE} Character: {name} ({english}), a Taiwanese temple spirit warrior. "
            f"Identity lock: {identity}. Palette: {palette}.")


def load_actors() -> dict:
    spec = json.loads(PROMPT_MANIFEST.read_text(encoding="utf-8"))
    return {a["id"].replace("character_", ""): a for a in spec["actors"]}


def gen_one(key: str, actor: dict, api_key: str) -> None:
    STAGING.mkdir(parents=True, exist_ok=True)
    payload = {
        "description": build_description(actor),
        "negative_description": HEROIC_NEG,
        "image_size": {"width": GEN_W, "height": GEN_H},
        "text_guidance_scale": 7.5,
        "no_background": True,
    }
    print(f"[{key}] generating heroic ({GEN_W}x{GEN_H}) …")
    resp = post("/generate-image-pixflux", payload, api_key)
    png = b64_decode(resp["image"]["base64"])
    (STAGING / f"{key}_raw.png").write_bytes(png)
    cut = autocrop(remove_bg(Image.open(BytesIO(png))))
    cut.save(STAGING / f"{key}_cut.png", "PNG")
    portrait = compose_portrait(cut)
    portrait.save(STAGING / f"{key}.png", "PNG")
    print(f"  ✓ {key}.png ({portrait.size[0]}x{portrait.size[1]})")


def main() -> None:
    api_key = get_api_key()
    actors = load_actors()
    targets = sys.argv[1:] or list(actors.keys())
    for key in targets:
        if key not in actors:
            print(f"!! 未知角色 {key}（可用：{', '.join(actors)}）")
            continue
        gen_one(key, actors[key], api_key)


if __name__ == "__main__":
    main()
