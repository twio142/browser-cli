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

### User Story 3 - Capture Screenshot of Frontmost Arc Tab (Priority: P3)

A user wants to capture a screenshot of the currently active tab in Arc browser
and receive the image as a file.

**Why this priority**: Arc-specific capability; does not block other stories and
can be delivered independently.

**Independent Test**: With Arc running and a tab in the foreground, run the
screenshot command. Verify an image file is produced at the expected path.

**Acceptance Scenarios**:

1. **Given** Arc is running with a tab in the foreground, **When** the user runs
   `browser-cli screenshot --browser arc`, **Then** a PNG file is written to the
   path specified by `--output` (defaulting to a timestamped filename in the
   current directory).
2. **Given** Arc is not running, **When** the screenshot command is invoked, **Then**
   exit code is non-zero and stderr contains a human-readable error.
3. **Given** the `--browser` flag is set to `chrome` or `safari`, **When** the
   screenshot command is invoked, **Then** exit code is non-zero and stderr states
   that screenshot is only supported for Arc.

---

### User Story 4 - Extract Article Text from a Tab (Priority: P4)

A user wants to extract the readable article body from a tab, stripping navigation,
ads, and boilerplate, receiving clean text output.

**Why this priority**: A convenience layer on top of HTML retrieval (P2). Requires
an external extraction tool to be installed.

**Independent Test**: Run the extract command on a tab showing a news article.
Verify the output contains the article body text and is free of navigation markup.

**Acceptance Scenarios**:

1. **Given** a tab is open on an article page, **When** the user runs
   `browser-cli extract --browser chrome --tab 1:2`, **Then** stdout contains the
   article body as clean text with boilerplate removed.
2. **Given** the required extraction tool is not installed, **When** the extract
   command is run, **Then** exit code is non-zero and stderr names the missing tool
   and explains how to install it.
3. **Given** the page has no identifiable article body, **When** the extract command
   is run, **Then** the tool returns best-effort text content and exits with code 0,
   optionally warning on stderr.

---

### Edge Cases

- What happens when a browser window has no open tabs?
- What happens if a tab is still loading when HTML is requested?
- What if two instances of the same browser are running (e.g., Chrome and Chrome Canary)?
- What if a tab title or URL contains non-ASCII characters?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The tool MUST support a `--browser` flag accepting `chrome`, `safari`,
  and `arc` as values.
- **FR-002**: The `list` command MUST output a JSON array to stdout where each
  element contains at minimum `id`, `title`, and `url` fields.
- **FR-003**: Tab IDs MUST be usable as input to the `html` and `extract` commands
  within the same browser session.
- **FR-004**: The `html` command MUST write the full HTML source of the specified
  tab to stdout.
- **FR-005**: The `screenshot` command MUST be restricted to Arc browser and MUST
  write a PNG image to the path specified by `--output`, defaulting to a
  timestamped filename in the current directory.
- **FR-006**: The `extract` command MUST pipe the tab's HTML through an external
  article extraction tool and write the result to stdout.
- **FR-007**: All error conditions MUST produce a non-zero exit code and a
  human-readable message on stderr that names the browser, describes the failure,
  and where possible suggests a remediation step.
- **FR-008**: When Chrome or Arc HTML retrieval requires a browser permission that
  is not enabled, stderr MUST identify the missing permission and describe how to
  enable it.

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
- **SC-004**: The article extraction workflow (list → html → extract) can be
  composed as a single shell pipeline.

## Assumptions

- The tool runs on macOS only; no cross-platform support is in scope.
- At most one instance of each supported browser is running at a time.
- Tab IDs are positional (window index : tab index) and are not guaranteed to be
  stable across separate command invocations.
- For Chrome and Arc HTML retrieval, the user is responsible for enabling
  "Allow JavaScript from Apple Events" in the browser's developer settings.
- For Safari HTML retrieval, static page source is used by default; JS-rendered
  content is out of scope for v1.
- The article extraction tool is a separately installed external binary; the CLI
  will document which tool is expected but will not bundle or install it.
- Arc screenshot captures the frontmost tab only; targeting a background tab by
  ID is out of scope for v1.
