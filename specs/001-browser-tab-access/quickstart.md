# Quickstart: browser-cli

## Prerequisites

- macOS 12.0+
- Xcode 15+ (for building)
- For Chrome/Arc HTML retrieval: enable "Allow JavaScript from Apple Events"
  in the browser's developer menu
- For Arc screenshot: grant Accessibility permission in
  System Settings → Privacy & Security → Accessibility
- For article extraction: `npm install -g readability-cli`

## Build

```bash
swift build -c release
```

The binary is output to `.build/release/browser-cli`.

Optionally, copy to a location on your `$PATH`:

```bash
cp .build/release/browser-cli /usr/local/bin/browser-cli
```

## Usage

### List all tabs

```bash
browser-cli list                   # uses system default browser
browser-cli list --browser chrome
browser-cli list --browser safari
browser-cli list --browser arc
```

### Get HTML source of a tab

```bash
# Get tab ID from list first, then fetch HTML
browser-cli html --tab 1:2
browser-cli html --browser chrome --tab 1:2
```

### Capture Arc screenshot

```bash
browser-cli screenshot --browser arc                              # frontmost tab → clipboard
browser-cli screenshot --browser arc --tab 1:2                    # activate tab 1:2, then capture → clipboard
browser-cli screenshot --browser arc --tab 1:2 --output ~/cap.png # save to file
```

### Pipeline example

```bash
# Get HTML of the first tab in default browser
browser-cli list | jq -r '.[0].id' | xargs -I{} browser-cli html --tab {}
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `Chrome is not running` | Open the browser and try again |
| `requires "Allow JavaScript from Apple Events"` | Chrome → View → Developer → Allow JavaScript from Apple Events |
| `Accessibility permission not granted` | System Settings → Privacy & Security → Accessibility → enable terminal app |
| `default browser is not supported` | Use `--browser chrome`, `--browser safari`, or `--browser arc` explicitly |
