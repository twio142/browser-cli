<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0
Modified principles:
  - I. JXA-First Automation → I. Layered macOS-Native Automation
    (Redefined to reflect confirmed three-layer automation stack:
     ScriptingBridge for tab metadata, OSAKit/JXA for JS execution,
     AXUIElement for UI-level interactions)
Added sections: N/A
Removed sections: N/A
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (Constitution Check gates still align)
  - .specify/templates/spec-template.md ✅ (no structural changes required)
  - .specify/templates/tasks-template.md ✅ (task phases consistent with principles)
Follow-up TODOs: None — all placeholders resolved.
-->

# browser-cli Constitution

## Core Principles

### I. Layered macOS-Native Automation

Browser automation MUST use the most appropriate macOS-native layer for each
operation. The three permitted layers, in order of preference, are:

- **ScriptingBridge** — MUST be used for tab metadata operations (listing tabs,
  reading title/URL/ID). It is in-process, typed, and requires no scripting runtime.
- **OSAKit (in-process JXA)** — MUST be used when JavaScript execution in a
  browser tab is required (e.g., HTML retrieval). JXA scripts run via `OSAScript`
  inside the process; no `osascript` subprocess is spawned.
- **AXUIElement (Accessibility API)** — MUST be used for UI-level interactions
  that have no ScriptingBridge equivalent (e.g., triggering Arc's screenshot menu
  item).

No layer MAY substitute for another without explicit justification recorded in
the Complexity Tracking table of the relevant plan. CDP, Playwright, Puppeteer,
Selenium, and `osascript` subprocesses are NOT permitted.

**Rationale**: Each layer has a distinct cost/capability profile. ScriptingBridge
is the lightest and most reliable for metadata. OSAKit keeps JXA in-process.
AXUIElement covers UI gaps that scripting APIs do not expose. Using the right
layer for each job keeps the tool lean and dependency-free.

### II. Uniform Browser Adapter Interface

Every supported browser (Chrome, Safari, Arc) MUST implement the same adapter
contract. Callers MUST NOT contain browser-specific branching logic; all
browser differences are encapsulated inside the adapter for that browser.
New browser support MUST be added as a new adapter, never as conditionals in
shared code.

**Rationale**: Ensures that adding or removing a browser never breaks existing
callers, and that the CLI surface remains consistent regardless of which browser
is targeted.

### III. CLI-First Interface (NON-NEGOTIABLE)

The tool MUST expose all functionality exclusively through a CLI.
Input MUST come from command-line arguments or stdin.
Normal output MUST go to stdout.
Errors and diagnostics MUST go to stderr.
The `list` command MUST output JSON by default. Other commands MAY support a
`--json` flag where structured output is useful.

**Rationale**: CLI-first design ensures scriptability, pipeline composability,
and zero-GUI dependencies. JSON output allows downstream tools to consume
browser data programmatically.

### IV. Graceful Degradation & Clear Errors

When a target browser is not running, a requested tab does not exist, or a
required permission is not granted, the tool MUST:
- Exit with a non-zero status code.
- Emit a human-readable error message to stderr that names the browser,
  describes the failure, and suggests a remediation step where possible.
- Never silently return empty output for an error condition.

**Rationale**: CLI tools are often used in scripts. Silent failures cause
hard-to-debug downstream errors. Explicit, actionable error messages reduce
friction for users and scripts alike.

### V. Simplicity & Minimal Footprint

The tool MUST NOT introduce runtime dependencies beyond the macOS system
frameworks required for automation (ScriptingBridge, OSAKit, ApplicationServices)
and Swift's standard library. No web servers, no daemons, no persistent
background processes. YAGNI applies: functionality is added only when there is
a concrete use case, not speculatively.

**Rationale**: A CLI tab-access tool should run offline and leave no residual
state. The only permitted external dependency is the article extraction tool,
which is user-installed and invoked as a subprocess.

## Platform & Compatibility

- **Target OS**: macOS only. ScriptingBridge, OSAKit, and AXUIElement are
  macOS-exclusive; no cross-platform support is planned or implied.
- **Language**: Swift. No other implementation language is permitted.
- **Supported browsers**: Google Chrome, Safari, Arc. Each MUST have its own
  adapter. Browser support MAY be extended via new adapters without modifying
  existing ones.
- **Permissions**: The tool MUST document all macOS permission grants required
  per browser (Automation, Accessibility, Apple Events) and surface a clear,
  actionable error when any required permission is absent.

## Development Workflow

- Every new browser adapter MUST include at minimum one integration test that
  verifies the adapter can list tabs when the browser is running.
- Breaking changes to the CLI argument surface (flag names, output schema)
  MUST increment the MAJOR version and be documented in CHANGELOG.md.
- All code MUST pass linting and formatting checks before merge.
- The JSON output schema for each command MUST be defined and documented
  before implementation begins (contract-first for machine output).

## Governance

This constitution supersedes all other practices and conventions in this
repository. Any practice that conflicts with a principle above is invalid.

**Amendment procedure**: Amendments require updating this file with a version
bump, a rationale note in the Sync Impact Report comment at the top, and a
review of affected templates. Amendments that remove or redefine a principle
are MAJOR bumps; new principles or materially expanded guidance are MINOR bumps;
clarifications and wording fixes are PATCH bumps.

**Compliance review**: Every implementation plan (plan.md) MUST include a
Constitution Check section that gates work against the principles above.
Any violation MUST be recorded in the Complexity Tracking table with explicit
justification.

**Versioning policy**: `MAJOR.MINOR.PATCH` per the amendment procedure above.

**Version**: 1.1.0 | **Ratified**: 2026-04-06 | **Last Amended**: 2026-04-06
