import SwiftUI

@MainActor
struct FlashcardStudyView: View {
    private enum DeckSource: String, CaseIterable, Identifiable {
        case bookmarks = "Saved"
        case n5 = "N5"
        case n4 = "N4"
        case n3 = "N3"
        case all = "All"

        var id: String { rawValue }
    }

    @ObservedObject var viewModel: DictionaryViewModel
    @State private var deckSource: DeckSource = .n5
    @State private var japaneseFront: Bool = true
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false

    private var activeDeck: [DictionaryEntry] {
        switch deckSource {
        case .bookmarks:
            return viewModel.bookmarkedEntries
        case .n5:
            return viewModel.entries(forJLPT: .n5)
        case .n4:
            return viewModel.entries(forJLPT: .n4)
        case .n3:
            return viewModel.entries(forJLPT: .n3)
        case .all:
            return viewModel.allEntries
        }
    }

    private var safeIndex: Int {
        guard !activeDeck.isEmpty else { return 0 }
        return min(max(0, currentIndex), activeDeck.count - 1)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                deckControls

                if activeDeck.isEmpty {
                    emptyDeckView
                } else {
                    let entry = activeDeck[safeIndex]
                    progressHeader(for: entry)
                    flashcard(for: entry)
                    actionButtons(for: entry)
                }

                Spacer(minLength: 8)
            }
            .padding(16)
            .navigationTitle("လေ့ကျင့်ရန် • Study")
            .onChange(of: deckSource) { _ in
                currentIndex = 0
                isFlipped = false
            }
        }
    }

    private var deckControls: some View {
        VStack(spacing: 10) {
            Picker("Deck", selection: $deckSource) {
                ForEach(DeckSource.allCases) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Button {
                    japaneseFront.toggle()
                    isFlipped = false
                } label: {
                    Label(
                        japaneseFront ? "🇯🇵 Front → 🇲🇲 Back" : "🇲🇲 Front → 🇯🇵 Back",
                        systemImage: "arrow.left.arrow.right"
                    )
                    .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)

                Spacer()

                let masteredCount = activeDeck.filter { viewModel.isMastered($0) }.count
                Text("Mastered: \(masteredCount)/\(activeDeck.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func progressHeader(for entry: DictionaryEntry) -> some View {
        HStack {
            Text("Card \(safeIndex + 1) of \(activeDeck.count)")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            Spacer()

            if viewModel.isMastered(entry) {
                Label("Mastered", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.green)
            }
        }
    }

    private func flashcard(for entry: DictionaryEntry) -> some View {
        let showingJapaneseSide = (japaneseFront && !isFlipped) || (!japaneseFront && isFlipped)

        return VStack(spacing: 14) {
            HStack {
                JLPTBadgeView(level: entry.jlpt)
                Spacer()
                Button {
                    viewModel.speech.speakJapanese(entry.kana)
                } label: {
                    Image(systemName: "speaker.wave.2.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if showingJapaneseSide {
                VStack(spacing: 8) {
                    Text(entry.kanji)
                        .font(.system(size: 38, weight: .bold))
                        .multilineTextAlignment(.center)

                    if isFlipped || !japaneseFront {
                        if entry.showsDistinctKana {
                            Text(entry.kana)
                                .font(.title3)
                                .foregroundColor(.accentColor)
                        }
                        Text(entry.romaji)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Text(entry.burmese)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.vertical, 4)

                    Text(entry.english)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    if !entry.burmesePhonetic.isEmpty {
                        Text("အသံထွက်: \(entry.burmesePhonetic)")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .padding(.vertical, 2)
                    }

                    if entry.showsDistinctKana {
                        Text("\(entry.kanji) • \(entry.kana) (\(entry.romaji))")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Text("Tap card to flip • ကတ်ကိုနှိပ်၍လှန်ကြည့်ပါ")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.vertical, 2)
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 290)
        .background(Color.secondary.opacity(0.09))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.accentColor.opacity(0.22), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isFlipped.toggle()
            }
        }
    }

    private func actionButtons(for entry: DictionaryEntry) -> some View {
        HStack(spacing: 12) {
            Button {
                goPrevious()
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .disabled(safeIndex == 0)

            Button {
                viewModel.setMastered(false, for: entry)
                goNext()
            } label: {
                Label("Review", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                viewModel.setMastered(true, for: entry)
                goNext()
            } label: {
                Label("Got It", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                goNext()
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
        }
    }

    private var emptyDeckView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 42))
                .foregroundColor(.secondary)
            Text("No Saved Cards Yet")
                .font(.headline)
            Text("Bookmark words while searching, or switch the deck above to N5 / N4 / All to start practicing immediately.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
    }

    private func goPrevious() {
        guard !activeDeck.isEmpty else { return }
        isFlipped = false
        currentIndex = max(0, safeIndex - 1)
    }

    private func goNext() {
        guard !activeDeck.isEmpty else { return }
        isFlipped = false
        currentIndex = (safeIndex + 1) % activeDeck.count
    }
}
