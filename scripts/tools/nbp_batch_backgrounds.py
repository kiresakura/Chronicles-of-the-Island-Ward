#!/usr/bin/env python3
"""批次生成全畫面背景 + App Icon via NBP（Gemini pixel art）。

畫面清單：
  1. splash_bg_v3    — SplashScreen 廟門入口載入畫面
  2. mainmenu_bg_v3  — MainMenu 廟會夜景主選單底圖
  3. altar_shrine_v3 — MainMenu 神龕物件（portrait）
  4. newrun_bg_v3    — NewRunMenu 廟堂選角大廳
  5. combat_bg_v3    — Combat 廟前廣場對陣戰場
  6. map_bg_v3       — Map 台灣鳥瞰地圖

App Icon:
  7. app_icon_1024   — 1024×1024 app store icon（1:1）

全部存入 assets/generated/pixellab/
"""
import subprocess
from pathlib import Path
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "assets/generated/pixellab"
OUT_DIR.mkdir(parents=True, exist_ok=True)
GEN = str(REPO / "scripts/tools/nbp_gen.py")

# ──────────────────────────────────────────────────────────────
# 共用品質前綴（比照 nbp_batch_acts.py，保持全系列一致）
# ──────────────────────────────────────────────────────────────
BG_STYLE = (
    "Refined HD pixel art Taiwanese folk religion game scene background, "
    "dense fine pixel work like Sea of Stars and Octopath Traveler quality, "
    "sharp pixel boundaries with multiple shading levels and rich color depth, "
    "atmospheric lighting with vibrant color palette, "
    "central area kept clear for UI overlay, no people no text no watermark"
)

PORTAL_STYLE = (
    "Refined HD pixel art Taiwanese folk religion game portrait illustration, "
    "dense fine pixel work like Sea of Stars Octopath Traveler quality, "
    "sharp pixel boundaries multiple shading levels rich color depth, "
    "centered composition on dark background, no text no watermark"
)

ICON_STYLE = (
    "Refined HD pixel art mobile game app icon, "
    "dense fine pixel work like Sea of Stars quality, "
    "sharp pixel boundaries multiple shading levels rich color depth, "
    "bold readable design, perfectly square composition, vibrant colors, no text no watermark"
)

# ──────────────────────────────────────────────────────────────
# 背景規格表 (filename, aspect, style_prefix, subject)
# ──────────────────────────────────────────────────────────────
BACKGROUNDS = [
    (
        "splash_bg_v3",
        "16:9",
        BG_STYLE,
        "Taiwanese folk religion temple entrance at night as boot loading screen background widescreen. "
        "Grand ornate paifang gate with crimson red lacquer pillars and golden dragon carvings, "
        "two large stone guardian lion statues flanking wide stone steps, "
        "dozens of glowing red paper lanterns hanging overhead in rows casting warm amber light, "
        "white incense smoke wisps curling upward, "
        "deep teal night sky with stars and crescent moon visible through gate arch, "
        "distant silhouette of temple roof behind gate, "
        "rich crimson and gold palette with dark navy sky, dramatic deity aura glow, "
        "bottom third steps and foreground, top two thirds gate and sky composition",
    ),
    (
        "mainmenu_bg_v3",
        "16:9",
        BG_STYLE,
        "Grand Taiwanese temple exterior at night during beehive fireworks festival widescreen. "
        "Three-tiered temple with green glazed tile ornate curved roofs and gold ridge decorations, "
        "elaborate ceramic figurines and dragons on roofline against deep night sky, "
        "dozens of large red paper lanterns with gold fringe lining the entire facade, "
        "colorful beehive fireworks (蜂炮) exploding in night sky above temple in brilliant yellow orange red, "
        "silhouettes of festival crowd below waving flags, "
        "stone plaza in foreground with incense burner smoke, "
        "deep crimson and gold temple, black night sky lit by fireworks and lanterns, "
        "wide cinematic widescreen composition perfectly centered temple",
    ),
    (
        "newrun_bg_v3",
        "16:9",
        BG_STYLE,
        "Interior of grand Taiwanese temple shrine hall for character selection widescreen. "
        "Majestic shrine hall with three symmetrically spaced empty ceremonial stone pedestals "
        "each lit by soft divine spotlight from above, "
        "tall red lacquer pillars with golden dragon carvings lining both sides, "
        "ceiling covered with clusters of red round paper lanterns, "
        "embroidered silk banners and gold calligraphy hanging from rafters, "
        "stone tile floor with glowing trigram symbols, "
        "main altar with deity statues glowing at far end, "
        "incense smoke creating atmospheric blue-white haze, "
        "deep blue midnight interior with warm amber lantern light accents, "
        "perfectly symmetric horizontal widescreen composition with pedestals evenly spaced",
    ),
    (
        "combat_bg_v3",
        "16:9",
        BG_STYLE,
        "Ancient Taiwanese temple courtyard battle arena at night widescreen. "
        "Wide stone-paved plaza surrounded by massive red lacquer pillars with gold paint, "
        "burning torches and bronze incense burners with flame on both sides, "
        "ornate temple building facade with lanterns as backdrop, "
        "dramatic moonlit sky with swirling divine clouds, "
        "magical spirit energy crackling between pillars in cyan and gold, "
        "battle-worn stone tiles with faint bagua trigram markings, "
        "ghost fire wisps and auspicious cloud patterns floating, "
        "dark dramatic palette: deep crimson stone, gold pillar accents, moonlit sky, "
        "horizontal widescreen composition, large open center clearing for combatants",
    ),
    (
        "map_bg_v3",
        "16:9",
        BG_STYLE,
        "Stylized aerial view of Taiwan island adventure map at twilight widescreen. "
        "Isometric top-down style pixel art map showing Taiwan landscape: "
        "Central Mountain Range peaks with mist, "
        "western coastal plains with rice paddies and fishing villages, "
        "eastern cliffs meeting Pacific Ocean, "
        "small red-roofed temples and shrines scattered on hilltops marked with red lanterns, "
        "winding rivers and roads connecting locations, "
        "ocean waters surrounding island with crashing waves, "
        "warm orange-gold sunset sky fading to purple dusk at edges, "
        "glowing paths connecting dungeon nodes between locations, "
        "rich warm ochre and green island tones, deep blue-purple ocean, golden sky",
    ),
]

# ──────────────────────────────────────────────────────────────
# 神龕（portrait 3:4）
# ──────────────────────────────────────────────────────────────
PORTRAIT_ASSETS = [
    (
        "altar_shrine_v3",
        "3:4",
        PORTAL_STYLE,
        "Traditional Taiwanese god altar table full composition portrait. "
        "Ornate dark rosewood altar cabinet with intricate carved dragon panels and red lacquer finish, "
        "central tall golden Mazu goddess statue in regal red and gold imperial robes with pearl crown, "
        "flanked by two smaller deity attendant statues in gold armor, "
        "pair of tall red dragon candles burning bright flame, "
        "large bronze incense burner (香爐) with three smoking incense sticks, "
        "five-fruit offerings on ritual plates (pineapple pomelo orange apple banana), "
        "stacked gold ingot paper money (金紙) neatly folded, "
        "red silk tablecloth embroidered with golden dragon clouds, "
        "warm amber candlelight illumination, "
        "rich dark rosewood and gold palette with red silk and white smoke accents, "
        "centered vertical composition showing full altar from floor to ceiling",
    ),
]

# ──────────────────────────────────────────────────────────────
# App Icon（1:1 正方形）
# ──────────────────────────────────────────────────────────────
ICON_ASSETS = [
    (
        "app_icon_1024",
        "1:1",
        ICON_STYLE,
        "Taiwanese folk religion roguelike card game app icon. "
        "Central focus: silhouette of 乩童 tongji spirit medium warrior with fiery possession aura, "
        "dramatic pose wielding spiked ritual self-mortification weapon, "
        "surrounded by radiant golden divine light burst, "
        "eight trigram bagua octagonal frame border with gold trim, "
        "deep crimson red background with lantern glow, "
        "small decorative elements: red lantern, incense smoke, paper charm talismans in corners, "
        "high contrast bold colors: crimson red, gold, white spirit flame, "
        "pixel art style fitting for mobile game store listing, "
        "bold iconic immediately recognizable at small sizes",
    ),
]


def run_gen(sid: str, aspect: str, full_prompt: str, out_dir: Path) -> bool:
    out = out_dir / f"{sid}.png"
    if out.exists():
        print(f"  SKIP {sid} (already exists)")
        return True
    print(f"  GEN {sid} [{aspect}]...")
    try:
        subprocess.run(
            ["python3", GEN, full_prompt, "--out", str(out.relative_to(REPO)), "--aspect", aspect],
            cwd=str(REPO), check=True,
        )
        # Convert to RGBA PNG
        img = Image.open(out).convert("RGBA")
        img.save(out, "PNG")
        print(f"    → {out.stat().st_size // 1024} KB  ✓")
        return True
    except Exception as e:
        print(f"    ERR: {e}")
        return False


def create_android_icon(src: Path) -> None:
    """從 1024px master 生成 Android mipmap 各密度 icon。"""
    # Godot Android export 需要 res/mipmap-* 各密度 icon，但 export_presets 可設定 master icon
    # 這裡額外存一份 512px 供 Google Play 上架用
    if not src.exists():
        return
    out_512 = src.parent / "app_icon_512.png"
    img = Image.open(src).convert("RGBA")
    img_512 = img.resize((512, 512), Image.LANCZOS)
    img_512.save(out_512, "PNG")
    print(f"  → app_icon_512.png  ({out_512.stat().st_size // 1024} KB)")

    # Godot icon.png（256px，用於 editor 預覽）
    icon_godot = REPO / "icon.png"
    img_256 = img.resize((256, 256), Image.LANCZOS)
    img_256.save(icon_godot, "PNG")
    print(f"  → icon.png (256px Godot editor icon)")


def main():
    ok = err = 0

    print("\n===== 橫向背景（16:9）=====")
    for sid, aspect, style, subj in BACKGROUNDS:
        full = f"{style}. {subj}."
        if run_gen(sid, aspect, full, OUT_DIR):
            ok += 1
        else:
            err += 1

    print("\n===== 神龕物件（3:4）=====")
    for sid, aspect, style, subj in PORTRAIT_ASSETS:
        full = f"{style}. {subj}."
        if run_gen(sid, aspect, full, OUT_DIR):
            ok += 1
        else:
            err += 1

    print("\n===== App Icon（1:1）=====")
    for sid, aspect, style, subj in ICON_ASSETS:
        full = f"{style}. {subj}."
        if run_gen(sid, aspect, full, OUT_DIR):
            ok += 1
            create_android_icon(OUT_DIR / f"{sid}.png")
        else:
            err += 1

    print(f"\n{'='*48}")
    print(f"完成 {ok} 張，失敗 {err} 張")
    print(f"輸出目錄：{OUT_DIR}")


if __name__ == "__main__":
    main()
