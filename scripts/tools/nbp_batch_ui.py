#!/usr/bin/env python3
"""批次生 UI 元件 + 新 splash hero via NBP。"""
import subprocess
from pathlib import Path
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "assets/generated/ui_v3"
OUT_DIR.mkdir(parents=True, exist_ok=True)
GEN = str(REPO / "scripts/tools/nbp_gen.py")

# UI 元件用 transparent / centered prompt
STYLE_UI = ("Refined HD pixel art Taiwanese temple ornate UI element, "
            "sharp pixel edges multiple shading levels like Sea of Stars Octopath Traveler UI quality, "
            "vibrant red gold amber palette, centered isolated single element on transparent background, "
            "no text inside")

UI_ELEMENTS = [
    # (filename, aspect, subject)
    ("cta_button_frame", "16:9",
     "Wide horizontal Chinese temple wooden plaque button for CTA call to action, "
     "red lacquered wooden background with thick golden carved filigree frame, "
     "two small golden dragon ornaments on left and right ends, golden ribbon banner top, "
     "empty central recessed area for button text, premium mobile game CTA button frame"),
    ("slot_frame", "1:1",
     "Square Chinese temple wooden tile slot frame for utility buttons, "
     "dark red lacquered wood with golden filigree carved border, "
     "small golden cloud ornaments on four corners, "
     "deep red recessed center area for icon placement, "
     "premium mobile game utility slot frame"),
    ("title_plaque", "21:9",
     "Horizontal Chinese temple wooden plaque banner for game title display, "
     "ornate red lacquered wooden board with thick golden carved frame, "
     "golden dragon coiled ornaments on top corners, "
     "golden cloud filigree on top crest, cream beige inner panel for title text placement, "
     "two red string tassels hanging from bottom corners, "
     "premium mobile game title banner plaque"),
]

SPLASH_PROMPT = (
    "Refined HD pixel art Taiwanese temple game loading screen hero scene, "
    "ornate red lacquered shrine altar in center with carved gold filigree, "
    "glowing golden spirit tablet floating with sacred aura, "
    "three lit incense sticks rising curling smoke wisps upward, "
    "two tall red ceremonial candles with golden bases flickering flames flanking altar, "
    "brass cauldron incense burner with handles, "
    "warm crimson amber gold palette with rich shading, "
    "atmospheric warm glow throughout, "
    "dense fine HD-2D pixel work Sea of Stars quality, sharp pixel boundaries multiple shading levels, "
    "festive sacred atmosphere, "
    "empty top quarter for game logo and empty bottom quarter for loading bar UI, "
    "no text no people, widescreen"
)


def main() -> None:
    for fname, aspect, subj in UI_ELEMENTS:
        out = OUT_DIR / f"{fname}.png"
        if out.exists():
            print(f"SKIP exists: {out.name}")
            continue
        prompt = f"{STYLE_UI}. {subj}."
        print(f"GEN {fname}...")
        subprocess.run([
            "python3", GEN, prompt,
            "--out", str(out.relative_to(REPO)),
            "--aspect", aspect,
        ], cwd=str(REPO), check=True)
        try:
            img = Image.open(out).convert("RGBA")
            img.save(out, "PNG")
        except Exception as e:
            print(f"  convert err: {e}")

    # New splash hero
    splash_out = REPO / "assets/generated/mainmenu_v2/splash_bg.png"
    print("GEN splash_bg_v3...")
    subprocess.run([
        "python3", GEN, SPLASH_PROMPT,
        "--out", str(splash_out.relative_to(REPO)),
        "--aspect", "16:9",
    ], cwd=str(REPO), check=True)
    try:
        img = Image.open(splash_out).convert("RGBA")
        img.save(splash_out, "PNG")
    except Exception as e:
        print(f"  convert err: {e}")

    print(f"\nDone.")


if __name__ == "__main__":
    main()
