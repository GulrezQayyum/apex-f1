# APEX F1 - Responsive Design & Custom Races Feature

## Overview

This package adds two major features to the APEX F1 app:

### 1. **Responsive Design System**
- Mobile, tablet, and desktop layouts
- Adaptive spacing, fonts, and grid layouts
- Orientation-aware design
- Safe area handling

### 2. **Custom Races Import Feature**
- Users can import custom `races.json` files
- Support for 2023, 2024, 2025 seasons
- JSON validation and error handling
- Persistent storage using app documents
- Automatic fallback to default races if custom invalid

---

## Files Added

### Core Utilities
```
lib/core/utils/responsive_helper.dart
```
- ResponsiveHelper class with static methods for responsive design
- Breakpoints: Mobile (<600dp), Tablet (600-900dp), Desktop (>900dp)
- Methods for padding, fonts, spacing, grid columns, etc.

### Race Management Services
```
lib/features/races/data/services/
├── custom_races_manager.dart      # Manages custom races file storage
├── file_picker_service.dart       # File operations helper
└── race_service_v2.dart           # Enhanced race service with custom support
```

### UI Screens
```
lib/features/
├── races/presentation/
│   ├── season_import_screen.dart            # Import custom races
│   └── responsive_calendar_screen.dart      # Responsive race calendar
├── home/presentation/
│   └── responsive_home_screen.dart          # Responsive home layout
├── standings/presentation/
│   └── responsive_standings_screen.dart     # Responsive standings & drivers
└── championship/presentation/
    └── responsive_championship_screen.dart  # Responsive championship view
```

### Documentation
```
INTEGRATION_GUIDE.md    # Step-by-step integration instructions
README.md               # This file
```

---

## Installation

### 1. Update pubspec.yaml

Add these dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  path_provider: ^2.1.0
  # Optional - for real file picker integration:
  # file_picker: ^6.0.0
```

Run: `flutter pub get`

### 2. Copy Files to Your Project

Copy all files from this package to your `lib/` directory maintaining the folder structure.

### 3. Update Imports in Existing Code

Refer to `INTEGRATION_GUIDE.md` for specific screen integrations.

---

## Usage

### Responsive Design

```dart
import 'package:apex_f1/core/utils/responsive_helper.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Check device type
    if (ResponsiveHelper.isMobile(context)) {
      return _buildMobileLayout();
    } else if (ResponsiveHelper.isTablet(context)) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }
  
  Widget _buildMobileLayout() {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final spacing = ResponsiveHelper.getResponsiveSpacing(context);
    
    return Padding(
      padding: padding,
      child: Column(
        spacing: spacing,
        children: [
          // Mobile layout content
        ],
      ),
    );
  }
}
```

### Available Responsive Methods

```dart
// Device checks
ResponsiveHelper.isMobile(context)        // width < 600
ResponsiveHelper.isTablet(context)        // 600 <= width < 900
ResponsiveHelper.isDesktop(context)       // width >= 900

ResponsiveHelper.isLandscape(context)
ResponsiveHelper.isPortrait(context)

// Spacing helpers
ResponsiveHelper.getResponsivePadding(context)      // Returns EdgeInsets
ResponsiveHelper.getResponsiveSpacing(context)      // Returns double
ResponsiveHelper.getResponsiveBorderRadius(context) // Returns double

// Font sizing
ResponsiveHelper.getResponsiveFontSize(
  context,
  mobileSize: 14,
  tabletSize: 16,
  desktopSize: 18,
)

// Layout helpers
ResponsiveHelper.getGridColumns(context)         // 1, 2, or 3
ResponsiveHelper.getResponsiveWidth(context, 0.5) // 50% of width

// Safe area
ResponsiveHelper.getSafeAreaPadding(context)    // Returns EdgeInsets
```

---

## Custom Races Feature

### User Flow

1. User navigates to "Season Import" screen
2. Selects season: 2023, 2024, or 2025
3. Clicks "Import" button
4. Pastes races.json content
5. App validates and saves to device
6. Custom races auto-load when viewing races

### Navigation Integration

Add this to your home navigation:

```dart
case 'season-import':
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const SeasonImportScreen(),
    ),
  );
  break;
```

Or add a button to the home screen:

```dart
ElevatedButton(
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => const SeasonImportScreen(),
    ),
  ),
  child: const Text('Import Custom Races'),
)
```

### Required JSON Format

```json
{
  "races": [
    {
      "round": 1,
      "name": "Bahrain Grand Prix",
      "circuit": "Bahrain International Circuit",
      "country": "Bahrain",
      "date": "2024-03-02",
      "status": "completed",
      "lapRecord": {
        "driver": "Driver Name",
        "time": "1:31.447",
        "lap": 54
      },
      "results": [
        {
          "position": 1,
          "driver": "Max Verstappen",
          "team": "Red Bull Racing",
          "points": 25,
          "status": "Finished",
          "laps": 57,
          "time": "1:45:02.351",
          "tyreFinal": "Hard",
          "tyreAtFinish": "Hard"
        }
      ]
    }
  ]
}
```

### Using Custom Races in Code

```dart
import 'package:apex_f1/features/races/data/services/race_service_v2.dart';

final raceService = RaceServiceV2();

// Automatically loads custom if available, else default
final seasonModel = await raceService.getSeasonRaces('2024');

// Get all races
final allRaces = await raceService.getAllRaces();

// Get specific races
final completed = await raceService.getCompletedRaces('2024');
final upcoming = await raceService.getUpcomingRaces('2024');
final nextRace = await raceService.getNextRace('2024');
```

### Managing Custom Races

```dart
import 'package:apex_f1/features/races/data/services/custom_races_manager.dart';

final manager = CustomRacesManager();

// Save custom races
await manager.saveCustomRaces('2024', jsonString);

// Check if custom exists
final hasCustom = await manager.hasCustomRaces('2024');

// Load custom races
final jsonContent = await manager.loadCustomRaces('2024');

// Delete custom races
await manager.deleteCustomRaces('2024');

// Get all available custom seasons
final seasons = await manager.getAvailableCustomSeasons();

// Validate JSON structure before saving
bool isValid = CustomRacesManager.validateRacesStructure(jsonData);
```

---

## Screen Integration Patterns

### Pattern 1: Simple Responsive Grid

```dart
Widget _buildResponsiveGrid(BuildContext context) {
  final columns = ResponsiveHelper.getGridColumns(context);
  final spacing = ResponsiveHelper.getResponsiveSpacing(context);
  
  return GridView.count(
    crossAxisCount: columns,
    crossAxisSpacing: spacing,
    mainAxisSpacing: spacing,
    children: items,
  );
}
```

### Pattern 2: Adaptive Columns (Mobile vs Desktop)

```dart
Widget _buildAdaptiveLayout(BuildContext context) {
  final isMobile = ResponsiveHelper.isMobile(context);
  
  return isMobile
    ? Column(children: widgets)
    : Row(children: widgets.map((w) => Expanded(child: w)).toList());
}
```

### Pattern 3: Responsive Font Sizes

```dart
Text(
  'Heading',
  style: TextStyle(
    fontSize: ResponsiveHelper.getResponsiveFontSize(
      context,
      mobileSize: 18,
      tabletSize: 22,
      desktopSize: 28,
    ),
  ),
)
```

---

## Breakpoints Reference

| Device Type | Width Range | Columns | Padding | Spacing |
|------------|-----------|---------|---------|---------|
| Mobile     | < 600     | 1       | 12      | 8       |
| Tablet     | 600-900   | 2       | 16      | 12      |
| Desktop    | > 900     | 3-4     | 24      | 16      |

---

## Storage Location

Custom races files are stored in the app's documents directory:

```
/data/user/0/com.example.apex_f1/documents/apex_f1/custom_races/
├── races_2023.json
├── races_2024.json
└── races_2025.json
```

Delete these files to reset to default races for a season.

---

## Error Handling

The custom races system includes robust error handling:

```dart
try {
  await manager.saveCustomRaces(season, jsonContent);
} on Exception catch (e) {
  // Validate JSON format
  if (!CustomRacesManager.validateRacesStructure(parsed)) {
    print('Invalid JSON structure');
  }
  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

---

## Testing

### Test Custom Races Import

```dart
// Test data
final testJson = '''{
  "races": [
    {
      "round": 1,
      "name": "Test Race",
      "circuit": "Test Circuit",
      "country": "Test Country",
      "date": "2024-01-01",
      "status": "upcoming"
    }
  ]
}''';

// Save and load
await manager.saveCustomRaces('2024', testJson);
final loaded = await manager.loadCustomRaces('2024');
assert(loaded == testJson);

// Get race
final season = await raceService.getSeasonRaces('2024');
assert(season.races.isNotEmpty);
```

---

## Troubleshooting

### Custom races not loading

1. Check JSON format is valid using online validator
2. Ensure all required fields are present
3. Check app has write permission to documents directory
4. Clear app cache and retry

### Responsive layout looks wrong

1. Verify ResponsiveHelper imports
2. Ensure MediaQuery.of(context) is called inside build method
3. Test on actual device/emulator at different sizes
4. Check scaffold is wrapping content properly

### File operations fail

1. Check app has storage permissions (Android)
2. Verify path_provider package is installed
3. Check documents directory exists and is writable
4. Review logs for specific error messages

---

## Future Enhancements

- [ ] Real file picker integration (via file_picker package)
- [ ] Import/export race results
- [ ] Multiple custom race sets per season
- [ ] Cloud backup of custom races
- [ ] Race comparison tools
- [ ] Advanced filtering on race calendar
- [ ] Custom paint visualizations for responsive charts

---

## Support

For issues or questions, refer to:
- `INTEGRATION_GUIDE.md` - Detailed integration steps
- Source code comments - Detailed explanations
- Example implementations - Responsive patterns

---

**Version:** 1.0.0  
**Last Updated:** April 2026  
**Compatibility:** Flutter 3.0+, Dart 2.18+
