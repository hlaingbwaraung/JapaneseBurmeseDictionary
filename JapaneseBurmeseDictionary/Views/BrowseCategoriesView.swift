import SwiftUI

@MainActor
struct BrowseCategoriesView: View {
    @ObservedObject var viewModel: DictionaryViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    jlptSection
                    categoriesSection
                }
                .padding(16)
            }
            .navigationTitle("အမျိုးအစား • Browse")
        }
    }

    private var jlptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("JLPT အဆင့်အလိုက် • By JLPT Level")
                .font(.headline)
                .padding(.vertical, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(JLPTLevel.allCases.filter { $0 != .all }) { level in
                        let items = viewModel.entries(forJLPT: level)
                        NavigationLink {
                            FilteredEntryListView(
                                title: "JLPT \(level.displayTitle)",
                                subtitle: "\(items.count) entries",
                                entries: items,
                                viewModel: viewModel
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                JLPTBadgeView(level: level.rawValue)
                                Text("\(items.count) words")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 104, alignment: .leading)
                            .padding(12)
                            .background(Color.secondary.opacity(0.09))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ကဏ္ဍအလိုက် • By Topic Category")
                .font(.headline)
                .padding(.vertical, 2)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(DictionaryCategory.browseableCategories) { category in
                    let items = viewModel.entries(for: category)
                    NavigationLink {
                        FilteredEntryListView(
                            title: category.rawValue,
                            subtitle: category.burmeseTitle,
                            entries: items,
                            viewModel: viewModel
                        )
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: category.iconName)
                                    .font(.title3)
                                    .foregroundColor(.accentColor)
                                Spacer()
                                Text("\(items.count)")
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundColor(.accentColor)
                                    .clipShape(Capsule())
                            }

                            Text(category.burmeseTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .padding(.vertical, 2)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.secondary.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

@MainActor
struct FilteredEntryListView: View {
    let title: String
    let subtitle: String
    let entries: [DictionaryEntry]
    @ObservedObject var viewModel: DictionaryViewModel
    @State private var localFilter: String = ""

    private var visibleEntries: [DictionaryEntry] {
        let trimmed = localFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        let miniEngine = DictionarySearchEngine(entries: entries)
        return miniEngine.search(query: trimmed).results.map(\.entry)
    }

    var body: some View {
        List {
            Section {
                ForEach(visibleEntries) { entry in
                    NavigationLink {
                        EntryDetailView(entry: entry, viewModel: viewModel)
                    } label: {
                        EntryRowView(
                            entry: entry,
                            matchKind: nil,
                            isBookmarked: viewModel.isBookmarked(entry),
                            onSpeak: { viewModel.speech.speakJapanese(entry.kana) }
                        )
                    }
                }
            } header: {
                Text("\(subtitle) • \(visibleEntries.count) words")
                    .padding(.vertical, 2)
            }
        }
        .navigationTitle(title)
        .searchable(text: $localFilter, prompt: "Filter within \(title)")
    }
}
