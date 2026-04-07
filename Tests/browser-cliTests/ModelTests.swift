@testable import BrowserCore
import Foundation
import Testing

struct BrowserNameTests {
    @Test func rawValues() {
        #expect(BrowserName.chrome.rawValue == "chrome")
        #expect(BrowserName.safari.rawValue == "safari")
        #expect(BrowserName.arc.rawValue == "arc")
    }

    @Test func bundleIds() {
        #expect(BrowserName.chrome.bundleId == "com.google.Chrome")
        #expect(BrowserName.safari.bundleId == "com.apple.Safari")
        #expect(BrowserName.arc.bundleId == "company.thebrowser.Browser")
    }

    @Test func initFromBundleId() {
        #expect(BrowserName(bundleId: "com.google.Chrome") == .chrome)
        #expect(BrowserName(bundleId: "com.apple.Safari") == .safari)
        #expect(BrowserName(bundleId: "company.thebrowser.Browser") == .arc)
        #expect(BrowserName(bundleId: "org.mozilla.firefox") == nil)
    }

    @Test func roundTrip() {
        for browser in BrowserName.allCases {
            #expect(BrowserName(bundleId: browser.bundleId) == browser)
            #expect(BrowserName(rawValue: browser.rawValue) == browser)
        }
    }
}

struct TabTests {
    @Test func jsonEncoding() throws {
        let tab = Tab(id: "2:3", title: "Example", url: "https://example.com", active: true)
        let data = try JSONEncoder().encode(tab)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["id"] as? String == "2:3")
        #expect(json["title"] as? String == "Example")
        #expect(json["url"] as? String == "https://example.com")
        #expect(json["active"] as? Bool == true)
    }

    @Test func jsonDecoding() throws {
        let json = #"{"id":"1:2","title":"Test","url":"https://test.com","active":false}"#
        let tab = try JSONDecoder().decode(Tab.self, from: Data(json.utf8))
        #expect(tab.id == "1:2")
        #expect(tab.title == "Test")
        #expect(tab.url == "https://test.com")
        #expect(tab.active == false)
    }

    @Test func description() {
        let active = Tab(id: "1:1", title: "Home", url: "https://example.com", active: true)
        let inactive = Tab(id: "1:2", title: "Other", url: "https://other.com", active: false)
        #expect(active.description.contains("1:1*"))
        #expect(!inactive.description.contains("*"))
    }
}

struct BrowserErrorTests {
    @Test func exitCodes() {
        #expect(BrowserError.browserNotRunning(.chrome).exitCode == 1)
        #expect(BrowserError.tabNotFound("1:1").exitCode == 2)
        #expect(BrowserError.permissionDenied(.chrome, "x").exitCode == 3)
        #expect(BrowserError.screenshotUnsupported(.chrome).exitCode == 4)
        #expect(BrowserError.unsupportedDefaultBrowser("firefox").exitCode == 5)
        #expect(BrowserError.pageNotScriptable.exitCode == 6)
        #expect(BrowserError.tabStillLoading("1:1").exitCode == 7)
        #expect(BrowserError.noActiveTab(.chrome).exitCode == 8)
        #expect(BrowserError.menuItemDisabled("Capture Full Page").exitCode == 9)
    }

    @Test func errorDescriptions() {
        let notRunning = BrowserError.browserNotRunning(.arc)
        #expect(notRunning.errorDescription?.contains("Arc") == true)
        #expect(notRunning.errorDescription?.contains("not running") == true)

        let notFound = BrowserError.tabNotFound("9:9")
        #expect(notFound.errorDescription?.contains("9:9") == true)

        let unsupported = BrowserError.unsupportedDefaultBrowser("firefox")
        #expect(unsupported.errorDescription?.contains("firefox") == true)
        #expect(unsupported.errorDescription?.contains("chrome") == true)

        let stillLoading = BrowserError.tabStillLoading("1:3")
        #expect(stillLoading.errorDescription?.contains("1:3") == true)
        #expect(stillLoading.errorDescription?.contains("loading") == true)

        let noActiveTab = BrowserError.noActiveTab(.safari)
        #expect(noActiveTab.errorDescription?.contains("Safari") == true)
        #expect(noActiveTab.errorDescription?.contains("active tab") == true)

        let menuItemDisabled = BrowserError.menuItemDisabled("Capture Full Page")
        #expect(menuItemDisabled.errorDescription?.contains("Capture Full Page") == true)
        #expect(menuItemDisabled.errorDescription?.contains("not available") == true)
    }
}
