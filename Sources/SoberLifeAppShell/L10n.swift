import Foundation
import SwiftUI

enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: "")
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        String(format: string(key), arguments: args)
    }

    static func text(_ key: String) -> Text {
        Text(LocalizedStringKey(key), bundle: .module)
    }
}

