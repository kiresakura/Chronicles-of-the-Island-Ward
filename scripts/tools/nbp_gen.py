#!/usr/bin/env python3
"""
Nano Banana Pro (Gemini 2.5 Flash Image) generator wrapper for COTIW.

Usage:
    python nbp_gen.py "<prompt>" --out <path.png> [--aspect <ratio>]

Examples:
    python nbp_gen.py "Taiwanese 乩童 warrior pixel art" --out assets/portraits/tongji_v3.png
    python nbp_gen.py "廟宇前景" --out assets/bg/mainmenu_v3.png --aspect 16:9

Env:
    GEMINI_API_KEY  (loaded from .env.local at repo root if not set)
"""
import os
import sys
import json
import argparse
import base64
import urllib.request
import urllib.error
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
MODEL = "nano-banana-pro-preview"  # highest quality; alt: gemini-3.1-flash-image-preview / gemini-2.5-flash-image
API = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


def load_api_key() -> str:
    key = os.environ.get("GEMINI_API_KEY")
    if key:
        return key
    env_file = REPO_ROOT / ".env.local"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            line = line.strip()
            if line.startswith("GEMINI_API_KEY="):
                return line.split("=", 1)[1].strip().strip('"').strip("'")
    sys.exit("ERR: GEMINI_API_KEY not set and .env.local missing")


def generate(prompt: str, out_path: Path, aspect: str = "1:1") -> None:
    key = load_api_key()
    url = API.format(model=MODEL) + f"?key={key}"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["IMAGE"],
            "imageConfig": {"aspectRatio": aspect},
        },
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        sys.exit(f"ERR: HTTP {e.code} — {body[:600]}")

    # Drill into response to find inlineData
    img_b64 = None
    for cand in data.get("candidates", []):
        for part in cand.get("content", {}).get("parts", []):
            inline = part.get("inlineData") or part.get("inline_data")
            if inline and "data" in inline:
                img_b64 = inline["data"]
                break
        if img_b64:
            break
    if not img_b64:
        sys.exit(f"ERR: no image returned. raw: {json.dumps(data)[:400]}")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    raw = base64.b64decode(img_b64)
    # NBP 回傳的是 JPEG bytes；若輸出副檔名是 .png，必須真正重編碼成 PNG，
    # 否則「JPEG 假裝成 .png」會讓 Godot importer 報 Error loading image。
    if out_path.suffix.lower() == ".png":
        from io import BytesIO
        from PIL import Image
        Image.open(BytesIO(raw)).convert("RGB").save(out_path, "PNG")
    else:
        out_path.write_bytes(raw)
    print(f"OK: {out_path}  ({out_path.stat().st_size:,} bytes)")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("prompt", help="text prompt")
    ap.add_argument("--out", required=True, help="output PNG path (relative to repo or absolute)")
    ap.add_argument("--aspect", default="1:1",
                    choices=["1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4", "9:16", "16:9", "21:9"],
                    help="aspect ratio (default 1:1)")
    args = ap.parse_args()

    out = Path(args.out)
    if not out.is_absolute():
        out = REPO_ROOT / out
    generate(args.prompt, out, args.aspect)


if __name__ == "__main__":
    main()
