import Foundation
import SwiftUI

enum L10n {
    private static var forcedLanguageCode: String?

    /// `*.lproj` folder names shipped in `SoberLifeAppShell` resources.
    private static let supportedBundleCodes: Set<String> = [
        "en", "ru", "de", "fr", "es", "it", "pl", "zh-Hans", "th", "ja",
    ]

    static func setForcedLanguageCode(_ code: String?) {
        forcedLanguageCode = code
    }

    static func string(_ key: String) -> String {
        let bundleCode: String
        if let forcedLanguageCode {
            bundleCode = forcedLanguageCode
        } else {
            bundleCode = bundleCodeForSystemPreferred()
        }
        return localizedString(key, bundleCode: bundleCode)
    }

    private static func localizedString(_ key: String, bundleCode: String) -> String {
        if let path = Bundle.module.path(forResource: bundleCode, ofType: "lproj"),
           let bundle = Bundle(path: path)
        {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        if bundleCode != "en",
           let path = Bundle.module.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path)
        {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        return key
    }

    /// Resolves which packaged `*.lproj` matches the device language list (SwiftPM `Bundle.module` does not reliably follow
    /// `NSLocalizedString` / system language on its own).
    private static func bundleCodeForSystemPreferred() -> String {
        for preferred in Locale.preferredLanguages {
            let normalized = preferred.lowercased().replacingOccurrences(of: "_", with: "-")
            if normalized.hasPrefix("zh-hans") || normalized == "zh-cn" || normalized.hasPrefix("zh-cn-") {
                return "zh-Hans"
            }
            if normalized.hasPrefix("zh-hant") || normalized.hasPrefix("zh-tw") || normalized.hasPrefix("zh-hk")
                || normalized.hasPrefix("zh-mo")
            {
                return "zh-Hans"
            }
            let parts = normalized.split(separator: "-")
            guard let first = parts.first.map(String.init) else { continue }
            if first == "zh" {
                return "zh-Hans"
            }
            if supportedBundleCodes.contains(first) {
                return first
            }
        }
        return "en"
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: string(key), arguments: args)
    }

    static func text(_ key: String) -> Text {
        Text(verbatim: string(key))
    }
}

