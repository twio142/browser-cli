import AppKit
import ApplicationServices
import ScriptingBridge

/// Handles Chromium browsers that share Chrome's scripting dictionary (Chrome, Vivaldi).
struct ChromeAdapter: BrowserAdapter {
    let browser: BrowserName
    private let bridge = ScriptingBridgeClient()
    private let jxa = JXAClient()
    private let accessibility = AccessibilityClient()

    init(browser: BrowserName = .chrome) {
        self.browser = browser
    }

    /// Application name used in JXA scripts.
    private var appName: String {
        browser == .vivaldi ? "Vivaldi" : "Google Chrome"
    }

    private var allowJSMessage: String {
        browser == .chrome
            ? "Allow JavaScript from Apple Events"
                + " (Chrome → View → Developer → Allow JavaScript from Apple Events)"
            : "Allow JavaScript from Apple Events"
    }

    func listTabs() throws -> [Tab] {
        guard let app = bridge.connect(bundleId: browser.bundleId) else {
            throw BrowserError.browserNotRunning(browser)
        }

        var activeTabIdPerWindow: [Int: String] = [:]
        return bridge.listTabs(app: app).map { entry in
            let title = bridge.performSelector(on: entry.raw, name: "title", default: "")
            let url = bridge.performSelector(on: entry.raw, name: "URL", default: "")
            if activeTabIdPerWindow[entry.windowIndex] == nil {
                let activeTab = entry.windowRaw.value(forKey: "activeTab") as AnyObject
                activeTabIdPerWindow[entry.windowIndex] = activeTab.value(forKey: "id") as? String ?? ""
            }
            let tabId = bridge.performSelector(on: entry.raw, name: "id", default: "")
            let active = !tabId.isEmpty && tabId == activeTabIdPerWindow[entry.windowIndex]
            return Tab(id: "\(entry.windowIndex):\(entry.tabIndex)", title: title, url: url, active: active)
        }
    }

    func getHTML(tabId: String?) throws -> String {
        guard let app = bridge.connect(bundleId: browser.bundleId) else {
            throw BrowserError.browserNotRunning(browser)
        }

        let tabRef: String
        let displayId: String

        if let tabId = tabId {
            let (windowIndex, tabIndex) = try parseTabId(tabId)
            let allTabs = bridge.listTabs(app: app)
            guard allTabs.contains(where: { $0.windowIndex == windowIndex && $0.tabIndex == tabIndex }) else {
                throw BrowserError.tabNotFound(tabId)
            }
            tabRef = "windows[\(windowIndex - 1)].tabs[\(tabIndex - 1)]"
            displayId = tabId
        } else {
            guard let windowsArray = (app as AnyObject).value(forKey: "windows") as? NSArray,
                  windowsArray.count > 0,
                  let tabs = (windowsArray[0] as AnyObject).value(forKey: "tabs") as? NSArray,
                  tabs.count > 0
            else {
                throw BrowserError.noActiveTab(browser)
            }
            tabRef = "windows[0].activeTab"
            displayId = "active"
        }

        let readyState: String
        do {
            let script = "Application('\(appName)').\(tabRef).execute({javascript: 'document.readyState'})"
            readyState = try jxa.execute(script: script)
        } catch let error as NSError {
            if isPermissionError(error) {
                throw BrowserError.permissionDenied(browser, allowJSMessage)
            }
            throw error
        }

        guard readyState == "complete" else {
            throw BrowserError.tabStillLoading(displayId)
        }

        do {
            let script = "Application('\(appName)').\(tabRef)"
                + ".execute({javascript: 'document.documentElement.outerHTML'})"
            return try jxa.execute(script: script)
        } catch let error as NSError {
            if isPermissionError(error) {
                throw BrowserError.permissionDenied(browser, allowJSMessage)
            }
            throw error
        }
    }

    func getSelection() throws -> SelectionResult {
        guard let app = bridge.connect(bundleId: browser.bundleId) else {
            throw BrowserError.browserNotRunning(browser)
        }

        guard let windowsArray = (app as AnyObject).value(forKey: "windows") as? NSArray,
              windowsArray.count > 0
        else {
            throw BrowserError.noActiveTab(browser)
        }

        let windowObj = windowsArray[0] as AnyObject
        let activeTab = windowObj.value(forKey: "activeTab") as AnyObject
        let title = bridge.performSelector(on: activeTab, name: "title", default: "")
        let url = bridge.performSelector(on: activeTab, name: "URL", default: "")

        let selection: String
        do {
            let script = "Application('\(appName)').windows[0].activeTab"
                + ".execute({javascript: 'window.getSelection().toString()'})"
            selection = try jxa.execute(script: script, allowEmpty: true)
        } catch is BrowserError {
            selection = ""
        } catch let error as NSError {
            if isPermissionError(error) {
                throw BrowserError.permissionDenied(browser, allowJSMessage)
            }
            selection = ""
        }

        return SelectionResult(title: title, url: url, selection: selection)
    }

    /// Menu item that copies the page image to the clipboard. Chrome has none.
    private var screenshotMenuPath: [String]? {
        browser == .vivaldi ? ["Tools", "Capture", "Page to Clipboard"] : nil
    }

    func screenshot(tabId: String?) throws {
        guard let menuPath = screenshotMenuPath else {
            throw BrowserError.screenshotUnsupported(browser)
        }
        guard let app = bridge.connect(bundleId: browser.bundleId) else {
            throw BrowserError.browserNotRunning(browser)
        }

        if let tabId = tabId {
            let (windowIndex, tabIndex) = try parseTabId(tabId)
            guard let entry = bridge.listTabs(app: app).first(where: {
                $0.windowIndex == windowIndex && $0.tabIndex == tabIndex
            }) else {
                throw BrowserError.tabNotFound(tabId)
            }
            // Chrome's dictionary switches tabs through the window's writable, 1-based activeTabIndex.
            let script = "Application('\(appName)').windows[\(windowIndex - 1)].activeTabIndex = \(tabIndex)"
            do {
                try jxa.run(script: script)
            } catch let error as NSError {
                if isPermissionError(error) {
                    throw BrowserError.permissionDenied(browser, "Allow Apple Events")
                }
                throw error
            }
            waitForActiveTab(window: entry.windowRaw, tabId: entry.raw.value(forKey: "id") as? String)
        }

        guard let runningApp = NSRunningApplication.runningApplications(
            withBundleIdentifier: browser.bundleId
        ).first else {
            throw BrowserError.browserNotRunning(browser)
        }

        runningApp.activate(options: .activateIgnoringOtherApps)

        let appElement = AXUIElementCreateApplication(runningApp.processIdentifier)
        try accessibility.clickMenuItem(app: appElement, browser: browser, path: menuPath)
    }

    /// Polls until the window's active tab is `tabId`, then lets the page settle before capture.
    private func waitForActiveTab(window: AnyObject, tabId: String?, timeout: TimeInterval = 2.0) {
        let settleDelay: TimeInterval = 0.3
        if let tabId = tabId, !tabId.isEmpty {
            let deadline = Date().addingTimeInterval(timeout)
            while Date() < deadline {
                let activeTab = window.value(forKey: "activeTab") as AnyObject
                if bridge.performSelector(on: activeTab, name: "id", default: "") == tabId {
                    break
                }
                Thread.sleep(forTimeInterval: 0.05)
            }
        }
        Thread.sleep(forTimeInterval: settleDelay)
    }

    private func parseTabId(_ tabId: String) throws -> (Int, Int) {
        let parts = tabId.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { throw BrowserError.tabNotFound(tabId) }
        return (parts[0], parts[1])
    }

    private func isPermissionError(_ error: NSError) -> Bool {
        // -1743: errAEEventNotPermitted, -1719: errAEEventWouldRequireUserConsent
        return error.code == -1743 || error.code == -1719
    }
}
