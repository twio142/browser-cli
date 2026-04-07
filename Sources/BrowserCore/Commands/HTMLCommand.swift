import ArgumentParser
import Foundation

struct HTMLCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "html",
        abstract: "Get raw HTML source of a tab. Defaults to the active tab."
    )

    @Option(name: .long, help: "Browser to use: chrome, safari, or arc. Defaults to system default browser.")
    var browser: String?

    @Option(name: .long, help: "Tab ID in \"<windowIndex>:<tabIndex>\" format (see 'list'). Defaults to active tab.")
    var tab: String?

    func run() throws {
        let browserName = try parseBrowserName(browser)

        let adapter: any BrowserAdapter
        do {
            adapter = try resolveAdapter(name: browserName)
        } catch let error as BrowserError {
            writeStderr(error.errorDescription ?? error.localizedDescription)
            throw ExitCode(Int32(error.exitCode))
        }

        let html: String
        do {
            html = try adapter.getHTML(tabId: tab)
        } catch let error as BrowserError {
            writeStderr(error.errorDescription ?? error.localizedDescription)
            throw ExitCode(Int32(error.exitCode))
        }

        print(html)
    }

    private func parseBrowserName(_ name: String?) throws -> BrowserName? {
        guard let name = name else { return nil }
        guard let browserName = BrowserName(rawValue: name) else {
            writeStderr("Error: Unknown browser \"\(name)\". Use chrome, safari, or arc.")
            throw ExitCode(1)
        }
        return browserName
    }
}
