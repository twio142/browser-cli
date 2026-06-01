import ArgumentParser
import Foundation

struct SelectionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "selection",
        abstract: "Get selected text in the active tab, with title and URL. Outputs JSON."
    )

    @Option(name: .long, help: "Browser to use: chrome, safari, or arc. Defaults to system default browser.")
    var browser: String?

    func run() throws {
        let browserName = try parseBrowserName(browser)

        let adapter: any BrowserAdapter
        do {
            adapter = try resolveAdapter(name: browserName)
        } catch let error as BrowserError {
            writeStderr(error.errorDescription ?? error.localizedDescription)
            throw ExitCode(Int32(error.exitCode))
        }

        let result: SelectionResult
        do {
            result = try adapter.getSelection()
        } catch let error as BrowserError {
            writeStderr(error.errorDescription ?? error.localizedDescription)
            throw ExitCode(Int32(error.exitCode))
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(result)
        print(String(data: data, encoding: .utf8) ?? "{}")
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
