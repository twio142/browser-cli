# browser-cli Development Guidelines

Last updated: 2026-04-07

## Active Technologies

- Swift 6.0 (swift-tools-version:6.0, macOS 12+)
- ScriptingBridge (system) — KVC-based, no generated headers
- OSAKit (system) — in-process JXA execution
- ApplicationServices/AXUIElement (system) — Arc screenshot
- swift-argument-parser 1.3+
- swift-testing 6.0

## Project Structure

```text
Sources/BrowserCore/        # Library: all logic, importable by tests
  Adapters/                 # BrowserAdapter protocol + Chrome/Safari/Arc adapters
  Automation/               # ScriptingBridgeClient, JXAClient, AccessibilityClient
  Commands/                 # ListCommand, HTMLCommand, ScreenshotCommand
  Models/                   # Tab, BrowserName, BrowserError
  BrowserCLI.swift          # Root ParsableCommand (public)
  Utilities.swift

Sources/browser-cli/        # Thin executable: main.swift only
  main.swift                # import BrowserCore; BrowserCLI.main()
  Info.plist                # Embedded via -sectcreate (AppleEvents + AX usage descriptions)

Tests/browser-cliTests/     # @testable import BrowserCore
  ModelTests.swift
  IntegrationTests.swift
```

## Commands

```bash
swift build -c release      # always build release, not debug
swift test
```

## Code Style

- Swift 6.0 — follow standard conventions
- Use `swift-testing` for all tests, no XCTest
- Release-only builds

## Key Implementation Details

- Arc active tab: compare `tab.value(forKey: "id")` (UUID string) with `window.value(forKeyPath: "activeTab.id")` — `value(forKey: "activeTab")` returns an opaque SB proxy; `forKeyPath` resolves through the scripting engine
- Safari active tab: compare `currentTab.value(forKey: "index")` with tab index
- Chrome active tab: `tab.value(forKey: "active")` boolean
- HTML retrieval: in-process JXA via OSAKit (no `osascript` subprocess)
- Screenshot: AXUIElement `File → Capture Full Page` menu click

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
