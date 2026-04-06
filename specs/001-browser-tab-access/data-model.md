# Data Model: Browser Tab Access CLI

**Date**: 2026-04-06
**Branch**: `001-browser-tab-access`

## Entities

### BrowserName

Enum identifying a supported browser.

| Value    | Bundle ID                        |
|----------|----------------------------------|
| `chrome` | `com.google.Chrome`              |
| `safari` | `com.apple.Safari`               |
| `arc`    | `company.thebrowser.Browser`     |

Serialized as lowercase string in CLI flags and JSON output.

---

### Tab

Represents a single open browser tab.

| Field   | Type   | Description |
|---------|--------|-------------|
| `id`    | String | Positional identifier: `"<windowIndex>:<tabIndex>"` (1-based). Not stable across invocations. |
| `title` | String | Page title. Empty string if the tab is still loading. |
| `url`   | String | Full URL including scheme. Empty string for blank tabs. |

**Constraints**:
- `id` format MUST be `"<Int>:<Int>"` — consumers may parse on `:`.
- `title` and `url` are never null; use empty string for absent values.

**JSON representation**:
```json
{
  "id": "1:3",
  "title": "Example Domain",
  "url": "https://example.com"
}
```

---

### Window

Represents a browser window. Not directly surfaced in JSON output; used
internally to enumerate tabs.

| Field   | Type   | Description |
|---------|--------|-------------|
| `index` | Int    | 1-based window position within the browser. |
| `tabs`  | [Tab]  | Ordered list of tabs in this window. |

---

### BrowserError

Typed error cases that map to non-zero exit codes and stderr messages.

| Case | Exit Code | Stderr Message Pattern |
|------|-----------|------------------------|
| `browserNotRunning(BrowserName)` | 1 | `Error: <Browser> is not running. Open <Browser> and try again.` |
| `tabNotFound(String)` | 2 | `Error: No tab with ID "<id>" found in <Browser>.` |
| `permissionDenied(BrowserName, String)` | 3 | `Error: <Browser> requires "<permission>". <how-to-enable>` |
| `screenshotUnsupported(BrowserName)` | 4 | `Error: screenshot is only supported for Arc.` |
| `unsupportedDefaultBrowser(String)` | 5 | `Error: Your default browser ("<name>") is not supported. Use --browser chrome, safari, or arc.` |
| `arcReturnedNoValue` | 6 | `Error: Arc returned no value for JavaScript execution. This is a known Arc limitation. Try again or use --browser safari.` |

All errors write to stderr. stdout MUST be empty on error.
