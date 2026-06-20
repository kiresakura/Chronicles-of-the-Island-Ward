#!/usr/bin/env python3
"""Recraft V3 生成器（COTIW）。金鑰從環境或 .env.local 讀 RECRAFT_API_KEY。

兩種模式：
  單張：  python3 scripts/tools/recraft_gen.py --subject "一只紅燈籠" --out qa/x.svg --icon
  批次：  python3 scripts/tools/recraft_gen.py --manifest m.json --outdir qa/art_regen/icons_v14 --icon

--icon  把 subject 包進「美術生產標準」鎖定的廟會金箔 icon 風格（金為主、硃砂點綴、
        高對比可讀於黑底、透明 SVG、無文字無錢符號）。確保整批 cohesion。
manifest 格式： {"檔名（不含副檔名）": "subject 描述", ...}

輸出一律向量 SVG（原生透明、任意解析度脆），符合 icons 優先向量的標準。
"""
from __future__ import annotations
import os, sys, json, argparse, urllib.request
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
API = "https://external.api.recraft.ai/v1/images/generations"
ME = "https://external.api.recraft.ai/v1/users/me"

LOCKED_ICON_STYLE = (
    "minimalist flat mobile game icon: a single clear bold symbol of {s}. "
    "Solid antique gold #E8C46A fill with a thin darker gold outline, "
    "thick simple readable shapes, centered, high contrast on dark UI. "
    "NO scenery, NO buildings, NO temple, NO pagoda, NO landscape, "
    "NO text, NO letters, NO numbers, NO currency or dollar symbols. "
    "Flat vector, single subject only, transparent background."
)


def _key() -> str:
    k = os.environ.get("RECRAFT_API_KEY", "").strip()
    if k:
        return k
    f = REPO / ".env.local"
    if f.exists():
        for line in f.read_text().splitlines():
            if line.startswith("RECRAFT_API_KEY="):
                return line.split("=", 1)[1].strip().strip('"').strip("'")
    sys.exit("ERR: RECRAFT_API_KEY 未設定（環境或 .env.local）")


def _credits(key: str) -> int:
    req = urllib.request.Request(ME, headers={"Authorization": f"Bearer {key}"})
    return json.loads(urllib.request.urlopen(req, timeout=20).read())["credits"]


def gen_one(subject: str, out: Path, key: str, icon: bool) -> bool:
    if out.exists() and out.stat().st_size > 0:
        print(f"  · skip (exists) {out.name}")
        return True
    prompt = LOCKED_ICON_STYLE.format(s=subject) if icon else subject
    body = json.dumps({
        "prompt": prompt, "style": "vector_illustration", "size": "1024x1024",
        "model": "recraftv3", "n": 1, "response_format": "url",
    }).encode()
    req = urllib.request.Request(API, data=body, headers={
        "Authorization": f"Bearer {key}", "Content-Type": "application/json"})
    try:
        d = json.loads(urllib.request.urlopen(req, timeout=180).read())
    except urllib.error.HTTPError as e:  # type: ignore[attr-defined]
        print(f"  ✗ {out.name}: HTTP {e.code} {e.read().decode('utf-8','ignore')[:200]}")
        return False
    url = d["data"][0]["url"]
    dl = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (COTIW art pipeline)"})
    raw = urllib.request.urlopen(dl, timeout=60).read()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(raw)
    print(f"  ✓ {out.relative_to(REPO)} ({len(raw):,}B)")
    return True


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--subject")
    ap.add_argument("--out")
    ap.add_argument("--manifest")
    ap.add_argument("--outdir")
    ap.add_argument("--icon", action="store_true")
    a = ap.parse_args()
    key = _key()
    c0 = _credits(key)
    print(f"Recraft credits: {c0}")
    n = 0
    if a.manifest:
        items = json.loads((REPO / a.manifest if not Path(a.manifest).is_absolute()
                            else Path(a.manifest)).read_text())
        outdir = REPO / a.outdir
        for name, subject in items.items():
            if gen_one(subject, outdir / f"{name}.svg", key, a.icon):
                n += 1
    elif a.subject and a.out:
        out = Path(a.out)
        out = out if out.is_absolute() else REPO / out
        if gen_one(a.subject, out, key, a.icon):
            n += 1
    else:
        sys.exit("用法：--subject+--out  或  --manifest+--outdir")
    c1 = _credits(key)
    print(f"完成 {n} 張。credits {c0} → {c1}（花 {c0 - c1}）")


if __name__ == "__main__":
    main()
