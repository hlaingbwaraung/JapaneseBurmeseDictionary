import SwiftUI

struct BookmarksView: View {
    private enum SavedTab: String, CaseIterable, Identifiable {
        case bookmarks = "Saved"
        case custom = "My Words"
        var id: String { rawValue }
    }

    @ObservedObject var viewModel: DictionaryViewModel
    @State private var selectedTab: SavedTab = .bookmarks
    @State private var showingAddWord = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    Text("မှတ်သားချက် (\(viewModel.bookmarkedEntries.count))")
                        .tag(SavedTab.bookmarks)
                    Text("ကိုယ်ပိုင် (\(viewModel.customEntries.count))")
                        .tag(SavedTab.custom)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                switch selectedTab {
                case .bookmarks:
                    bookmarksContent
                case .custom:
                    customWordsContent
                }
            }
            .navigationTitle("မှတ်သားချက် • Saved")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddWord = true
                    } label: {
                        Label("Add Word", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWord) {
                AddCustomWordSheet(viewModel: viewModel, initialQuery: "")
            }
        }
    }

    @ViewBuilder
    private var bookmarksContent: some View {
        if viewModel.bookmarkedEntries.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "bookmark")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                Text("မှတ်သားထားသော ဝေါဟာရ မရှိသေးပါ")
                    .font(.headline)
                    .padding(.vertical, 2)
                Text("Tap the bookmark icon on any word or swipe left on search results to save words for quick review.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
        } else {
            List {
                ForEach(viewModel.bookmarkedEntries) { entry in
                    NavigationLink {
                        EntryDetailView(entry: entry, viewModel: viewModel)
                    } label: {
                        EntryRowView(
                            entry: entry,
                            matchKind: nil,
                            isBookmarked: true,
                            onSpeak: { viewModel.speech.speakJapanese(entry.kana) }
                        )
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            viewModel.toggleBookmark(entry)
                        } label: {
                            Label("Remove", systemImage: "bookmark.slash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private var customWordsContent: some View {
        if viewModel.customEntries.isEmpty {
            VStack(spacing: 14) {
                Spacer()
                Image(systemName: "plus.bubble")
                    .font(.system(size: 44))
                    .foregroundColor(.secondary)
                Text("ကိုယ်ပိုင်ဝေါဟာရ ထည့်သွင်းနိုင်ပါသည်")
                    .font(.headline)
                    .padding(.vertical, 2)
                Text("Save specialized workplace, school, or daily Japanese–Burmese words right on your iPhone.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    showingAddWord = true
                } label: {
                    Label("Add New Word", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
        } else {
            List {
                ForEach(viewModel.customEntries) { entry in
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
                        Button(role: .destructive) {
                            viewModel.deleteCustomEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
