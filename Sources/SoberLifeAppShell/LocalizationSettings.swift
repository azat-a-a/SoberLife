import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case english
    case russian
    case german
    case french
    case spanish
    case italian
    case polish
    case chineseSimplified
    case thai
    case japanese

    public var id: String { rawValue }

    var localizationCode: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .russian:
            return "ru"
        case .german:
            return "de"
        case .french:
            return "fr"
        case .spanish:
            return "es"
        case .italian:
            return "it"
        case .polish:
            return "pl"
        case .chineseSimplified:
            return "zh-Hans"
        case .thai:
            return "th"
        case .japanese:
            return "ja"
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .english:
            return Locale(identifier: "en")
        case .russian:
            return Locale(identifier: "ru")
        case .german:
            return Locale(identifier: "de")
        case .french:
            return Locale(identifier: "fr")
        case .spanish:
            return Locale(identifier: "es")
        case .italian:
            return Locale(identifier: "it")
        case .polish:
            return Locale(identifier: "pl")
        case .chineseSimplified:
            return Locale(identifier: "zh-Hans")
        case .thai:
            return Locale(identifier: "th")
        case .japanese:
            return Locale(identifier: "ja")
        }
    }

    var labelKey: String {
        switch self {
        case .system:
            return "profile.language.system"
        case .english:
            return "profile.language.english"
        case .russian:
            return "profile.language.russian"
        case .german:
            return "profile.language.german"
        case .french:
            return "profile.language.french"
        case .spanish:
            return "profile.language.spanish"
        case .italian:
            return "profile.language.italian"
        case .polish:
            return "profile.language.polish"
        case .chineseSimplified:
            return "profile.language.chinese_simplified"
        case .thai:
            return "profile.language.thai"
        case .japanese:
            return "profile.language.japanese"
        }
    }
}

@MainActor
public final class LocalizationSettings: ObservableObject {
    private let defaults: UserDefaults
    private let storageKey: String

    @Published public var selectedLanguage: AppLanguage {
        didSet {
            defaults.set(selectedLanguage.rawValue, forKey: storageKey)
            L10n.setForcedLanguageCode(selectedLanguage.localizationCode)
        }
    }

    public init(
        defaults: UserDefaults = .standard,
        storageKey: String = "soberlife.app.language"
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        if
            let raw = defaults.string(forKey: storageKey),
            let value = AppLanguage(rawValue: raw)
        {
            self.selectedLanguage = value
        } else {
            self.selectedLanguage = .system
        }
        L10n.setForcedLanguageCode(selectedLanguage.localizationCode)
    }

    public var locale: Locale {
        selectedLanguage.locale
    }
}

