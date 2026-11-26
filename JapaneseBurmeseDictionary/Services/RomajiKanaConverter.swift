import Foundation

/// Bidirectional Kana <-> Romaji normalization supporting Hepburn, Kunrei-shiki, and relaxed long vowels.
public enum RomajiKanaConverter {
    private static let romajiTable: [String: String] = [
        // 3-character sequences
        "kya": "きゃ", "kyu": "きゅ", "kyo": "きょ",
        "sha": "しゃ", "shu": "しゅ", "sho": "しょ",
        "sya": "しゃ", "syu": "しゅ", "syo": "しょ",
        "cha": "ちゃ", "chu": "ちゅ", "cho": "ちょ",
        "tya": "ちゃ", "tyu": "ちゅ", "tyo": "ちょ",
        "cya": "ちゃ", "cyu": "ちゅ", "cyo": "ちょ",
        "nya": "にゃ", "nyu": "にゅ", "nyo": "にょ",
        "hya": "ひゃ", "hyu": "ひゅ", "hyo": "ひょ",
        "mya": "みゃ", "myu": "みゅ", "myo": "みょ",
        "rya": "りゃ", "ryu": "りゅ", "ryo": "りょ",
        "gya": "ぎゃ", "gyu": "ぎゅ", "gyo": "ぎょ",
        "zya": "じゃ", "zyu": "じゅ", "zyo": "じょ",
        "jya": "じゃ", "jyu": "じゅ", "jyo": "じょ",
        "bya": "びゃ", "byu": "びゅ", "byo": "びょ",
        "pya": "ぴゃ", "pyu": "ぴゅ", "pyo": "ぴょ",
        "shi": "し", "chi": "ち", "tsu": "つ",
        "xtu": "っ", "ltsu": "っ",
        // 2-character sequences
        "ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
        "sa": "さ", "si": "し", "su": "す", "se": "せ", "so": "そ",
        "ta": "た", "ti": "ち", "tu": "つ", "te": "て", "to": "と",
        "na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",
        "ha": "は", "hi": "ひ", "fu": "ふ", "hu": "ふ", "he": "へ", "ho": "ほ",
        "ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",
        "ya": "や", "yu": "ゆ", "yo": "よ",
        "ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",
        "wa": "わ", "wo": "を", "nn": "ん", "n'": "ん",
        "ga": "が", "gi": "ぎ", "gu": "ぐ", "ge": "げ", "go": "ご",
        "za": "ざ", "ji": "じ", "zi": "じ", "zu": "ず", "ze": "ぜ", "zo": "ぞ",
        "da": "だ", "di": "ぢ", "du": "づ", "de": "で", "do": "ど",
        "ba": "ば", "bi": "び", "bu": "ぶ", "be": "べ", "bo": "ぼ",
        "pa": "ぱ", "pi": "ぴ", "pu": "ぷ", "pe": "ぺ", "po": "ぽ",
        "ja": "じゃ", "ju": "じゅ", "jo": "じょ",
        "fa": "ふぁ", "fi": "ふぃ", "fe": "ふぇ", "fo": "ふぉ",
        // 1-character vowels
        "a": "あ", "i": "い", "u": "う", "e": "え", "o": "お",
        "-": "ー"
    ]

    private static let vowels: Set<Character> = ["a", "i", "u", "e", "o"]

    public static func katakanaToHiragana(_ text: String) -> String {
        var scalars: [Unicode.Scalar] = []
        scalars.reserveCapacity(text.unicodeScalars.count)
        for scalar in text.unicodeScalars {
            if (0x30A1...0x30F6).contains(scalar.value),
               let hira = Unicode.Scalar(scalar.value - 0x60) {
                scalars.append(hira)
            } else {
                scalars.append(scalar)
            }
        }
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars)
        return String(view)
    }

    public static func hiraganaToKatakana(_ text: String) -> String {
        var scalars: [Unicode.Scalar] = []
        scalars.reserveCapacity(text.unicodeScalars.count)
        for scalar in text.unicodeScalars {
            if (0x3041...0x3096).contains(scalar.value),
               let kata = Unicode.Scalar(scalar.value + 0x60) {
                scalars.append(kata)
            } else {
                scalars.append(scalar)
            }
        }
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars)
        return String(view)
    }

    public static func normalizeRomaji(_ text: String) -> String {
        var s = text.lowercased()
        let macronMap: [(String, String)] = [
            ("ā", "aa"), ("ī", "ii"), ("ū", "uu"), ("ē", "ee"), ("ō", "ou"),
            ("’", "'")
        ]
        for (src, dst) in macronMap {
            s = s.replacingOccurrences(of: src, with: dst)
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Collapses long vowel spellings so queries like "arigato", "byoin", "kohi", "tokyo" match "arigatou", "byouin", "koohii", "toukyou".
    public static func relaxRomajiVowels(_ text: String) -> String {
        var s = normalizeRomaji(text)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "'", with: "")
        let pairs: [(String, String)] = [
            ("ou", "o"), ("oo", "o"), ("uu", "u"),
            ("aa", "a"), ("ii", "i"), ("ee", "e")
        ]
        for (src, dst) in pairs {
            s = s.replacingOccurrences(of: src, with: dst)
        }
        return s
    }

    /// Converts Latin Romaji text into Hiragana if all tokens are valid Romaji syllables; returns nil if clearly non-Romaji English.
    public static func romajiToHiragana(_ raw: String) -> String? {
        let cleaned = normalizeRomaji(raw).replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return nil }
        let chars = Array(cleaned)
        // Must only contain ASCII letters, hyphen, or apostrophe
        for c in chars {
            if !(c.isASCII && (c.isLetter || c == "-" || c == "'")) {
                return nil
            }
        }

        var out = ""
        var i = 0
        let n = chars.count

        while i < n {
            // Check 4-char ("ltsu")
            if i + 4 <= n {
                let sub4 = String(chars[i..<(i + 4)])
                if let kana = romajiTable[sub4] {
                    out += kana
                    i += 4
                    continue
                }
            }

            // Handle "tch" -> っち / っちゃ
            if i + 3 <= n && chars[i] == "t" && chars[i + 1] == "c" && chars[i + 2] == "h" {
                out += "っ"
                i += 1
                continue
            }

            // Double consonant -> っ (except 'nn')
            if i + 1 < n {
                let c1 = chars[i]
                let c2 = chars[i + 1]
                if c1 == c2 && !vowels.contains(c1) && c1 != "n" && c1.isLetter {
                    out += "っ"
                    i += 1
                    continue
                }
            }

            // 3-char lookup
            if i + 3 <= n {
                let sub3 = String(chars[i..<(i + 3)])
                if let kana = romajiTable[sub3] {
                    out += kana
                    i += 3
                    continue
                }
            }

            // 2-char lookup
            if i + 2 <= n {
                let sub2 = String(chars[i..<(i + 2)])
                if let kana = romajiTable[sub2] {
                    out += kana
                    i += 2
                    continue
                }
            }

            // Moraic 'n' before consonant (not vowel or 'y') or at end of word
            if chars[i] == "n" {
                if i + 1 == n {
                    out += "ん"
                    i += 1
                    continue
                }
                let next = chars[i + 1]
                if !vowels.contains(next) && next != "y" {
                    out += "ん"
                    i += 1
                    continue
                }
            }

            // 1-char lookup
            let sub1 = String(chars[i])
            if let kana = romajiTable[sub1] {
                out += kana
                i += 1
                continue
            }

            // Unrecognized consonant cluster (e.g. English "hospital", "train") -> not pure Romaji
            return nil
        }

        return out.isEmpty ? nil : out
    }
}
