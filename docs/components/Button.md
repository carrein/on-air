# Button (AppTextButton)

Standardized text button component with three visual variants. All action buttons in dialogs, forms, and sheets must use `AppTextButton` instead of raw `TextButton`, `ElevatedButton`, or `FilledButton`.

---

## Variants

| Variant | Background | Text Color | Border |
|-------------|------------|------------|--------|
| `primary` | `#3450A3` (filled) | `#FFFFFF` | None |
| `secondary` | Transparent | `#00171F` | 1px `#3450A3` |
| `destructive`| `#DB0000` (filled) | `#FFFFFF` | None |

Default variant is `primary`.

---

## API

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `label` | `String` | required | Button text |
| `onPressed` | `VoidCallback?` | required | Tap callback; null disables the button |
| `variant` | `AppTextButtonVariant` | `.primary` | Visual variant |
| `loading` | `bool` | `false` | Shows `AppSpinner(size: 16)` in foreground color instead of label |
| `expand` | `bool` | `false` | Full-width (`double.infinity`) with 48px height |
| `color` | `Color?` | `null` | Override: bg color for primary/destructive, border+text color for secondary |

---

## Styling

- **Corners**: Sharp (BorderRadius.zero)
- **Padding**: 16px horizontal, 10px vertical
- **Font size**: 14px
- **Animation**: 100ms ease-in-out `AnimatedContainer` for press/hover feedback

### Hover/Press States

- **Primary/Destructive**: Press darkens bg by 10% (`Color.lerp` toward black)
- **Secondary**: Hover shows accent at 8% alpha bg; press shows accent at 15% alpha bg

### Disabled States

- **Primary/Destructive**: Background at 30% alpha, text at 50% alpha
- **Secondary**: Border and text at 30% alpha

---

## Loading State

When `loading: true`, the label is replaced with `AppSpinner(size: 16, color: fg)` where `fg` is the resolved foreground color for the variant. The button is also disabled (taps ignored).

---

## Expand Mode

When `expand: true`, the button is wrapped in `SizedBox(width: double.infinity, height: 48)` with centered content. Used for full-width form buttons (e.g., server setup screen).

---

## File

`memoka_flutter/lib/widgets/app_text_button.dart`
