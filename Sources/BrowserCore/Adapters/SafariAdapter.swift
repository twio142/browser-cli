import Foundation
import ScriptingBridge

struct SafariAdapter: BrowserAdapter {
    private let bridge = ScriptingBridgeClient()
    private let jxa = JXAClient()

    func listTabs() throws -> [Tab] {
        guard let app = bridge.connect(bundleId: BrowserName.safari.bundleId) else {
            throw BrowserError.browserNotRunning(.safari)
        }

        var activeTabIndexPerWindow: [Int: Int] = [:]
        return bridge.listTabs(app: app).map { entry in
            let title = bridge.performSelector(on: entry.raw, name: "name", default: "")
            let url = bridge.performSelector(on: entry.raw, name: "URL", default: "")
            if activeTabIndexPerWindow[entry.windowIndex] == nil {
                let currentTab = entry.windowRaw.value(forKey: "currentTab") as AnyObject
                activeTabIndexPerWindow[entry.windowIndex] = currentTab.value(forKey: "index") as? Int ?? -1
            }
            let active = activeTabIndexPerWindow[entry.windowIndex] == entry.tabIndex
            return Tab(id: "\(entry.windowIndex):\(entry.tabIndex)", title: title, url: url, active: active)
        }
    }

    func getHTML(tabId: String?) throws -> String {
        guard let app = bridge.connect(bundleId: BrowserName.safari.bundleId) else {
            throw BrowserError.browserNotRunning(.safari)
        }

        let tabRaw: AnyObject

        if let tabId = tabId {
            let (windowIndex, tabIndex) = try parseTabId(tabId)
            let allTabs = bridge.listTabs(app: app)
            guard let entry = allTabs.first(where: { $0.windowIndex == windowIndex && $0.tabIndex == tabIndex }) else {
                throw BrowserError.tabNotFound(tabId)
            }
            tabRaw = entry.raw
        } else {
            guard let windowsArray = (app as AnyObject).value(forKey: "windows") as? NSArray,
                  windowsArray.count > 0
            else {
                throw BrowserError.noActiveTab(.safari)
            }
            tabRaw = (windowsArray[0] as AnyObject).value(forKey: "currentTab") as AnyObject
        }

        let source = bridge.performSelector(on: tabRaw, name: "source", default: "")
        guard !source.isEmpty else {
            if let tabId = tabId {
                throw BrowserError.tabNotFound(tabId)
            } else {
                throw BrowserError.noActiveTab(.safari)
            }
        }

        return source
    }

    func getSelection() throws -> SelectionResult {
        guard let app = bridge.connect(bundleId: BrowserName.safari.bundleId) else {
            throw BrowserError.browserNotRunning(.safari)
        }

        guard let windowsArray = (app as AnyObject).value(forKey: "windows") as? NSArray,
              windowsArray.count > 0
        else {
            throw BrowserError.noActiveTab(.safari)
        }

        let windowObj = windowsArray[0] as AnyObject
        let currentTab = windowObj.value(forKey: "currentTab") as AnyObject
        let title = bridge.performSelector(on: currentTab, name: "name", default: "")
        let url = bridge.performSelector(on: currentTab, name: "URL", default: "")

        let selection: String
        do {
            let script = "Application('Safari').windows[0].currentTab"
                + ".doJavaScript('window.getSelection().toString()')"
            selection = try jxa.execute(script: script, allowEmpty: true)
        } catch {
            selection = ""
        }

        return SelectionResult(title: title, url: url, selection: selection)
    }

    private func parseTabId(_ tabId: String) throws -> (Int, Int) {
        let parts = tabId.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { throw BrowserError.tabNotFound(tabId) }
        return (parts[0], parts[1])
    }
}
