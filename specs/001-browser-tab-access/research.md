# Research: Browser Tab Access CLI

**Date**: 2026-04-06
**Branch**: `001-browser-tab-access`

## Decision 1: Tab Listing — ScriptingBridge via Dynamic Selectors

**Decision**: Use `SBApplication` + dynamic `performSelector` invocation (no
generated ScriptingBridge headers).

**Rationale**: Proven approach from alfred-switch-windows reference implementation.
Dynamic selectors handle per-browser API differences (e.g. Safari uses `name`,
Chrome/Arc use `title`) without browser-specific subclasses. Generated headers
require regenerating when browser sdef files change.

**Browser bundle IDs**:
- Chrome: `com.google.Chrome`
- Safari: `com.apple.Safari`
- Arc: `company.thebrowser.Browser`

**Tab properties available via ScriptingBridge**:
- `URL` — tab URL (all browsers)
- `title` — tab title (Chrome, Arc)
- `name` — tab title (Safari)
- `id` — numeric tab ID (Chrome, Arc; Safari uses positional index)

**Tab ID strategy**: Positional `"<windowIndex>:<tabIndex>"` (1-based). Not stable
across invocations; documented as such.

**Alternatives considered**: Generated typed ScriptingBridge headers — rejected
because they require per-browser sdef extraction and regeneration on browser updates.

---

## Decision 2: HTML Retrieval — OSAKit (in-process JXA)

**Decision**: Use `OSAKit.OSAScript` to execute JXA in-process. No `osascript`
subprocess.

**JXA script per browser**:

- **Chrome / Arc**:
  ```javascript
  Application('Google Chrome').windows[0].tabs[tabIndex].execute({
    javascript: 'document.documentElement.outerHTML'
  })
  ```
  Requires "Allow JavaScript from Apple Events" enabled in
  Chrome → View → Developer menu (one-time per installation).

- **Safari** (v1): Use `source` property via ScriptingBridge — no JS execution,
  no permission required. Returns static server-delivered HTML.
  JS-rendered DOM retrieval (via `doJavaScript`) is deferred to v2.

**Arc caveat**: `execute javascript` may return `missing value` on some Arc versions.
If encountered, workaround via clipboard injection deferred to v2; document error
with actionable message in v1.

**Alternatives considered**: `NSAppleScript` — rejected (AppleScript syntax, not JXA).
`osascript` subprocess — rejected by constitution (Principle I).

---

## Decision 3: Arc Screenshot — AXUIElement

**Decision**: Use `AXUIElementCreateApplication` + `AXUIElementPerformAction` with
`kAXPressAction` to trigger Arc's **File → Capture Full Page** menu item.

**Menu path** (verified from Arc Help Center):
`File` → `Capture Full Page`

**Behavior**:
1. If `--tab` is provided, activate that tab via ScriptingBridge before proceeding.
2. Trigger **File → Capture Full Page** via AXUIElement.
3. Arc copies the image to the system clipboard.
4. If `--output` is specified: wait briefly (~500ms), read image data from
   `NSPasteboard.general` (type `NSPasteboard.PasteboardType.tiff` or `.png`),
   write as PNG to the given path using `NSBitmapImageRep`, print path to stdout.
5. If `--output` is omitted: print "Screenshot copied to clipboard." to stdout.

**Tab activation**: Use ScriptingBridge to set the target tab as the active tab
of its window, then bring Arc to the foreground, before triggering the menu item.

**Requires**: Accessibility permission (`NSAccessibilityUsageDescription` in
Info.plist; user must grant in System Settings → Privacy → Accessibility).

**Alternatives considered**: JXA menu navigation — rejected (AXUIElement is the
confirmed mechanism from alfred-menubar-search reference implementation).

---

## Decision 4: Default Browser Detection

**Decision**: When `--browser` is omitted, resolve the system default browser via
`NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://")!)` and map
its bundle ID to a supported `BrowserName`. If the resolved bundle ID is not in
the supported set, exit with a clear error naming the detected browser and listing
supported alternatives.

**Rationale**: Reduces friction for the common case where the user only uses one
browser. Preserves explicit control via `--browser`.

**Alternatives considered**: Reading `com.apple.LaunchServices` defaults directly —
rejected; `NSWorkspace` API is the documented, stable approach.

---

## Decision 5: Article Extraction — Deferred

Out of scope for current implementation. Deferred to a future feature branch.

---

## Decision 6: Argument Parsing — swift-argument-parser

**Decision**: Use Apple's `swift-argument-parser` package.

**Rationale**: Official Apple library for Swift CLI tools; statically linked into
the binary (zero runtime footprint); widely used, well-documented. Does not violate
Principle V ("no runtime dependencies") because it is compiled into the binary.

**Package URL**: `https://github.com/apple/swift-argument-parser`
**Version**: 1.3.x (current stable)
