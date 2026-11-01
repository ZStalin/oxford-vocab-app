# -*- coding: utf-8 -*-
"""合并：base.json（单词/词性/级别）+ cn_*.txt（中文释义）+ cmudict（音标）
输出 assets/data/words.json，供 App 直接读取。
运行：python tools/build_words.py
"""
import json
import re
from pathlib import Path

import cmudict

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "assets" / "data"

# ---------- ARPAbet -> IPA（美音） ----------
MAP = {
    "AA": "ɑ", "AE": "æ", "AH": "ʌ", "AO": "ɔ", "AW": "aʊ", "AY": "aɪ",
    "EH": "ɛ", "ER": "ɝ", "EY": "eɪ", "IH": "ɪ", "IY": "i", "OW": "oʊ",
    "OY": "ɔɪ", "UH": "ʊ", "UW": "u",
    "B": "b", "CH": "tʃ", "D": "d", "DH": "ð", "F": "f", "G": "ɡ", "HH": "h",
    "JH": "dʒ", "K": "k", "L": "l", "M": "m", "N": "n", "NG": "ŋ", "P": "p",
    "R": "r", "S": "s", "SH": "ʃ", "T": "t", "TH": "θ", "V": "v", "W": "w",
    "Y": "j", "Z": "z", "ZH": "ʒ",
}
VOWELS = {k for k in MAP if len(k) == 2}

# 合法的英语音节首辅音群（用于判断重音符号该插在哪）
LEGAL_ONSETS = {
    "PR", "PL", "BR", "BL", "TR", "DR", "KR", "KL", "GR", "GL", "FR", "FL",
    "THR", "SHR", "SP", "ST", "SK", "SM", "SN", "SL", "SW", "SF", "PY", "BY",
    "KY", "GY", "FY", "VY", "MY", "NY", "HY", "LY", "RY", "TW", "DW", "KW",
    "GW", "SPR", "SPL", "STR", "SKR", "SKW", "SKY",
}


def _onset_start(tokens: list[str], v: int) -> int:
    """返回元音 v 所在音节的起始音素下标（最大合法音节首）。"""
    j = v - 1
    cluster: list[str] = []
    while j >= 0 and tokens[j].rstrip("012") not in VOWELS:
        cluster.insert(0, tokens[j].rstrip("012"))
        j -= 1
    for k in range(len(cluster), 0, -1):
        tail = "".join(cluster[-k:])
        if k == 1 or tail in LEGAL_ONSETS:
            return v - k
    return v - 1 if v > 0 else 0


def to_ipa(phones: list[str]) -> str:
    """ARPAbet -> IPA（美音），含弱读元音处理与重音符号。"""
    tokens = list(phones)
    out: list[str] = []
    marks: list[tuple[int, str]] = []   # (音素下标, 符号)

    for i, p in enumerate(tokens):
        base = p.rstrip("012")
        stress = int(p[-1]) if p[-1].isdigit() else 0
        if base in VOWELS:
            start = _onset_start(tokens, i)
            if stress == 1:
                marks.append((start, "ˈ"))
            elif stress == 2:
                marks.append((start, "ˌ"))
        # 弱读：AH0 -> ə, ER0 -> ɚ
        if base == "AH" and stress == 0:
            sym = "ə"
        elif base == "ER" and stress == 0:
            sym = "ɚ"
        else:
            sym = MAP.get(base, base.lower())
        out.append(sym)

    offsets, acc = [], 0
    for ph in out:
        offsets.append(acc)
        acc += len(ph)
    text = "".join(out)
    for pos, mark in sorted(marks, key=lambda x: -x[0]):
        text = text[: offsets[pos]] + mark + text[offsets[pos]:]
    return text.replace("ɝ", "ɜr").replace("ɚ", "ər")


BRITISH = {
    "colourful": "colorful", "flavour": "flavor", "litre": "liter",
    "councillor": "councilor", "enrol": "enroll", "favourable": "favorable",
    "sceptical": "skeptical", "harbour": "harbor", "neighbouring": "neighboring",
    "rumour": "rumor", "colour": "color", "centre": "center",
}


def ipa_of(word: str, dic) -> str:
    w = word.lower().strip()
    if not w:
        return ""
    # 连字符词：分段拼接
    if "-" in w:
        parts = [ipa_of(p, dic) for p in w.split("-") if p]
        return "-".join(p for p in parts if p)
    w = BRITISH.get(w, w)
    entries = dic.get(w)
    if not entries:
        # 去掉词尾 s / ed / ing 再试一次（简单回退）
        for suf in ("s", "es", "ed", "ing", "ly", "er", "est"):
            if w.endswith(suf) and dic.get(w[: -len(suf)]):
                entries = dic[w[: -len(suf)]]
                break
    if not entries:
        return ""
    return to_ipa(entries[0])


# ---------- 单词规整 ----------
NOTE_RE = re.compile(r"\s*\(([^)]*)\)\s*")
HOMO_RE = re.compile(r"\d+$")


def normalize(raw: str) -> tuple[str, str]:
    """counter (long flat surface) -> ('counter', 'long flat surface')
    bass1 -> ('bass', '')"""
    note = ""
    m = NOTE_RE.search(raw)
    if m:
        note = m.group(1).strip()
    word = NOTE_RE.sub("", raw).strip()
    word = HOMO_RE.sub("", word).strip()
    return word.lower(), note


def main() -> None:
    base = json.loads((DATA / "base.json").read_text(encoding="utf-8"))
    dic = cmudict.dict()

    cn: dict[int, str] = {}
    for f in sorted(DATA.glob("cn_*.txt")):
        for line in f.read_text(encoding="utf-8").splitlines():
            if "|" not in line:
                continue
            k, v = line.split("|", 1)
            cn[int(k)] = v.strip()

    # 例句：id|英文|中文
    examples: dict[int, tuple[str, str]] = {}
    for f in sorted(DATA.glob("ex_*.txt")):
        for line in f.read_text(encoding="utf-8").splitlines():
            parts = line.split("|")
            if len(parts) != 3 or not parts[0].strip().isdigit():
                continue
            examples[int(parts[0])] = (parts[1].strip(), parts[2].strip())

    merged: dict[str, dict] = {}
    order: list[str] = []
    for item in base["words"]:
        word, note = normalize(item["w"])
        meaning = cn.get(item["id"], "")
        ex, ex_cn = examples.get(item["id"], ("", ""))
        if word in merged:
            cur = merged[word]
            senses = [s for s in (cur["cn"] + "；" + meaning).split("；") if s]
            seen, uniq = set(), []
            for s in senses:
                if s not in seen:
                    seen.add(s)
                    uniq.append(s)
            cur["cn"] = "；".join(uniq)
            pos = {p for p in (cur["pos"] + "," + item["pos"]).split(",") if p}
            cur["pos"] = ",".join(sorted(pos))
            if note and note not in cur.get("note", ""):
                cur["note"] = (cur.get("note", "") + "；" + note).strip("；")
            continue
        merged[word] = {
            "id": 0,
            "w": word,
            "pos": item["pos"],
            "level": item["level"],
            "ipa": ipa_of(word, dic),
            "cn": meaning,
            "note": note,
            "ex": ex,
            "exCn": ex_cn,
        }
        order.append(word)

    words = [merged[w] for w in order]
    for i, w in enumerate(words, start=1):
        w["id"] = i

    missing_cn = [w["w"] for w in words if not w["cn"]]
    missing_ipa = [w["w"] for w in words if not w["ipa"]]
    payload = {
        "version": 1,
        "source": "The Oxford 5000 by CEFR level (B2 + C1)",
        "count": len(words),
        "words": words,
    }
    (DATA / "words.json").write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )
    print(f"合并完成：{len(words)} 词 -> words.json")
    print(f"缺中文释义：{len(missing_cn)} {missing_cn[:10]}")
    print(f"缺音标：{len(missing_ipa)} {missing_ipa[:10]}")


if __name__ == "__main__":
    main()
