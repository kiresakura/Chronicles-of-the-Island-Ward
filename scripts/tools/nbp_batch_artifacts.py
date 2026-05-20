#!/usr/bin/env python3
"""批次生 15 遺物/法器 portraits via Nano Banana Pro。"""
import subprocess
from pathlib import Path
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "assets/generated/artifacts_v3"
OUT_DIR.mkdir(parents=True, exist_ok=True)
GEN = str(REPO / "scripts/tools/nbp_gen.py")

STYLE = ("Refined HD pixel art Taiwanese folk religion artifact item icon, "
         "isolated centered single object on dark crimson temple background, "
         "sharp pixel edges multiple shading levels like Sea of Stars Octopath Traveler item sprite quality, "
         "vibrant warm red gold amber palette with rich color depth, "
         "subtle divine aura glow around item, premium mobile game artifact icon, no text")

ARTIFACTS = [
    ("artifact_tongji_amulet",
     "Taiwanese paper talisman amulet ping-an-fu, single yellow rectangular paper with red ink calligraphy strokes, "
     "tied with red string at top, fringed bottom edge, gentle golden glow aura"),
    ("artifact_incense_burner",
     "small bronze Chinese incense burner cauldron with three smoking incense sticks rising curling smoke, "
     "ornate carved dragon handles on sides, glowing amber base"),
    ("artifact_red_string",
     "red sacred Buddhist string bracelet with small gold bell and lotus charm, "
     "knotted with auspicious patterns, gentle red glow"),
    ("artifact_temple_drum",
     "small Taiwanese temple ceremony drum tang-gu in red lacquered wood with gold studs around rim, "
     "small wooden drumstick beside it, gold dragon design on drum face"),
    ("artifact_tiger_token",
     "small wooden tiger spirit token with carved tiger face in vibrant orange and black stripes, "
     "Chinese character carved into back, hanging red string with tassel"),
    ("artifact_add_money",
     "wealth fu charm folded paper amulet with gold coin embedded in center, "
     "red Chinese prosperity character ink calligraphy on yellow paper, glowing gold aura"),
    ("artifact_block_on_attacks",
     "small bronze defensive shield medallion with carved bagua eight trigrams pattern, "
     "red silk ribbon wrapped around it"),
    ("artifact_draw_on_combat_start",
     "yellow paper invocation fu charm with stylized red Chinese summoning script, "
     "fluttering with motion lines as if drawing in cards, golden aura"),
    ("artifact_draw_on_kill",
     "demon-slayer talisman in dark crimson paper with bold black ink calligraphy, "
     "two crossed swords carved on it, drips of dark blood on edges"),
    ("artifact_full_heal",
     "small jade vase containing glowing liquid healing elixir, "
     "carved with peach immortality symbols, soft healing green light"),
    ("artifact_heal_on_combat_ended",
     "small bronze healing herb pouch with embroidered red Chinese health character, "
     "small green herb sprigs poking out top"),
    ("artifact_increase_attack_on_rest",
     "iron training weight with carved tiger face, "
     "wrapped in red ceremonial cloth, golden bell hanging from chain"),
    ("artifact_retain_hand",
     "small jade hand-shaped charm carved with intricate finger details, "
     "red silk cord through wrist hole, gentle blue aura"),
    ("artifact_right_click_shuffle_deck",
     "ancient Chinese fortune-telling bamboo container with bamboo sticks fanning out, "
     "wrapped in red cloth, golden Chinese fortune characters carved on container"),
    ("artifact_see_top_of_draw_pile",
     "small jade eye-shaped amulet with carved iris and pupil details, "
     "all-seeing third eye motif, surrounded by golden divination markings"),
]


def main() -> None:
    for aid, subj in ARTIFACTS:
        out = OUT_DIR / f"{aid}.png"
        if out.exists():
            print(f"SKIP exists: {out.name}")
            continue
        prompt = f"{STYLE}. {subj}."
        print(f"GEN {aid}...")
        try:
            subprocess.run([
                "python3", GEN, prompt,
                "--out", str(out.relative_to(REPO)),
                "--aspect", "1:1",
            ], cwd=str(REPO), check=True)
            img = Image.open(out).convert("RGBA")
            img.save(out, "PNG")
        except Exception as e:
            print(f"  ERR: {e}")
    print(f"\nDone. {len(ARTIFACTS)} artifacts in {OUT_DIR}")


if __name__ == "__main__":
    main()
