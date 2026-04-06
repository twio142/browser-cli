import ArgumentParser
import Foundation

public struct BrowserCLI: ParsableCommand {
    public init() {}
    public static let configuration = CommandConfiguration(
        commandName: "browser-cli",
        abstract: "Access browser tab data from Chrome, Safari, and Arc.",
        subcommands: [ListCommand.self, HTMLCommand.self, ScreenshotCommand.self]
    )
}
