import Foundation
import SwiftUI

enum L10n {
    private static var forcedLanguageCode: String?

    static func setForcedLanguageCode(_ code: String?) {
        forcedLanguageCode = code
    }

    static func string(_ key: String) -> String {
        if let forcedLanguageCode,
           let path = Bundle.module.path(forResource: forcedLanguageCode, ofType: "lproj"),
           let bundle = Bundle(path: path)
        {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        return NSLocalizedString(key, bundle: .module, comment: "")
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: string(key), arguments: args)
    }

    static func text(_ key: String) -> Text {
        Text(verbatim: string(key))
    }
}

