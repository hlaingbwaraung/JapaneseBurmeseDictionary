#!/usr/bin/env python3
"""
Builds and validates JapaneseBurmeseDictionary/Resources/dictionary_entries.json
from curated Japanese-Burmese vocabulary modules.
"""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))

from kana_to_burmese import kana_to_burmese_phonetic  # noqa: E402
from vocab.part1_greetings_verbs import ENTRIES_PART1  # noqa: E402
from vocab.part2_adjectives_food_travel import ENTRIES_PART2  # noqa: E402
from vocab.part3_work_daily_people import ENTRIES_PART3  # noqa: E402
from vocab.part4_health_shopping_time_nature import ENTRIES_PART4  # noqa: E402
from vocab.part5_numbers_questions_japan_life import ENTRIES_PART5  # noqa: E402
from vocab.part6_everyday_n4_n3_expansion import ENTRIES_PART6  # noqa: E402

POS_BURMESE: dict[str, str] = {
    "Noun": "နာမ်",
    "Pronoun": "နာမ်စား",
    "Counter": "အရေအတွက်ပြပုဒ်",
    "Verb (Ichidan)": "ကြိယာ (အုပ်စု ၂)",
    "Verb (Godan)": "ကြိယာ (အုပ်စု ၁)",
    "Verb (Irregular)": "ကြိယာ (အုပ်စု ၃)",
    "Verb (Suru)": "ကြိယာ (する)",
    "i-Adjective": "နာမဝိသေသန (い)",
    "na-Adjective": "နာမဝိသေသန (な)",
    "Adverb": "ကြိယာဝိသေသန",
    "Expression": "အသုံးအနှုန်း",
}

ZAWGYI_SUSPECT_RANGES = [
    (0x1060, 0x1097),  # Mon/Karen/Shan extensions abused by Zawgyi encoding
]


def has_myanmar_unicode(text: str) -> bool:
    return any(0x1000 <= ord(ch) <= 0x104F for ch in text)


def validate_myanmar_unicode(text: str, context: str) -> None:
    if not has_myanmar_unicode(text):
        raise ValueError(f"Missing Myanmar Unicode in {context}: {text!r}")
    for ch in text:
        cp = ord(ch)
        for lo, hi in ZAWGYI_SUSPECT_RANGES:
            if lo <= cp <= hi:
                raise ValueError(f"Zawgyi codepoint U+{cp:04X} detected in {context}: {text!r}")
    # Check invalid vowel+visarga combinations that produce dotted circles (allow valid -ိုး \u102d\u102f\u1038)
    if "\u102d\u1038" in text or re.search(r"(?<!\u102d)\u102f\u1038", text):
        raise ValueError(f"Invalid short vowel + visarga sequence in {context}: {text!r}")


def make_slug(romaji: str, index: int) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", romaji.lower()).strip("_")
    return f"entry_{index:04d}_{slug}"


def main() -> None:
    raw_all = (
        ENTRIES_PART1
        + ENTRIES_PART2
        + ENTRIES_PART3
        + ENTRIES_PART4
        + ENTRIES_PART5
        + ENTRIES_PART6
    )

    seen_keys: set[tuple[str, str]] = set()
    entries: list[dict] = []

    for row in raw_all:
        (
            kanji,
            kana,
            romaji,
            burmese,
            english,
            pos,
            jlpt,
            category,
            ex_jp,
            ex_kana,
            ex_romaji,
            ex_my,
        ) = row

        dedup_key = (kanji.strip(), kana.strip())
        if dedup_key in seen_keys:
            continue
        seen_keys.add(dedup_key)

        burmese_nfc = unicodedata.normalize("NFC", burmese.strip())
        ex_my_nfc = unicodedata.normalize("NFC", ex_my.strip())
        phonetic = unicodedata.normalize("NFC", kana_to_burmese_phonetic(kana))

        validate_myanmar_unicode(burmese_nfc, f"{kanji} burmese")
        validate_myanmar_unicode(ex_my_nfc, f"{kanji} example")
        validate_myanmar_unicode(phonetic, f"{kanji} phonetic")

        if pos not in POS_BURMESE:
            raise ValueError(f"Unknown POS {pos!r} on {kanji}")

        idx = len(entries) + 1
        entries.append(
            {
                "id": make_slug(romaji, idx),
                "kanji": unicodedata.normalize("NFC", kanji.strip()),
                "kana": unicodedata.normalize("NFC", kana.strip()),
                "romaji": romaji.strip(),
                "burmese": burmese_nfc,
                "burmesePhonetic": phonetic,
                "english": english.strip(),
                "partOfSpeech": pos,
                "partOfSpeechBurmese": POS_BURMESE[pos],
                "jlpt": jlpt,
                "category": category,
                "examples": [
                    {
                        "jp": unicodedata.normalize("NFC", ex_jp.strip()),
                        "kana": unicodedata.normalize("NFC", ex_kana.strip()),
                        "romaji": ex_romaji.strip(),
                        "my": ex_my_nfc,
                    }
                ],
            }
        )

    out_path = ROOT / "JapaneseBurmeseDictionary" / "Resources" / "dictionary_entries.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(entries, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # Summary stats
    by_cat: dict[str, int] = {}
    by_jlpt: dict[str, int] = {}
    for e in entries:
        by_cat[e["category"]] = by_cat.get(e["category"], 0) + 1
        by_jlpt[e["jlpt"]] = by_jlpt.get(e["jlpt"], 0) + 1

    print(f"Built {len(entries)} validated Japanese-Burmese entries -> {out_path}")
    print("Categories:", json.dumps(by_cat, ensure_ascii=False))
    print("JLPT:", json.dumps(by_jlpt, ensure_ascii=False))


if __name__ == "__main__":
    main()
