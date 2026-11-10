# browser-cli

A Swift-based CLI tool designed for AI agents to access browser tab data from Chrome, Vivaldi, Safari, and Arc on macOS.

## Usage

Access tab lists, raw HTML, selected text, and full-page screenshots directly from the terminal.

### List Tabs

Lists all open tabs from the default or specified browser as JSON.

```bash
browser-cli list [--browser <chrome|vivaldi|safari|arc>]
```

### Get HTML

Retrieves the raw HTML source of the active or a specific tab.

```bash
browser-cli html [--tab "<windowIndex>:<tabIndex>"] [--browser <browser>]
```

### Get Selection

Retrieves the selected text in the active tab, along with its title and URL, as JSON. `selection` is an empty string when nothing is selected.

```bash
browser-cli selection [--browser <chrome|vivaldi|safari|arc>]
```

Example output:

```json
{
  "title" : "Example Domain",
  "url" : "https://example.com",
  "selection" : "This domain is for use in illustrative examples."
}
```

### Capture Screenshot (Arc and Vivaldi Only)

Captures a screenshot of an Arc or Vivaldi tab. Arc uses File → Capture Full Page; Vivaldi uses Tools → Capture → Page to Clipboard. Saves to a file or keeps in the clipboard if `--output` is omitted. Without `--browser`, uses the default browser if it supports screenshots, otherwise Arc.

```bash
browser-cli screenshot [--browser <arc|vivaldi>] [--tab <tab>] [--output /path/to/image.png]
```

## Supported Browsers

- Google Chrome
- Safari
- Arc
- Vivaldi

## Requirements

- macOS 12+
- Swift 6.0 (for building)

## Build

```bash
swift build -c release
# Executable is built at .build/release/browser-cli
```
