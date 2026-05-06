import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case english
    case russian

    public var id: String { rawValue }

    var localizationCode: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .russian:
            return "ru"
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

