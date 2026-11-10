import Foundation

enum BrowserName: String, CaseIterable {
    case chrome
    case vivaldi
    case safari
    case arc

    var bundleId: String {
        switch self {
        case .chrome: return "com.google.Chrome"
        case .vivaldi: return "com.vivaldi.Vivaldi"
        case .safari: return "com.apple.Safari"
        case .arc: return "company.thebrowser.Browser"
        }
    }

    /// Browsers whose adapter implements `screenshot`.
    var supportsScreenshot: Bool {
        self == .arc || self == .vivaldi
    }

    init?(bundleId: String) {
        switch bundleId {
        case "com.google.Chrome": self = .chrome
        case "com.vivaldi.Vivaldi": self = .vivaldi
        case "com.apple.Safari": self = .safari
        case "company.thebrowser.Browser": self = .arc
        default: return nil
        }
    }
}
