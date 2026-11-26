import XCTest
@testable import JapaneseBurmeseDictionary

final class DictionarySearchEngineTests: XCTestCase {
    private var engine: DictionarySearchEngine!

    override func setUpWithError() throws {
        let entries = try DictionaryRepository.loadBundledEntries()
        XCTAssertGreaterThanOrEqual(entries.count, 500, "Bundled offline dictionary should contain 500+ entries")
        engine = DictionarySearchEngine(entries: entries)
    }

    func testJapaneseKanjiAndKanaLookup() {
        let kanjiOut = engine.search(query: "食べる")
        XCTAssertEqual(kanjiOut.detectedScript, .japanese)
        XCTAssertEqual(kanjiOut.results.first?.entry.kanji, "食べる")
        XCTAssertEqual(kanjiOut.results.first?.entry.burmese, "စားသည်")

        let kataOut = engine.search(query: "タベル")
        XCTAssertEqual(kataOut.results.first?.entry.kanji, "食べる")

        let konbiniHira = engine.search(query: "こんびに")
        XCTAssertEqual(konbiniHira.results.first?.entry.kanji, "コンビニ")
    }

    func testConjugatedJapaneseDeinflection() {
        let politePast = engine.search(query: "食べました")
        XCTAssertEqual(politePast.results.first?.entry.kanji, "食べる")

        let politeGo = engine.search(query: "行きます")
        XCTAssertEqual(politeGo.results.first?.entry.kanji, "行く")

        let pastAdj = engine.search(query: "高かった")
        XCTAssertEqual(pastAdj.results.first?.entry.kanji, "高い")
    }

    func testRomajiAndRelaxedLongVowels() {
        let taberu = engine.search(query: "taberu")
        XCTAssertEqual(taberu.detectedScript, .latin)
        XCTAssertEqual(taberu.kanaPreview, "たべる / タベル")
        XCTAssertEqual(taberu.results.first?.entry.kanji, "食べる")

        let relaxedArigato = engine.search(query: "arigato")
        XCTAssertEqual(relaxedArigato.results.first?.entry.kanji, "ありがとう")

        let kunreiSyashin = engine.search(query: "syashin")
        XCTAssertEqual(kunreiSyashin.results.first?.entry.kanji, "写真")
    }

    func testBurmeseLiteraryAndColloquialSearch() {
        let literary = engine.search(query: "စားသည်")
        XCTAssertEqual(literary.detectedScript, .burmese)
        XCTAssertEqual(literary.results.first?.entry.kanji, "食べる")

        // Colloquial spoken ending (-တယ်) should match literary dictionary headword (-သည်)
        let spoken = engine.search(query: "စားတယ်")
        XCTAssertEqual(spoken.results.first?.entry.kanji, "食べる")

        // Zero-width space pasted from chat apps should be normalized cleanly
        let zwsHospital = engine.search(query: "ဆေး\u{200B}ရုံ")
        XCTAssertEqual(zwsHospital.results.first?.entry.kanji, "病院")
    }

    func testEnglishLookupAndJLPTFilter() {
        let station = engine.search(query: "train station")
        XCTAssertEqual(station.results.first?.entry.kanji, "駅")

        let n3Only = engine.search(query: "", jlptFilter: .n3)
        XCTAssertFalse(n3Only.results.isEmpty)
        XCTAssertTrue(n3Only.results.allSatisfy { $0.entry.jlpt == "N3" })
    }
}
