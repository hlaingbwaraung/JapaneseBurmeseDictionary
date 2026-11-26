import Foundation

/// Persists user bookmarks, recent search queries, flashcard progress, and custom user-created entries on-device.
public final class UserWordsStore {
    private let defaults: UserDefaults
    private let bookmarksKey = "jp_mm_dict.bookmarked_ids.v1"
    private let recentQueriesKey = "jp_mm_dict.recent_queries.v1"
    private let masteredIdsKey = "jp_mm_dict.mastered_ids.v1"
    private let customEntriesFilename = "custom_dictionary_entries.json"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadBookmarkedIDs() -> Set<String> {
        let array = defaults.stringArray(forKey: bookmarksKey) ?? []
        return Set(array)
    }

    public func saveBookmarkedIDs(_ ids: Set<String>) {
        defaults.set(Array(ids).sorted(), forKey: bookmarksKey)
    }

    public func loadRecentQueries() -> [String] {
        defaults.stringArray(forKey: recentQueriesKey) ?? []
    }

    public func saveRecentQueries(_ queries: [String]) {
        defaults.set(Array(queries.prefix(15)), forKey: recentQueriesKey)
    }

    public func loadMasteredIDs() -> Set<String> {
        let array = defaults.stringArray(forKey: masteredIdsKey) ?? []
        return Set(array)
    }

    public func saveMasteredIDs(_ ids: Set<String>) {
        defaults.set(Array(ids).sorted(), forKey: masteredIdsKey)
    }

    public func loadCustomEntries() -> [DictionaryEntry] {
        let url = customEntriesURL()
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([DictionaryEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    public func saveCustomEntries(_ entries: [DictionaryEntry]) {
        let url = customEntriesURL()
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(entries)
            try data.write(to: url, options: .atomic)
        } catch {
            // Ignore write errors in restricted environments
        }
    }

    private func customEntriesURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("JapaneseBurmeseDictionary", isDirectory: true)
            .appendingPathComponent(customEntriesFilename)
    }
}
