import Foundation

/// Lightweight rule-based Japanese de-inflector so conjugated verbs and adjectives
/// (e.g., 食べました, 行って, 高かった, 勉強しています) resolve back to dictionary base forms.
public enum JapaneseDeinflector {
    private static let rules: [(suffix: String, replacements: [String])] = [
        ("ませんでした", ["る", "う", "く", "ぐ", "す", "つ", "ぬ", "ぶ", "む"]),
        ("しています", ["する"]),
        ("しました", ["する"]),
        ("しません", ["する"]),
        ("している", ["する"]),
        ("して", ["する"]),
        ("しない", ["する"]),
        ("ました", ["る", "う", "く", "ぐ", "す", "つ", "ぬ", "ぶ", "む"]),
        ("ません", ["る", "う", "く", "ぐ", "す", "つ", "ぬ", "ぶ", "む"]),
        ("ます", ["る", "う", "く", "ぐ", "す", "つ", "ぬ", "ぶ", "む"]),
        ("ている", ["る", "う", "つ", "る"]),
        ("ていました", ["る", "う", "つ"]),
        ("なかった", ["い", "る", "う", "く", "す", "つ", "む"]),
        ("くない", ["い"]),
        ("かった", ["い"]),
        ("くて", ["い"]),
        ("いたい", ["う"]),
        ("きたい", ["く"]),
        ("したい", ["す", "する"]),
        ("たい", ["る"]),
        ("いた", ["く"]),
        ("いて", ["く"]),
        ("いだ", ["ぐ"]),
        ("いで", ["ぐ"]),
        ("んだ", ["む", "ぶ", "ぬ"]),
        ("んで", ["む", "ぶ", "ぬ"]),
        ("った", ["う", "つ", "る"]),
        ("って", ["う", "つ", "る"]),
        ("した", ["す"]),
        ("ない", ["る"]),
        ("た", ["る"]),
        ("て", ["る"])
    ]

    private static let godanIMap: [Character: Character] = [
        "い": "う",
        "き": "く",
        "ぎ": "ぐ",
        "し": "す",
        "ち": "つ",
        "に": "ぬ",
        "び": "ぶ",
        "み": "む",
        "り": "る"
    ]

    private static let godanAMap: [Character: Character] = [
        "わ": "う",
        "か": "く",
        "が": "ぐ",
        "さ": "す",
        "た": "つ",
        "な": "ぬ",
        "ば": "ぶ",
        "ま": "む",
        "ら": "る"
    ]

    public static func containsJapanese(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            let v = scalar.value
            if (0x3040...0x309F).contains(v)
                || (0x30A0...0x30FF).contains(v)
                || (0x4E00...0x9FFF).contains(v)
                || (0x3400...0x4DBF).contains(v) {
                return true
            }
        }
        return false
    }

    public static func candidates(for query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var seen: Set<String> = [trimmed]
        var result: [String] = []

        func add(_ s: String) {
            if !s.isEmpty && seen.insert(s).inserted {
                result.append(s)
            }
        }

        // Irregular verbs (来る / する)
        if ["きます", "きました", "きません", "きて", "こない"].contains(trimmed) {
            add("くる")
            add("来る")
        }
        if ["来ます", "来ました", "来ません", "来て", "来ない"].contains(trimmed) {
            add("来る")
        }
        if ["いきます", "いきました", "いって", "いった"].contains(trimmed) {
            add("いく")
        }
        if ["行きます", "行きました", "行って", "行った"].contains(trimmed) {
            add("行く")
        }

        // Polite masu-stem for Godan verbs: e.g. 飲みます -> 飲み -> 飲む
        for politeSuffix in ["ました", "ません", "ませんでした", "ます", "たい"] where trimmed.hasSuffix(politeSuffix) {
            let stem = String(trimmed.dropLast(politeSuffix.count))
            if let last = stem.last, let dictEnd = godanIMap[last] {
                add(String(stem.dropLast()) + String(dictEnd))
            }
        }

        // Negative nai-stem for Godan verbs: e.g. 飲まない -> 飲ま -> 飲む
        for negSuffix in ["なかった", "ない"] where trimmed.hasSuffix(negSuffix) {
            let stem = String(trimmed.dropLast(negSuffix.count))
            if let last = stem.last, let dictEnd = godanAMap[last] {
                add(String(stem.dropLast()) + String(dictEnd))
            }
        }

        // General suffix replacement rules
        for rule in rules where trimmed.hasSuffix(rule.suffix) {
            let base = String(trimmed.dropLast(rule.suffix.count))
            guard !base.isEmpty else { continue }
            for rep in rule.replacements {
                add(base + rep)
            }
        }

        return result
    }
}
