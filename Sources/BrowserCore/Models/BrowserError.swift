import Foundation

enum BrowserError: Error, LocalizedError {
    case browserNotRunning(BrowserName)
    case tabNotFound(String)
    case permissionDenied(BrowserName, String)
    case screenshotUnsupported(BrowserName)
    case unsupportedDefaultBrowser(String)
    case pageNotScriptable
    case tabStillLoading(String)
    case noActiveTab(BrowserName)
    case menuItemDisabled(String)

    var exitCode: Int {
        switch self {
        case .browserNotRunning: return 1
        case .tabNotFound: return 2
        case .permissionDenied: return 3
        case .screenshotUnsupported: return 4
        case .unsupportedDefaultBrowser: return 5
        case .pageNotScriptable: return 6
        case .tabStillLoading: return 7
        case .noActiveTab: return 8
        case .menuItemDisabled: return 9
        }
    }

    var errorDescription: String? {
        switch self {
        case let .browserNotRunning(browser):
            let name = browser.rawValue.capitalized
            return "Error: \(name) is not running. Open \(name) and try again."
        case let .tabNotFound(id):
            return "Error: No tab with ID \"\(id)\" found."
        case let .permissionDenied(browser, permission):
            return "Error: \(browser.rawValue.capitalized) requires \"\(permission)\"."
                + " Grant access in System Settings → Privacy & Security."
        case .screenshotUnsupported:
            return "Error: screenshot is only supported for Arc."
        case let .unsupportedDefaultBrowser(name):
            return "Error: Your default browser (\"\(name)\") is not supported."
                + " Use --browser chrome, safari, or arc."
        case .pageNotScriptable:
            return "Error: The page returned no content."
                + " It may be an internal page, a PDF, or still loading."
        case let .tabStillLoading(id):
            return "Error: Tab \(id) is still loading. Wait for it to finish and retry."
        case let .noActiveTab(browser):
            return "Error: \(browser.rawValue.capitalized) has no active tab."
        case let .menuItemDisabled(item):
            return "Error: Menu item \"\(item)\" is not available."
                + " The current tab may not support it."
        }
    }
}
