#!/usr/bin/env python3
"""批次生 6 敵人 sprite via Nano Banana Pro。"""
import subprocess
from pathlib import Path
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "assets/generated/enemies_v3"
OUT_DIR.mkdir(parents=True, exist_ok=True)
GEN = str(REPO / "scripts/tools/nbp_gen.py")

STYLE = ("Refined HD pixel art Taiwanese folk religion creature enemy sprite, "
         "isolated single creature on simple dark background or transparent, "
         "sharp pixel edges multiple shading levels like Sea of Stars Octopath Traveler "
         "enemy sprite quality, sharp clean pixel boundaries, vibrant atmospheric colors, "
         "front-facing battle stance ready to fight, no text")

ENEMIES = [
    ("enemy_mountain_boar",
     "fierce Taiwanese mountain boar spirit Shanzhu Jing, large wild boar with red eyes glowing, "
     "two huge curved tusks, dark brown bristly fur with tribal red markings on flanks, "
     "muddy hooves, snarling expression with foam at mouth, supernatural aura"),
    ("enemy_lost_soul",
     "Taiwanese lost soul wandering ghost wanghun, pale translucent pale-blue female ghost with long flowing black hair "
     "covering face, white burial robe trailing into mist, no feet visible, hands reaching forward "
     "with elongated fingers, mournful eerie expression, ghostly aura"),
    ("enemy_white_snake",
     "Taiwanese white snake spirit Baishe, large pearlescent white serpent coiled and rearing up, "
     "red eyes with vertical pupils, golden flame patterns along scales, forked tongue extended, "
     "human female face above snake body, mystical aura"),
    ("enemy_tiger_god",
     "Taiwanese tiger god Huye sacred temple guardian, fierce orange tiger with golden stripes, "
     "wearing red sash and brass bell collar, divine flame patterns around head, "
     "bared fangs and roaring expression, sacred guardian aura"),
    ("enemy_tree_spirit",
     "ancient Taiwanese tree spirit Shujing, gnarled banyan tree with humanoid face in the trunk, "
     "twisting branches as arms holding flaming spirit lanterns, red eyes glowing from bark, "
     "hanging vines and red prayer ribbons tied to limbs, mystic aura"),
    ("enemy_chair_girl",
     "Taiwanese folk spirit Yi-zai Gu chair girl ghost, dark wooden ceremonial child chair "
     "with ghostly girl spirit perched on top, white face powder long black hair red ribbon, "
     "small white dress, holding paper doll, eerie playful expression"),
]


def main() -> None:
    for eid, subj in ENEMIES:
        out = OUT_DIR / f"{eid}.png"
        if out.exists():
            print(f"SKIP exists: {out.name}")
            continue
        prompt = f"{STYLE}. {subj}."
        print(f"GEN {eid}...")
        subprocess.run([
            "python3", GEN, prompt,
            "--out", str(out.relative_to(REPO)),
            "--aspect", "1:1",
        ], cwd=str(REPO), check=True)
        try:
            img = Image.open(out).convert("RGBA")
            img.save(out, "PNG")
        except Exception as e:
            print(f"  convert err: {e}")
    print(f"\nDone. {len(ENEMIES)} enemies in {OUT_DIR}")


if __name__ == "__main__":
    main()
