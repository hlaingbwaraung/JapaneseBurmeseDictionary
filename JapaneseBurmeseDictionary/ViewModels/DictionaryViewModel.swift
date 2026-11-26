import Combine
import Foundation

@MainActor
public final class DictionaryViewModel: ObservableObject {
    @Published public var searchText: String = "" {
        didSet { performSearch() }
    }
    @Published public var selectedJLPT: JLPTLevel = .all {
        didSet { performSearch() }
    }

    @Published public private(set) var searchResults: [ScoredEntry] = []
    @Published public private(set) var detectedScript: DetectedScript = .empty
    @Published public private(set) var kanaPreview: String?

    @Published public private(set) var allEntries: [DictionaryEntry] = []
    @Published public private(set) var customEntries: [DictionaryEntry] = []
    @Published public private(set) var bookmarkedIDs: Set<String> = []
    @Published public private(set) var recentQueries: [String] = []
    @Published public private(set) var masteredIDs: Set<String> = []
    @Published public private(set) var loadErrorMessage: String?

    public let speech = SpeechService()

    private let store: UserWordsStore
    private let bundledEntries: [DictionaryEntry]
    private var engine: DictionarySearchEngine

    public init(
        bundledEntries: [DictionaryEntry]? = nil,
        store: UserWordsStore? = nil
    ) {
        let resolvedStore = store ?? UserWordsStore()
        self.store = resolvedStore
        self.bookmarkedIDs = resolvedStore.loadBookmarkedIDs()
        self.recentQueries = resolvedStore.loadRecentQueries()
        self.masteredIDs = resolvedStore.loadMasteredIDs()
        let savedCustom = resolvedStore.loadCustomEntries()
        self.customEntries = savedCustom

        if let provided = bundledEntries {
            self.bundledEntries = provided
            self.loadErrorMessage = nil
        } else {
            do {
                self.bundledEntries = try DictionaryRepository.loadBundledEntries()
                self.loadErrorMessage = nil
            } catch {
                self.bundledEntries = []
                self.loadErrorMessage = error.localizedDescription
            }
        }

        let merged = savedCustom + self.bundledEntries
        self.allEntries = merged
        self.engine = DictionarySearchEngine(entries: merged)
        performSearch()
    }

    public var wordOfTheDay: DictionaryEntry? {
        engine.wordOfTheDay()
    }

    public var bookmarkedEntries: [DictionaryEntry] {
        allEntries.filter { bookmarkedIDs.contains($0.id) }
    }

    public func isBookmarked(_ entry: DictionaryEntry) -> Bool {
        bookmarkedIDs.contains(entry.id)
    }

    public func toggleBookmark(_ entry: DictionaryEntry) {
        if bookmarkedIDs.contains(entry.id) {
            bookmarkedIDs.remove(entry.id)
        } else {
            bookmarkedIDs.insert(entry.id)
        }
        store.saveBookmarkedIDs(bookmarkedIDs)
    }

    public func isMastered(_ entry: DictionaryEntry) -> Bool {
        masteredIDs.contains(entry.id)
    }

    public func setMastered(_ mastered: Bool, for entry: DictionaryEntry) {
        if mastered {
            masteredIDs.insert(entry.id)
        } else {
            masteredIDs.remove(entry.id)
        }
        store.saveMasteredIDs(masteredIDs)
    }

    public func resetMasteredProgress() {
        masteredIDs.removeAll()
        store.saveMasteredIDs(masteredIDs)
    }

    public func recordRecentQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentQueries.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        recentQueries.insert(trimmed, at: 0)
        if recentQueries.count > 12 {
            recentQueries = Array(recentQueries.prefix(12))
        }
        store.saveRecentQueries(recentQueries)
    }

    public func clearRecentQueries() {
        recentQueries.removeAll()
        store.saveRecentQueries([])
    }

    public func entries(for category: DictionaryCategory) -> [DictionaryEntry] {
        allEntries.filter { $0.category == category.rawValue }
    }

    public func entries(forJLPT level: JLPTLevel) -> [DictionaryEntry] {
        guard level != .all else { return allEntries }
        return allEntries.filter { $0.jlpt == level.rawValue }
    }

    public func relatedEntries(for entry: DictionaryEntry) -> [DictionaryEntry] {
        engine.relatedEntries(for: entry)
    }

    public func addCustomEntry(
        kanji: String,
        kana: String,
        romaji: String,
        burmese: String,
        burmesePhonetic: String,
        english: String,
        partOfSpeech: String,
        exampleJP: String,
        exampleMY: String
    ) {
        let cleanKanji = kanji.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanKana = kana.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedKana = cleanKana.isEmpty ? cleanKanji : cleanKana
        let cleanRomaji = romaji.trimmingCharacters(in: .whitespacesAndNewlines)

        var examples: [ExampleSentence] = []
        let trimmedExJP = exampleJP.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedExMY = exampleMY.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedExJP.isEmpty && !trimmedExMY.isEmpty {
            examples.append(
                ExampleSentence(
                    jp: trimmedExJP,
                    kana: "",
                    romaji: "",
                    my: trimmedExMY
                )
            )
        }

        let newEntry = DictionaryEntry(
            id: "custom_\(UUID().uuidString)",
            kanji: cleanKanji,
            kana: resolvedKana,
            romaji: cleanRomaji,
            burmese: burmese.trimmingCharacters(in: .whitespacesAndNewlines),
            burmesePhonetic: burmesePhonetic.trimmingCharacters(in: .whitespacesAndNewlines),
            english: english.trimmingCharacters(in: .whitespacesAndNewlines),
            partOfSpeech: partOfSpeech,
            partOfSpeechBurmese: "ကိုယ်ပိုင်မှတ်စု",
            jlpt: "Phrase",
            category: DictionaryCategory.custom.rawValue,
            examples: examples,
            isCustom: true
        )

        customEntries.insert(newEntry, at: 0)
        store.saveCustomEntries(customEntries)
        rebuildIndex()
    }

    public func deleteCustomEntry(_ entry: DictionaryEntry) {
        customEntries.removeAll { $0.id == entry.id }
        bookmarkedIDs.remove(entry.id)
        store.saveCustomEntries(customEntries)
        store.saveBookmarkedIDs(bookmarkedIDs)
        rebuildIndex()
    }

    private func rebuildIndex() {
        allEntries = customEntries + bundledEntries
        engine = DictionarySearchEngine(entries: allEntries)
        performSearch()
    }

    private func performSearch() {
        let output = engine.search(query: searchText, jlptFilter: selectedJLPT)
        searchResults = output.results
        detectedScript = output.detectedScript
        kanaPreview = output.kanaPreview
    }
}
