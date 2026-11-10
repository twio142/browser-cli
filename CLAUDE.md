# browser-cli Development Guidelines

Last updated: 2026-11-10

## Active Technologies

- Swift 6.0 (swift-tools-version:6.0, macOS 12+)
- ScriptingBridge (system) — KVC-based browser automation
- OSAKit (system) — in-process JXA execution
- ApplicationServices/AXUIElement (system) — accessibility-based automation
- swift-argument-parser 1.3+
- Swift Testing (built into the toolchain, no package dependency)

## Project Structure

```text
Sources/BrowserCore/        # Library: all logic, importable by tests
  Adapters/                 # BrowserAdapter protocol + per-browser implementations
  Automation/               # Low-level clients (ScriptingBridge, JXA, Accessibility)
  Commands/                 # One file per CLI subcommand
  Models/                   # Value types and error definitions
  BrowserCLI.swift          # Root ParsableCommand (public)
  Utilities.swift

Sources/browser-cli/        # Thin executable: main.swift only
  main.swift                # import BrowserCore; BrowserCLI.main()
  Info.plist                # Embedded via -sectcreate (AppleEvents + AX usage descriptions)

Tests/browser-cliTests/     # @testable import BrowserCore
  ModelTests.swift          # Pure unit tests, no browser required
  IntegrationTests.swift    # Live adapter tests, skipped when browser not running
```

## Commands

```bash
swift build -c release      # always build release, not debug

# With only the Command Line Tools (no Xcode), the Swift Testing macro plugin must be passed by hand:
swift test -Xswiftc -plugin-path -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing
```

## Code Style

- Swift 6.0 — follow standard conventions
- Use Swift Testing (`import Testing`) for all tests, no XCTest
- Release-only builds

## Architecture

Each browser is implemented as an adapter conforming to `BrowserAdapter`. Adding a new subcommand means: add the method to the protocol, implement it in each adapter, create a `*Command.swift`, and register it in `BrowserCLI.swift`.

The automation layer is split by mechanism: ScriptingBridge for metadata (tabs, titles, URLs), JXA via OSAKit for JavaScript execution, and AXUIElement for UI interactions. Prefer reading the source over relying on notes here — implementation details live in the code and its comments.
