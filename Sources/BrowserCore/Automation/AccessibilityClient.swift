import Foundation
import ApplicationServices

struct AccessibilityClient {

    /// Returns the menu bar AXUIElement for the application with the given PID.
    func menuBarElement(for pid: pid_t) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &value) == .success else {
            return nil
        }
        return (value as! AXUIElement)
    }

    /// Clicks the menu item at `menuTitle > itemTitle` in the given app element's menu bar.
    /// Throws `BrowserError.permissionDenied` if Accessibility access is not granted.
    func clickMenuItem(app appElement: AXUIElement, menuTitle: String, itemTitle: String) throws {
        guard AXIsProcessTrusted() else {
            throw BrowserError.permissionDenied(.arc, "Accessibility")
        }

        var menuBarRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBarRef) == .success,
              let menuBar = menuBarRef as! AXUIElement? else {
            throw BrowserError.permissionDenied(.arc, "Accessibility")
        }

        guard let menuBarItems = attribute(menuBar, kAXChildrenAttribute) as? [AXUIElement] else {
            return
        }

        guard let menuItem = menuBarItems.first(where: {
            attribute($0, kAXTitleAttribute) as? String == menuTitle
        }) else { return }

        guard let submenuChildren = attribute(menuItem, kAXChildrenAttribute) as? [AXUIElement],
              let submenu = submenuChildren.first else { return }

        guard let items = attribute(submenu, kAXChildrenAttribute) as? [AXUIElement] else { return }

        guard let target = items.first(where: {
            attribute($0, kAXTitleAttribute) as? String == itemTitle
        }) else { return }

        AXUIElementPerformAction(target, kAXPressAction as CFString)
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue(element, name as CFString, &value)
        return value
    }
}
