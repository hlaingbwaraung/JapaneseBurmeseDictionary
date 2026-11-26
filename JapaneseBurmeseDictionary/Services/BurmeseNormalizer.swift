import Foundation

/// Normalizes Myanmar Unicode text, canonicalizes combining mark order typed on iOS keyboards,
/// and extracts verb/adjective stems so colloquial ("စားတယ်") and literary ("စားသည်") queries match seamlessly.
public enum BurmeseNormalizer {
    private static let suffixes: [String] = [
        "ပါတယ်", "ပါသည်", "နေပါတယ်", "နေသည်", "နေတယ်",
        "ခဲ့သည်", "ခဲ့တယ်", "ခြင်း", "သော", "သည်", "တယ်", "မယ်", "မည်"
    ]

    public static func containsMyanmar(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            let v = scalar.value
            if (0x1000...0x109F).contains(v) || (0xAA60...0xAA7F).contains(v) {
                return true
            }
        }
        return false
    }

    public static func normalize(_ text: String) -> String {
        let nfc = text.precomposedStringWithCanonicalMapping
        var scalars: [Unicode.Scalar] = []
        scalars.reserveCapacity(nfc.unicodeScalars.count)

        for scalar in nfc.unicodeScalars {
            // Strip zero-width spaces / joiners often present in pasted Myanmar text
            if scalar.value == 0x200B || scalar.value == 0x200C || scalar.value == 0x200D || scalar.value == 0xFEFF {
                continue
            }
            scalars.append(scalar)
        }

        // Canonicalize common Myanmar combining mark order variations
        if scalars.count >= 2 {
            var idx = 0
            while idx < scalars.count - 1 {
                let a = scalars[idx].value
                let b = scalars[idx + 1].value
                // aukmyit (1037) + asat (103A) -> canonical asat (103A) + aukmyit (1037)
                // anusvara (1036) + u (102F) -> u (102F) + anusvara (1036)
                // anusvara (1036) + i (102D) -> i (102D) + anusvara (1036)
                if (a == 0x1037 && b == 0x103A)
                    || (a == 0x1036 && b == 0x102F)
                    || (a == 0x1036 && b == 0x102D) {
                    scalars.swapAt(idx, idx + 1)
                }
                idx += 1
            }
        }

        var result = String.UnicodeScalarView()
        result.append(contentsOf: scalars)
        return String(result).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Strips common Burmese verb/adjective endings while preserving single-consonant roots.
    public static func stem(_ normalizedText: String) -> String {
        let clean = normalize(normalizedText)
        for suffix in suffixes where clean.hasSuffix(suffix) {
            let candidate = String(clean.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            if containsMyanmar(candidate) {
                return candidate
            }
        }
        return clean
    }

    /// Splits compound Burmese dictionary glosses ("စားသည်၊ သုံးဆောင်သည် (အစားအစာ)") into clean searchable parts.
    public static func splitGlosses(_ text: String) -> [String] {
        let normalized = normalize(text)
        // Remove parenthetical notes for clean head-gloss matching
        let strippedParens = removeParentheticalNotes(normalized)
        let separators = CharacterSet(charactersIn: "၊,/;")
        var out: [String] = []
        for rawPart in strippedParens.components(separatedBy: separators) {
            let trimmed = rawPart.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                out.append(trimmed)
            }
        }
        return out.isEmpty ? [normalized] : out
    }

    private static func removeParentheticalNotes(_ text: String) -> String {
        var scalars: [Unicode.Scalar] = []
        var depth = 0
        for s in text.unicodeScalars {
            if s == "(" || s == "（" {
                depth += 1
            } else if s == ")" || s == "）" {
                depth = max(0, depth - 1)
            } else if depth == 0 {
                scalars.append(s)
            }
        }
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars)
        return String(view)
    }
}
