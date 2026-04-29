# Quick Reference Guide - APEX F1 Responsive & Custom Races

## 🚀 Quick Start

### 1. Add to pubspec.yaml
```yaml
dependencies:
  path_provider: ^2.1.0
```

### 2. Copy All Files
```
Copy the generated files to lib/ maintaining folder structure
```

### 3. Import and Use

```dart
import 'package:apex_f1/core/utils/responsive_helper.dart';
import 'package:apex_f1/features/races/presentation/season_import_screen.dart';

// In your screen
final isMobile = ResponsiveHelper.isMobile(context);
final padding = ResponsiveHelper.getResponsivePadding(context);
```

---

## 📱 Responsive Design Cheat Sheet

### Check Device Type
```dart
ResponsiveHelper.isMobile(context)     // < 600w
ResponsiveHelper.isTablet(context)     // 600-900w
ResponsiveHelper.isDesktop(context)    // > 900w
```

### Layout Pattern
```dart
@override
Widget build(BuildContext context) {
  return ResponsiveHelper.isMobile(context)
    ? _mobileLayout()
    : _desktopLayout();
}
```

### Get Values
```dart
final padding = ResponsiveHelper.getResponsivePadding(context);          // EdgeInsets
final spacing = ResponsiveHelper.getResponsiveSpacing(context);          // double
final fontSize = ResponsiveHelper.getResponsiveFontSize(...);            // double
final columns = ResponsiveHelper.getGridColumns(context);                // 1, 2, or 3
```

---

## 🎯 Custom Races Feature

### Add Navigation
```dart
case 'season-import':
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SeasonImportScreen()),
  );
  break;
```

### Display Custom Races
```dart
import 'package:apex_f1/features/races/data/services/race_service_v2.dart';

final raceService = RaceServiceV2();
final races = await raceService.getSeasonRaces('2024');
```

### Save Custom Races
```dart
import 'package:apex_f1/features/races/data/services/custom_races_manager.dart';

final manager = CustomRacesManager();
await manager.saveCustomRaces('2024', jsonString);
```

---

## 📦 File Structure

```
lib/
├── core/utils/
│   └── responsive_helper.dart
├── features/
│   ├── races/
│   │   ├── data/services/
│   │   │   ├── custom_races_manager.dart
│   │   │   ├── file_picker_service.dart
│   │   │   └── race_service_v2.dart
│   │   └── presentation/
│   │       ├── season_import_screen.dart
│   │       └── responsive_calendar_screen.dart
│   ├── home/presentation/
│   │   └── responsive_home_screen.dart
│   ├── standings/presentation/
│   │   └── responsive_standings_screen.dart
│   └── championship/presentation/
│       └── responsive_championship_screen.dart
```

---

## 🔧 Common Integration Tasks

### Task 1: Make Home Screen Responsive

```dart
// Before: Single layout
@override
Widget build(BuildContext context) {
  return Column(children: [...]);
}

// After: Responsive layout
@override
Widget build(BuildContext context) {
  final padding = ResponsiveHelper.getResponsivePadding(context);
  final columns = ResponsiveHelper.getGridColumns(context);
  
  return Padding(
    padding: padding,
    child: columns == 1
      ? _buildMobileLayout()
      : _buildTabletLayout(),
  );
}
```

### Task 2: Add Season Import Button

```dart
ElevatedButton.icon(
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SeasonImportScreen()),
  ),
  icon: const Icon(Icons.upload_file),
  label: const Text('Import Races'),
)
```

### Task 3: Use Custom Races in RaceService

```dart
// Instead of old RaceService
// Use this instead:
final service = RaceServiceV2();

// Automatically loads custom or default
final season = await service.getSeasonRaces('2024');

// Works seamlessly
List<RaceModel> races = season.races;
```

---

## 📐 Responsive Grid Helper

```dart
// Automatically returns 1, 2, or 3 columns
GridView.count(
  crossAxisCount: ResponsiveHelper.getGridColumns(context),
  crossAxisSpacing: ResponsiveHelper.getResponsiveSpacing(context),
  mainAxisSpacing: ResponsiveHelper.getResponsiveSpacing(context),
  children: items,
)
```

---

## 🎨 Responsive Text Sizes

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

## 💾 Custom Races JSON Template

```json
{
  "races": [
    {
      "round": 1,
      "name": "Race Name",
      "circuit": "Circuit Name",
      "country": "Country",
      "date": "2024-03-02",
      "status": "completed|upcoming",
      "lapRecord": {
        "driver": "Driver Name",
        "time": "1:31.447",
        "lap": 54
      },
      "results": [
        {
          "position": 1,
          "driver": "Driver Name",
          "team": "Team Name",
          "points": 25,
          "status": "Finished",
          "laps": 57,
          "time": "1:45:02.351"
        }
      ]
    }
  ]
}
```

---

## ✅ Implementation Checklist

- [ ] Add path_provider to pubspec.yaml
- [ ] Copy all files to lib/
- [ ] Update navigation to include season-import route
- [ ] Replace RaceService with RaceServiceV2
- [ ] Wrap home/calendar screens with ResponsiveHelper
- [ ] Test on mobile, tablet, desktop
- [ ] Add import button to UI
- [ ] Test custom races import
- [ ] Verify fallback to default races

---

## 🐛 Debugging Tips

### Check Device Type
```dart
print('isMobile: ${ResponsiveHelper.isMobile(context)}');
print('isTablet: ${ResponsiveHelper.isTablet(context)}');
print('isDesktop: ${ResponsiveHelper.isDesktop(context)}');
print('Width: ${MediaQuery.of(context).size.width}');
```

### Verify Custom Races Storage
```dart
final manager = CustomRacesManager();
final seasons = await manager.getAvailableCustomSeasons();
print('Available seasons: $seasons');

final has2024 = await manager.hasCustomRaces('2024');
print('Has 2024 custom: $has2024');
```

### Test JSON Validation
```dart
import 'dart:convert';
void testJson(String json) {
  try {
    final parsed = jsonDecode(json);
    final isValid = CustomRacesManager.validateRacesStructure(parsed);
    print('Valid: $isValid');
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 📞 Need Help?

### For Responsive Design Issues
1. Check ResponsiveHelper import
2. Verify MediaQuery.of(context) usage
3. Test on actual device
4. Check screen width thresholds

### For Custom Races Issues
1. Validate JSON format
2. Check app permissions
3. Verify file storage location
4. Check custom races file exists

### Reference Files
- RESPONSIVE_CUSTOM_RACES_README.md - Full documentation
- INTEGRATION_GUIDE.md - Detailed steps
- Source code comments - Implementation details

---

## 🔗 API Reference

### ResponsiveHelper Methods
```dart
// Device checks
static bool isMobile(BuildContext context)
static bool isTablet(BuildContext context)
static bool isDesktop(BuildContext context)
static bool isLandscape(BuildContext context)
static bool isPortrait(BuildContext context)

// Spacing
static EdgeInsets getResponsivePadding(BuildContext context)
static double getResponsiveSpacing(BuildContext context)
static double getResponsiveBorderRadius(BuildContext context)

// Sizing
static double getResponsiveFontSize(BuildContext context, {required double mobileSize, ...})
static double getResponsiveWidth(BuildContext context, double fraction)
static int getGridColumns(BuildContext context)

// Other
static EdgeInsets getSafeAreaPadding(BuildContext context)
```

### CustomRacesManager Methods
```dart
static final CustomRacesManager _instance = CustomRacesManager._internal();

Future<void> saveCustomRaces(String season, String jsonContent)
Future<String?> loadCustomRaces(String season)
Future<bool> hasCustomRaces(String season)
Future<List<String>> getAvailableCustomSeasons()
Future<void> deleteCustomRaces(String season)
static bool validateRacesStructure(dynamic json)
```

### RaceServiceV2 Methods
```dart
static final RaceServiceV2 _instance = RaceServiceV2._internal();

Future<SeasonModel> getSeasonRaces(String season)
Future<List<RaceModel>> getAllRaces()
Future<List<RaceModel>> getCompletedRaces(String season)
Future<List<RaceModel>> getUpcomingRaces(String season)
Future<RaceModel?> getNextRace(String season)
Future<RaceModel?> getLastCompletedRace(String season)
Future<RaceModel?> getRaceByRound(String season, int round)
Future<List<RaceModel>> getRacesForDriver(String season, String driverName)
void clearCache()
```

---

**Last Updated:** April 2026  
**Version:** 1.0.0
