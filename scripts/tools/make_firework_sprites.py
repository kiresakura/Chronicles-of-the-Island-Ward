#!/usr/bin/env python3
"""
Route B — 煙火精靈圖生成腳本
─────────────────────────────
輸入：
  ~/.mcp-recraft-server/ae05c205-68fa-4568-b794-84f057f5a613.webp  ← 爆炸花火 burst
  ~/.mcp-recraft-server/8a64851b-7bb5-43bb-952e-3b273b263512.webp  ← 八角星點 sparkle

輸出（assets/generated/pixellab/）：
  firework_burst_sheet.png   — 8 幀 × 128px = 1024×128 橫排精靈表
  firework_sparkle.png       — 32×32 單張粒子材質

亮度型 alpha 萃取：
  alpha = 0.299R + 0.587G + 0.114B （黑底→透明，亮部→不透明）
  再乘以來源 alpha（已是 RGBA，通常全不透明）

Burst 8 幀拆解：
  幀 0-4（展開）：從中心裁出 25%→45%→65%→85%→100% 範圍，放大回 128×128 nearest
  幀 5-7（消散）：全圖 128×128，整體 alpha × 0.75 / 0.45 / 0.18；並向下 gravity_shift 3/8/16px
"""

from pathlib import Path
from PIL import Image
import numpy as np

REPO      = Path(__file__).resolve().parents[2]
RECRAFT   = Path.home() / ".mcp-recraft-server"
OUT_DIR   = REPO / "assets/generated/pixellab"
OUT_DIR.mkdir(parents=True, exist_ok=True)

BURST_SRC   = RECRAFT / "ae05c205-68fa-4568-b794-84f057f5a613.webp"
SPARKLE_SRC = RECRAFT / "8a64851b-7bb5-43bb-952e-3b273b263512.webp"

FRAME_SIZE  = 128
NUM_FRAMES  = 8


def luma_alpha(img_rgba: np.ndarray, gamma: float = 1.2) -> np.ndarray:
    """亮度驅動 alpha：RGB 越亮越不透明，用於去黑底。"""
    r = img_rgba[:, :, 0] / 255.0
    g = img_rgba[:, :, 1] / 255.0
    b = img_rgba[:, :, 2] / 255.0
    luma = 0.299 * r + 0.587 * g + 0.114 * b   # BT.601
    luma_boost = np.clip(luma ** gamma, 0.0, 1.0)
    result = img_rgba.copy()
    result[:, :, 3] = (luma_boost * img_rgba[:, :, 3] / 255.0 * 255).astype(np.uint8)
    return result


def crop_center_frac(img: Image.Image, frac: float) -> Image.Image:
    """從圖片正中央裁切 frac 比例的區域。"""
    w, h = img.size
    cx, cy = w // 2, h // 2
    half_w = int(w * frac / 2)
    half_h = int(h * frac / 2)
    box = (cx - half_w, cy - half_h, cx + half_w, cy + half_h)
    return img.crop(box)


def gravity_shift(arr: np.ndarray, shift_px: int) -> np.ndarray:
    """將像素整體向下移位（模擬重力下墜），空出的上方填透明。"""
    if shift_px <= 0:
        return arr
    h = arr.shape[0]
    result = np.zeros_like(arr)
    visible = min(shift_px, h)
    result[visible:, :, :] = arr[:h - visible, :, :]
    return result


def make_burst_sheet() -> None:
    print(f"[burst] 載入 {BURST_SRC.name}...")
    src = Image.open(BURST_SRC).convert("RGBA")
    src_arr = np.array(src)
    src_arr = luma_alpha(src_arr)
    src = Image.fromarray(src_arr, "RGBA")

    # 擴展幀配置
    expand_fracs = [0.25, 0.45, 0.65, 0.85, 1.00]   # 幀 0-4
    fade_alphas  = [0.75, 0.45, 0.18]                # 幀 5-7
    gravity_shifts = [3, 8, 16]                      # 幀 5-7 下移 px

    sheet = Image.new("RGBA", (FRAME_SIZE * NUM_FRAMES, FRAME_SIZE), (0, 0, 0, 0))

    for i, frac in enumerate(expand_fracs):
        crop = crop_center_frac(src, frac)
        frame = crop.resize((FRAME_SIZE, FRAME_SIZE), Image.NEAREST)
        sheet.paste(frame, (i * FRAME_SIZE, 0))
        print(f"  幀 {i}: crop {frac*100:.0f}% → 128px ✓")

    # 幀 5-7：全圖縮小到 128×128，apply alpha fade + gravity
    full_128 = src.resize((FRAME_SIZE, FRAME_SIZE), Image.NEAREST)
    full_arr = np.array(full_128)

    for j, (alpha_mul, gshift) in enumerate(zip(fade_alphas, gravity_shifts)):
        arr = full_arr.copy()
        arr = gravity_shift(arr, gshift)
        arr[:, :, 3] = (arr[:, :, 3] / 255.0 * alpha_mul * 255).astype(np.uint8)
        frame = Image.fromarray(arr, "RGBA")
        idx = 5 + j
        sheet.paste(frame, (idx * FRAME_SIZE, 0))
        print(f"  幀 {idx}: fade {alpha_mul:.2f} + gravity {gshift}px ✓")

    out = OUT_DIR / "firework_burst_sheet.png"
    sheet.save(out, "PNG")
    kb = out.stat().st_size // 1024
    print(f"\n  → {out.name}  {FRAME_SIZE * NUM_FRAMES}×{FRAME_SIZE}  {kb} KB  ✓")


def make_sparkle() -> None:
    print(f"\n[sparkle] 載入 {SPARKLE_SRC.name}...")
    src = Image.open(SPARKLE_SRC).convert("RGBA")
    arr = np.array(src)
    arr = luma_alpha(arr, gamma=1.5)  # 更積極去黑底
    result = Image.fromarray(arr, "RGBA")
    result = result.resize((32, 32), Image.LANCZOS)
    out = OUT_DIR / "firework_sparkle.png"
    result.save(out, "PNG")
    kb = out.stat().st_size // 1024
    print(f"  → {out.name}  32×32  {kb} KB  ✓")


if __name__ == "__main__":
    make_burst_sheet()
    make_sparkle()
    print("\n完成！精靈圖已輸出到 assets/generated/pixellab/")
