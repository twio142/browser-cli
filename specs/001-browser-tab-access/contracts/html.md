# Contract: `browser-cli html`

Retrieve the raw HTML source of a specific tab.

## Invocation

```
browser-cli html --browser <chrome|safari|arc> --tab <id>
```

## Flags

| Flag        | Required | Default        | Description |
|-------------|----------|----------------|-------------|
| `--browser` | No       | system default | Target browser: `chrome`, `safari`, or `arc` |
| `--tab`     | Yes      | —              | Tab ID in `"<windowIndex>:<tabIndex>"` format (from `list` output) |

## Output (stdout)

Raw HTML string of the page. No JSON wrapper — plain HTML to stdout so it
can be piped directly to other tools.

```
<!DOCTYPE html><html>...</html>
```

## Exit Codes

| Code | Condition |
|------|-----------|
| 0    | Success |
| 1    | Browser not running |
| 2    | Tab ID not found |
| 3    | JavaScript from Apple Events not enabled (Chrome/Arc) |
| 6    | Arc returned no value (known Arc limitation) |

## Notes

- Safari returns static server-delivered HTML (no JS rendering).
- Chrome and Arc return the live DOM via JavaScript execution and require
  "Allow JavaScript from Apple Events" to be enabled in the browser's
  developer settings.
