import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct EntryDetailView: View {
    let entry: DictionaryEntry
    @ObservedObject var viewModel: DictionaryViewModel
    @State private var copiedMessage: String?

    private var shareSummary: String {
        """
        \(entry.kanji) (\(entry.kana) • \(entry.romaji))
        🇲🇲 \(entry.burmese)
        🇬🇧 \(entry.english)
        """
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerCard
                burmeseMeaningCard
                grammarAndPhoneticCard

                if !entry.examples.isEmpty {
                    examplesSection
                }

                let related = viewModel.relatedEntries(for: entry)
                if !related.isEmpty {
                    relatedWordsSection(related)
                }
            }
            .padding(16)
        }
        .navigationTitle(entry.kanji)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleBookmark(entry)
                } label: {
                    Image(systemName: viewModel.isBookmarked(entry) ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel("Toggle Bookmark")

                ShareLink(item: shareSummary) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let message = copiedMessage {
                Text(message)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 4)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    if entry.showsDistinctKana {
                        Text(entry.kana)
                            .font(.headline)
                            .foregroundColor(.accentColor)
                    }

                    Text(entry.kanji)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(entry.romaji)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                JLPTBadgeView(level: entry.jlpt)
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.speech.speakJapanese(entry.kana, slow: false)
                } label: {
                    Label("အသံထွက် • Listen", systemImage: "speaker.wave.2.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 2)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.speech.speakJapanese(entry.kana, slow: true)
                } label: {
                    Label("Slow", systemImage: "tortoise.fill")
                        .font(.subheadline.weight(.medium))
                        .padding(.vertical, 2)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button {
                    copyToClipboard(entry.kanji, label: "Copied Japanese")
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Copy Japanese word")
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var burmeseMeaningCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("မြန်မာအဓိပ္ပာယ် • Burmese Meaning", systemImage: "text.book.closed.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    copyToClipboard(entry.burmese, label: "Copied Burmese")
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
            }

            Text(entry.burmese)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
                .lineSpacing(6)
                .padding(.vertical, 4)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            HStack(alignment: .top, spacing: 8) {
                Text("English:")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(entry.english)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var grammarAndPhoneticCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !entry.burmesePhonetic.isEmpty {
                HStack(alignment: .firstTextBaseline) {
                    Text("မြန်မာအသံထွက် (Phonetic)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(entry.burmesePhonetic)
                        .font(.body.weight(.medium))
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 2)
                }
                Divider()
            }

            HStack {
                Text("ဝါစင်္ဂ • Part of Speech")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(
                    entry.partOfSpeechBurmese.isEmpty
                        ? entry.partOfSpeech
                        : "\(entry.partOfSpeech) • \(entry.partOfSpeechBurmese)"
                )
                .font(.subheadline)
                .padding(.vertical, 2)
            }

            Divider()

            HStack {
                Text("ကဏ္ဍ • Category")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text(entry.category)
                    .font(.subheadline)
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ဥပမာဝါကျများ • Example Sentences")
                .font(.headline)
                .padding(.vertical, 2)

            ForEach(entry.examples) { ex in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ex.jp)
                                .font(.body.weight(.semibold))
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            if !ex.kana.isEmpty && ex.kana != ex.jp {
                                Text(ex.kana)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if !ex.romaji.isEmpty {
                                Text(ex.romaji)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button {
                            viewModel.speech.speakJapanese(ex.jp)
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.accentColor)
                                .frame(width: 30, height: 30)
                                .background(Color.accentColor.opacity(0.14))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    Text(ex.my)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .lineSpacing(5)
                        .padding(.vertical, 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func relatedWordsSection(_ related: [DictionaryEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ဆက်စပ်ဝေါဟာရများ • Related Words")
                .font(.headline)
                .padding(.vertical, 2)

            ForEach(related) { item in
                NavigationLink {
                    EntryDetailView(entry: item, viewModel: viewModel)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(item.kanji)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.primary)
                                if item.showsDistinctKana {
                                    Text(item.kana)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Text(item.burmese)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .padding(.vertical, 1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func copyToClipboard(_ text: String, label: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #endif
        withAnimation {
            copiedMessage = label
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                if copiedMessage == label {
                    copiedMessage = nil
                }
            }
        }
    }
}
