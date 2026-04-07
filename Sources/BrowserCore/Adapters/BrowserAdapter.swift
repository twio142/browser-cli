import AppKit

protocol BrowserAdapter {
    func listTabs() throws -> [Tab]
    func getHTML(tabId: String?) throws -> String
    func screenshot(tabId: String?) throws
}

extension BrowserAdapter {
    /// Default: screenshot not supported.
    func screenshot(tabId _: String?) throws {
        throw BrowserError.screenshotUnsupported(.chrome)
    }
}

/// Resolves the appropriate adapter for the given browser name, or detects the system default.
func resolveAdapter(name: BrowserName?) throws -> any BrowserAdapter {
    let browserName: BrowserName

    if let name = name {
        browserName = name
    } else {
        guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://")!) else {
            throw BrowserError.unsupportedDefaultBrowser("unknown")
        }
        guard let bundle = Bundle(url: appURL),
              let bundleId = bundle.bundleIdentifier,
              let detected = BrowserName(bundleId: bundleId) else {
            let appName = Bundle(url: appURL)?.infoDictionary?["CFBundleName"] as? String ?? "unknown"
            throw BrowserError.unsupportedDefaultBrowser(appName)
        }
        browserName = detected
    }

    switch browserName {
    case .chrome: return ChromeAdapter()
    case .safari: return SafariAdapter()
    case .arc: return ArcAdapter()
    }
}
