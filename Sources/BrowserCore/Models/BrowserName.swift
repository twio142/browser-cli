import Foundation

enum BrowserName: String, CaseIterable {
    case chrome = "chrome"
    case safari = "safari"
    case arc = "arc"

    var bundleId: String {
        switch self {
        case .chrome: return "com.google.Chrome"
        case .safari: return "com.apple.Safari"
        case .arc: return "company.thebrowser.Browser"
        }
    }

    init?(bundleId: String) {
        switch bundleId {
        case "com.google.Chrome": self = .chrome
        case "com.apple.Safari": self = .safari
        case "company.thebrowser.Browser": self = .arc
        default: return nil
        }
    }
}
