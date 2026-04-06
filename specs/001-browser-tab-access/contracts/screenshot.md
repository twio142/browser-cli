# Contract: `browser-cli screenshot`

Capture a screenshot of an Arc tab and either save it to a file or leave it on
the clipboard.

## Invocation

```
browser-cli screenshot [--browser arc] [--tab <id>] [--output <path>]
```

## Flags

| Flag        | Required | Default        | Description |
|-------------|----------|----------------|-------------|
| `--browser` | No       | system default | Must be `arc`. Any other value produces exit code 4. |
| `--tab`     | No       | frontmost tab  | Tab ID to activate before capturing. If omitted, captures the currently active tab. |
| `--output`  | No       | —              | Path to write the captured PNG. If specified, the CLI reads the image from the clipboard and writes it to this path. |

## Output (stdout)

- With `--output`: the absolute path of the written PNG file.
- Without `--output`: `Screenshot copied to clipboard.`

## Exit Codes

| Code | Condition |
|------|-----------|
| 0    | Success |
| 1    | Arc not running |
| 2    | Tab ID not found (when `--tab` is specified) |
| 3    | Accessibility permission not granted |
| 4    | `--browser` is not `arc` |

## Notes

- Arc's **File → Capture Full Page** copies a full-page PNG to the system clipboard.
- If `--output` is specified, the CLI reads the image from `NSPasteboard` after
  a brief wait and writes it to the given path as PNG.
- Requires Accessibility permission: System Settings → Privacy & Security →
  Accessibility.
- Tab activation (when `--tab` is provided) is performed via ScriptingBridge
  before the menu item is triggered.
