#!/usr/bin/env python3
"""NBP v5 批次生成：5 遊戲背景 + boot_splash + iOS launch storyboard。

輸出：assets/generated/pixellab/
  splash_bg_v5.png      — 16:9  SplashScreen 廟門
  mainmenu_bg_v5.png    — 16:9  MainMenu 廟會夜景煙火
  newrun_bg_v5.png      — 16:9  NewRunMenu 廟堂選角
  combat_bg_v5.png      — 16:9  Combat 廟前廣場
  map_bg_v5.png         — 16:9  Map 台灣鳥瞰
  boot_splash_v5.png    — 16:9  Godot boot splash
  ios_launch_v5.png     — 9:16  iOS Launch Storyboard（portrait）
"""
import subprocess
from pathlib import Path
from PIL import Image

REPO    = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "assets/generated/pixellab"
OUT_DIR.mkdir(parents=True, exist_ok=True)
GEN     = str(REPO / "scripts/tools/nbp_gen.py")

# ──────────────────────────────────────────────────────────────
# 共用風格前綴
# ──────────────────────────────────────────────────────────────
BG_STYLE = (
    "Refined HD pixel art Taiwanese folk religion mobile game background, "
    "dense fine chunky pixel work inspired by Sea of Stars and Octopath Traveler, "
    "sharp pixel boundaries multiple shading levels rich color depth, "
    "atmospheric mood lighting vibrant saturated palette, "
    "no people in center area, no text no watermark"
)

SPLASH_STYLE = (
    "Refined HD pixel art Taiwanese folk religion mobile game title screen, "
    "dense fine chunky pixel work Sea of Stars quality, "
    "sharp pixel boundaries multiple shading levels rich color depth, "
    "bold dramatic composition centered design, "
    "no text no watermark"
)

# ──────────────────────────────────────────────────────────────
# 7 張圖規格（filename, aspect, style, subject）
# ──────────────────────────────────────────────────────────────
ASSETS = [
    # ── 5 遊戲背景 ────────────────────────────────────────────
    (
        "splash_bg_v5", "16:9", BG_STYLE,
        "Taiwanese folk religion temple entrance at night, loading screen background widescreen. "
        "Grand ornate paifang gate with crimson red lacquer pillars gold dragon carvings, "
        "two large stone guardian lion statues flanking wide stone steps, "
        "dozens of glowing red paper lanterns overhead in rows casting warm amber light, "
        "white incense smoke wisps curling upward from bronze burners, "
        "deep teal night sky with stars crescent moon visible through gate arch, "
        "soft mystical deity aura glow at gate center, "
        "rich crimson gold palette dark navy sky, "
        "bottom third steps foreground top two thirds gate and sky, wide cinematic composition"
    ),
    (
        "mainmenu_bg_v5", "16:9", BG_STYLE,
        "Grand Taiwanese temple main hall exterior at night during beehive fireworks festival widescreen. "
        "Three-tiered ornate temple with green glazed curved roofs gold ridge decorations, "
        "elaborate ceramic figurines and dragons on roofline against deep night sky, "
        "dozens of large red paper lanterns with gold fringe lining entire facade, "
        "colorful beehive fireworks 蜂炮 explosions in night sky brilliant yellow orange red cyan, "
        "silhouettes of festival crowd below with flags and torches, "
        "stone plaza foreground incense burner smoke rising, "
        "deep crimson gold temple black sky lit by fireworks and lanterns, "
        "wide cinematic perfectly centered temple composition"
    ),
    (
        "newrun_bg_v5", "16:9", BG_STYLE,
        "Interior of grand Taiwanese temple shrine hall character selection widescreen. "
        "Majestic hall with three symmetrically spaced empty ceremonial stone pedestals "
        "each lit by soft divine spotlight from above, "
        "tall red lacquer pillars gold dragon carvings both sides, "
        "ceiling covered with clusters of red round paper lanterns, "
        "embroidered silk banners gold calligraphy hanging from rafters, "
        "stone tile floor with glowing bagua trigram symbols, "
        "main altar deity statues glowing at far end, "
        "incense smoke atmospheric blue-white haze, "
        "deep blue midnight interior warm amber lantern accents, "
        "symmetric horizontal composition pedestals evenly spaced"
    ),
    (
        "combat_bg_v5", "16:9", BG_STYLE,
        "Ancient Taiwanese temple courtyard battle arena at night widescreen. "
        "Wide stone-paved plaza massive red lacquer pillars gold paint both sides, "
        "burning torches bronze incense burners with flame flanking arena, "
        "ornate temple facade with lanterns as backdrop full moon behind clouds, "
        "magical spirit energy crackling between pillars cyan and gold lightning, "
        "battle-worn stone tiles faint bagua trigram markings, "
        "ghost fire wisps auspicious clouds floating, "
        "dark dramatic palette deep crimson stone gold accents moonlit sky, "
        "large open center clearing widescreen composition"
    ),
    (
        "map_bg_v5", "16:9", BG_STYLE,
        "Stylized aerial isometric view Taiwan island adventure map at twilight widescreen. "
        "Central Mountain Range peaks with mist and cloud, "
        "western coastal plains rice paddies fishing villages temples, "
        "eastern cliffs Pacific Ocean, "
        "small red-roofed temples shrines on hilltops marked red lanterns, "
        "winding rivers roads connecting locations dungeon nodes, "
        "ocean surrounding island crashing waves, "
        "warm orange-gold sunset sky fading purple dusk at edges, "
        "glowing paths between map locations, "
        "rich ochre green island tones deep blue-purple ocean golden sky"
    ),
    # ── Godot boot splash ─────────────────────────────────────
    (
        "boot_splash_v5", "16:9", SPLASH_STYLE,
        "Taiwanese folk religion pixel art game title splash screen widescreen. "
        "Dramatic centered composition: giant golden eight-trigram bagua wheel radiating divine light, "
        "silhouette of 乩童 tongji spirit medium warrior standing at center inside the wheel, "
        "arms raised holding ritual weapons, surrounded by crimson aura and incense smoke, "
        "top area deep dark night sky with stars and temple roof silhouettes, "
        "bottom area ornate red stone temple steps with stone lions, "
        "floating red paper talismans charm papers drifting, "
        "color palette: deep crimson background gold bagua glow cyan spirit flame white smoke, "
        "dramatic lighting from central deity glow, perfectly centered iconic composition"
    ),
    # ── iOS launch storyboard（portrait 9:16）────────────────
    (
        "ios_launch_v5", "9:16", SPLASH_STYLE,
        "Taiwanese folk religion pixel art mobile game launch screen portrait vertical. "
        "Tall vertical composition: "
        "top third ornate temple gate arch framing the scene with red lanterns, "
        "center large golden bagua eight-trigram circle glowing with divine energy, "
        "silhouette of tongji spirit medium warrior inside circle, "
        "floating red paper charm talismans around the circle, "
        "bottom third stone steps with burning incense bronze burners, "
        "deep crimson and dark navy background gold and amber glow, "
        "vertical portrait format perfectly centered design, "
        "suitable for mobile game splash loading screen"
    ),
]


def run_gen(sid: str, aspect: str, style: str, subj: str) -> bool:
    out = OUT_DIR / f"{sid}.png"
    if out.exists():
        out.unlink()           # 強制重新生成（v5 全部刷新）
    print(f"\n  GEN {sid} [{aspect}]...")
    full_prompt = f"{style}. {subj}."
    try:
        subprocess.run(
            ["python3", GEN, full_prompt,
             "--out", str(out.relative_to(REPO)),
             "--aspect", aspect],
            cwd=str(REPO), check=True,
        )
        img = Image.open(out).convert("RGBA")
        img.save(out, "PNG")
        print(f"    → {out.stat().st_size // 1024} KB  ✓")
        return True
    except Exception as e:
        print(f"    ERR: {e}")
        return False


def main():
    ok = err = 0
    for sid, aspect, style, subj in ASSETS:
        if run_gen(sid, aspect, style, subj):
            ok += 1
        else:
            err += 1
    print(f"\n{'='*48}")
    print(f"v5 生成完成 {ok} 張，失敗 {err} 張")
    print(f"輸出：{OUT_DIR}")


if __name__ == "__main__":
    main()
