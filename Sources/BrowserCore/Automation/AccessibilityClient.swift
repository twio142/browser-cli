import ApplicationServices
import Foundation

struct AccessibilityClient {
    /// Returns the menu bar AXUIElement for the application with the given PID.
    func menuBarElement(for pid: pid_t) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &value) == .success,
              let ref = value else {
            return nil
        }
        return unsafeDowncast(ref, to: AXUIElement.self)
    }

    /// Clicks the menu item at `menuTitle > itemTitle` in the given app element's menu bar.
    /// Throws `BrowserError.permissionDenied` if Accessibility access is not granted.
    /// Throws `BrowserError.menuItemDisabled` if the item is not found or is disabled.
    func clickMenuItem(app appElement: AXUIElement, menuTitle: String, itemTitle: String) throws {
        guard AXIsProcessTrusted() else {
            throw BrowserError.permissionDenied(.arc, "Accessibility")
        }

        var menuBarRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBarRef) == .success,
              let ref = menuBarRef else {
            throw BrowserError.permissionDenied(.arc, "Accessibility")
        }
        let menuBar = unsafeDowncast(ref, to: AXUIElement.self)

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
        }) else {
            throw BrowserError.menuItemDisabled(itemTitle)
        }

        let enabled = attribute(target, kAXEnabledAttribute) as? Bool ?? false
        guard enabled else {
            throw BrowserError.menuItemDisabled(itemTitle)
        }

        AXUIElementPerformAction(target, kAXPressAction as CFString)
    }

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        AXUIElementCopyAttributeValue(element, name as CFString, &value)
        return value
    }
}
