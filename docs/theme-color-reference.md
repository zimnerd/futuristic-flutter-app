# Quick Color Reference for Theme Fixes

## Import Required
```dart
import '../theme/theme_extensions.dart'; // For context extensions
```

## Common Color Replacements

### Background Colors
| Hard-coded | Theme-aware | Extension |
|------------|-------------|-----------|
| `Colors.white` | `Theme.of(context).colorScheme.surface` | `context.surfaceColor` |
| `Colors.black` | `Theme.of(context).colorScheme.surface` (dark) | `context.surfaceColor` |
| `Colors.grey[50]` | `Theme.of(context).colorScheme.surfaceContainerHighest` | `context.surfaceVariantColor` |
| `Colors.grey[100]` | `Theme.of(context).colorScheme.surfaceContainerHighest` | `context.surfaceVariantColor` |

### Text Colors
| Hard-coded | Theme-aware | Extension |
|------------|-------------|-----------|
| `Colors.black` | `Theme.of(context).colorScheme.onSurface` | `context.onSurfaceColor` |
| `Colors.white` | `Theme.of(context).colorScheme.onSurface` (on dark) | `context.onSurfaceColor` |
| `Colors.grey` | `Theme.of(context).colorScheme.onSurfaceVariant` | `context.onSurfaceVariantColor` |
| `Colors.grey[600]` | `Theme.of(context).colorScheme.onSurfaceVariant` | `context.onSurfaceVariantColor` |

### Status Colors
| Hard-coded | Theme-aware | Extension |
|------------|-------------|-----------|
| `Colors.red` | `Theme.of(context).colorScheme.error` | `context.errorColor` |
| `Colors.red[50]` | `context.errorColor.withValues(alpha: 0.1)` | N/A |
| `Colors.red[700]` | `Theme.of(context).colorScheme.error` | `context.errorColor` |
| `Colors.green` | `Theme.of(context).colorScheme.tertiary` | `context.successColor` |
| `Colors.blue` | `Theme.of(context).colorScheme.primary` | `context.primaryColor` |

### Borders & Dividers
| Hard-coded | Theme-aware | Extension |
|------------|-------------|-----------|
| `Colors.grey[300]` | `Theme.of(context).colorScheme.outline` | `context.outlineColor` |
| Border alpha | `context.outlineColor.withValues(alpha: 0.2)` | `ThemeColors.getBorderColor(context)` |
| Divider | `context.outlineColor.withValues(alpha: 0.12)` | `ThemeColors.getDividerColor(context)` |

## Brand Colors (Keep as-is)
These are part of PulseColors and should NOT be changed:
- `PulseColors.primary` - Purple (#6E3BFF)
- `PulseColors.accent` / `PulseColors.secondary` - Cyan (#00C2FF)
- `PulseColors.success` - Green (#00D95F)
- `PulseColors.error` - Red (#FF3B5C)
- `PulseColors.warning` - Orange (#FF9900)

## Dialog/Modal Specific

### AlertDialog
```dart
AlertDialog(
  // backgroundColor auto-themed via DialogTheme
  title: Text(
    'Title',
    style: TextStyle(color: context.onSurfaceColor),
  ),
  content: Text(
    'Content',
    style: TextStyle(color: context.onSurfaceVariantColor),
  ),
)
```

### Container with colored background
```dart
// OLD - Hard-coded
Container(
  color: Colors.red[50],
  child: Text('Error', style: TextStyle(color: Colors.red[700])),
)

// NEW - Theme-aware
Container(
  color: context.errorColor.withValues(alpha: 0.1),
  child: Text(
    'Error',
    style: TextStyle(color: context.errorColor),
  ),
)
```

### Bottom Sheet
```dart
showModalBottomSheet(
  context: context,
  backgroundColor: context.surfaceColor, // Add this
  builder: (context) => Container(
    // Use theme colors throughout
  ),
)
```

## Helper Methods

### Check if dark mode
```dart
bool isDark = context.isDarkMode;
```

### Get appropriate text color for background
```dart
Color textColor = ThemeColors.getTextColorForBackground(context, backgroundColor);
```

### Get disabled color
```dart
Color disabled = ThemeColors.getDisabledColor(context);
```

### Get overlay color
```dart
Color overlay = ThemeColors.getOverlayColor(context);
```

## Common Patterns

### Card with proper theming
```dart
Card(
  // color auto-themed via CardTheme
  child: ListTile(
    title: Text(
      'Title',
      style: TextStyle(color: context.onSurfaceColor),
    ),
    subtitle: Text(
      'Subtitle',
      style: TextStyle(color: context.onSurfaceVariantColor),
    ),
  ),
)
```

### Button with theme colors
```dart
ElevatedButton(
  // colors auto-themed via ElevatedButtonTheme
  onPressed: () {},
  child: Text('Button'),
)

TextButton(
  onPressed: () {},
  child: Text(
    'Text Button',
    style: TextStyle(color: context.primaryColor),
  ),
)
```

### Icon with theme color
```dart
Icon(
  Icons.check,
  color: context.primaryColor,
)

// For status icons
Icon(
  Icons.error,
  color: context.errorColor,
)
```

## Priority Checklist

1. ✅ Dialogs - AlertDialog, showDialog
2. ✅ Bottom Sheets - showModalBottomSheet
3. ✅ Containers with white/black backgrounds
4. ✅ Text with black/white/grey colors
5. ✅ Borders and dividers
6. ✅ Status indicators (error, success, warning)
7. ✅ Icons
8. ✅ Custom widgets with hard-coded backgrounds
