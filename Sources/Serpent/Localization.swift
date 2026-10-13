import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .system: "🌐"
        case .english: "🇺🇸"
        case .simplifiedChinese: "🇨🇳"
        case .traditionalChinese: "🇹🇼"
        case .japanese: "🇯🇵"
        case .korean: "🇰🇷"
        case .french: "🇫🇷"
        case .german: "🇩🇪"
        case .spanish: "🇪🇸"
        }
    }

    var nativeName: String {
        switch self {
        case .system: "System"
        case .english: "English (US)"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .french: "Français"
        case .german: "Deutsch"
        case .spanish: "Español"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .system: Locale.current.identifier
        case .english: "en_US"
        case .simplifiedChinese: "zh_CN"
        case .traditionalChinese: "zh_TW"
        case .japanese: "ja_JP"
        case .korean: "ko_KR"
        case .french: "fr_FR"
        case .german: "de_DE"
        case .spanish: "es_ES"
        }
    }

    /// Unsupported preferences fall through to the next language, then English.
    static func matchingSystemLanguage(_ preferredLanguages: [String]) -> AppLanguage {
        for preference in preferredLanguages {
            let parts = preference.replacingOccurrences(of: "_", with: "-")
                .lowercased().split(separator: "-").map(String.init)
            guard let language = parts.first else { continue }
            switch language {
            case "en": return .english
            case "zh":
                if parts.contains("hant") { return .traditionalChinese }
                if parts.contains("hans") { return .simplifiedChinese }
                if parts.contains(where: { ["tw", "hk", "mo"].contains($0) }) {
                    return .traditionalChinese
                }
                return .simplifiedChinese
            case "ja": return .japanese
            case "ko": return .korean
            case "fr": return .french
            case "de": return .german
            case "es": return .spanish
            default: continue
            }
        }
        return .english
    }
}

@MainActor
final class Localization: ObservableObject {
    private static let preferenceKey = "serpent.language"
    private let defaults: UserDefaults
    private var bundles: [AppLanguage: Bundle] = [:]

    @Published var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Self.preferenceKey)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = defaults.string(forKey: Self.preferenceKey)
            .flatMap(AppLanguage.init(rawValue:)) ?? .system
        for option in AppLanguage.allCases where option != .system {
            if let path = Bundle.module.path(forResource: option.rawValue, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                bundles[option] = bundle
            }
        }
    }

    var resolvedLanguage: AppLanguage {
        language == .system
            ? AppLanguage.matchingSystemLanguage(Locale.preferredLanguages)
            : language
    }

    func text(_ key: String) -> String {
        let fallback = bundles[.english]?.localizedString(forKey: key, value: key, table: nil) ?? key
        return bundles[resolvedLanguage]?.localizedString(forKey: key, value: fallback, table: nil)
            ?? fallback
    }

    func formatted(_ key: String, _ args: CVarArg...) -> String {
        String(format: text(key), locale: Locale(identifier: resolvedLanguage.localeIdentifier), arguments: args)
    }
}
