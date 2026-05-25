#!/usr/bin/env python3
"""PixelLab API 小工具。

用途：
1. 驗證 PIXELLAB_API_KEY 是否可用
2. 查詢帳戶餘額
3. 列出主要端點，供後續動畫批次腳本接線

用法：
    PIXELLAB_API_KEY=... python3 scripts/tools/pixellab_api.py balance
    PIXELLAB_API_KEY=... python3 scripts/tools/pixellab_api.py summary

注意：
- 金鑰只讀環境變數，不寫死在 repo。
- 目前先做探測與摘要；真正批次生成腳本等 runtime 接線後再補。
"""

from __future__ import annotations

import json
import os
import sys
import urllib.error
import urllib.request
from typing import Any

API_ROOT = "https://api.pixellab.ai/v1"
OPENAPI_URL = f"{API_ROOT}/openapi.json"


def _get_api_key() -> str:
    key = os.environ.get("PIXELLAB_API_KEY", "").strip()
    if not key:
        raise SystemExit(
            "缺少 PIXELLAB_API_KEY。\n"
            "範例：PIXELLAB_API_KEY=... python3 scripts/tools/pixellab_api.py balance"
        )
    return key


def _request_json(url: str, api_key: str | None = None) -> Any:
    headers = {}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"

    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=20) as response:
        return json.loads(response.read().decode("utf-8"))


def get_balance() -> dict[str, Any]:
    api_key = _get_api_key()
    return _request_json(f"{API_ROOT}/balance", api_key)


def get_openapi() -> dict[str, Any]:
    return _request_json(OPENAPI_URL)


def print_balance() -> None:
    try:
        balance = get_balance()
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", "ignore")
        raise SystemExit(f"PixelLab balance API 失敗：HTTP {error.code}\n{body}")

    print(json.dumps(balance, ensure_ascii=False, indent=2))


def print_summary() -> None:
    spec = get_openapi()
    print(f"title: {spec.get('info', {}).get('title', '')}")
    print(f"version: {spec.get('info', {}).get('version', '')}")
    print("paths:")
    for path, operations in spec.get("paths", {}).items():
        methods = ", ".join(sorted(method.upper() for method in operations.keys()))
        summary = next(iter(operations.values())).get("summary", "")
        print(f"- {methods:8s} {path} :: {summary}")


COMMANDS = {
    "balance": print_balance,
    "summary": print_summary,
}


def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] not in COMMANDS:
        valid = ", ".join(COMMANDS.keys())
        raise SystemExit(f"用法錯誤。可用指令：{valid}")
    COMMANDS[sys.argv[1]]()


if __name__ == "__main__":
    main()
