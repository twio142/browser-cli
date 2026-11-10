import AppKit

protocol BrowserAdapter {
    func listTabs() throws -> [Tab]
    func getHTML(tabId: String?) throws -> String
    func getSelection() throws -> SelectionResult
    func screenshot(tabId: String?) throws
}

extension BrowserAdapter {
    /// Default: screenshot not supported.
    func screenshot(tabId _: String?) throws {
        throw BrowserError.screenshotUnsupported(.chrome)
    }
}

/// Returns the system default browser. Throws if it isn't one this tool supports.
func defaultBrowserName() throws -> BrowserName {
    guard let appURL = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://")!) else {
        throw BrowserError.unsupportedDefaultBrowser("unknown")
    }
    guard let bundle = Bundle(url: appURL),
          let bundleId = bundle.bundleIdentifier,
          let detected = BrowserName(bundleId: bundleId)
    else {
        let appName = Bundle(url: appURL)?.infoDictionary?["CFBundleName"] as? String ?? "unknown"
        throw BrowserError.unsupportedDefaultBrowser(appName)
    }
    return detected
}

/// Resolves the appropriate adapter for the given browser name, or detects the system default.
func resolveAdapter(name: BrowserName?) throws -> any BrowserAdapter {
    let browserName = try name ?? defaultBrowserName()

    switch browserName {
    case .chrome, .vivaldi: return ChromeAdapter(browser: browserName)
    case .safari: return SafariAdapter()
    case .arc: return ArcAdapter()
    }
}
