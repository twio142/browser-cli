# Feature Specification: Browser Tab Access CLI

**Feature Branch**: `001-browser-tab-access`
**Created**: 2026-04-06
**Status**: Draft
**Input**: User description: "List all tabs of a browser (title, url, id, JSON output), get raw HTML source of a tab, Arc browser screenshot for frontmost tab, HTML-to-text article extraction via external tool. Supports Chrome, Safari, Arc."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - List All Open Tabs (Priority: P1)

A user wants to see all currently open tabs across windows in a given browser,
returned as structured JSON so the output can be piped to other tools or scripts.

**Why this priority**: This is the foundational read operation. Every other feature
depends on knowing which tabs exist and being able to reference them by ID.

**Independent Test**: Run the list command against a running browser with at least
two windows and three tabs open. Verify the output is valid JSON containing title,
URL, and ID for every open tab.

**Acceptance Scenarios**:

1. **Given** Chrome is running with 3 tabs across 2 windows, **When** the user runs
   `browser-cli list --browser chrome`, **Then** stdout contains a JSON array with
   3 objects each having `title`, `url`, and `id` fields.
2. **Given** Safari is running with no open tabs, **When** the user runs
   `browser-cli list --browser safari`, **Then** stdout contains an empty JSON array
   and the exit code is 0.
3. **Given** the specified browser is not running, **When** the list command is
   invoked, **Then** the exit code is non-zero and stderr contains a human-readable
   error naming the browser and suggesting the user open it.

---

### User Story 2 - Get Raw HTML Source of a Tab (Priority: P2)

A user wants to retrieve the full HTML source of a specific open tab by its ID,
so they can inspect page content, pass it to other tools, or archive it.

**Why this priority**: Enables the primary "reading" use case. Unlocks article
extraction (P4) as a downstream operation.

**Independent Test**: List tabs, pick a tab ID, run the get-html command with that
ID. Verify stdout contains the raw HTML of that page.

**Acceptance Scenarios**:

1. **Given** a Chrome tab with ID `1:2` is open on a webpage, **When** the user runs
   `browser-cli html --browser chrome --tab 1:2`, **Then** stdout contains the full
   HTML source of that page.
2. **Given** a Safari tab is open, **When** the user runs the html command targeting
   that tab, **Then** stdout contains the page's HTML (static source).
3. **Given** a tab ID that does not exist, **When** the html command is invoked,
   **Then** exit code is non-zero and stderr names the missing tab ID.
4. **Given** the browser requires JavaScript from Apple Events to be enabled and it
   is not, **When** the html command is run against Chrome or Arc, **Then** stderr
   contains a clear message explaining the required permission and how to enable it.

---

### User Story 3 - Capture Screenshot of an Arc Tab (Priority: P3)

A user wants to capture a screenshot of a specific tab in Arc browser. The tab
is activated (brought to focus) first, then Arc's screenshot feature is triggered,
copying the image to the clipboard.

**Why this priority**: Arc-specific capability; does not block other stories and
can be delivered independently.

**Independent Test**: With Arc running and multiple tabs open, run the screenshot
command targeting a background tab. Verify that tab is activated and the clipboard
contains the captured image.

**Acceptance Scenarios**:

1. **Given** Arc is running with tab `1:2` open, **When** the user runs
   `browser-cli screenshot --browser arc --tab 1:2`, **Then** Arc activates that
   tab, captures the full page, and the image is available on the clipboard.
2. **Given** Arc is not running, **When** the screenshot command is invoked, **Then**
   exit code is non-zero and stderr contains a human-readable error.
3. **Given** the `--browser` flag is set to `chrome` or `safari`, **When** the
   screenshot command is invoked, **Then** exit code is non-zero and stderr states
   that screenshot is only supported for Arc.

---

### Edge Cases

- What happens when a browser window has no open tabs?
- What happens if a tab is still loading when HTML is requested? → Error with non-zero exit; user must wait for the tab to finish loading and retry.
- What if two instances of the same browser are running (e.g., Chrome and Chrome Canary)? → `--browser chrome` targets `com.google.Chrome` exclusively; Chrome Canary is only reachable as the system default browser.
- What if a tab title or URL contains non-ASCII characters?

## Clarifications

### Session 2026-04-07

- Q: What should happen when HTML is requested for a tab that is still loading? → A: Return a non-zero error; user must wait for the tab to finish loading and retry.
- Q: Does `--browser chrome` target exactly Google Chrome or all Chromium-based browsers? → A: Exactly `com.google.Chrome`. Other Chromium-based browsers (Canary, Brave, etc.) are only reachable via default browser detection; explicit flag support for them is out of scope for v1.
- Q: What should the screenshot command output on success? → A: If `--output` is specified, read the image from the clipboard via NSPasteboard, write it as PNG to the given path, and print the path to stdout. If `--output` is omitted, the image stays on the clipboard and the CLI prints "Screenshot copied to clipboard."

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The `--browser` flag MUST accept `chrome` (exactly `com.google.Chrome`),
  `safari`, and `arc`. When omitted, the tool MUST detect the system default browser
  by bundle ID and use the appropriate adapter (including for other Chromium-based
  browsers such as Chrome Canary or Brave). If the default browser has no supported
  adapter, the tool MUST error with a clear message. Explicit `--browser` support
  for non-Chrome Chromium browsers is out of scope for v1.
- **FR-002**: The `list` command MUST output a JSON array to stdout where each
  element contains at minimum `id`, `title`, and `url` fields.
- **FR-003**: Tab IDs MUST be usable as input to the `html` and `screenshot`
  commands within the same browser session.
- **FR-004**: The `html` command MUST write the full HTML source of the specified
  tab to stdout.
- **FR-005**: The `screenshot` command MUST be restricted to Arc browser. If `--tab`
  is provided, Arc MUST activate that tab before capturing; otherwise the frontmost
  tab is used. Arc's "Capture Full Page" copies the image to the system clipboard.
  If `--output` is specified, the CLI MUST read the image from the clipboard via
  NSPasteboard, write it as a PNG to the given path, and print that path to stdout.
  If `--output` is omitted, the image stays on the clipboard and the CLI MUST print
  "Screenshot copied to clipboard." to stdout.
- **FR-006**: All error conditions MUST produce a non-zero exit code and a
  human-readable message on stderr that names the browser, describes the failure,
  and where possible suggests a remediation step.
- **FR-007**: When Chrome or Arc HTML retrieval requires a browser permission that
  is not enabled, stderr MUST identify the missing permission and describe how to
  enable it.
- **FR-008**: The `html` command MUST return a non-zero error if the target tab is
  still loading. stderr MUST indicate the tab is not yet loaded and suggest retrying.

### Key Entities

- **Browser**: A supported browser instance (Chrome, Safari, Arc) identified by
  name; has zero or more windows.
- **Window**: A browser window belonging to a Browser; contains one or more tabs.
- **Tab**: An open page within a Window; identified by `id` (window:tab position),
  with `title` and `url` properties.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can retrieve a JSON list of all open tabs in a running browser
  in under 2 seconds on a machine with up to 100 open tabs.
- **SC-002**: A user can retrieve the HTML source of any open tab and pipe it to
  another tool without intermediate files.
- **SC-003**: A user encountering any error can identify the cause and corrective
  action from the stderr message alone, without consulting documentation.
- **SC-004**: The HTML retrieval workflow (list → html) can be composed as a
  single shell pipeline, with output pipeable to any external tool.

## Assumptions

- The tool runs on macOS only; no cross-platform support is in scope.
- At most one instance of each supported browser is running at a time.
- Tab IDs are positional (window index : tab index) and are not guaranteed to be
  stable across separate command invocations.
- For Chrome and Arc HTML retrieval, the user is responsible for enabling
  "Allow JavaScript from Apple Events" in the browser's developer settings.
- For Safari HTML retrieval, static page source is used by default; JS-rendered
  content is out of scope for v1.
- Arc screenshot activates the specified tab (via `--tab`) before capturing, or
  uses the frontmost tab if `--tab` is omitted.
