# Theme

Canonical style reference for the Memoka app. All component specs and implementations
should reference these tokens rather than hard-coding values.

---

## Color Palette

### Core

| Token            | Hex       | RGB              | Usage                                    |
|------------------|-----------|------------------|------------------------------------------|
| `core.background`| `#00171F` | `0, 23, 31`      | Sidebar background, fade gradients       |
| `core.surface`   | `#FFFFFF` | `255, 255, 255`  | Chat bubbles, cards, input fields        |
| `core.text`      | `#FFFFFF` | `255, 255, 255`  | Primary text on dark backgrounds         |
| `core.textMuted` | `#FFFFFF` @ 70% | —           | Secondary/preview text on dark backgrounds |

### Brand

| Token              | Hex       | RGB              | Usage                                  |
|--------------------|-----------|------------------|----------------------------------------|
| `brand.primary`    | `#CE2161` | `206, 33, 97`    | Selected states, primary actions       |
| `brand.accent`     | `#FF52A1` | `255, 82, 161`   | Dividers, highlights, decorative lines |
| `brand.blue`       | `#48EEFF` | `72, 238, 255`   | Reserved (brand palette)               |
| `brand.yellow`     | `#FFE236` | `255, 226, 54`   | Reserved (brand palette)               |

### Semantic

| Token               | Hex / Value          | Usage                          |
|----------------------|----------------------|--------------------------------|
| `semantic.selected`  | `brand.primary`     | Selected channel, active item  |
| `semantic.divider`   | `brand.accent`      | Section dividers               |
| `semantic.success`   | Toast system green   | Success toasts                 |
| `semantic.error`     | Toast system red     | Error toasts                   |
| `semantic.info`      | Toast system blue    | Info toasts                    |

---

## Typography

### Font Families

| Token              | Family         | Usage                             |
|--------------------|----------------|-----------------------------------|
| `font.display`     | Combo          | Logo text, button labels          |
| `font.body`        | Space Grotesk  | Channel names, note text, UI text, all default text |

### Font Scale

| Token              | Size  | Weight  | Usage                            |
|--------------------|-------|---------|----------------------------------|
| `type.logo`        | 32px  | Normal  | App name in sidebar header       |
| `type.button`      | 16px  | Normal  | Sidebar action buttons           |
| `type.body`        | 14px  | Normal  | Channel names, note content      |
| `type.caption`     | 10px  | Normal  | Channel preview text             |

---

## Spacing

| Token         | Value | Usage                                         |
|---------------|-------|-----------------------------------------------|
| `space.xs`    | 4px   | Tight inner gaps                              |
| `space.sm`    | 8px   | Emoji-to-text gap, small padding              |
| `space.md`    | 12px  | Chat view margins, note horizontal padding    |
| `space.lg`    | 16px  | Logo gap, button gap, section padding         |
| `space.xl`    | 20px  | Logo horizontal padding, button right padding |

---

## Borders & Radii

| Token              | Value | Usage                                |
|--------------------|-------|--------------------------------------|
| `radius.note`      | 4px   | Chat bubble corners                  |
| `radius.pill`      | 20px  | Date separator pills                 |
| `divider.weight`   | 1px   | Sidebar section dividers             |

---

## Effects

| Token                  | Value                     | Usage                       |
|------------------------|---------------------------|-----------------------------|
| `fade.height`          | 60px                      | Sidebar scroll fade overlay |
| `fade.stops`           | 0.0 / 0.5 / 1.0          | Gradient distribution       |
| `shadow.note`          | Subtle box shadow         | Chat bubble elevation       |

---

## How to Use

**In component specs** (e.g., `docs/components/Sidebar.md`):
Reference tokens by name — e.g., "background uses `core.background`" rather than
repeating `#00171F`.

**In Dart source**:
Define `static const` fields in each widget's state class, grouped by category,
with values matching this document. See `sidebar.dart` for the reference pattern.
