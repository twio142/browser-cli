import AppKit
@testable import BrowserCore
import Testing

private func arcIsRunning() -> Bool {
    !NSRunningApplication.runningApplications(withBundleIdentifier: BrowserName.arc.bundleId).isEmpty
}

@Suite(.enabled(if: arcIsRunning()))
struct ArcAdapterTests {
    @Test func listTabsReturnsNonEmpty() throws {
        let tabs = try ArcAdapter().listTabs()
        #expect(!tabs.isEmpty)
    }

    @Test func exactlyOneActiveTabPerWindow() throws {
        let tabs = try ArcAdapter().listTabs()
        let byWindow = Dictionary(grouping: tabs, by: { $0.id.prefix(while: { $0 != ":" }) })
        for (_, windowTabs) in byWindow {
            let activeCount = windowTabs.filter(\.active).count
            #expect(activeCount == 1)
        }
    }

    @Test func tabIdsAreWellFormed() throws {
        let tabs = try ArcAdapter().listTabs()
        for tab in tabs {
            let parts = tab.id.split(separator: ":").compactMap { Int($0) }
            #expect(parts.count == 2)
            #expect(parts[0] >= 1)
            #expect(parts[1] >= 1)
        }
    }

    @Test func tabNotFoundThrowsCorrectError() throws {
        #expect(throws: BrowserError.self) {
            _ = try ArcAdapter().getHTML(tabId: "99:99")
        }
    }
}

struct ResolveAdapterTests {
    @Test func knownBrowserNamesResolve() throws {
        let chrome = try resolveAdapter(name: .chrome)
        let safari = try resolveAdapter(name: .safari)
        let arc = try resolveAdapter(name: .arc)
        #expect(chrome is ChromeAdapter)
        #expect(safari is SafariAdapter)
        #expect(arc is ArcAdapter)
    }
}
