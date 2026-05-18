#!/usr/bin/env python3
"""
Asset Pack 自動 import 腳本

用法：
  1. 把從 itch.io 下載的 zip 全部丟到 assets/_pack_downloads/
  2. 跑 `python3 scripts/import_asset_packs.py`
  3. 腳本會：
     - 解壓每個 zip 到分類目錄
     - 蒐集 license / attribution 寫到 docs/THIRD_PARTY_LICENSES.md
     - 跑 godot --headless --import 讓 Godot 認新 texture
     - 列出檔案總覽供你比對 .tscn 引用

不會自動改 .tscn — 那步要手動或用第二個 script。
"""
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
DOWNLOADS = ROOT / "assets" / "_pack_downloads"
EXT_SPRITES = ROOT / "external" / "sprites"
ASSETS_UI = ROOT / "assets" / "ui"
LICENSES_MD = ROOT / "docs" / "THIRD_PARTY_LICENSES.md"

# Pack 名稱關鍵字 → 目標子資料夾
PACK_DESTINATIONS = {
    "piposchpatz": EXT_SPRITES / "cards" / "frames_piposchpatz",
    "card-frame": EXT_SPRITES / "cards" / "frames_piposchpatz",
    "pixel-fantasy-cards": EXT_SPRITES / "cards" / "fantasy_cards",
    "yokai-realm": EXT_SPRITES / "yokai_realm",
    "etahoshi": EXT_SPRITES / "yokai_realm",
    "cp32": EXT_SPRITES / "enemies" / "cp32_yokai",
    "pixel-yokai": EXT_SPRITES / "enemies" / "cp32_yokai",
    "graveyard-undead-yokai": EXT_SPRITES / "enemies" / "yokai_dark_fantasy",
    "megentarou": EXT_SPRITES / "enemies" / "yokai_dark_fantasy",
}

LICENSE_PATTERNS = [
    re.compile(r"license", re.I),
    re.compile(r"readme", re.I),
    re.compile(r"credit", re.I),
    re.compile(r"attribution", re.I),
]


def find_dest(zip_name: str) -> pathlib.Path:
    name_lower = zip_name.lower().replace("_", "-")
    for keyword, dest in PACK_DESTINATIONS.items():
        if keyword in name_lower:
            return dest
    # fallback：用 zip basename 當資料夾
    safe = re.sub(r"[^a-z0-9_]+", "_", pathlib.Path(zip_name).stem.lower())
    return EXT_SPRITES / "_unsorted" / safe


def extract_zip(zip_path: pathlib.Path, dest: pathlib.Path) -> list[str]:
    dest.mkdir(parents=True, exist_ok=True)
    license_texts: list[str] = []
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(dest)
        for name in zf.namelist():
            for pat in LICENSE_PATTERNS:
                if pat.search(name) and name.lower().endswith((".txt", ".md", "")):
                    try:
                        text = zf.read(name).decode("utf-8", errors="replace")
                        if len(text) < 10_000:  # avoid huge dumps
                            license_texts.append(
                                f"### {zip_path.name} → `{name}`\n\n```\n{text.strip()}\n```\n"
                            )
                    except Exception:
                        pass
    return license_texts


def update_licenses_md(entries: list[str]) -> None:
    LICENSES_MD.parent.mkdir(parents=True, exist_ok=True)
    header = (
        "# 第三方素材授權清單\n\n"
        "由 `scripts/import_asset_packs.py` 自動產生。\n\n"
        "**重要**：每次新增 asset pack 都要保留此檔，"
        "符合 CC BY / Royalty-free / 其他 license 的 attribution 要求。\n\n"
        "---\n\n"
    )
    body = "\n".join(entries) if entries else "_（zip 內無 license/readme 文字檔，請手動補。）_\n"
    LICENSES_MD.write_text(header + body, encoding="utf-8")


def main() -> int:
    if not DOWNLOADS.exists():
        print(f"❌ {DOWNLOADS} 不存在")
        return 1
    zips = sorted(DOWNLOADS.glob("*.zip"))
    if not zips:
        print(f"⚠️  {DOWNLOADS} 內沒有 zip。請先到 itch.io 下載後丟進來。")
        return 0

    license_entries: list[str] = []
    print(f"\n找到 {len(zips)} 個 zip：\n")
    for z in zips:
        dest = find_dest(z.name)
        print(f"  📦 {z.name}  →  {dest.relative_to(ROOT)}")
        entries = extract_zip(z, dest)
        license_entries.extend(entries)
        print(f"     ✅ 解壓完成（內含 {len(entries)} 條 license 文字）")

    update_licenses_md(license_entries)
    print(f"\n📝 license 寫到：{LICENSES_MD.relative_to(ROOT)}")

    # Run godot import
    print("\n🔄 跑 godot --headless --import ...")
    try:
        result = subprocess.run(
            ["godot", "--headless", "--import"],
            cwd=ROOT, timeout=120, capture_output=True, text=True
        )
        ok = "DONE" in result.stdout or result.returncode == 0
        print("   ✅ import 完成" if ok else f"   ⚠️  import return={result.returncode}")
    except Exception as e:
        print(f"   ⚠️  godot import 失敗: {e}")

    # File overview
    print("\n📂 解壓後資料夾總覽：")
    for keyword, dest in {(k, str(v.relative_to(ROOT))) for k, v in PACK_DESTINATIONS.items() if v.exists()}:
        count = len(list(dest_path.rglob("*.png"))) if (dest_path := ROOT / keyword) and dest_path.exists() else 0
    for dest in sorted({v for v in PACK_DESTINATIONS.values()}):
        if dest.exists():
            png_count = len(list(dest.rglob("*.png")))
            print(f"   {dest.relative_to(ROOT)}: {png_count} 張 png")

    print("\n下一步：手動或寫第二個 script 把 .tscn 內 texture 引用換成新 sprite。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
