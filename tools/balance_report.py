#!/usr/bin/env python3
"""鎮島錄 Q3-F — 平衡模擬報表彙整（給憲龍拍板用；本工具只整理數據不下結論）。

用法：python3 tools/balance_report.py /tmp/balance_base.json [/tmp/balance_backup_deity.json ...]
輸出：markdown 報表到 stdout（重導向存檔）。
"""
import json
import sys
from collections import defaultdict


def load(path):
    with open(path) as f:
        return json.load(f)


def battle_table(datasets):
    lines = ["| 變體 | 戰數 | 勝率 | 超時 | 平均回合 | 平均殘血% | 合符/戰 | 降乩/戰 | 破煞/戰 |",
             "|---|---|---|---|---|---|---|---|---|"]
    for d in datasets:
        b = d["battles"]
        n = len(b)
        if n == 0:
            continue
        wins = sum(1 for r in b if r["victory"])
        timeouts = sum(1 for r in b if r.get("timeout"))
        avg_turns = sum(r["turns"] for r in b) / n
        avg_hp = sum(r["hp_left"] / max(1, r["hp_max"]) for r in b) / n * 100
        avg_merge = sum(r["merges"] for r in b) / n
        avg_invoke = sum(r["invokes"] for r in b) / n
        avg_break = sum(r["breaks"] for r in b) / n
        lines.append(f"| {d['variant']} | {n} | {wins/n*100:.0f}% | {timeouts} | "
                     f"{avg_turns:.1f} | {avg_hp:.0f}% | {avg_merge:.2f} | {avg_invoke:.2f} | {avg_break:.2f} |")
    return "\n".join(lines)


def floor_table(datasets):
    lines = ["| 變體 | 樓層 | 勝率 | 平均回合 | 平均殘血% |", "|---|---|---|---|---|"]
    for d in datasets:
        by_floor = defaultdict(list)
        for r in d["battles"]:
            by_floor[r["floor"]].append(r)
        for fl in sorted(by_floor):
            rs = by_floor[fl]
            wins = sum(1 for r in rs if r["victory"])
            avg_turns = sum(r["turns"] for r in rs) / len(rs)
            avg_hp = sum(r["hp_left"] / max(1, r["hp_max"]) for r in rs) / len(rs) * 100
            tag = "惡煞" if fl == 5 else "遇煞"
            lines.append(f"| {d['variant']} | {fl}（{tag}） | {wins/len(rs)*100:.0f}% | {avg_turns:.1f} | {avg_hp:.0f}% |")
    return "\n".join(lines)


def card_table(datasets):
    base = next((d for d in datasets if d["variant"] == "base"), datasets[0])
    use = sorted(base["card_use"].items(), key=lambda kv: -kv[1])
    total = sum(v for _, v in use) or 1
    lines = ["| 卡 | 出牌次數 | 佔比 |", "|---|---|---|"]
    for cid, n in use:
        lines.append(f"| {cid} | {n} | {n/total*100:.1f}% |")
    return "\n".join(lines)


def main():
    datasets = [load(p) for p in sys.argv[1:]]
    if not datasets:
        print("用法：balance_report.py <json...>", file=sys.stderr)
        sys.exit(1)
    print("# 鎮島錄 平衡模擬報表（Q3-F）\n")
    print("> 方法：真實戰鬥樹 + 貪婪 AI（合符優先→出牌打最殘敵→降乩→結束回合），")
    print("> 乩童預設班底、固定卡組（不領獎勵卡）、樓層 1/2/3/5 連戰、12 seeds/變體。")
    print("> **本報表只呈現數據；平衡定案由憲龍拍板。**\n")
    print("## 總表\n")
    print(battle_table(datasets))
    print("\n## 分層\n")
    print(floor_table(datasets))
    print("\n## 卡使用分佈（base 變體；AI 為貪婪策略，佔比反映「可出頻率」非人類選擇）\n")
    print(card_table(datasets))


if __name__ == "__main__":
    main()
