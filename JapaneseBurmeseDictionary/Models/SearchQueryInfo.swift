import Foundation

public enum DetectedScript: String, Sendable, Equatable {
    case empty
    case burmese
    case japanese
    case latin
    case mixed

    public var badgeLabel: String {
        switch self {
        case .empty:
            return ""
        case .burmese:
            return "🇲🇲 မြန်မာ → 🇯🇵 日本語"
        case .japanese:
            return "🇯🇵 日本語 → 🇲🇲 မြန်မာ"
        case .latin:
            return "🔤 Romaji / English → 🇯🇵 🇲🇲"
        case .mixed:
            return "🌐 Multi-script Search"
        }
    }
}

public enum MatchKind: String, Sendable, Equatable {
    case exact = "Exact"
    case stem = "Stem / Conjugated"
    case romajiKana = "Romaji → Kana"
    case prefix = "Starts With"
    case meaning = "Meaning"
    case example = "In Example"
}

public struct ScoredEntry: Identifiable, Hashable, Sendable {
    public let entry: DictionaryEntry
    public let score: Int
    public let matchKind: MatchKind

    public var id: String { entry.id }

    public init(entry: DictionaryEntry, score: Int, matchKind: MatchKind) {
        self.entry = entry
        self.score = score
        self.matchKind = matchKind
    }
}

public struct SearchOutput: Sendable {
    public let results: [ScoredEntry]
    public let detectedScript: DetectedScript
    public let kanaPreview: String?

    public init(results: [ScoredEntry], detectedScript: DetectedScript, kanaPreview: String?) {
        self.results = results
        self.detectedScript = detectedScript
        self.kanaPreview = kanaPreview
    }
}
