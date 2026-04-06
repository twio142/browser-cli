import Foundation
import ScriptingBridge

class ScriptingBridgeClient {

    func connect(bundleId: String) -> SBApplication? {
        guard let app = SBApplication(bundleIdentifier: bundleId), app.isRunning else {
            return nil
        }
        return app
    }

    /// KVC-based dynamic property accessor for ScriptingBridge objects.
    func performSelector<T>(on object: AnyObject, name: String, default defaultValue: T) -> T {
        return (object.value(forKey: name) as? T) ?? defaultValue
    }

    /// Enumerates all tabs across all windows. Returns 1-based (windowIndex, tabIndex) pairs plus the raw window and tab objects.
    func listTabs(app: SBApplication) -> [(windowIndex: Int, tabIndex: Int, windowRaw: AnyObject, raw: AnyObject)] {
        var result: [(windowIndex: Int, tabIndex: Int, windowRaw: AnyObject, raw: AnyObject)] = []

        guard let windowsArray = (app as AnyObject).value(forKey: "windows") as? NSArray else {
            return result
        }

        for (wIdx, windowObj) in windowsArray.enumerated() {
            guard let tabs = (windowObj as AnyObject).value(forKey: "tabs") as? NSArray else {
                continue
            }
            for (tIdx, tabObj) in tabs.enumerated() {
                result.append((windowIndex: wIdx + 1, tabIndex: tIdx + 1, windowRaw: windowObj as AnyObject, raw: tabObj as AnyObject))
            }
        }

        return result
    }

    /// Activates the specified tab (1-based indices) and brings its window to the foreground.
    func activateTab(app: SBApplication, windowIndex: Int, tabIndex: Int) {
        guard let windowsArray = (app as AnyObject).value(forKey: "windows") as? NSArray,
              windowIndex > 0, windowIndex <= windowsArray.count else { return }

        let windowObj = windowsArray[windowIndex - 1] as AnyObject
        windowObj.setValue(tabIndex, forKey: "activeTabIndex")
    }
}
