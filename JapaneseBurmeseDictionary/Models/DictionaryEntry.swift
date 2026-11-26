import Foundation

public struct ExampleSentence: Codable, Hashable, Sendable, Identifiable {
    public var id: String { "\(jp)|\(my)" }
    public let jp: String
    public let kana: String
    public let romaji: String
    public let my: String

    public init(jp: String, kana: String, romaji: String, my: String) {
        self.jp = jp
        self.kana = kana
        self.romaji = romaji
        self.my = my
    }
}

public enum JLPTLevel: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case all = "All"
    case n5 = "N5"
    case n4 = "N4"
    case n3 = "N3"
    case n2 = "N2"
    case phrase = "Phrase"

    public var id: String { rawValue }

    public var displayTitle: String {
        switch self {
        case .all: return "All"
        case .phrase: return "Phrases"
        default: return rawValue
        }
    }

    public static func sortPriority(for raw: String) -> Int {
        switch raw {
        case "N5": return 0
        case "Phrase": return 1
        case "N4": return 2
        case "N3": return 3
        case "N2": return 4
        default: return 5
        }
    }
}

public enum DictionaryCategory: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case greetings = "Greetings"
    case verbs = "Verbs"
    case adjectives = "Adjectives"
    case foodAndDrink = "Food & Drink"
    case travelAndTransport = "Travel & Transport"
    case workAndStudy = "Work & Study"
    case dailyLife = "Daily Life"
    case peopleAndFamily = "People & Family"
    case healthAndEmergency = "Health & Emergency"
    case shoppingAndMoney = "Shopping & Money"
    case timeAndNumbers = "Time & Numbers"
    case natureAndWeather = "Nature & Weather"
    case custom = "Custom"

    public var id: String { rawValue }

    public static var browseableCategories: [DictionaryCategory] {
        allCases.filter { $0 != .custom }
    }

    public var burmeseTitle: String {
        switch self {
        case .greetings: return "နှုတ်ဆက်စကားများ"
        case .verbs: return "ကြိယာများ"
        case .adjectives: return "နာမဝိသေသနများ"
        case .foodAndDrink: return "အစားအသောက်"
        case .travelAndTransport: return "ခရီးသွားနှင့် လမ်းပန်း"
        case .workAndStudy: return "အလုပ်နှင့် ပညာရေး"
        case .dailyLife: return "နေ့စဉ်လူနေမှုဘဝ"
        case .peopleAndFamily: return "လူနှင့် မိသားစု"
        case .healthAndEmergency: return "ကျန်းမာရေးနှင့် အရေးပေါ်"
        case .shoppingAndMoney: return "ဈေးဝယ်နှင့် ငွေကြေး"
        case .timeAndNumbers: return "အချိန်နှင့် ကိန်းဂဏန်း"
        case .natureAndWeather: return "သဘာဝနှင့် ရာသီဥတု"
        case .custom: return "ကိုယ်ပိုင်ဝေါဟာရ"
        }
    }

    public var iconName: String {
        switch self {
        case .greetings: return "hand.wave.fill"
        case .verbs: return "bolt.fill"
        case .adjectives: return "sparkles"
        case .foodAndDrink: return "fork.knife"
        case .travelAndTransport: return "tram.fill"
        case .workAndStudy: return "briefcase.fill"
        case .dailyLife: return "house.fill"
        case .peopleAndFamily: return "person.2.fill"
        case .healthAndEmergency: return "cross.case.fill"
        case .shoppingAndMoney: return "yensign.circle.fill"
        case .timeAndNumbers: return "clock.fill"
        case .natureAndWeather: return "sun.max.fill"
        case .custom: return "person.crop.circle.badge.plus"
        }
    }
}

public struct DictionaryEntry: Codable, Hashable, Sendable, Identifiable {
    public let id: String
    public let kanji: String
    public let kana: String
    public let romaji: String
    public let burmese: String
    public let burmesePhonetic: String
    public let english: String
    public let partOfSpeech: String
    public let partOfSpeechBurmese: String
    public let jlpt: String
    public let category: String
    public let examples: [ExampleSentence]
    public var isCustom: Bool

    public var showsDistinctKana: Bool {
        kanji != kana && !kana.isEmpty
    }

    enum CodingKeys: String, CodingKey {
        case id
        case kanji
        case kana
        case romaji
        case burmese
        case burmesePhonetic
        case english
        case partOfSpeech
        case partOfSpeechBurmese
        case jlpt
        case category
        case examples
        case isCustom
    }

    public init(
        id: String,
        kanji: String,
        kana: String,
        romaji: String,
        burmese: String,
        burmesePhonetic: String,
        english: String,
        partOfSpeech: String,
        partOfSpeechBurmese: String,
        jlpt: String,
        category: String,
        examples: [ExampleSentence] = [],
        isCustom: Bool = false
    ) {
        self.id = id
        self.kanji = kanji
        self.kana = kana
        self.romaji = romaji
        self.burmese = burmese
        self.burmesePhonetic = burmesePhonetic
        self.english = english
        self.partOfSpeech = partOfSpeech
        self.partOfSpeechBurmese = partOfSpeechBurmese
        self.jlpt = jlpt
        self.category = category
        self.examples = examples
        self.isCustom = isCustom
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        kanji = try container.decode(String.self, forKey: .kanji)
        kana = try container.decode(String.self, forKey: .kana)
        romaji = try container.decode(String.self, forKey: .romaji)
        burmese = try container.decode(String.self, forKey: .burmese)
        burmesePhonetic = try container.decodeIfPresent(String.self, forKey: .burmesePhonetic) ?? ""
        english = try container.decode(String.self, forKey: .english)
        partOfSpeech = try container.decode(String.self, forKey: .partOfSpeech)
        partOfSpeechBurmese = try container.decodeIfPresent(String.self, forKey: .partOfSpeechBurmese) ?? ""
        jlpt = try container.decode(String.self, forKey: .jlpt)
        category = try container.decode(String.self, forKey: .category)
        examples = try container.decodeIfPresent([ExampleSentence].self, forKey: .examples) ?? []
        isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
    }
}
