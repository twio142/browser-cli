import Foundation

enum BrowserError: Error, LocalizedError {
    case browserNotRunning(BrowserName)
    case tabNotFound(String)
    case permissionDenied(BrowserName, String)
    case screenshotUnsupported(BrowserName)
    case unsupportedDefaultBrowser(String)
    case arcReturnedNoValue
    case tabStillLoading(String)

    var exitCode: Int {
        switch self {
        case .browserNotRunning:        return 1
        case .tabNotFound:              return 2
        case .permissionDenied:         return 3
        case .screenshotUnsupported:    return 4
        case .unsupportedDefaultBrowser: return 5
        case .arcReturnedNoValue:       return 6
        case .tabStillLoading:          return 7
        }
    }

    var errorDescription: String? {
        switch self {
        case .browserNotRunning(let browser):
            return "Error: \(browser.rawValue.capitalized) is not running. Open \(browser.rawValue.capitalized) and try again."
        case .tabNotFound(let id):
            return "Error: No tab with ID \"\(id)\" found."
        case .permissionDenied(let browser, let permission):
            return "Error: \(browser.rawValue.capitalized) requires \"\(permission)\". Grant access in System Settings → Privacy & Security."
        case .screenshotUnsupported:
            return "Error: screenshot is only supported for Arc."
        case .unsupportedDefaultBrowser(let name):
            return "Error: Your default browser (\"\(name)\") is not supported. Use --browser chrome, safari, or arc."
        case .arcReturnedNoValue:
            return "Error: Arc returned no value for JavaScript execution. This is a known Arc limitation. Try again or use --browser safari."
        case .tabStillLoading(let id):
            return "Error: Tab \(id) is still loading. Wait for it to finish and retry."
        }
    }
}
