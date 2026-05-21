#!/usr/bin/env python3
"""批次生 3 章節背景 via NBP（act1 山/act2 海/act3 陰間）。"""
import subprocess
from pathlib import Path
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "assets/generated/scenes_v3"
OUT_DIR.mkdir(parents=True, exist_ok=True)
GEN = str(REPO / "scripts/tools/nbp_gen.py")

STYLE = (
    "Refined HD pixel art Taiwanese game scene background widescreen, "
    "dense fine pixel work like Sea of Stars Octopath Traveler scene quality, "
    "sharp pixel boundaries multiple shading levels rich color depth, "
    "central area kept clear for placing combatants and UI, no people no text"
)

ACTS = [
    ("act1_mountain_temple",
     "Taiwanese mountain temple courtyard at golden hour, "
     "warm sunset over green forested mountains in distance, "
     "small Chinese temple with red eaves and stone path, "
     "lush bamboo groves and pine trees on edges, "
     "red lanterns hanging, atmospheric warm glow, festive cheerful"),
    ("act2_water_temple",
     "Taiwanese coastal seaside temple at dramatic blue twilight, "
     "ornate Mazu sea goddess temple overlooking ocean waves crashing on rocks, "
     "white seagulls flying, lighthouse in distance, "
     "blue water reflections, fishermen boats on horizon, "
     "atmospheric salt mist, cool oceanic palette with red temple accents, mystical seafaring"),
    ("act3_evil_underworld",
     "Taiwanese underworld ghost city diyu at eerie night, "
     "ornate ghost temple with green flames and dark purple lanterns, "
     "ghostly mist swirling, stone bridges over black river styx, "
     "twisted ancient banyan trees with hanging red ribbons, "
     "moonlight, dark crimson black and ghost green palette, ominous supernatural atmosphere"),
]


def main():
    for sid, subj in ACTS:
        out = OUT_DIR / f"{sid}.png"
        if out.exists():
            print(f"SKIP {sid}")
            continue
        prompt = f"{STYLE}. {subj}."
        print(f"GEN {sid}...")
        try:
            subprocess.run([
                "python3", GEN, prompt,
                "--out", str(out.relative_to(REPO)),
                "--aspect", "16:9",
            ], cwd=str(REPO), check=True)
            img = Image.open(out).convert("RGBA")
            img.save(out, "PNG")
        except Exception as e:
            print(f"  ERR: {e}")
    print(f"\nDone. {len(ACTS)} acts in {OUT_DIR}")


if __name__ == "__main__":
    main()
