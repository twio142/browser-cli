import Foundation
import ScriptingBridge

struct SafariAdapter: BrowserAdapter {
    private let sb = ScriptingBridgeClient()

    func listTabs() throws -> [Tab] {
        guard let app = sb.connect(bundleId: BrowserName.safari.bundleId) else {
            throw BrowserError.browserNotRunning(.safari)
        }

        return sb.listTabs(app: app).map { entry in
            let title = sb.performSelector(on: entry.raw, name: "name", default: "")
            let url = sb.performSelector(on: entry.raw, name: "URL", default: "")
            let currentTab = entry.windowRaw.value(forKey: "currentTab")
            let active = (entry.raw as? NSObject)?.isEqual(currentTab) ?? false
            return Tab(id: "\(entry.windowIndex):\(entry.tabIndex)", title: title, url: url, active: active)
        }
    }

    func getHTML(tabId: String) throws -> String {
        guard let app = sb.connect(bundleId: BrowserName.safari.bundleId) else {
            throw BrowserError.browserNotRunning(.safari)
        }

        let (windowIndex, tabIndex) = try parseTabId(tabId)
        let allTabs = sb.listTabs(app: app)

        guard let entry = allTabs.first(where: { $0.windowIndex == windowIndex && $0.tabIndex == tabIndex }) else {
            throw BrowserError.tabNotFound(tabId)
        }

        let source = sb.performSelector(on: entry.raw, name: "source", default: "")
        guard !source.isEmpty else {
            throw BrowserError.tabNotFound(tabId)
        }

        return source
    }

    private func parseTabId(_ tabId: String) throws -> (Int, Int) {
        let parts = tabId.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { throw BrowserError.tabNotFound(tabId) }
        return (parts[0], parts[1])
    }
}
