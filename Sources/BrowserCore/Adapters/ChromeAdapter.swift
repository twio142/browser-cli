import Foundation
import ScriptingBridge

struct ChromeAdapter: BrowserAdapter {
    private let sb = ScriptingBridgeClient()
    private let jxa = JXAClient()

    func listTabs() throws -> [Tab] {
        guard let app = sb.connect(bundleId: BrowserName.chrome.bundleId) else {
            throw BrowserError.browserNotRunning(.chrome)
        }

        return sb.listTabs(app: app).map { entry in
            let title = sb.performSelector(on: entry.raw, name: "title", default: "")
            let url = sb.performSelector(on: entry.raw, name: "URL", default: "")
            let active = sb.performSelector(on: entry.raw, name: "active", default: false)
            return Tab(id: "\(entry.windowIndex):\(entry.tabIndex)", title: title, url: url, active: active)
        }
    }

    func getHTML(tabId: String) throws -> String {
        guard let app = sb.connect(bundleId: BrowserName.chrome.bundleId) else {
            throw BrowserError.browserNotRunning(.chrome)
        }

        let (windowIndex, tabIndex) = try parseTabId(tabId)
        let allTabs = sb.listTabs(app: app)

        guard allTabs.contains(where: { $0.windowIndex == windowIndex && $0.tabIndex == tabIndex }) else {
            throw BrowserError.tabNotFound(tabId)
        }

        let wi = windowIndex - 1
        let ti = tabIndex - 1

        let readyScript = """
        Application('Google Chrome').windows[\(wi)].tabs[\(ti)].execute({javascript: 'document.readyState'})
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
            throw BrowserError.tabStillLoading(tabId)
        }

        let htmlScript = """
        Application('Google Chrome').windows[\(wi)].tabs[\(ti)].execute({javascript: 'document.documentElement.outerHTML'})
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
