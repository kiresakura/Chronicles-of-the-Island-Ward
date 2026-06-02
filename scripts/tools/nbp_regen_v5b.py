#!/usr/bin/env python3
"""NBP v5b 局部重生：mainmenu_bg（去除靜態煙火）+ engine boot splash（清晰乩童角色）。

mainmenu_bg_v5.png — 廟前夜景，純夜空無煙火；動態煙火由 PixelFX 粒子提供。
boot_splash_v5.png — 乩童角色全身正面像，清晰可辨，目前用途為：
                     (1) Godot 引擎 boot_splash  → assets/ui/boot_splash_v5.png
                     (2) iOS / export 啟動畫面素材（與 Root 內建 loading overlay 做視覺承接）

現況：runtime 已不再使用獨立 SplashScreen scene/script。
"""
import subprocess
import shutil
from pathlib import Path
from PIL import Image

REPO    = Path(__file__).resolve().parents[2]
OUT_DIR = REPO / "assets/generated/pixellab"
OUT_DIR.mkdir(parents=True, exist_ok=True)
GEN     = str(REPO / "scripts/tools/nbp_gen.py")

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

ASSETS = [
    # ── boot splash only — mainmenu already looks correct, skip it
    # (
    #     "mainmenu_bg_v5", "16:9", BG_STYLE,
    # ── (commented out — re-enable if mainmenu also needs regen)
    # ── boot splash：乩童全身正面人類角色（第二版）
    (
        "mainmenu_bg_v5_skip", "16:9", BG_STYLE,  # placeholder, will be skipped by rename trick
        "Grand Taiwanese temple main hall exterior at night widescreen background. "
        "Three-tiered ornate temple with green glazed curved roofs gold ridge decorations, "
        "elaborate ceramic figurines and dragons on roofline against deep night sky, "
        "dozens of large red paper lanterns with gold fringe lining entire facade, "
        "silhouettes of festival crowd below with flags and torches, "
        "stone plaza foreground incense burner smoke rising, "
        "deep dark navy sky filled with bright stars no fireworks no explosions, "
        "deep crimson gold temple, rich lantern light only, "
        "wide cinematic perfectly centered temple composition, "
        "sky must be dark and clear with stars only"
    ),
    # ── boot splash：乩童全身正面，清晰可辨，明確人類角色
    (
        "boot_splash_v5", "16:9", SPLASH_STYLE,
        "Taiwanese folk religion mobile game title splash screen widescreen. "
        "Center hero: HUMAN male tongji spirit medium warrior standing heroically, "
        "HUMAN PERSON not an animal, young male human figure, "
        "shirtless upper body with red cloth sash, bright red baggy pants, "
        "red cloth headband tied around forehead, "
        "holding one long red ritual wooden staff weapon raised high, "
        "traditional Taiwanese tang-ki spirit medium ritual costume, "
        "fully colored detailed pixel art character NOT a silhouette, "
        "standing in center of image on ornate stone temple plaza, "
        "grand temple gate behind character with red paper lanterns glowing amber, "
        "deep dark navy night sky with bright stars and full moon, "
        "mystical golden divine aura surrounding the character, "
        "white incense smoke rising from bronze burners at the sides, "
        "outer edges filled with atmospheric temple architecture and dark sky, "
        "important character in safe center 70 percent of image, "
        "color palette: crimson red character deep navy sky gold divine light amber lanterns"
    ),
]


def run_gen(sid: str, aspect: str, style: str, subj: str) -> bool:
    out = OUT_DIR / f"{sid}.png"
    if out.exists():
        out.unlink()
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

    # boot_splash_v5.png 同步複製到 assets/ui/ 供 Godot 引擎 boot splash 使用
    src = OUT_DIR / "boot_splash_v5.png"
    dst = REPO / "assets/ui/boot_splash_v5.png"
    if src.exists():
        shutil.copy2(src, dst)
        print(f"\n  COPY {src.name} → assets/ui/  ✓")
    else:
        print(f"\n  WARN: {src} not found, skip copy")
        err += 1

    print(f"\n{'='*48}")
    print(f"v5b 重生完成 {ok} 張，失敗 {err} 次")
    print(f"輸出：{OUT_DIR}")


if __name__ == "__main__":
    main()
