# Implementation Plan: Browser Tab Access CLI

**Branch**: `001-browser-tab-access` | **Date**: 2026-04-06 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-browser-tab-access/spec.md`

## Summary

Build a macOS Swift CLI tool that exposes four commands (list, html, screenshot,
extract) for accessing browser tab data from Chrome, Safari, and Arc. Tab metadata
is retrieved via ScriptingBridge; HTML retrieval uses OSAKit (in-process JXA);
Arc screenshot uses the AXUIElement Accessibility API; article extraction pipes
HTML through a user-installed external tool.

## Technical Context

**Language/Version**: Swift 5.9+ (Xcode 15+)
**Primary Dependencies**: ScriptingBridge (system), OSAKit (system),
  ApplicationServices/AXUIElement (system), swift-argument-parser (statically
  linked build dep — no runtime footprint)
**Storage**: N/A
**Testing**: XCTest (Swift Package Manager test target)
**Target Platform**: macOS 12.0+
**Project Type**: CLI tool (Swift Package Manager executable)
**Performance Goals**: Tab listing completes in under 2 seconds for up to 100 open tabs
**Constraints**: No runtime dependencies beyond macOS system frameworks; binary
  must be runnable without installation of any runtime
**Scale/Scope**: Single user, personal use; one browser instance at a time

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Layered macOS-Native Automation | ✅ | ScriptingBridge for list, OSAKit for html, AXUIElement for screenshot — each layer used for its designated purpose |
| II. Uniform Browser Adapter Interface | ✅ | `BrowserAdapter` protocol; Chrome/Safari/Arc each have a dedicated adapter; no browser-specific branching in command layer |
| III. CLI-First Interface | ✅ | Swift CLI binary; `list` outputs JSON by default; all output to stdout/stderr |
| IV. Graceful Degradation & Clear Errors | ✅ | `BrowserError` enum maps to non-zero exit codes and actionable stderr messages |
| V. Simplicity & Minimal Footprint | ✅ | `swift-argument-parser` is statically linked (zero runtime footprint); no servers, no daemons |

**Post-Phase-1 re-check**: No violations introduced by design. `swift-argument-parser`
is a build-time dependency only — the compiled binary has no external runtime
dependencies, satisfying Principle V.

## Project Structure

### Documentation (this feature)

```text
specs/001-browser-tab-access/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── list.md
│   ├── html.md
│   ├── screenshot.md
│   └── extract.md
└── tasks.md             # Phase 2 output (/speckit.tasks — NOT created here)
```

### Source Code (repository root)

```text
Package.swift

Sources/
└── browser-cli/
    ├── main.swift                    # Entry point; ArgumentParser root command
    ├── Commands/
    │   ├── ListCommand.swift         # `browser-cli list`
    │   ├── HTMLCommand.swift         # `browser-cli html`
    │   ├── ScreenshotCommand.swift   # `browser-cli screenshot`
    │   └── ExtractCommand.swift      # `browser-cli extract`
    ├── Adapters/
    │   ├── BrowserAdapter.swift      # Protocol: listTabs(), getHTML(tab:), screenshot()
    │   ├── ChromeAdapter.swift       # ScriptingBridge + OSAKit
    │   ├── SafariAdapter.swift       # ScriptingBridge + source property via OSAKit
    │   └── ArcAdapter.swift          # ScriptingBridge + OSAKit + AXUIElement
    ├── Automation/
    │   ├── ScriptingBridgeClient.swift   # SBApplication wrapper, dynamic selectors
    │   ├── JXAClient.swift               # OSAScript wrapper for in-process JXA
    │   └── AccessibilityClient.swift     # AXUIElement helpers
    └── Models/
        ├── Tab.swift                 # Tab struct: id, title, url
        ├── BrowserName.swift         # Enum: chrome, safari, arc
        └── BrowserError.swift        # Error enum with exit codes + stderr messages

Tests/
└── browser-cliTests/
    ├── ChromeAdapterTests.swift
    ├── SafariAdapterTests.swift
    └── ArcAdapterTests.swift
```

**Structure Decision**: Single Swift Package Manager executable target. No libraries,
no sub-packages — the scope does not justify splitting. Tests live in a separate
test target within the same package.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations. Table omitted.
