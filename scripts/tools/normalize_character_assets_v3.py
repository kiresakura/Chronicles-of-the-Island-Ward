from __future__ import annotations

"""把角色候選圖重排成一致構圖的遊戲素材。

目標不是再把不一致的圖硬塞進畫面，而是統一：
- 相同畫布比例
- 相同腳底 baseline
- 相同角色視覺高度
- 相同像素化 / 色階 / 外框處理
- 相同地面陰影與金邊輪廓語言
"""

from pathlib import Path
from typing import Any
import json
import shutil
import time

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "assets/generated/recraft/character_previews_v2/cutouts"
OUT_DIR = ROOT / "assets/generated/character_cohesive_v3"
PREVIEW_DIR = OUT_DIR / "preview"
BACKUP_ROOT = ROOT / "assets/generated/_backup_before_character_replace"

ROLE_SOURCE = {
    "tongji": "tongji_a_cutout.png",
    "luannu": "luannu_b_cutout.png",
    "daoshi": "daoshi_a_cutout.png",
    "jiajiang": "jiajiang_b_cutout.png",
}

# 每個角色的視覺權重不同。用 scale_bias 校正，避免家將壓滿、鸞女漂小。
SCALE_BIAS = {
    "tongji": 0.95,
    "luannu": 0.98,
    "daoshi": 0.96,
    "jiajiang": 0.92,
}

X_BIAS = {
    "tongji": -0.02,
    "luannu": 0.00,
    "daoshi": 0.01,
    "jiajiang": 0.01,
}

CARD_SIZE = (1024, 1365)
PORTRAIT_SIZE = (896, 1200)
ANIM_FRAME_SIZE = (512, 512)
CARD_CHARACTER_HEIGHT = 1020
PORTRAIT_CHARACTER_HEIGHT = 900
ANIM_CHARACTER_HEIGHT = 410


def ensure_dirs() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)


def load_rgba(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def remove_obvious_generated_backdrops(img: Image.Image, role: str) -> Image.Image:
    """移除候選圖裡破壞一致性的紙圈、印章、地面碎塊。

    這是美術後製，不是魔法。保守處理，只清掉明顯背景色與邊角雜訊。
    """
    rgba = img.copy()
    px = rgba.load()
    width, height = rgba.size

    for y in range(height):
        for x in range(width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            mx = max(r, g, b)
            mn = min(r, g, b)
            sat = 0 if mx == 0 else (mx - mn) / mx
            bright = (r + g + b) / 3

            kill = False

            # 鸞女背後的大米色圓盤；保留皮膚與金飾，殺低飽和高亮背景。
            if role == "luannu":
                if bright > 205 and sat < 0.24:
                    kill = True
                # 底部棕灰地面筆觸。
                if y > height * 0.78 and bright < 150 and sat < 0.22:
                    kill = True

            # 道士右下角印章、底部灰線與部分符印外圈，避免像另一套素材。
            if role == "daoshi":
                if x > width * 0.78 and y > height * 0.70 and r > 130 and g < 120 and b < 120:
                    kill = True
                if y > height * 0.90 and bright > 145 and sat < 0.25:
                    kill = True

            # 乩童、家將底部地面塊與背景粒子，統一改成我們自己的陰影。
            if role in {"tongji", "jiajiang"}:
                if y > height * 0.78 and bright < 120 and sat < 0.22:
                    kill = True
                if role == "jiajiang" and bright > 190 and sat < 0.28:
                    kill = True

            if kill:
                px[x, y] = (r, g, b, 0)

    return rgba


def alpha_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    alpha = img.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return (0, 0, img.width, img.height)
    return bbox


def trim_alpha(img: Image.Image, padding: int = 8) -> Image.Image:
    left, top, right, bottom = alpha_bbox(img)
    left = max(0, left - padding)
    top = max(0, top - padding)
    right = min(img.width, right + padding)
    bottom = min(img.height, bottom + padding)
    return img.crop((left, top, right, bottom))


def pixel_unify(img: Image.Image) -> Image.Image:
    """統一像素密度與色階。透明 alpha 獨立處理，避免鋸齒髒邊。"""
    rgb = img.convert("RGB")
    alpha = img.getchannel("A")

    rgb = ImageEnhance.Color(rgb).enhance(1.18)
    rgb = ImageEnhance.Contrast(rgb).enhance(1.12)
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.35)
    rgb = ImageOps.posterize(rgb, 5)

    # 先縮後放，讓四人像素顆粒一致。尺寸不是越大越美；不一致才醜。
    small_size = (max(1, img.width // 3), max(1, img.height // 3))
    rgb = rgb.resize(small_size, Image.Resampling.NEAREST).resize(img.size, Image.Resampling.NEAREST)
    alpha = alpha.resize(small_size, Image.Resampling.NEAREST).resize(img.size, Image.Resampling.NEAREST)

    # 自適應量化，四人同一種 16-bit game-unit 感。
    rgba = Image.merge("RGBA", (*rgb.split(), alpha))
    return rgba


def add_common_outline(img: Image.Image) -> Image.Image:
    alpha = img.getchannel("A")
    outer = alpha.filter(ImageFilter.MaxFilter(9))
    mid = alpha.filter(ImageFilter.MaxFilter(5))
    outer_only = ImageChops.subtract(outer, alpha)
    mid_only = ImageChops.subtract(mid, alpha)

    canvas = Image.new("RGBA", img.size, (0, 0, 0, 0))
    canvas.paste(Image.new("RGBA", img.size, (37, 12, 10, 255)), (0, 0), outer_only)
    canvas.paste(Image.new("RGBA", img.size, (221, 160, 55, 210)), (0, 0), mid_only)
    canvas.alpha_composite(img)
    return canvas


def make_character_base(role: str) -> Image.Image:
    source = load_rgba(SOURCE_DIR / ROLE_SOURCE[role])
    cleaned = remove_obvious_generated_backdrops(source, role)
    trimmed = trim_alpha(cleaned, 12)
    unified = pixel_unify(trimmed)
    return add_common_outline(unified)


def compose_on_canvas(
    char_img: Image.Image,
    role: str,
    size: tuple[int, int],
    target_height: int,
    baseline_ratio: float,
    include_shadow: bool = True,
) -> Image.Image:
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    bbox = alpha_bbox(char_img)
    char = char_img.crop(bbox)
    scale = target_height * SCALE_BIAS[role] / char.height
    new_size = (max(1, round(char.width * scale)), max(1, round(char.height * scale)))
    char = char.resize(new_size, Image.Resampling.NEAREST)

    baseline = int(size[1] * baseline_ratio)
    x = int(size[0] * (0.5 + X_BIAS[role]) - char.width / 2)
    y = baseline - char.height

    if include_shadow:
        shadow = Image.new("RGBA", size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(shadow)
        cx = size[0] // 2
        shadow_w = int(char.width * 0.62)
        shadow_h = max(18, int(shadow_w * 0.16))
        draw.ellipse(
            (
                cx - shadow_w // 2,
                baseline - shadow_h // 2,
                cx + shadow_w // 2,
                baseline + shadow_h // 2,
            ),
            fill=(18, 7, 6, 88),
        )
        canvas.alpha_composite(shadow)

    canvas.alpha_composite(char, (x, y))
    return canvas


def make_anim_sheet(frame: Image.Image) -> Image.Image:
    sheet = Image.new("RGBA", (ANIM_FRAME_SIZE[0] * 4, ANIM_FRAME_SIZE[1]), (0, 0, 0, 0))
    for idx in range(4):
        sheet.alpha_composite(frame, (idx * ANIM_FRAME_SIZE[0], 0))
    return sheet


def backup(path: Path, backup_dir: Path) -> None:
    if not path.exists():
        return
    dest = backup_dir / path.relative_to(ROOT)
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not dest.exists():
        shutil.copy2(path, dest)


def write_png(path: Path, img: Image.Image, backup_dir: Path | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if backup_dir is not None:
        backup(path, backup_dir)
    img.save(path)


def build_preview(cards: dict[str, Image.Image], portraits: dict[str, Image.Image]) -> None:
    role_order = ["tongji", "luannu", "daoshi", "jiajiang"]
    card_thumbs = [cards[r].resize((220, 293), Image.Resampling.NEAREST) for r in role_order]
    portrait_thumbs = [portraits[r].resize((224, 300), Image.Resampling.NEAREST) for r in role_order]

    row1 = Image.new("RGBA", (220 * 4, 293), (0, 0, 0, 0))
    row2 = Image.new("RGBA", (224 * 4, 300), (0, 0, 0, 0))
    for i, img in enumerate(card_thumbs):
        row1.alpha_composite(img, (i * 220, 0))
    for i, img in enumerate(portrait_thumbs):
        row2.alpha_composite(img, (i * 224, 0))

    bg = Image.new("RGBA", (896, 653), (32, 17, 13, 255))
    bg.alpha_composite(row1, (18, 20))
    bg.alpha_composite(row2, (0, 333))
    bg.save(PREVIEW_DIR / "character_assets_cohesive_v3_preview.png")


def main() -> None:
    ensure_dirs()
    timestamp = time.strftime("%Y%m%d-%H%M%S")
    backup_dir = BACKUP_ROOT / f"cohesive-v3-{timestamp}"
    backup_dir.mkdir(parents=True, exist_ok=True)

    cards: dict[str, Image.Image] = {}
    portraits: dict[str, Image.Image] = {}
    manifest: dict[str, Any] = {
        "version": "3.0.0",
        "timestamp": timestamp,
        "backup_dir": str(backup_dir.relative_to(ROOT)),
        "design_rule": "same canvas, same foot baseline, same target height, same pixel density, same outline, same shadow",
        "roles": {},
    }

    states = ["idle", "alert", "cast", "hit", "death", "victory"]
    combat_states = ["idle", "attack", "defend", "hit", "death"]

    for role in ROLE_SOURCE:
        base = make_character_base(role)
        card = compose_on_canvas(base, role, CARD_SIZE, CARD_CHARACTER_HEIGHT, 0.92)
        portrait = compose_on_canvas(base, role, PORTRAIT_SIZE, PORTRAIT_CHARACTER_HEIGHT, 0.92)
        anim_frame = compose_on_canvas(base, role, ANIM_FRAME_SIZE, ANIM_CHARACTER_HEIGHT, 0.88)
        cards[role] = card
        portraits[role] = portrait

        role_targets: list[str] = []

        # Active chains.
        targets = [
            (ROOT / f"assets/generated/portraits_v3/{role}.png", portrait),
            (ROOT / f"assets/generated/characters_v2/{role}_card.png", card),
            (ROOT / f"assets/generated/characters_v2/{role}_standee.png", card),
        ]
        for state in states:
            targets.append((ROOT / f"assets/generated/characters_v2/{role}_anim_{state}.png", card))
        for path, img in targets:
            write_png(path, img, backup_dir)
            role_targets.append(str(path.relative_to(ROOT)))

        # Combat sheets.
        sheet = make_anim_sheet(anim_frame)
        anim_dir = ROOT / f"assets/generated/pixellab/anim/character_{role}"
        for state in combat_states:
            path = anim_dir / f"{state}.png"
            write_png(path, sheet, backup_dir)
            role_targets.append(str(path.relative_to(ROOT)))

        # Mascot fallbacks for currently selectable mascot roles.
        if role in {"tongji", "luannu"}:
            mascot = compose_on_canvas(base, role, (1024, 1536), 1370, 0.96)
            path = ROOT / f"assets/generated/pixellab/mascot_{role}_bust_v2.png"
            write_png(path, mascot, backup_dir)
            role_targets.append(str(path.relative_to(ROOT)))

        # Keep cohesive source outputs too.
        write_png(OUT_DIR / f"{role}_base.png", base)
        write_png(OUT_DIR / f"{role}_card.png", card)
        write_png(OUT_DIR / f"{role}_portrait.png", portrait)
        write_png(OUT_DIR / f"{role}_combat_sheet.png", sheet)

        manifest["roles"][role] = {
            "source": str((SOURCE_DIR / ROLE_SOURCE[role]).relative_to(ROOT)),
            "targets": role_targets,
        }

    build_preview(cards, portraits)
    (OUT_DIR / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(manifest, ensure_ascii=False, indent=2))
    print(PREVIEW_DIR / "character_assets_cohesive_v3_preview.png")


if __name__ == "__main__":
    main()
