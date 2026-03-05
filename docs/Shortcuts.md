# Keyboard Shortcuts

Available on web and desktop platforms. Registered via `HardwareKeyboard.instance.addHandler` in `ChatScreen`. On web, Ctrl+F and Ctrl+K also have DOM-level `preventDefault` to block browser defaults (find-in-page and address bar focus).

## Shortcuts

| Shortcut | Action |
|----------|--------|
| **Ctrl/Cmd+F** | Focus search bar (opens global search) |
| **Ctrl/Cmd+K** | Focus note input (exits search if active) |
| **Escape** | Cancel search / selection mode / edit mode (in priority order) |
| **Arrow Left/Right** | Cycle channels (when no text field focused) |
| **Enter** | Submit note (when input focused) |
| **Shift+Enter** | New line in note input |

## Implementation

- `chat_screen.dart`: `_handleHardwareKey` — global key handler for Ctrl+F, Ctrl+K, Escape, arrow keys
- `input_focus_provider.dart`: Toggle provider (`InputFocusRequest`) — `NoteInput` listens and calls `requestFocus()` on its private `FocusNode`
- `global_search_provider.dart`: Search state — `Navbar` search field listens for `isActive`
- `note_input.dart`: `Shortcuts`/`Actions` widgets handle Enter → submit
