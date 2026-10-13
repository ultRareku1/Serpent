import XCTest
@testable import Serpent

final class LocalizationTests: XCTestCase {
    func testSupportedSystemLocalesResolveToRequestedLanguages() {
        let cases: [(String, AppLanguage)] = [
            ("en-US", .english),
            ("zh-CN", .simplifiedChinese),
            ("zh-TW", .traditionalChinese),
            ("ja-JP", .japanese),
            ("ko-KR", .korean),
            ("fr-FR", .french),
            ("de-DE", .german),
            ("es-ES", .spanish)
        ]

        for (locale, expected) in cases {
            XCTAssertEqual(AppLanguage.matchingSystemLanguage([locale]), expected, locale)
        }
    }

    func testChineseScriptTakesPriorityOverRegion() {
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["zh-Hant-CN"]), .traditionalChinese)
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["zh-Hans-TW"]), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["zh-Hant"]), .traditionalChinese)
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["zh-Hans"]), .simplifiedChinese)
    }

    func testTraditionalChineseRegionalPreferencesAreRecognized() {
        for locale in ["zh-TW", "zh-HK", "zh-MO"] {
            XCTAssertEqual(AppLanguage.matchingSystemLanguage([locale]), .traditionalChinese, locale)
        }
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["zh"]), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["zh-SG"]), .simplifiedChinese)
    }

    func testLocaleMatchingAcceptsUnderscoresAndMixedCase() {
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["ZH_hAnT_TW"]), .traditionalChinese)
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["FR_fr"]), .french)
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["KO_kr"]), .korean)
    }

    func testFirstSupportedPreferenceWinsAndUnsupportedLanguagesFallBack() {
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["pt-BR", "ja-JP", "en-US"]), .japanese)
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["de-DE", "es-ES"]), .german)
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["ar-SA", "it-IT"]), .english)
        XCTAssertEqual(AppLanguage.matchingSystemLanguage([]), .english)
        XCTAssertEqual(AppLanguage.matchingSystemLanguage(["", "-", "es-ES"]), .spanish)
    }

    func testPackagedResourcesHaveAllKeysAndMatchingFormatArguments() throws {
        let english = try strings(for: .english)
        let expectedKeys = Set(english.keys)

        for language in AppLanguage.allCases where language != .system {
            let translated = try strings(for: language)
            XCTAssertEqual(Set(translated.keys), expectedKeys, language.rawValue)
            for key in expectedKeys {
                let value = try XCTUnwrap(translated[key], "Missing \(key) in \(language.rawValue)")
                XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               "Empty \(key) in \(language.rawValue)")
                XCTAssertEqual(value.components(separatedBy: "%d").count,
                               english[key]!.components(separatedBy: "%d").count,
                               "Format argument mismatch for \(key) in \(language.rawValue)")
            }
        }
    }

    func testEdgeWrappingCopyIsPackagedForEveryLanguage() throws {
        let requiredKeys = [
            "label.wrapEdges",
            "settings.wrapEdgesNote",
            "settings.wrapEdgesPending",
            "status.wrapEdges"
        ]

        for language in AppLanguage.allCases where language != .system {
            let translated = try strings(for: language)
            for key in requiredKeys {
                let value = try XCTUnwrap(translated[key], "Missing \(key) in \(language.rawValue)")
                XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               "Empty \(key) in \(language.rawValue)")
            }
        }
    }

    func testLanguageSelectionLoadsTranslatedResourcesAndFormatsScores() async throws {
        try await MainActor.run {
            let suite = "Serpent.LocalizationTests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let localization = Localization(defaults: defaults)
            let cases: [(AppLanguage, String, String)] = [
                (.english, "Find your flow.", "320 points"),
                (.simplifiedChinese, "找到你的节奏。", "320 分"),
                (.traditionalChinese, "找到你的節奏。", "320 分"),
                (.japanese, "自分のリズムで。", "320 点"),
                (.korean, "나만의 리듬으로.", "320점"),
                (.french, "Trouvez votre rythme.", "320 points"),
                (.german, "Finde deinen Takt.", "320 Punkte"),
                (.spanish, "Encuentra tu ritmo.", "320 puntos")
            ]

            for (language, title, points) in cases {
                localization.language = language
                XCTAssertEqual(localization.resolvedLanguage, language)
                XCTAssertEqual(localization.text("ready.title"), title, language.rawValue)
                XCTAssertEqual(localization.formatted("score.points", 320), points, language.rawValue)
                XCTAssertFalse(localization.formatted("over.body", 320).contains("%d"), language.rawValue)
                XCTAssertEqual(localization.text("unknown.key"), "unknown.key")
            }
        }
    }

    func testLanguageDefaultsToSystemAndSelectedLanguagePersists() async throws {
        try await MainActor.run {
            let suite = "Serpent.LocalizationTests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let initial = Localization(defaults: defaults)
            XCTAssertEqual(initial.language, .system)
            initial.language = .traditionalChinese
            XCTAssertEqual(Localization(defaults: defaults).language, .traditionalChinese)
            initial.language = .system
            XCTAssertEqual(Localization(defaults: defaults).language, .system)
            defaults.set("unsupported", forKey: "serpent.language")
            XCTAssertEqual(Localization(defaults: defaults).language, .system)
        }
    }

    private func strings(for language: AppLanguage) throws -> [String: String] {
        let directory = try XCTUnwrap(Bundle.module.url(forResource: language.rawValue, withExtension: "lproj"),
                                      "Missing packaged \(language.rawValue) localization")
        let data = try Data(contentsOf: directory.appendingPathComponent("Localizable.strings"))
        let propertyList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(propertyList as? [String: String])
    }
}
