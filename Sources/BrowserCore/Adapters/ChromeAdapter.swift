import Foundation
import ScriptingBridge

struct ChromeAdapter: BrowserAdapter {
    private let sb = ScriptingBridgeClient()
    private let jxa = JXAClient()

    func listTabs() throws -> [Tab] {
        guard let app = sb.connect(bundleId: BrowserName.chrome.bundleId) else {
            throw BrowserError.browserNotRunning(.chrome)
        }

        var activeTabIdPerWindow: [Int: String] = [:]
        return sb.listTabs(app: app).map { entry in
            let title = sb.performSelector(on: entry.raw, name: "title", default: "")
            let url = sb.performSelector(on: entry.raw, name: "URL", default: "")
            if activeTabIdPerWindow[entry.windowIndex] == nil {
                let activeTab = entry.windowRaw.value(forKey: "activeTab") as AnyObject
                activeTabIdPerWindow[entry.windowIndex] = activeTab.value(forKey: "id") as? String ?? ""
            }
            let tabId = sb.performSelector(on: entry.raw, name: "id", default: "")
            let active = !tabId.isEmpty && tabId == activeTabIdPerWindow[entry.windowIndex]
            return Tab(id: "\(entry.windowIndex):\(entry.tabIndex)", title: title, url: url, active: active)
        }
    }

    func getHTML(tabId: String?) throws -> String {
        guard let app = sb.connect(bundleId: BrowserName.chrome.bundleId) else {
            throw BrowserError.browserNotRunning(.chrome)
        }

        let tabRef: String
        let displayId: String

        if let tabId = tabId {
            let (windowIndex, tabIndex) = try parseTabId(tabId)
            let allTabs = sb.listTabs(app: app)
            guard allTabs.contains(where: { $0.windowIndex == windowIndex && $0.tabIndex == tabIndex }) else {
                throw BrowserError.tabNotFound(tabId)
            }
            tabRef = "windows[\(windowIndex - 1)].tabs[\(tabIndex - 1)]"
            displayId = tabId
        } else {
            guard let windowsArray = (app as AnyObject).value(forKey: "windows") as? NSArray,
                  windowsArray.count > 0,
                  let tabs = (windowsArray[0] as AnyObject).value(forKey: "tabs") as? NSArray,
                  tabs.count > 0 else {
                throw BrowserError.noActiveTab(.chrome)
            }
            tabRef = "windows[0].activeTab"
            displayId = "active"
        }

        let readyScript = """
        Application('Google Chrome').\(tabRef).execute({javascript: 'document.readyState'})
        """

        let readyState: String
        do {
            readyState = try jxa.execute(script: readyScript)
        } catch let error as NSError {
            if isPermissionError(error) {
                throw BrowserError.permissionDenied(.chrome,
                    "Allow JavaScript from Apple Events (Chrome → View → Developer → Allow JavaScript from Apple Events)")
            }
            throw error
        }

        guard readyState == "complete" else {
            throw BrowserError.tabStillLoading(displayId)
        }

        let htmlScript = """
        Application('Google Chrome').\(tabRef).execute({javascript: 'document.documentElement.outerHTML'})
        """

        do {
            return try jxa.execute(script: htmlScript)
        } catch let error as NSError {
            if isPermissionError(error) {
                throw BrowserError.permissionDenied(.chrome,
                    "Allow JavaScript from Apple Events (Chrome → View → Developer → Allow JavaScript from Apple Events)")
            }
            throw error
        }
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
