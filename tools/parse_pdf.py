# -*- coding: utf-8 -*-
"""从 Oxford 5000 PDF 抽取词条，输出 base JSON（单词/词性/级别）。
运行：python tools/parse_pdf.py
"""
import json
import re
import sys
from pathlib import Path

import pymupdf

PDF = Path(
    r"C:/Users/Stalin/Documents/xwechat_files/wxid_18vq8yelldxb22_bd4c/temp/"
    r"RWTemp/2026-11/9e20f478899dc29eb19741386f9343c8/The Oxford 5000_by CEFR level.pdf"
)
OUT = Path(__file__).resolve().parent.parent / "assets" / "data" / "base.json"

# 词性标记，允许 n., v., adj., adv., prep. 等组合，如 "bid n., v."
POS = r"(?:n|v|adj|adv|prep|conj|pron|det|exclam|number|modal|auxiliary)"
LINE_RE = re.compile(r"^(.+?)\s+((?:%s\.(?:/%s\.)?(?:,\s*)?)+)$" % (POS, POS))


def main() -> None:
    doc = pymupdf.open(PDF)
    level = None
    rows: list[dict] = []
    for page in doc:
        for raw in page.get_text().split("\n"):
            line = raw.strip().replace("\x08", "")
            if not line:
                continue
            if line in ("B2", "C1"):
                level = line
                continue
            # 跳过页眉页脚与说明段
            if line.startswith(("©", "The Oxford", "3000,")) or re.match(r"^\d+ / \d+$", line):
                continue
            m = LINE_RE.match(line)
            if not (level and m):
                continue
            word, pos = m.group(1).strip(), m.group(2).replace(" ", "")
            rows.append({"w": word.lower(), "pos": pos, "level": level})

    # 同一单词可能以不同词性分别出现在 B2 / C1（如 acid n. 与 acid adj.）
    # 处理策略：合并为一条，词性合并，级别取较低者（先学到的那一级）
    index: dict[str, dict] = {}
    words: list[dict] = []
    for r in rows:
        if r["w"] in index:
            item = index[r["w"]]
            merged = {p for p in (item["pos"] + "," + r["pos"]).split(",") if p}
            item["pos"] = ",".join(sorted(merged))
            continue
        item = {"id": len(words) + 1, **r}
        index[r["w"]] = item
        words.append(item)

    payload = {
        "version": 1,
        "source": "The Oxford 5000 by CEFR level (B2 + C1)",
        "count": len(words),
        "words": words,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=1), encoding="utf-8")

    b2 = sum(1 for w in words if w["level"] == "B2")
    print(f"解析完成：{len(words)} 词（B2 {b2} / C1 {len(words) - b2}） -> {OUT}")


if __name__ == "__main__":
    sys.exit(main())
