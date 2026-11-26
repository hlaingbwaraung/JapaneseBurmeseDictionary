import Foundation

public enum DictionaryRepository {
    public enum RepositoryError: LocalizedError {
        case resourceNotFound
        case decodingFailed(String)

        public var errorDescription: String? {
            switch self {
            case .resourceNotFound:
                return "Could not find bundled dictionary_entries.json."
            case .decodingFailed(let detail):
                return "Failed to decode dictionary entries: \(detail)"
            }
        }
    }

    public static func loadBundledEntries(from bundle: Bundle = .main) throws -> [DictionaryEntry] {
        guard let url = bundle.url(forResource: "dictionary_entries", withExtension: "json") else {
            throw RepositoryError.resourceNotFound
        }
        return try loadEntries(from: url)
    }

    public static func loadEntries(from url: URL) throws -> [DictionaryEntry] {
        let data = try Data(contentsOf: url)
        do {
            return try JSONDecoder().decode([DictionaryEntry].self, from: data)
        } catch {
            throw RepositoryError.decodingFailed(error.localizedDescription)
        }
    }
}
