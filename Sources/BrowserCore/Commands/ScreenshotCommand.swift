import ArgumentParser
import AppKit
import Foundation

struct ScreenshotCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screenshot",
        abstract: "Capture a full-page screenshot in Arc (copies to clipboard or saves to file)."
    )

    @Option(name: .long, help: "Browser to use. Only 'arc' is supported.")
    var browser: String?

    @Option(name: .long, help: "Tab ID in \"<windowIndex>:<tabIndex>\" format. Activates this tab before capture.")
    var tab: String?

    @Option(name: .long, help: "Output path for the PNG file. If omitted, screenshot stays in clipboard.")
    var output: String?

    func run() throws {
        let browserName = try parseBrowserName(browser)

        guard browserName == nil || browserName == .arc else {
            writeStderr(BrowserError.screenshotUnsupported(browserName!).errorDescription ?? "")
            throw ExitCode(4)
        }

        let adapter: any BrowserAdapter
        do {
            adapter = try resolveAdapter(name: .arc)
        } catch let error as BrowserError {
            writeStderr(error.errorDescription ?? error.localizedDescription)
            throw ExitCode(Int32(error.exitCode))
        }

        do {
            try adapter.screenshot(tabId: tab)
        } catch let error as BrowserError {
            writeStderr(error.errorDescription ?? error.localizedDescription)
            throw ExitCode(Int32(error.exitCode))
        }

        if let outputPath = output {
            Thread.sleep(forTimeInterval: 0.5)

            guard let tiffData = NSPasteboard.general.data(forType: .tiff) else {
                writeStderr("Error: No image found in clipboard after screenshot.")
                throw ExitCode(1)
            }

            guard let imageRep = NSBitmapImageRep(data: tiffData),
                  let pngData = imageRep.representation(using: .png, properties: [:]) else {
                writeStderr("Error: Failed to convert clipboard image to PNG.")
                throw ExitCode(1)
            }

            let url = URL(fileURLWithPath: outputPath)
            do {
                try pngData.write(to: url)
            } catch {
                writeStderr("Error: Failed to write PNG to \(outputPath): \(error.localizedDescription)")
                throw ExitCode(1)
            }

            print(outputPath)
        } else {
            print("Screenshot copied to clipboard.")
        }
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
