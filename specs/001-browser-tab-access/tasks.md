---

description: "Task list for browser-cli browser tab access"
---

# Tasks: Browser Tab Access CLI

**Input**: Design documents from `/specs/001-browser-tab-access/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Not requested — no test tasks generated.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story this task belongs to (US1, US2, US3)
- Exact file paths included in all descriptions

## Path Conventions

- Swift Package Manager executable target: `Sources/browser-cli/`
- Tests: `Tests/browser-cliTests/`

---

## Phase 1: Setup

**Purpose**: Swift Package Manager project initialization and structure.

- [X] T001 Create `Package.swift` with executable target `browser-cli`, test target `browser-cliTests`, and dependency on `swift-argument-parser` 1.3.x
- [X] T002 [P] Create directory structure: `Sources/browser-cli/Commands/`, `Sources/browser-cli/Adapters/`, `Sources/browser-cli/Automation/`, `Sources/browser-cli/Models/`
- [X] T003 [P] Create `Tests/browser-cliTests/` directory and placeholder test file `Tests/browser-cliTests/PlaceholderTests.swift`
- [X] T004 [P] Create `.gitignore` ignoring `.build/`, `*.xcodeproj`, `*.xcworkspace`, `DerivedData/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core models, error types, automation clients, and CLI entry point that all user stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T00 [P] Create `Sources/browser-cli/Models/BrowserName.swift` — `BrowserName` enum with cases `chrome`, `safari`, `arc`; each case has a `bundleId: String` property (`com.google.Chrome`, `com.apple.Safari`, `company.thebrowser.Browser`); add static `init?(bundleId:)` for default browser detection
- [X] T00 [P] Create `Sources/browser-cli/Models/Tab.swift` — `Tab` struct with `id: String`, `title: String`, `url: String`; implement `Codable` and `CustomStringConvertible`; document ID format `"<windowIndex>:<tabIndex>"` (1-based)
- [X] T00 [P] Create `Sources/browser-cli/Models/BrowserError.swift` — `BrowserError` enum conforming to `Error` and `LocalizedError`; cases: `browserNotRunning(BrowserName)`, `tabNotFound(String)`, `permissionDenied(BrowserName, String)`, `screenshotUnsupported(BrowserName)`, `unsupportedDefaultBrowser(String)`, `arcReturnedNoValue`, `tabStillLoading(String)`; each case MUST have `errorDescription` with actionable stderr message per data-model.md
- [X] T00 Create `Sources/browser-cli/Automation/ScriptingBridgeClient.swift` — `ScriptingBridgeClient` class; `connect(bundleId:) -> SBApplication?`; `performSelector<T>(on:name:default:) -> T` dynamic selector helper mirroring alfred-switch-windows pattern; `listTabs(app:) -> [(windowIndex: Int, tabIndex: Int, raw: AnyObject)]`; `activateTab(app:windowIndex:tabIndex:)` to bring tab to foreground
- [X] T00 Create `Sources/browser-cli/Automation/JXAClient.swift` — `JXAClient` struct; `execute(script:) throws -> String` using `OSAScript` from OSAKit for in-process JXA execution; throws `BrowserError.arcReturnedNoValue` if result is empty/missing
- [X] T01 Create `Sources/browser-cli/Automation/AccessibilityClient.swift` — `AccessibilityClient` struct; `menuBarElement(for pid: pid_t) -> AXUIElement?`; `clickMenuItem(app: AXUIElement, menuTitle: String, itemTitle: String) throws` — walks AXUIElement tree matching on `kAXTitleAttribute`, calls `AXUIElementPerformAction(element, kAXPressAction as CFString)`
- [X] T01 Create `Sources/browser-cli/Adapters/BrowserAdapter.swift` — `BrowserAdapter` protocol with methods: `listTabs() throws -> [Tab]`; `getHTML(tabId: String) throws -> String`; and optional `screenshot(tabId: String?) throws` for Arc only; add `resolve(name: BrowserName?) throws -> any BrowserAdapter` factory function that detects system default via `NSWorkspace.shared.urlForApplication(toOpen:)`
- [X] T01 Create `Sources/browser-cli/main.swift` — `BrowserCLI` root `ParsableCommand` using `swift-argument-parser`; register subcommands `ListCommand`, `HTMLCommand`, `ScreenshotCommand`; top-level error handler that writes `BrowserError.errorDescription` to stderr and calls `exit(1)`

**Checkpoint**: Foundation ready — all user story phases can begin.

---

## Phase 3: User Story 1 - List All Open Tabs (Priority: P1) 🎯 MVP

**Goal**: `browser-cli list [--browser <name>]` outputs a JSON array of all open tabs.

**Independent Test**: Run `browser-cli list --browser chrome` with Chrome open; verify stdout is valid JSON with `id`, `title`, `url` per tab. Run without `--browser` with a supported default browser; verify same output.

### Implementation for User Story 1

- [X] T01 [P] [US1] Create `Sources/browser-cli/Adapters/ChromeAdapter.swift` — `ChromeAdapter` conforming to `BrowserAdapter`; `listTabs()` connects via `ScriptingBridgeClient.connect(bundleId: BrowserName.chrome.bundleId)`, enumerates windows/tabs via `performSelector`, returns `[Tab]` with `id` as `"<windowIndex>:<tabIndex>"`; title via `title` selector; URL via `URL` selector; throws `browserNotRunning` if connection fails
- [X] T01 [P] [US1] Create `Sources/browser-cli/Adapters/SafariAdapter.swift` — `SafariAdapter` conforming to `BrowserAdapter`; `listTabs()` same pattern as ChromeAdapter but uses `name` selector for title; `getHTML` uses `source` selector via ScriptingBridge (no JXA needed for Safari)
- [X] T01 [P] [US1] Create `Sources/browser-cli/Adapters/ArcAdapter.swift` — `ArcAdapter` conforming to `BrowserAdapter`; `listTabs()` uses bundle ID `company.thebrowser.Browser`; title via `title` selector; stub out `getHTML` and `screenshot` (to be filled in US2/US3)
- [X] T01 [US1] Create `Sources/browser-cli/Commands/ListCommand.swift` — `ListCommand: ParsableCommand`; `--browser` optional `String?` flag; resolve adapter via `BrowserAdapter.resolve(name:)`; call `listTabs()`; encode result as JSON with `JSONEncoder` (outputFormatting: `.prettyPrinted`); write to stdout; catch `BrowserError` and exit non-zero with stderr message

**Checkpoint**: `browser-cli list` fully functional across Chrome, Safari, Arc, and system default.

---

## Phase 4: User Story 2 - Get Raw HTML Source (Priority: P2)

**Goal**: `browser-cli html --tab <id> [--browser <name>]` writes raw HTML to stdout.

**Independent Test**: List tabs, take an ID, run `browser-cli html --tab 1:1 --browser chrome`; verify stdout contains `<!DOCTYPE html>` or `<html`. Run against a still-loading tab; verify non-zero exit and stderr message.

### Implementation for User Story 2

- [X] T01 [US2] Implement `getHTML(tabId:)` in `Sources/browser-cli/Adapters/ChromeAdapter.swift` — parse `tabId` into `(windowIndex, tabIndex)`; check tab exists via ScriptingBridgeClient (throw `tabNotFound` if not); build JXA script `Application('Google Chrome').windows[windowIndex-1].tabs[tabIndex-1].execute({javascript: 'document.readyState'})` via `JXAClient`; throw `tabStillLoading` if result is not `"complete"`; execute `document.documentElement.outerHTML` and return result; throw `permissionDenied` if OSAKit returns an Apple Events permission error
- [X] T01 [US2] Implement `getHTML(tabId:)` in `Sources/browser-cli/Adapters/ArcAdapter.swift` — same pattern as ChromeAdapter but with `Application('Arc')` in JXA scripts; throw `arcReturnedNoValue` if JXA result is empty
- [X] T01 [US2] Implement `getHTML(tabId:)` in `Sources/browser-cli/Adapters/SafariAdapter.swift` — parse tabId; retrieve `source` property via ScriptingBridge `performSelector(on:name:"source":default:"")` on the tab object; throw `tabNotFound` if empty and tab doesn't exist; no JXA required
- [X] T02 [US2] Create `Sources/browser-cli/Commands/HTMLCommand.swift` — `HTMLCommand: ParsableCommand`; `--browser` optional `String?`; `--tab` required `String`; resolve adapter; call `getHTML(tabId:)`; write raw string to stdout; catch `BrowserError` → stderr + non-zero exit

**Checkpoint**: `browser-cli html --tab <id>` works for Chrome, Safari, Arc.

---

## Phase 5: User Story 3 - Arc Screenshot (Priority: P3)

**Goal**: `browser-cli screenshot [--tab <id>] [--output <path>]` triggers Arc's Capture Full Page, optionally saving clipboard PNG to a file.

**Independent Test**: With Arc open, run `browser-cli screenshot --browser arc`; verify exit 0 and "Screenshot copied to clipboard." on stdout. Run with `--output /tmp/test.png`; verify file exists and is a valid PNG.

### Implementation for User Story 3

- [X] T02 [US3] Implement `screenshot(tabId:)` in `Sources/browser-cli/Adapters/ArcAdapter.swift` — if `tabId` provided: parse into `(windowIndex, tabIndex)`, call `ScriptingBridgeClient.activateTab(app:windowIndex:tabIndex:)` to bring tab to front; call `NSRunningApplication` with Arc bundle ID to `activate()`; call `AccessibilityClient.clickMenuItem(app:menuTitle:"File" itemTitle:"Capture Full Page")`; throws `permissionDenied` if AX permission absent
- [X] T02 [US3] Create `Sources/browser-cli/Commands/ScreenshotCommand.swift` — `ScreenshotCommand: ParsableCommand`; `--browser` optional `String?`; `--tab` optional `String?`; `--output` optional `String?`; validate browser is arc (throw `screenshotUnsupported` otherwise); call `adapter.screenshot(tabId:)`; if `--output` provided: `Thread.sleep(forTimeInterval: 0.5)`, read `NSPasteboard.general.data(forType: .tiff)`, convert via `NSBitmapImageRep` to PNG, write to output path, print path to stdout; else print "Screenshot copied to clipboard."

**Checkpoint**: All three user stories independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Wire up default browser resolution, error handling consistency, and build validation.

- [X] T02 Implement `BrowserAdapter.resolve(name:)` in `Sources/browser-cli/Adapters/BrowserAdapter.swift` — call `NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://")!)` to get default browser app URL; extract bundle ID; attempt `BrowserName(bundleId:)`; if recognized, return appropriate adapter; if unrecognized, throw `unsupportedDefaultBrowser(detectedName)`
- [X] T02 [P] Add `tabStillLoading` case to `Sources/browser-cli/Models/BrowserError.swift` with message: `"Tab <id> is still loading. Wait for it to finish and retry."`
- [X] T02 [P] Validate `Package.swift` builds cleanly with `swift build -c release` and binary is produced at `.build/release/browser-cli`
- [X] T02 [P] Run quickstart.md validation: execute each example command from `specs/001-browser-tab-access/quickstart.md` manually and confirm expected output

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately; all T001-T004 parallel
- **Foundational (Phase 2)**: Depends on Phase 1 — T005-T007 parallel; T008-T010 parallel after T005; T011 after T008-T010; T012 after T011
- **US1 (Phase 3)**: Depends on Foundational — T013-T015 parallel; T016 after T013-T015
- **US2 (Phase 4)**: Depends on Foundational — T017-T019 parallel; T020 after T017-T019
- **US3 (Phase 5)**: Depends on Foundational + T015 (ArcAdapter stub) — T021 after T015; T022 after T021
- **Polish (Phase 6)**: T023 depends on T011; T024 depends on T007; T025/T026 depend on all phases complete

### Within Each User Story

- Adapter implementations (T013-T015, T017-T019) are independent of each other — run in parallel
- Command implementations (T016, T020, T022) depend on their adapters

### Parallel Opportunities

```bash
# Phase 1 — all parallel:
T001, T002, T003, T004

# Phase 2 — parallel groups:
T005, T006, T007          # models (no deps)
T008, T009, T010          # automation clients (after T005)
T011                      # adapter protocol (after T008-T010)
T012                      # entry point (after T011)

# Phase 3 (US1) — parallel adapters:
T013, T014, T015          # ChromeAdapter, SafariAdapter, ArcAdapter stubs
T016                      # ListCommand (after T013-T015)

# Phase 4 (US2) — parallel HTML implementations:
T017, T018, T019          # getHTML for Chrome, Arc, Safari
T020                      # HTMLCommand (after T017-T019)
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (list tabs)
4. **STOP and validate**: `browser-cli list --browser chrome` works end-to-end
5. Continue to US2 and US3

### Incremental Delivery

1. Setup + Foundational → skeleton compiles
2. US1 → `list` works → validate
3. US2 → `html` works → validate
4. US3 → `screenshot` works → validate
5. Polish → default browser, build validation

---

## Notes

- `[P]` = parallelizable (different files, no shared state)
- `[USn]` maps task to user story for traceability
- T023 (default browser resolution) is in Polish because all three adapters must exist first
- No test tasks generated (not requested)
- ScriptingBridge requires `Info.plist` with `NSAppleEventsUsageDescription`; AXUIElement requires `NSAccessibilityUsageDescription` — add both in T001 Package.swift or a companion entitlements file
