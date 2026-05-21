#!/usr/bin/env python3
"""PixelLab 角色去背工具。

PixelLab pixflux 輸出帶「純色背景」（非真透明）。單純從角落 flood-fill 只能
去掉外部背景，會漏掉被角色包住的「封閉背景口袋」（手臂內側、繩圈內等）。
此工具兩段處理：
  1. 角落 flood-fill — 去外部背景
  2. 補去殘留同色封閉口袋 — flood 後仍 opaque 且接近 bg 色的像素即封閉區；
     若 bg 為中性灰，額外要求像素也中性灰，避免吃到角色彩色像素。

用法： python3 scripts/tools/pixellab_debg.py <image.png> [image2.png ...]
就地覆寫（已在版控內，鐵律 3 友善）。
"""
import sys
from collections import deque
from PIL import Image

TOL: int = 52          # 與 bg 色的每通道容差
GREY_SPREAD: int = 40  # 判定「中性灰」的 RGB 最大-最小差上限


def _near(a: tuple, b: tuple) -> bool:
	return abs(a[0] - b[0]) < TOL and abs(a[1] - b[1]) < TOL and abs(a[2] - b[2]) < TOL


def debg(path: str) -> tuple:
	im = Image.open(path).convert("RGBA")
	w, h = im.size
	px = im.load()
	bg = px[1, 1]

	# 1) 角落 flood-fill — 去外部背景
	seen: set = set()
	q: deque = deque([(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)])
	while q:
		x, y = q.popleft()
		if (x, y) in seen or x < 0 or y < 0 or x >= w or y >= h:
			continue
		seen.add((x, y))
		p = px[x, y]
		if p[3] == 0:
			continue
		if _near(p, bg):
			px[x, y] = (0, 0, 0, 0)
			q.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])

	# 2) 補去封閉口袋 — flood 後仍接近 bg 色的 opaque 像素
	bg_is_grey = (max(bg[:3]) - min(bg[:3])) < GREY_SPREAD
	enclosed = 0
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a == 0:
				continue
			if _near((r, g, b), bg):
				if (not bg_is_grey) or (max(r, g, b) - min(r, g, b) < GREY_SPREAD):
					px[x, y] = (0, 0, 0, 0)
					enclosed += 1

	im.save(path, "PNG")
	return im.size, enclosed


if __name__ == "__main__":
	if len(sys.argv) < 2:
		print(__doc__)
		sys.exit(1)
	for p in sys.argv[1:]:
		size, rm = debg(p)
		print(f"{p}: {size}  enclosed-removed={rm}")
