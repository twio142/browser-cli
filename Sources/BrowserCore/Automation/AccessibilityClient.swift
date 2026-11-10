import ApplicationServices
import Foundation

struct AccessibilityClient {
    /// Returns the menu bar AXUIElement for the application with the given PID.
    func menuBarElement(for pid: pid_t) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &value) == .success,
              let ref = value
        else {
            return nil
        }
        return unsafeDowncast(ref, to: AXUIElement.self)
    }

    /// Clicks the menu item at `path` in the app's menu bar,
    /// e.g. `["Tools", "Capture", "Page to Clipboard"]`.
    /// The first element is the menu bar title; each later one is an item inside the previous menu.
    /// Throws `BrowserError.permissionDenied` if Accessibility access is not granted.
    /// Throws `BrowserError.menuItemDisabled` if any item on the path is missing, or the final item is disabled.
    func clickMenuItem(app appElement: AXUIElement, browser: BrowserName, path: [String]) throws {
        guard AXIsProcessTrusted() else {
            throw BrowserError.permissionDenied(browser, "Accessibility")
        }

        var menuBarRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBarRef) == .success,
              let ref = menuBarRef
        else {
            throw BrowserError.permissionDenied(browser, "Accessibility")
        }

        let displayPath = path.joined(separator: " → ")
        var container = unsafeDowncast(ref, to: AXUIElement.self)

        for (depth, title) in path.enumerated() {
            guard let items = attribute(container, kAXChildrenAttribute) as? [AXUIElement],
                  let item = items.first(where: { attribute($0, kAXTitleAttribute) as? String == title })
            else {
                throw BrowserError.menuItemDisabled(displayPath)
            }

            if depth == path.count - 1 {
                guard attribute(item, kAXEnabledAttribute) as? Bool ?? false else {
                    throw BrowserError.menuItemDisabled(displayPath)
                }
                AXUIElementPerformAction(item, kAXPressAction as CFString)
                return
            }

            // A menu bar item or submenu item holds its menu as its single child.
            guard let children = attribute(item, kAXChildrenAttribute) as? [AXUIElement],
                  let menu = children.first
            else {
                throw BrowserError.menuItemDisabled(displayPath)
            }
            container = menu
        }
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue(element, name as CFString, &value)
        return value
    }
}
