import Foundation

/// High-speed offline bidirectional search engine supporting:
/// - Japanese Kanji, Hiragana, Katakana, and conjugated verb/adjective forms
/// - Burmese Unicode (both literary -သည် and spoken -တယ် forms, plus Myanmar phonetic readings)
/// - Hepburn & Kunrei Romaji (including relaxed long vowels like "arigato" / "byoin")
/// - English glosses & example sentences
public final class DictionarySearchEngine: Sendable {
    private struct IndexedItem: Sendable {
        let entry: DictionaryEntry
        let kanjiNorm: String
        let kanaHira: String
        let romajiLower: String
        let romajiRelaxed: String
        let burmeseNorm: String
        let burmeseGlosses: [String]
        let burmeseStems: [String]
        let phoneticNorm: String
        let englishLower: String
        let englishTokens: [String]
        let examplesJP: String
        let examplesHira: String
        let examplesMY: String
        let examplesENRomaji: String
        let jlptPriority: Int
    }

    private let items: [IndexedItem]
    public let allEntries: [DictionaryEntry]

    public init(entries: [DictionaryEntry]) {
        self.allEntries = entries
        self.items = entries.map { entry in
            let kanjiNorm = entry.kanji.precomposedStringWithCanonicalMapping
            let kanaHira = RomajiKanaConverter.katakanaToHiragana(entry.kana.precomposedStringWithCanonicalMapping)
            let romajiLower = RomajiKanaConverter.normalizeRomaji(entry.romaji)
            let romajiRelaxed = RomajiKanaConverter.relaxRomajiVowels(entry.romaji)
            let burmeseNorm = BurmeseNormalizer.normalize(entry.burmese)
            let glosses = BurmeseNormalizer.splitGlosses(entry.burmese)
            let stems = glosses.map { BurmeseNormalizer.stem($0) }
            let phoneticNorm = BurmeseNormalizer.normalize(entry.burmesePhonetic)
            let englishLower = entry.english.lowercased()
            let englishTokens = englishLower
                .components(separatedBy: CharacterSet(charactersIn: ";,()/ "))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let exJP = entry.examples.map(\.jp).joined(separator: " ")
            let exHira = RomajiKanaConverter.katakanaToHiragana(entry.examples.map(\.kana).joined(separator: " "))
            let exMY = BurmeseNormalizer.normalize(entry.examples.map(\.my).joined(separator: " "))
            let exRomaji = entry.examples.map(\.romaji).joined(separator: " ").lowercased()

            return IndexedItem(
                entry: entry,
                kanjiNorm: kanjiNorm,
                kanaHira: kanaHira,
                romajiLower: romajiLower,
                romajiRelaxed: romajiRelaxed,
                burmeseNorm: burmeseNorm,
                burmeseGlosses: glosses,
                burmeseStems: stems,
                phoneticNorm: phoneticNorm,
                englishLower: englishLower,
                englishTokens: englishTokens,
                examplesJP: exJP,
                examplesHira: exHira,
                examplesMY: exMY,
                examplesENRomaji: exRomaji,
                jlptPriority: JLPTLevel.sortPriority(for: entry.jlpt)
            )
        }
    }

    public func detectScript(_ rawQuery: String) -> DetectedScript {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }

        let hasMY = BurmeseNormalizer.containsMyanmar(trimmed)
        let hasJP = JapaneseDeinflector.containsJapanese(trimmed)
        let hasLatin = trimmed.unicodeScalars.contains { ($0.value >= 0x41 && $0.value <= 0x5A) || ($0.value >= 0x61 && $0.value <= 0x7A) }

        let count = [hasMY, hasJP, hasLatin].filter { $0 }.count
        if count > 1 { return .mixed }
        if hasMY { return .burmese }
        if hasJP { return .japanese }
        if hasLatin { return .latin }
        return .mixed
    }

    public func search(
        query rawQuery: String,
        jlptFilter: JLPTLevel = .all,
        categoryFilter: DictionaryCategory? = nil
    ) -> SearchOutput {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let script = detectScript(trimmed)

        // Filter-only browse mode when query is empty
        if trimmed.isEmpty {
            let filtered = items
                .filter { matchesFilters($0.entry, jlptFilter: jlptFilter, categoryFilter: categoryFilter) }
                .map { ScoredEntry(entry: $0.entry, score: 100, matchKind: .exact) }
            return SearchOutput(results: filtered, detectedScript: .empty, kanaPreview: nil)
        }

        let qNormMY = BurmeseNormalizer.normalize(trimmed)
        let qStemMY = BurmeseNormalizer.stem(qNormMY)
        let qHira = RomajiKanaConverter.katakanaToHiragana(trimmed.precomposedStringWithCanonicalMapping)
        let qDeinflected = JapaneseDeinflector.candidates(for: trimmed)
        let qDeinflectedHira = JapaneseDeinflector.candidates(for: qHira)

        let qLower = RomajiKanaConverter.normalizeRomaji(trimmed)
        let qRelaxed = RomajiKanaConverter.relaxRomajiVowels(trimmed)
        let qConvertedHira = (script == .latin) ? RomajiKanaConverter.romajiToHiragana(trimmed) : nil
        let kanaPreview: String? = {
            guard let hira = qConvertedHira, trimmed.count >= 2 else { return nil }
            let kata = RomajiKanaConverter.hiraganaToKatakana(hira)
            return "\(hira) / \(kata)"
        }()

        var scored: [ScoredEntry] = []
        scored.reserveCapacity(64)

        for item in items {
            guard matchesFilters(item.entry, jlptFilter: jlptFilter, categoryFilter: categoryFilter) else {
                continue
            }

            if let match = scoreItem(
                item,
                rawTrimmed: trimmed,
                qNormMY: qNormMY,
                qStemMY: qStemMY,
                qHira: qHira,
                qDeinflected: qDeinflected,
                qDeinflectedHira: qDeinflectedHira,
                qLower: qLower,
                qRelaxed: qRelaxed,
                qConvertedHira: qConvertedHira
            ) {
                scored.append(match)
            }
        }

        scored.sort { lhs, rhs in
            if lhs.score != rhs.score {
                return lhs.score > rhs.score
            }
            let p1 = JLPTLevel.sortPriority(for: lhs.entry.jlpt)
            let p2 = JLPTLevel.sortPriority(for: rhs.entry.jlpt)
            if p1 != p2 {
                return p1 < p2
            }
            if lhs.entry.kanji.count != rhs.entry.kanji.count {
                return lhs.entry.kanji.count < rhs.entry.kanji.count
            }
            return lhs.entry.id < rhs.entry.id
        }

        return SearchOutput(results: scored, detectedScript: script, kanaPreview: kanaPreview)
    }

    private func matchesFilters(
        _ entry: DictionaryEntry,
        jlptFilter: JLPTLevel,
        categoryFilter: DictionaryCategory?
    ) -> Bool {
        if jlptFilter != .all && entry.jlpt != jlptFilter.rawValue {
            return false
        }
        if let cat = categoryFilter, entry.category != cat.rawValue {
            return false
        }
        return true
    }

    private func scoreItem(
        _ item: IndexedItem,
        rawTrimmed: String,
        qNormMY: String,
        qStemMY: String,
        qHira: String,
        qDeinflected: [String],
        qDeinflectedHira: [String],
        qLower: String,
        qRelaxed: String,
        qConvertedHira: String?
    ) -> ScoredEntry? {
        // 1. Exact matches across all 4 scripts (1000..960)
        if item.kanjiNorm == rawTrimmed || item.kanaHira == qHira {
            return ScoredEntry(entry: item.entry, score: 1000, matchKind: .exact)
        }
        if item.burmeseNorm == qNormMY || item.burmeseGlosses.contains(qNormMY) {
            return ScoredEntry(entry: item.entry, score: 995, matchKind: .exact)
        }
        if !qLower.isEmpty && item.romajiLower == qLower {
            return ScoredEntry(entry: item.entry, score: 990, matchKind: .exact)
        }
        if !qLower.isEmpty && (item.englishLower == qLower || item.englishLower == "to \(qLower)") {
            return ScoredEntry(entry: item.entry, score: 985, matchKind: .exact)
        }

        // 2. Romaji -> Kana exact or relaxed long-vowel Romaji match (940..910)
        if let convHira = qConvertedHira, item.kanaHira == convHira {
            return ScoredEntry(entry: item.entry, score: 940, matchKind: .romajiKana)
        }
        if qRelaxed.count >= 3 && item.romajiRelaxed == qRelaxed {
            return ScoredEntry(entry: item.entry, score: 925, matchKind: .romajiKana)
        }

        // 3. Stem / De-inflected matches for Burmese ("စားတယ်" -> "စားသည်") & Japanese ("食べました" -> "食べる")
        if BurmeseNormalizer.containsMyanmar(qStemMY) && !qStemMY.isEmpty {
            if item.burmeseStems.contains(qStemMY) {
                return ScoredEntry(entry: item.entry, score: 915, matchKind: .stem)
            }
            if item.phoneticNorm == qNormMY {
                return ScoredEntry(entry: item.entry, score: 905, matchKind: .exact)
            }
        }
        for candidate in qDeinflected where item.kanjiNorm == candidate {
            return ScoredEntry(entry: item.entry, score: 910, matchKind: .stem)
        }
        for candidateHira in qDeinflectedHira where item.kanaHira == candidateHira {
            return ScoredEntry(entry: item.entry, score: 900, matchKind: .stem)
        }

        // 4. Whole-word English gloss match (e.g. "eat", "station", "water")
        if !qLower.isEmpty {
            let englishParts = item.englishLower
                .components(separatedBy: CharacterSet(charactersIn: ";,"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if englishParts.contains(qLower) || englishParts.contains("to \(qLower)") {
                return ScoredEntry(entry: item.entry, score: 880, matchKind: .meaning)
            }
            if item.englishTokens.contains(qLower) && qLower.count >= 2 {
                return ScoredEntry(entry: item.entry, score: 820, matchKind: .meaning)
            }
        }

        // 5. Prefix matches (780..720)
        if item.kanjiNorm.hasPrefix(rawTrimmed) || item.kanaHira.hasPrefix(qHira) {
            return ScoredEntry(entry: item.entry, score: 780, matchKind: .prefix)
        }
        if let convHira = qConvertedHira, convHira.count >= 2, item.kanaHira.hasPrefix(convHira) {
            return ScoredEntry(entry: item.entry, score: 765, matchKind: .romajiKana)
        }
        if BurmeseNormalizer.containsMyanmar(qNormMY) {
            if item.burmeseGlosses.contains(where: { $0.hasPrefix(qNormMY) })
                || (qStemMY.count >= 1 && item.burmeseStems.contains(where: { $0.hasPrefix(qStemMY) })) {
                return ScoredEntry(entry: item.entry, score: 760, matchKind: .prefix)
            }
        }
        if qLower.count >= 2 && (item.romajiLower.hasPrefix(qLower) || item.romajiRelaxed.hasPrefix(qRelaxed)) {
            return ScoredEntry(entry: item.entry, score: 740, matchKind: .prefix)
        }
        if qLower.count >= 3 && item.englishTokens.contains(where: { $0.hasPrefix(qLower) }) {
            return ScoredEntry(entry: item.entry, score: 710, matchKind: .prefix)
        }

        // 6. Substring matches in headwords, Burmese meanings, or phonetic readings (620..500)
        if item.kanjiNorm.contains(rawTrimmed) || item.kanaHira.contains(qHira) {
            return ScoredEntry(entry: item.entry, score: 620, matchKind: .meaning)
        }
        if BurmeseNormalizer.containsMyanmar(qNormMY) {
            if item.burmeseNorm.contains(qNormMY) || item.burmeseNorm.contains(qStemMY) {
                return ScoredEntry(entry: item.entry, score: 610, matchKind: .meaning)
            }
            if item.phoneticNorm.contains(qNormMY) {
                return ScoredEntry(entry: item.entry, score: 560, matchKind: .meaning)
            }
        }
        if qLower.count >= 3 {
            if item.romajiLower.contains(qLower) {
                return ScoredEntry(entry: item.entry, score: 540, matchKind: .meaning)
            }
            if item.englishLower.contains(qLower) {
                return ScoredEntry(entry: item.entry, score: 510, matchKind: .meaning)
            }
        }

        // 7. Example sentence matches (350)
        if rawTrimmed.count >= 2 {
            if item.examplesJP.contains(rawTrimmed)
                || item.examplesHira.contains(qHira)
                || (BurmeseNormalizer.containsMyanmar(qNormMY) && item.examplesMY.contains(qNormMY))
                || (qLower.count >= 4 && item.examplesENRomaji.contains(qLower)) {
                return ScoredEntry(entry: item.entry, score: 350, matchKind: .example)
            }
        }

        return nil
    }

    public func wordOfTheDay(for date: Date = Date()) -> DictionaryEntry? {
        guard !allEntries.isEmpty else { return nil }
        let dayOrdinal = Calendar(identifier: .gregorian).ordinality(of: .day, in: .era, for: date) ?? 1
        let index = abs(dayOrdinal * 31) % allEntries.count
        return allEntries[index]
    }

    public func relatedEntries(for target: DictionaryEntry, limit: Int = 5) -> [DictionaryEntry] {
        guard !allEntries.isEmpty else { return [] }
        let targetKanjiScalars = Set(target.kanji.unicodeScalars.filter { (0x4E00...0x9FFF).contains($0.value) })

        var candidates: [(DictionaryEntry, Int)] = []
        for candidate in allEntries where candidate.id != target.id {
            var relevance = 0
            if !targetKanjiScalars.isEmpty {
                let shared = candidate.kanji.unicodeScalars.filter { targetKanjiScalars.contains($0) }.count
                relevance += shared * 20
            }
            if candidate.category == target.category {
                relevance += 5
            }
            if candidate.jlpt == target.jlpt {
                relevance += 2
            }
            if relevance >= 5 {
                candidates.append((candidate, relevance))
            }
        }

        candidates.sort { a, b in
            if a.1 != b.1 { return a.1 > b.1 }
            return a.0.id < b.0.id
        }
        return Array(candidates.prefix(limit).map(\.0))
    }
}
