#!/usr/bin/env python3
"""批次生 8 家將 + 6 神明立繪 + 技能特效 + 卡背 via NBP。"""
import subprocess
from pathlib import Path
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
GEN = str(REPO / "scripts/tools/nbp_gen.py")

# ===== 8 家將 =====
JIAJIANG_DIR = REPO / "assets/generated/jiajiang_v3"
JIAJIANG_DIR.mkdir(parents=True, exist_ok=True)
JIAJIANG_STYLE = (
    "Refined HD pixel art Taiwanese bajiajiang temple guardian general individual portrait, "
    "fierce muscular Asian male warrior with intricate painted face mask Taiwanese opera makeup, "
    "ornate headpiece, holding signature weapon, intricate armor robes with embroidered patterns, "
    "isolated full body standing on transparent background, "
    "sharp pixel edges multiple shading levels like Sea of Stars Octopath Traveler character sprite quality, "
    "vibrant warm palette, intimidating heroic stance, mobile game character portrait"
)
JIAJIANG = [
    ("gan_general",
     "甘將軍 General Gan with red and black face paint asymmetric pattern, "
     "high topknot headpiece with red feathers, holding curved sabre and ceremonial flag, "
     "red and gold armor with tiger insignia"),
    ("liu_general",
     "柳將軍 General Liu with green and black face paint with willow leaf patterns, "
     "scholarly hat with green ribbons, holding spear and signal banner, "
     "green and silver armor with willow embroidery"),
    ("xie_general",
     "謝將軍 General Xie tall white-faced ghost general elongated face with red tongue protruding, "
     "tall conical hat with white ribbons, holding wooden staff with iron chains, "
     "white and black mourning robes with red sash, otherworldly aura"),
    ("fan_general",
     "范將軍 General Fan short black-faced ghost general squat muscular figure with bulging eyes, "
     "wide-brimmed bamboo hat, holding paper fan and small wooden tablet, "
     "dark blue and black robes with white funerary trim"),
    ("spring_god",
     "春神 Spring God seasonal general with pink cherry blossom face paint, "
     "flowery headdress with peach blossoms, holding budding branch and bronze bell, "
     "pink and green silk robes with floral embroidery, gentle elegance"),
    ("summer_god",
     "夏神 Summer God seasonal general with red sun face paint, "
     "headdress with red ribbons and gold sun motif, holding flaming torch and lotus, "
     "red and orange robes with fire patterns, warm vibrant energy"),
    ("autumn_god",
     "秋神 Autumn God seasonal general with golden maple leaf face paint, "
     "headdress with golden maple leaves, holding sickle and harvest grain bundle, "
     "amber and brown robes with maple patterns, harvest abundance feel"),
    ("winter_god",
     "冬神 Winter God seasonal general with pale blue snowflake face paint, "
     "headdress with white feathers and silver snowflakes, holding ice scepter and plum branch, "
     "blue and white robes with snow patterns, cold serene presence"),
]

# ===== 6 神明立繪 =====
DEITY_DIR = REPO / "assets/generated/deities_v3"
DEITY_DIR.mkdir(parents=True, exist_ok=True)
DEITY_STYLE = (
    "Refined HD pixel art Taiwanese folk deity full body portrait standing pose, "
    "divine aura surrounding figure, isolated transparent background, "
    "sharp pixel edges multiple shading levels like Sea of Stars Octopath Traveler character quality, "
    "rich color depth, sacred majestic atmosphere, mobile game character art"
)
DEITIES = [
    ("mazu",
     "媽祖 Tianhou Mazu sea goddess gentle compassionate face, "
     "ornate pearl crown with hanging tassels, blue and gold imperial robes with phoenix embroidery, "
     "holding white pearl in one hand and golden seal in other, "
     "blue cyan divine aura with waves at feet"),
    ("guanyin",
     "觀音 Guanyin Bodhisattva of compassion seated on lotus throne, "
     "white silk robes flowing, gentle female face with serene closed-eye smile, "
     "holding willow branch and water vase, "
     "white jade aura with lotus petals floating"),
    ("wangye",
     "王爺 Wang Ye imperial inspector deity stern bearded face, "
     "ornate dragon imperial crown, gold and purple imperial dragon robes, "
     "holding ceremonial baton and sword of justice, "
     "purple mystic aura with paper money fluttering"),
    ("chenghuang",
     "城隍 Cheng Huang city god magistrate with stern judging face, "
     "black scholar gauze hat with golden trim, dark blue and gold magistrate robes, "
     "holding abacus and judgment book, "
     "dark blue aura with ghostly chains"),
    ("tudi",
     "土地公 Tudigong earth god kind elderly grandfather smiling warmly, "
     "black gauze hat with golden trim, earthy brown robes with longevity symbols, "
     "holding wooden walking cane and gold ingot, "
     "warm golden aura with auspicious clouds"),
    ("huye",
     "虎爺 Hu Ye Tiger God sacred temple guardian beast, "
     "fierce orange tiger standing on hind legs in protective stance, "
     "wearing brass bell collar and red sash, divine flame markings on stripes, "
     "red and gold aura"),
]

# ===== 技能特效 sprite =====
FX_DIR = REPO / "assets/generated/fx_v3"
FX_DIR.mkdir(parents=True, exist_ok=True)
FX_STYLE = (
    "Refined HD pixel art skill visual effect FX sprite, "
    "isolated effect on transparent or solid dark background, "
    "sharp pixel edges multiple shading levels, dynamic action visual, "
    "vibrant glowing colors, mobile game effect overlay, no characters no text"
)
FX = [
    ("fx_slash_red",
     "diagonal red slash arc with golden sparks and motion lines, sword strike effect"),
    ("fx_holy_burst",
     "golden circular holy burst with radiating light rays and white sparkles, divine blessing"),
    ("fx_heal_green",
     "green healing particles spiraling upward with white plus crosses, restoration effect"),
    ("fx_curse_black",
     "black tendrils with purple smoke wisps and red eyes appearing within, curse application"),
    ("fx_lightning",
     "vibrant white-blue lightning bolt with crackling electricity sparks"),
    ("fx_shield",
     "translucent golden octagonal bagua shield bubble with light reflections, protective barrier"),
]

# ===== 卡背 =====
CARDBACK_DIR = REPO / "assets/generated/card_backs_v3"
CARDBACK_DIR.mkdir(parents=True, exist_ok=True)
CARDBACK = [
    ("card_back_tongji",
     "Refined HD pixel art vertical card back design for tongji deck, "
     "ornate red lacquered border with golden filigree, central yin yang taiji symbol with bagua trigrams, "
     "small Chinese cloud patterns in corners, dark crimson red and gold color palette, "
     "sharp pixel edges multiple shading levels, premium mobile game card back design, no text"),
    ("card_back_curse",
     "Refined HD pixel art vertical card back design for curse cards, "
     "dark border with crimson filigree, central skull motif with crossed bones, "
     "ominous purple and black palette with red accents, "
     "sharp pixel edges multiple shading levels, mobile game cursed card back, no text"),
]


def run_batch(specs, out_dir, default_aspect="1:1"):
    style_funcs = {}  # not used; specs are (id, prompt)
    for spec in specs:
        if len(spec) == 2:
            sid, subj = spec
            aspect = default_aspect
        else:
            sid, subj, aspect = spec
        out = out_dir / f"{sid}.png"
        if out.exists():
            print(f"SKIP {sid}")
            continue
        print(f"GEN {sid}...")
        try:
            subprocess.run([
                "python3", GEN, subj,
                "--out", str(out.relative_to(REPO)),
                "--aspect", aspect,
            ], cwd=str(REPO), check=True)
            img = Image.open(out).convert("RGBA")
            img.save(out, "PNG")
        except Exception as e:
            print(f"  ERR: {e}")


def main():
    # 8 家將 (3:4 portrait)
    print("=== 8 家將 ===")
    jj_specs = [(sid, f"{JIAJIANG_STYLE}. {subj}.", "3:4") for sid, subj in JIAJIANG]
    run_batch(jj_specs, JIAJIANG_DIR)

    # 6 deities (3:4 portrait)
    print("=== 6 deities ===")
    dt_specs = [(sid, f"{DEITY_STYLE}. {subj}.", "3:4") for sid, subj in DEITIES]
    run_batch(dt_specs, DEITY_DIR)

    # FX (1:1 square)
    print("=== 6 FX ===")
    fx_specs = [(sid, f"{FX_STYLE}. {subj}.", "1:1") for sid, subj in FX]
    run_batch(fx_specs, FX_DIR)

    # Card backs (3:4 like cards)
    print("=== 2 card backs ===")
    cb_specs = [(sid, subj, "3:4") for sid, subj in CARDBACK]
    run_batch(cb_specs, CARDBACK_DIR)

    print("\nDONE. Total:")
    for d in [JIAJIANG_DIR, DEITY_DIR, FX_DIR, CARDBACK_DIR]:
        files = list(d.glob("*.png"))
        print(f"  {d.name}: {len(files)} files")


if __name__ == "__main__":
    main()
