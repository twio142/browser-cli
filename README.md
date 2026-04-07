# browser-cli

A Swift-based CLI tool designed for AI agents to access browser tab data from Chrome, Safari, and Arc on macOS.

## Usage

Access tab lists, raw HTML, and full-page screenshots directly from the terminal.

### List Tabs

Lists all open tabs from the default or specified browser as JSON.

```bash
browser-cli list [--browser <chrome|safari|arc>]
```

### Get HTML

Retrieves the raw HTML source of the active or a specific tab.

```bash
browser-cli html [--tab "<windowIndex>:<tabIndex>"] [--browser <browser>]
```

### Capture Screenshot (Arc Only)

Captures a full-page screenshot of an Arc tab. Saves to a file or keeps in the clipboard if `--output` is omitted.

```bash
browser-cli screenshot --browser arc [--tab <tab>] [--output /path/to/image.png]
```

## Supported Browsers

- Google Chrome
- Safari
- Arc
- Other Chromium-based browsers (when set as the system default)

## Requirements

- macOS 12+
- Swift 6.0 (for building)

## Build

```bash
swift build -c release
# Executable is built at .build/release/browser-cli
```
