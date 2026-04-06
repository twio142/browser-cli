# Contract: `browser-cli list`

List all open tabs in a browser.

## Invocation

```
browser-cli list --browser <chrome|safari|arc>
```

## Flags

| Flag         | Required | Default        | Description |
|--------------|----------|----------------|-------------|
| `--browser`  | No       | system default | Target browser: `chrome`, `safari`, or `arc` |

## Output (stdout)

JSON array of Tab objects. Always an array; empty array if no tabs are open.

```json
[
  {
    "id": "1:1",
    "title": "Example Domain",
    "url": "https://example.com"
  },
  {
    "id": "1:2",
    "title": "GitHub",
    "url": "https://github.com"
  }
]
```

## Exit Codes

| Code | Condition |
|------|-----------|
| 0    | Success (including empty tab list) |
| 1    | Browser not running |
| 3    | Automation permission not granted |
