# Japanese–Burmese Dictionary for iPhone (JP ⇄ MM အဘိဓာန်)

A native **iOS (SwiftUI)** offline Japanese–Burmese dictionary app built for iPhone (`iOS 16.0+`). Search seamlessly in **Japanese Kanji/Kana**, **Romaji**, **Burmese Unicode (မြန်မာယူနီကုဒ်)**, or **English** — 100% offline with zero internet connection required.

---

## ✨ Key Features

- **4-Way Bidirectional Smart Search**
  - **Japanese (`日本語`)**: Search by Kanji (`食べる`, `病院`), Hiragana (`たべる`), Katakana (`コンビニ` / `こんびに`), or **conjugated forms** (`食べました` → `食べる`, `行きます` → `行く`, `高かった` → `高い`).
  - **Burmese Unicode (`မြန်မာ`)**: Supports both literary (`စားသည်`) and spoken/colloquial (`စားတယ်`) verb forms, canonicalizes iOS Myanmar keyboard combining mark order, and strips invisible zero-width characters pasted from chat apps.
  - **Romaji (`ローマ字`)**: Live Hepburn & Kunrei-shiki Romaji-to-Kana conversion (`taberu` → `たべる / タベル`, `syashin` → `写真`) plus relaxed long-vowel matching (`arigato` → `ありがとう`, `byoin` → `病院`).
  - **English**: Search by English meaning (`train station`, `hospital`, `eat`) or example sentences.
- **630+ Curated Offline Entries** across **JLPT N5–N2 + Practical Japan Life Phrases** and **12 Categories** (Greetings, Verbs, Adjectives, Food & Drink, Travel & Transport, Work & Study, Daily Life, People & Family, Health & Emergency, Shopping & Money, Time & Numbers, Nature & Weather).
- **Burmese Phonetic Guide (`မြန်မာအသံထွက်`)** alongside Furigana and Hepburn Romaji for every word.
- **Offline Japanese Voice Playback (`AVSpeechSynthesizer`)**: Normal speed and 🐢 Slow learner speed for both headwords and example sentences (works even when the iPhone hardware mute switch is on).
- **Bookmarks, Recent Searches, Custom User Words & 3D Flip Flashcards**: Save favorites, add your own workplace/school vocabulary right on your iPhone, and practice with bidirectional flashcards.

---

## 📱 Install on Your iPhone from Your Mac (Xcode)

1. **Clone the repository on your Mac**:
   ```bash
   git clone https://github.com/hlaingbwaraung/JapaneseBurmeseDictionary.git
   cd JapaneseBurmeseDictionary
   open JapaneseBurmeseDictionary.xcodeproj
   ```
2. **Configure Signing in Xcode**:
   - Click **JapaneseBurmeseDictionary** in the left Project Navigator.
   - Select the **JapaneseBurmeseDictionary** target → **Signing & Capabilities** tab.
   - Under **Team**, select your Apple ID (**Personal Team**).
   - *(Optional)* If Xcode reports the Bundle Identifier is already taken, change `com.hlaingbwaraung.JapaneseBurmeseDictionary` to any unique string (e.g. `com.<yourname>.jpmmdict`).
3. **Connect & Run on Your iPhone**:
   - Plug your iPhone into your Mac (or pair wirelessly) and select your iPhone from the top device dropdown in Xcode.
   - If this is your first sideloaded app on iOS 16+, enable **Settings → Privacy & Security → Developer Mode** on your iPhone.
   - Press **`Cmd + R`** in Xcode to build and install!
   - If prompted on first launch with *"Untrusted Developer"*, open **Settings → General → VPN & Device Management** on your iPhone and tap **Trust**.

---

## 🛠 Project Structure

```text
JapaneseBurmeseDictionary/
├── JapaneseBurmeseDictionary.xcodeproj/   # Native Xcode 15/16+ iOS project & shared scheme
├── JapaneseBurmeseDictionary/
│   ├── App/                               # SwiftUI @main entry point
│   ├── Models/                            # DictionaryEntry, JLPTLevel, Category, SearchQueryInfo
│   ├── Services/                          # Search engine, Burmese stemmer, Romaji-Kana, Deinflector, TTS
│   ├── ViewModels/                        # @MainActor DictionaryViewModel
│   ├── Views/                             # Search, Detail, Browse, Saved/Custom Words, Flashcards
│   ├── Resources/dictionary_entries.json  # 630+ validated Japanese-Burmese offline entries
│   └── Assets.xcassets/                   # 1024x1024 AppIcon & adaptive AccentColor
├── JapaneseBurmeseDictionaryTests/        # XCTest suite for bidirectional search & normalization
└── scripts/
    ├── build_dictionary.py                # Dataset compiler & Myanmar Unicode validator
    ├── kana_to_burmese.py                 # Deterministic Kana -> Myanmar phonetic transliterator
    └── generate_xcodeproj.py              # Reproducible Xcode project generator
```

## 🔄 Adding Bulk Vocabulary

To add more curated entries in bulk and rebuild `dictionary_entries.json` with automatic Myanmar Unicode validation and phonetic generation:

```bash
python3 scripts/build_dictionary.py
```
