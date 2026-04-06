import AppKit
import ScriptingBridge
import ApplicationServices

struct ArcAdapter: BrowserAdapter {
    private let sb = ScriptingBridgeClient()
    private let jxa = JXAClient()
    private let ax = AccessibilityClient()

    func listTabs() throws -> [Tab] {
        guard let app = sb.connect(bundleId: BrowserName.arc.bundleId) else {
            throw BrowserError.browserNotRunning(.arc)
        }

        var activeIdPerWindow: [Int: String] = [:]

        return sb.listTabs(app: app).map { entry in
            let title = sb.performSelector(on: entry.raw, name: "title", default: "")
            let url = sb.performSelector(on: entry.raw, name: "URL", default: "")

            if activeIdPerWindow[entry.windowIndex] == nil {
                let activeTab = entry.windowRaw.value(forKey: "activeTab") as AnyObject
                activeIdPerWindow[entry.windowIndex] = activeTab.value(forKey: "id") as? String ?? ""
            }

            let tabId = sb.performSelector(on: entry.raw, name: "id", default: "")
            let active = !tabId.isEmpty && tabId == activeIdPerWindow[entry.windowIndex]

            return Tab(id: "\(entry.windowIndex):\(entry.tabIndex)", title: title, url: url, active: active)
        }
    }

    func getHTML(tabId: String) throws -> String {
        guard let app = sb.connect(bundleId: BrowserName.arc.bundleId) else {
            throw BrowserError.browserNotRunning(.arc)
        }

        let (windowIndex, tabIndex) = try parseTabId(tabId)
        let allTabs = sb.listTabs(app: app)

        guard allTabs.contains(where: { $0.windowIndex == windowIndex && $0.tabIndex == tabIndex }) else {
            throw BrowserError.tabNotFound(tabId)
        }

        let wi = windowIndex - 1
        let ti = tabIndex - 1

        let htmlScript = """
        Application('Arc').windows[\(wi)].tabs[\(ti)].execute({javascript: 'document.documentElement.outerHTML'})
        """

        do {
            return try jxa.execute(script: htmlScript)
        } catch BrowserError.arcReturnedNoValue {
            throw BrowserError.arcReturnedNoValue
        } catch let error as NSError {
            if isPermissionError(error) {
                throw BrowserError.permissionDenied(.arc, "Allow JavaScript from Apple Events")
            }
            throw error
        }
    }

    func screenshot(tabId: String?) throws {
        guard let app = sb.connect(bundleId: BrowserName.arc.bundleId) else {
            throw BrowserError.browserNotRunning(.arc)
        }

        if let tabId = tabId {
            let (windowIndex, tabIndex) = try parseTabId(tabId)
            sb.activateTab(app: app, windowIndex: windowIndex, tabIndex: tabIndex)
        }

        guard let runningApp = NSRunningApplication.runningApplications(
            withBundleIdentifier: BrowserName.arc.bundleId).first else {
            throw BrowserError.browserNotRunning(.arc)
        }

        runningApp.activate(options: .activateIgnoringOtherApps)

        let arcElement = AXUIElementCreateApplication(runningApp.processIdentifier)
        try ax.clickMenuItem(app: arcElement, menuTitle: "File", itemTitle: "Capture Full Page")
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
