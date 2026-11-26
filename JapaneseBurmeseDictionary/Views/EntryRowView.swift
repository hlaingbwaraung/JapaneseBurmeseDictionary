import SwiftUI

struct EntryRowView: View {
    let entry: DictionaryEntry
    var matchKind: MatchKind?
    let isBookmarked: Bool
    let onSpeak: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(entry.kanji)
                        .font(.title3.weight(.bold))
                        .foregroundColor(.primary)

                    if entry.showsDistinctKana {
                        Text(entry.kana)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer(minLength: 4)

                    JLPTBadgeView(level: entry.jlpt)
                }

                HStack(spacing: 6) {
                    Text(entry.romaji)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !entry.burmesePhonetic.isEmpty {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(entry.burmesePhonetic)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                            .padding(.vertical, 1)
                    }
                }

                // Generous vertical breathing room prevents Myanmar vowel/medial clipping on iOS
                Text(entry.burmese)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .padding(.vertical, 2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Text(entry.english)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                    }

                    if let kind = matchKind, kind != .exact {
                        Text(kind.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundColor(.accentColor)
                            .clipShape(Capsule())
                    }
                }
            }

            Button(action: onSpeak) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.accentColor)
                    .frame(width: 34, height: 34)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play Japanese pronunciation for \(entry.kanji)")
        }
        .padding(.vertical, 4)
    }
}

struct JLPTBadgeView: View {
    let level: String

    private var badgeColor: Color {
        switch level {
        case "N5": return .green
        case "N4": return .teal
        case "N3": return .blue
        case "N2": return .purple
        default: return .orange
        }
    }

    var body: some View {
        Text(level)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
    }
}
