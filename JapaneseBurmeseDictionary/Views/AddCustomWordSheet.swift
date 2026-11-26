import SwiftUI

struct AddCustomWordSheet: View {
    @ObservedObject var viewModel: DictionaryViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var kanji: String
    @State private var kana: String
    @State private var romaji: String
    @State private var burmese: String
    @State private var burmesePhonetic: String = ""
    @State private var english: String
    @State private var partOfSpeech: String = "Noun"
    @State private var exampleJP: String = ""
    @State private var exampleMY: String = ""

    private let posOptions = [
        "Noun", "Verb (Ichidan)", "Verb (Godan)", "Verb (Suru)",
        "i-Adjective", "na-Adjective", "Adverb", "Expression"
    ]

    init(viewModel: DictionaryViewModel, initialQuery: String) {
        self.viewModel = viewModel
        let trimmed = initialQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if BurmeseNormalizer.containsMyanmar(trimmed) {
            _kanji = State(initialValue: "")
            _kana = State(initialValue: "")
            _romaji = State(initialValue: "")
            _burmese = State(initialValue: trimmed)
            _english = State(initialValue: "")
        } else if JapaneseDeinflector.containsJapanese(trimmed) {
            _kanji = State(initialValue: trimmed)
            _kana = State(initialValue: "")
            _romaji = State(initialValue: "")
            _burmese = State(initialValue: "")
            _english = State(initialValue: "")
        } else {
            _kanji = State(initialValue: "")
            _kana = State(initialValue: RomajiKanaConverter.romajiToHiragana(trimmed) ?? "")
            _romaji = State(initialValue: trimmed)
            _burmese = State(initialValue: "")
            _english = State(initialValue: "")
        }
    }

    private var canSave: Bool {
        !kanji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !burmese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Japanese (日本語)") {
                    TextField("Kanji or Word (e.g. 報連相)", text: $kanji)
                    TextField("Kana Reading (e.g. ほうれんそう)", text: $kana)
                    HStack {
                        TextField("Romaji (e.g. hourensou)", text: $romaji)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        if kana.isEmpty, let suggested = RomajiKanaConverter.romajiToHiragana(romaji) {
                            Button("→ \(suggested)") {
                                kana = suggested
                                if kanji.isEmpty {
                                    kanji = suggested
                                }
                            }
                            .font(.caption.weight(.semibold))
                        }
                    }
                }

                Section("Burmese & English (မြန်မာအဓိပ္ပာယ်)") {
                    TextField("မြန်မာအဓိပ္ပာယ် (Required)", text: $burmese)
                    TextField("မြန်မာအသံထွက် (Optional)", text: $burmesePhonetic)
                    TextField("English Meaning (Optional)", text: $english)
                    Picker("Part of Speech", selection: $partOfSpeech) {
                        ForEach(posOptions, id: \.self) { pos in
                            Text(pos).tag(pos)
                        }
                    }
                }

                Section("Example Sentence (Optional)") {
                    TextField("Japanese Example Sentence", text: $exampleJP)
                    TextField("မြန်မာဥပမာဝါကျ", text: $exampleMY)
                }
            }
            .navigationTitle("Add Custom Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addCustomEntry(
                            kanji: kanji,
                            kana: kana,
                            romaji: romaji,
                            burmese: burmese,
                            burmesePhonetic: burmesePhonetic,
                            english: english.isEmpty ? "-" : english,
                            partOfSpeech: partOfSpeech,
                            exampleJP: exampleJP,
                            exampleMY: exampleMY
                        )
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
