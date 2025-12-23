# Theme Color Fix Guide

## Problem:
Cards and containers are using hardcoded colors like:
- `AppTheme.cardColor` (#2A2938 - always dark)
- `AppTheme.surfaceColor` (#1C1B29 - always dark)
- `AppTheme.backgroundColor` (#0F0E17 - always dark)

## Solution:
Replace with theme-aware colors:
- `Theme.of(context).cardColor` - Uses current theme's card color
- `Theme.of(context).scaffoldBackgroundColor` - Uses current theme's background
- `Theme.of(context).colorScheme.surface` - Uses current theme's surface

## Files to Fix:

### Core Widgets:
1. `lib/widgets/stat_card.dart` - StatCard backgrounds
2. `lib/widgets/recent_expense_card.dart` - Expense card backgrounds
3. `lib/widgets/financial_health_card.dart` - Health card background
4. `lib/widgets/task_item.dart` - Task card backgrounds

### Screens:
1. `lib/screens/home_screen.dart` - All card containers
2. `lib/screens/expenses_screen.dart` - Category cards, transaction cards
3. `lib/screens/budget_screen.dart` - Budget cards
4. `lib/screens/income_screen.dart` - Income cards
5. `lib/screens/tasks_screen.dart` - Task cards
6. `lib/screens/health_screen.dart` - Health record cards
7. All other screens with cards

## Quick Fix Pattern:

### Before:
```dart
Container(
  decoration: BoxDecoration(
    color: AppTheme.cardColor,  // ❌ Always dark!
    borderRadius: BorderRadius.circular(12),
  ),
)
```

### After:
```dart
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,  // ✅ Theme-aware!
    borderRadius: BorderRadius.circular(12),
  ),
)
```

### For Card widgets:
```dart
// Before:
Card(color: AppTheme.cardColor)

// After:
Card()  // Uses theme automatically
```

## Search and Replace:
1. `AppTheme.cardColor` → `Theme.of(context).cardColor`
2. `AppTheme.surfaceColor` → `Theme.of(context).colorScheme.surface`
3. `AppTheme.backgroundColor` → `Theme.of(context).scaffoldBackgroundColor`
4. `AppTheme.textPrimary` → `Theme.of(context).textTheme.bodyLarge?.color`
5. `AppTheme.textSecondary` → `Theme.of(context).textTheme.bodyMedium?.color`
