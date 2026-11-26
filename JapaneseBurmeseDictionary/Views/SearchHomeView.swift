import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SearchHomeView: View {
    @ObservedObject var viewModel: DictionaryViewModel
    @State private var showingAddWordSheet = false

    private let sampleQueries: [(label: String, query: String)] = [
        ("🇲🇲 စားတယ်", "စားတယ်"),
        ("🇲🇲 ဆေးရုံ", "ဆေးရုံ"),
        ("🇯🇵 仕事", "仕事"),
        ("🇯🇵 食べました", "食べました"),
        ("🔤 arigatou", "arigatou"),
        ("🇬🇧 station", "station")
    ]

    private var isIdleHomeState: Bool {
        viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && viewModel.selectedJLPT == .all
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterAndStatusStrip

                if isIdleHomeState {
                    homeDiscoveryList
                } else if viewModel.searchResults.isEmpty {
                    emptySearchState
                } else {
                    resultsList
                }
            }
            .navigationTitle("JP ⇄ MM အဘိဓာန်")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "日本語 / မြန်မာ / Romaji / English"
            )
            .onSubmit(of: .search) {
                viewModel.recordRecentQuery(viewModel.searchText)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        pasteFromClipboard()
                    } label: {
                        Label("Paste", systemImage: "doc.on.clipboard")
                    }
                    .accessibilityLabel("Paste and search")
                }
            }
            .sheet(isPresented: $showingAddWordSheet) {
                AddCustomWordSheet(
                    viewModel: viewModel,
                    initialQuery: viewModel.searchText
                )
            }
        }
    }

    private var filterAndStatusStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(JLPTLevel.allCases) { level in
                        let selected = viewModel.selectedJLPT == level
                        Button {
                            viewModel.selectedJLPT = level
                        } label: {
                            Text(level.displayTitle)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selected ? Color.accentColor : Color.secondary.opacity(0.14))
                                .foregroundColor(selected ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            if viewModel.detectedScript != .empty {
                HStack(spacing: 8) {
                    Text(viewModel.detectedScript.badgeLabel)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())

                    if let kana = viewModel.kanaPreview {
                        Text("→ \(kana)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Text("\(viewModel.searchResults.count) results")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 8)
    }

    private var homeDiscoveryList: some View {
        List {
            if let wod = viewModel.wordOfTheDay {
                Section {
                    NavigationLink {
                        EntryDetailView(entry: wod, viewModel: viewModel)
                    } label: {
                        wordOfTheDayCard(wod)
                    }
                } header: {
                    Text("နေ့စဉ်ဝေါဟာရ • Word of the Day")
                        .padding(.vertical, 2)
                }
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sampleQueries, id: \.query) { sample in
                            Button {
                                viewModel.searchText = sample.query
                                viewModel.recordRecentQuery(sample.query)
                            } label: {
                                Text(sample.label)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 7)
                                    .background(Color.accentColor.opacity(0.11))
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("အမြန်စမ်းရှာကြည့်ရန် • Try Bidirectional Search")
                    .padding(.vertical, 2)
            }

            if !viewModel.recentQueries.isEmpty {
                Section {
                    ForEach(viewModel.recentQueries, id: \.self) { recent in
                        Button {
                            viewModel.searchText = recent
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.secondary)
                                Text(recent)
                                    .foregroundColor(.primary)
                                    .padding(.vertical, 1)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("လတ်တလော ရှာဖွေမှုများ • Recent")
                        Spacer()
                        Button("Clear") {
                            viewModel.clearRecentQueries()
                        }
                        .font(.caption)
                    }
                }
            }

            Section {
                ForEach(Array(viewModel.allEntries.prefix(25))) { entry in
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
                    .swipeActions(edge: .trailing) {
                        bookmarkSwipeButton(for: entry)
                    }
                }
            } header: {
                Text("အသုံးများသော ဝေါဟာရများ • Essential Words (\(viewModel.allEntries.count) offline)")
                    .padding(.vertical, 2)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func wordOfTheDayCard(_ entry: DictionaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.kanji)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        if entry.showsDistinctKana {
                            Text(entry.kana)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                        Text("(\(entry.romaji))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button {
                    viewModel.speech.speakJapanese(entry.kana)
                } label: {
                    Image(systemName: "speaker.wave.2.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }

            Text(entry.burmese)
                .font(.headline)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .padding(.vertical, 2)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(entry.english) • \(entry.jlpt)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var resultsList: some View {
        List {
            ForEach(viewModel.searchResults) { scored in
                NavigationLink {
                    EntryDetailView(entry: scored.entry, viewModel: viewModel)
                        .onAppear {
                            viewModel.recordRecentQuery(viewModel.searchText)
                        }
                } label: {
                    EntryRowView(
                        entry: scored.entry,
                        matchKind: scored.matchKind,
                        isBookmarked: viewModel.isBookmarked(scored.entry),
                        onSpeak: { viewModel.speech.speakJapanese(scored.entry.kana) }
                    )
                }
                .swipeActions(edge: .trailing) {
                    bookmarkSwipeButton(for: scored.entry)
                }
            }
        }
        .listStyle(.plain)
    }

    private var emptySearchState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "character.book.closed")
                .font(.system(size: 46))
                .foregroundColor(.secondary)

            Text("ရှာမတွေ့ပါ • No Matching Entries")
                .font(.headline)
                .padding(.vertical, 2)

            Text("Try searching in Japanese Kanji/Kana, Romaji (e.g. \"taberu\"), Burmese Unicode (e.g. \"စားသည်\"), or English.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if viewModel.selectedJLPT != .all {
                Button("Reset JLPT Filter (Show All Levels)") {
                    viewModel.selectedJLPT = .all
                }
                .buttonStyle(.bordered)
            }

            Button {
                showingAddWordSheet = true
            } label: {
                Label("Add \"\(viewModel.searchText)\" as Custom Word", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)

            Spacer()
        }
        .padding()
    }

    private func bookmarkSwipeButton(for entry: DictionaryEntry) -> some View {
        Button {
            viewModel.toggleBookmark(entry)
        } label: {
            Label(
                viewModel.isBookmarked(entry) ? "Remove" : "Save",
                systemImage: viewModel.isBookmarked(entry) ? "bookmark.slash" : "bookmark.fill"
            )
        }
        .tint(.accentColor)
    }

    private func pasteFromClipboard() {
        #if canImport(UIKit)
        if let pasted = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
           !pasted.isEmpty {
            viewModel.searchText = pasted
            viewModel.recordRecentQuery(pasted)
        }
        #endif
    }
}
