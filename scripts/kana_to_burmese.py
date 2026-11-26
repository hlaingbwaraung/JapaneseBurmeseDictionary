#!/usr/bin/env python3
"""
Deterministic Japanese Kana (Hiragana/Katakana) -> Burmese Phonetic (အသံထွက်) transliterator.
Respects Myanmar Unicode 5.1+ syllable & vowel-combining orthography (no dotted circles!).
"""

from __future__ import annotations

EXPLICIT_OVERRIDES: dict[str, str] = {
    "こんにちは": "ကွန်နိချိဝ",
    "こんばんは": "ကွန်ဘန်းဝ",
    "おはようございます": "အိုဟာယိုး ဂိုဇာအိမတ်စ်",
    "ありがとうございます": "အာရိဂါတိုး ဂိုဇာအိမတ်စ်",
    "ありがとう": "အာရိဂါတိုး",
    "すみません": "စုမိမဆဲန်",
    "ごめんなさい": "ဂိုမဲန်နဆိုင်း",
    "おねがいします": "အိုနဲဂါအိရှိမတ်စ်",
    "よろしくおねがいします": "ယိုရိုရှိကု အိုနဲဂါအိရှိမတ်စ်",
    "はじめまして": "ဟာဂျိမဲမရှိတဲ",
    "いただきます": "အိတာဒါကိမတ်စ်",
    "ごちそうさまでした": "ဂိုချိဆိုးဆာမာ ဒဲရှိတာ",
    "おつかれさまです": "အိုဆုကာရဲဆာမာဒဲစ်",
    "いってきます": "အိတ္တဲကိမတ်စ်",
    "いってらっしゃい": "အိတ္တဲရတ်ရှိုင်း",
    "ただいま": "တာဒါအိမာ",
    "おかえりなさい": "အိုကာအဲရိနဆိုင်း",
    "だいじょうぶ": "ဒိုင်ဂျိုးဘု",
    "わかりました": "ဝါကာရိမရှိတာ",
    "わかりません": "ဝါကာရိမဆဲန်",
}

DIGRAPHS: dict[str, str] = {
    "きゃ": "ကျာ", "きゅ": "ကျု", "きょ": "ကျို",
    "しゃ": "ရှာ", "しゅ": "ရှု", "しょ": "ရှို",
    "ちゃ": "ချာ", "ちゅ": "ချု", "ちょ": "ချို",
    "にゃ": "ညာ", "にゅ": "ညု", "にょ": "ညို",
    "ひゃ": "ဟျာ", "ひゅ": "ဟျု", "ひょ": "ဟျို",
    "みゃ": "မျာ", "みゅ": "မျု", "みょ": "မျို",
    "りゃ": "ရျာ", "りゅ": "ရျု", "りょ": "ရျို",
    "ぎゃ": "ဂျာ", "ぎゅ": "ဂျု", "ぎょ": "ဂျို",
    "じゃ": "ဂျာ", "じゅ": "ဂျု", "じょ": "ဂျို",
    "びゃ": "ဗျာ", "びゅ": "ဗျု", "びょ": "ဗျို",
    "ぴゃ": "ပျာ", "ぴゅ": "ပျု", "ぴょ": "ပျို",
    "ティ": "တိ", "ディ": "ဒိ", "ファ": "ဖာ", "フィ": "ဖိ", "フェ": "ဖဲ", "フォ": "ဖို",
    "ウィ": "ဝိ", "ウェ": "ဝဲ", "ウォ": "ဝို", "シェ": "ရှဲ", "チェ": "ချဲ", "ジェ": "ဂျဲ",
}

MONOGRAPHS: dict[str, str] = {
    "あ": "အာ", "い": "အိ", "う": "အု", "え": "အဲ", "お": "အို",
    "か": "ကာ", "き": "ကိ", "く": "ကု", "け": "ကဲ", "こ": "ကို",
    "さ": "ဆာ", "し": "ရှိ", "す": "စု", "せ": "ဆဲ", "そ": "ဆို",
    "た": "တာ", "ち": "ချိ", "つ": "ဆု", "て": "တဲ", "と": "တို",
    "な": "နာ", "に": "နိ", "ぬ": "နု", "ね": "နဲ", "の": "နို",
    "は": "ဟာ", "ひ": "ဟိ", "ふ": "ဖု", "へ": "ဟဲ", "ほ": "ဟို",
    "ま": "မာ", "み": "မိ", "む": "မု", "め": "မဲ", "も": "မို",
    "や": "ယာ", "ゆ": "ယု", "よ": "ယို",
    "ら": "ရာ", "り": "ရိ", "る": "ရု", "れ": "ရဲ", "ろ": "ရို",
    "わ": "ဝါ", "を": "အို",
    "が": "ဂါ", "ぎ": "ဂိ", "ぐ": "ဂု", "げ": "ဂဲ", "ご": "ဂို",
    "ざ": "ဇာ", "じ": "ဂျိ", "ず": "ဇု", "ぜ": "ဇဲ", "ぞ": "ဇို",
    "だ": "ဒါ", "ぢ": "ဂျိ", "づ": "ဇု", "で": "ဒဲ", "ど": "ဒို",
    "ば": "ဘာ", "び": "ဘိ", "ぶ": "ဘု", "べ": "ဘဲ", "ぼ": "ဘို",
    "ぱ": "ပါ", "ぴ": "ပိ", "ぷ": "ပု", "ぺ": "ပဲ", "ぽ": "ပို",
    "ぁ": "အာ", "ぃ": "အိ", "ぅ": "အု", "ぇ": "အဲ", "ぉ": "အို",
    "ゔ": "ဗု",
}


def katakana_to_hiragana(text: str) -> str:
    out = []
    for ch in text:
        code = ord(ch)
        if 0x30A1 <= code <= 0x30F6:
            out.append(chr(code - 0x60))
        else:
            out.append(ch)
    return "".join(out)


def lengthen_burmese_syllable(syl: str) -> str:
    """Apply proper Myanmar Unicode long-vowel orthography."""
    if syl.endswith(("း", "်")):
        return syl
    if syl.endswith("\u102d\u102f"):  # -ို -> -ိုး
        return syl + "\u1038"
    if syl.endswith("\u102d"):        # -ိ -> -ီး
        return syl[:-1] + "\u102e\u1038"
    if syl.endswith("\u102f"):        # -ု -> -ူး
        return syl[:-1] + "\u1030\u1038"
    if syl.endswith(("\u102c", "\u102b")):  # -ာ / -ါ -> -ား / -ါး
        return syl + "\u1038"
    if syl.endswith("\u1032"):        # -ဲ -> keep -ဲ (already high/heavy tone)
        return syl
    return syl


def add_nasal_coda(syl: str) -> str:
    """Attach Japanese ん coda using natural Myanmar closed-syllable spelling."""
    if syl.endswith("\u1038"):
        syl = syl[:-1]
    if syl.endswith("\u102d\u102f"):      # -ို + ん -> -ွန် (e.g. こ+ん -> ကွန်, ほ+ん -> ဟွန်)
        return syl[:-2] + "\u103d\u1014\u103a"
    if syl.endswith(("\u102c", "\u102b")):  # -ာ/-ါ + ん -> -န် (e.g. か+ん -> ကန်, さ+ん -> ဆန်)
        return syl[:-1] + "\u1014\u103a"
    if syl.endswith(("\u102d", "\u102e")):  # -ိ + ん -> -င် / -င်း (e.g. し+ん -> ရှင်, い+ん -> အင်း)
        base = syl[:-1]
        if base == "အ":
            return "အင်း"
        return base + "\u1004\u103a"
    if syl.endswith(("\u102f", "\u1030")):  # -ု + ん -> -ွန်း (e.g. ぶん -> ဘွန်း)
        return syl[:-1] + "\u103d\u1014\u103a\u1038"
    if syl.endswith("\u1032"):            # -ဲ + ん -> -ဲန် (valid Myanmar Unicode sequence)
        return syl + "\u1014\u103a"
    return syl + "\u1014\u103a"


def add_stop_coda(syl: str) -> str:
    """Attach Japanese っ geminate stop using natural Myanmar -တ် coda."""
    if syl.endswith("\u1038"):
        syl = syl[:-1]
    if syl.endswith("\u102d\u102f"):      # -ို + っ -> -ွတ်
        return syl[:-2] + "\u103d\u1010\u103a"
    if syl.endswith(("\u102c", "\u102b")):  # -ာ/-ါ + っ -> -တ် (e.g. が+っ -> ဂတ်)
        return syl[:-1] + "\u1010\u103a"
    if syl.endswith(("\u102d", "\u102e")):  # -ိ + っ -> -စ် (e.g. い+っ -> အစ်)
        return syl[:-1] + "\u1005\u103a"
    if syl.endswith(("\u102f", "\u1030")):  # -ု + っ -> -ွတ်
        return syl[:-1] + "\u103d\u1010\u103a"
    return syl + "\u1010\u103a"


def kana_to_burmese_phonetic(kana: str) -> str:
    clean = kana.strip().replace(" ", "").replace("　", "").replace("・", " ")
    if clean in EXPLICIT_OVERRIDES:
        return EXPLICIT_OVERRIDES[clean]

    hira = katakana_to_hiragana(clean)
    if hira in EXPLICIT_OVERRIDES:
        return EXPLICIT_OVERRIDES[hira]

    syllables: list[str] = []
    i = 0
    n = len(clean)

    while i < n:
        if clean[i] == " ":
            syllables.append(" ")
            i += 1
            continue

        if i + 1 < n and clean[i : i + 2] in DIGRAPHS:
            syl = DIGRAPHS[clean[i : i + 2]]
            i += 2
            if i < n and (
                clean[i] == "ー"
                or (
                    katakana_to_hiragana(clean[i]) == "う"
                    and (syl.endswith("\u102d\u102f") or syl.endswith("\u102f"))
                )
            ):
                syl = lengthen_burmese_syllable(syl)
                i += 1
            syllables.append(syl)
            continue

        pair_hira = katakana_to_hiragana(clean[i : i + 2])
        ch_hira = katakana_to_hiragana(clean[i])

        if ch_hira == "っ":
            if syllables and syllables[-1] != " ":
                syllables[-1] = add_stop_coda(syllables[-1])
            i += 1
            continue

        if clean[i] == "ー":
            if syllables and syllables[-1] != " ":
                syllables[-1] = lengthen_burmese_syllable(syllables[-1])
            i += 1
            continue

        if ch_hira == "ん":
            if syllables and syllables[-1] != " ":
                syllables[-1] = add_nasal_coda(syllables[-1])
            else:
                syllables.append("အင်း")
            i += 1
            continue

        if i + 1 < n and pair_hira in DIGRAPHS:
            syl = DIGRAPHS[pair_hira]
            i += 2
            if i < n and katakana_to_hiragana(clean[i]) == "う" and (
                syl.endswith("\u102d\u102f") or syl.endswith("\u102f")
            ):
                syl = lengthen_burmese_syllable(syl)
                i += 1
            syllables.append(syl)
            continue

        if ch_hira in MONOGRAPHS:
            syl = MONOGRAPHS[ch_hira]
            i += 1
            if i < n and katakana_to_hiragana(clean[i]) == "う" and (
                syl.endswith("\u102d\u102f") or syl.endswith("\u102f")
            ):
                syl = lengthen_burmese_syllable(syl)
                i += 1
            elif i < n and katakana_to_hiragana(clean[i]) == "い" and syl.endswith("\u1032"):
                # えい -> -ေး (long e in Japanese, e.g. せんせい -> ဆဲန်ဆေး, えいが -> အေးဂါ)
                syl = syl[:-1] + "\u1031\u1038"
                i += 1
            syllables.append(syl)
            continue

        i += 1

    return "".join(syllables)


if __name__ == "__main__":
    samples = [
        "たべる", "みず", "えき", "びょういん", "しんかんせん",
        "がっこう", "べんきょう", "でんしゃ", "コンビニ", "コーヒー",
        "せんせい", "えいが", "こんにちは", "ありがとうございます",
    ]
    for s in samples:
        print(f"{s} -> {kana_to_burmese_phonetic(s)}")
