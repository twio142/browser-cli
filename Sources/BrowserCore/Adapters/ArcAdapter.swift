import AppKit
import ApplicationServices
import ScriptingBridge

struct ArcAdapter: BrowserAdapter {
    private let bridge = ScriptingBridgeClient()
    private let jxa = JXAClient()
    private let accessibility = AccessibilityClient()

    func listTabs() throws -> [Tab] {
        guard let app = bridge.connect(bundleId: BrowserName.arc.bundleId) else {
            throw BrowserError.browserNotRunning(.arc)
        }

        var activeIdPerWindow: [Int: String] = [:]

        return bridge.listTabs(app: app).map { entry in
            let title = bridge.performSelector(on: entry.raw, name: "title", default: "")
            let url = bridge.performSelector(on: entry.raw, name: "URL", default: "")

            if activeIdPerWindow[entry.windowIndex] == nil {
                // value(forKey:) on the activeTab SB proxy returns nil for all properties;
                // forKeyPath resolves the chain through the scripting engine and returns the UUID string.
                activeIdPerWindow[entry.windowIndex] =
                    entry.windowRaw.value(forKeyPath: "activeTab.id") as? String ?? ""
            }

            let tabId = entry.raw.value(forKey: "id") as? String ?? ""
            let active = !tabId.isEmpty && tabId == activeIdPerWindow[entry.windowIndex]

            return Tab(id: "\(entry.windowIndex):\(entry.tabIndex)", title: title, url: url, active: active)
        }
    }

    func getHTML(tabId: String?) throws -> String {
        guard let app = bridge.connect(bundleId: BrowserName.arc.bundleId) else {
            throw BrowserError.browserNotRunning(.arc)
        }

        let tabRef: String

        if let tabId = tabId {
            let (windowIndex, tabIndex) = try parseTabId(tabId)
            let allTabs = bridge.listTabs(app: app)
            guard allTabs.contains(where: { $0.windowIndex == windowIndex && $0.tabIndex == tabIndex }) else {
                throw BrowserError.tabNotFound(tabId)
            }
            tabRef = "windows[\(windowIndex - 1)].tabs[\(tabIndex - 1)]"
        } else {
            guard let windowsArray = (app as AnyObject).value(forKey: "windows") as? NSArray,
                  windowsArray.count > 0,
                  let tabs = (windowsArray[0] as AnyObject).value(forKey: "tabs") as? NSArray,
                  tabs.count > 0 else {
                throw BrowserError.noActiveTab(.arc)
            }
            tabRef = "windows[0].activeTab"
        }

        let script = "Application('Arc').\(tabRef).execute({javascript: 'document.documentElement.outerHTML'})"

        do {
            return try jxa.execute(script: script)
        } catch let error as NSError {
            if isPermissionError(error) {
                throw BrowserError.permissionDenied(.arc, "Allow JavaScript from Apple Events")
            }
            throw error
        }
    }

    func screenshot(tabId: String?) throws {
        guard let app = bridge.connect(bundleId: BrowserName.arc.bundleId) else {
            throw BrowserError.browserNotRunning(.arc)
        }

        if let tabId = tabId {
            let (windowIndex, tabIndex) = try parseTabId(tabId)
            bridge.activateTab(app: app, windowIndex: windowIndex, tabIndex: tabIndex)
        }

        guard let runningApp = NSRunningApplication.runningApplications(
            withBundleIdentifier: BrowserName.arc.bundleId
        ).first else {
            throw BrowserError.browserNotRunning(.arc)
        }

        runningApp.activate(options: .activateIgnoringOtherApps)

        let arcElement = AXUIElementCreateApplication(runningApp.processIdentifier)
        try accessibility.clickMenuItem(app: arcElement, menuTitle: "File", itemTitle: "Capture Full Page")
    }

    private func parseTabId(_ tabId: String) throws -> (Int, Int) {
        let parts = tabId.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { throw BrowserError.tabNotFound(tabId) }
        return (parts[0], parts[1])
    }

    private func isPermissionError(_ error: NSError) -> Bool {
        return error.code == -1743 || error.code == -1719
    }
}
