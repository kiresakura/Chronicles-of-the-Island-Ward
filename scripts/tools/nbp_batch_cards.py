#!/usr/bin/env python3
"""批次生 11 乩童卡圖 via Nano Banana Pro。"""
import subprocess
from pathlib import Path
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "assets/generated/cards_v3"
OUT_DIR.mkdir(parents=True, exist_ok=True)
GEN = str(REPO / "scripts/tools/nbp_gen.py")

STYLE = ("Refined HD pixel art Taiwanese folk religion game card art, "
         "sharp pixel edges multiple shading levels like Sea of Stars or "
         "Octopath Traveler card art, vibrant warm red gold amber palette, "
         "central focal subject, transparent or simple dark background, "
         "no text no characters baked in, mobile card game art")

CARDS = [
    ("card_tongji_charge",
     "Tongji spirit medium warrior raising lacquered red prajna sword high above head with divine golden aura blazing around him, war banners trailing, action attack stance, charging into battle pose"),
    ("card_tongji_double_strike",
     "Two crossed strikes blurring with motion lines, tongji warrior delivering twin fist punches with red sparks of impact, dynamic action pose"),
    ("card_tongji_draw_charm",
     "Glowing yellow paper talismans with red ink calligraphy flying toward viewer, hand reaching out to grasp them, mystical golden light radiating"),
    ("card_tongji_evil_curse",
     "Dark cursed seal with black smoke tendrils and red eyes glowing inside, ominous skull motif at center, dripping curse magic"),
    ("card_tongji_exorcise",
     "Tongji warrior blasting away a ghost spirit with bright white sacred flame from sword, ghost dissipating into wisps, exorcism scene"),
    ("card_tongji_fury_strike",
     "Tongji warrior in rage with bloody forehead from ritual self-mutilation, raising huge fist to strike, red blood splatter and rage aura"),
    ("card_tongji_great_talisman",
     "Massive yellow paper fu talisman with red ink seal hovering protectively in front, glowing golden barrier dome around it, defensive ward"),
    ("card_tongji_heavy_strike",
     "Tongji warrior bringing down massive stone hammer with both hands, ground cracking with red shockwave lines, devastating impact pose"),
    ("card_tongji_possession",
     "Tongji warrior in spiritual trance with eyes rolled back showing white, divine spirit entering through head as golden light beam from above, sacred possession ritual"),
    ("card_tongji_punch",
     "Tongji warrior throwing direct punch toward viewer with red headband and bandaged fist, motion lines, simple basic attack pose"),
    ("card_tongji_talisman",
     "Single yellow paper fu talisman with red ink Chinese strokes floating in air, gentle golden glow protective aura around it"),
]


def main() -> None:
    for cid, subj in CARDS:
        out = OUT_DIR / f"{cid}.png"
        if out.exists():
            print(f"SKIP exists: {out.name}")
            continue
        prompt = f"{STYLE}. {subj}."
        print(f"GEN {cid}...")
        subprocess.run([
            "python3", GEN, prompt,
            "--out", str(out.relative_to(REPO)),
            "--aspect", "1:1",
        ], cwd=str(REPO), check=True)
        # NBP returns JPEG with .png ext → convert
        try:
            img = Image.open(out).convert("RGBA")
            img.save(out, "PNG")
        except Exception as e:
            print(f"  convert err: {e}")
    print(f"\nDone. {len(CARDS)} cards in {OUT_DIR}")


if __name__ == "__main__":
    main()
