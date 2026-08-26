# APEX F1 

A full Formula 1 race simulation experience built entirely in Flutter and Dart. Neon dark theme. GPS-accurate circuit maps.  
20 cars racing in real time. Three full seasons (2023, 2024, 2025). Built from scratch as a university project.

## Links

-  **Firebase Console:** https://console.firebase.google.com/project/apex-f1-159/overview
-  **Hosting URL:** https://apex-f1-159.web.app

## What is APEX F1?

APEX F1 is a mobile F1 simulation app that covers the complete racing experience — from picking your driver and team, to qualifying for grid position,  
racing lap‑by‑lap against 19 rivals with real personalities, and tracking your results across a full season.

The standout feature is the live GPS‑accurate circuit visualization: every race shows a GPS‑accurate layout of the real track  
with all 20 cars animated as colored dots racing around it in real time. All 24 circuits from the 2024 F1 calendar are included,  
derived from real GPS coordinate data.

## Screens and Flow

Screens:
- Splash Screen
- Profile Setup (name → team → driver)
- Home Screen
- Calendar
- Race Detail
- Qualifying
- Race Simulation
- Result Screen
- Post‑Race Debrief
- Standings
- Drivers
- Teams
- My Season (Championship Tracker)
- Season Picker

## Features

### Home Screen
- Live clock and date display
- Next race countdown with circuit and flag
- Top 5 driver standings preview
- Last race result card (updates automatically after every race)
- Season selector badge showing active season
- 7‑card quick navigation grid (Calendar, Standings, Drivers, Race Sim, Teams, My Season, Season Picker)
- Fully responsive — adapts to all screen sizes

### Calendar
- All 24 races from the active season
- Filter by completed / upcoming / all
- Race cards with flag, circuit name, date, status
- Tap any race to view full details

### Race Detail
- Circuit info, lap record, distance, weather conditions
- Two launch options: Qualifying → Race or Skip to Race

### Qualifying Session
- Full Q1 → Q2 → Q3 flow
- Player sets lap time by tapping 3 timing bars — one per sector
- Tap the centre purple zone for a purple sector, green for good, yellow for average
- 19 rivals with GPS‑accurate lap time simulation based on real 2024 pace
- Each rival has a consistency rating — Verstappen barely varies, Pérez is erratic
- Elimination at P16 (Q1) and P11 (Q2)
- Earns a grid starting position that seeds the race

### Race Simulation
- Lap‑by‑lap engine simulating all 20 drivers
- Live GPS circuit map — real track layout with all 20 cars as animated dots
- All 24 circuits GPS‑accurate, auto‑selected by race round
- Your car glows cyan with your name; rivals show real 2024 team livery colors
- Safety car and Virtual Safety Car deployment
- Weather changes (dry → wet → intermediate transitions)
- Rival battles with personality‑based behavior
- Pit stop menu with tyre recommendations based on conditions
- Engineer radio calls
- Tyre degradation and health bar
- Drama overlays for SC, weather, battles
- Skip to finish button

### Result Screen
- Dramatic animated reveal of finishing position
- Points counter animating from 0
- Race stats grid (laps, pit stops, tyre, weather, safety car)
- Race highlights from actual sim events
- 4 navigation buttons: Home, Race Again, Race Debrief, My Season

### Post‑Race Debrief
PACE tab:
- Animated lap time chart with fastest lap highlighted in purple, pit lap markers

TYRES tab:
- Visual stint timeline showing which compound was used and for how many laps

STORY tab:
- Full race timeline from lights out to chequered flag with every event

### Standings
Driver Championship tab:
- Animated points bars, wins/podiums/poles, team colors

Constructor Championship tab:
- All 10 teams with points bars and season stats
- Full 2024 final season data

### Drivers
- All 20 drivers with full profiles
- Stats: points, wins, podiums, poles, rating
- Sort by points, wins, or team
- Tap any driver for detailed overlay

### Teams / Constructors
- All 10 constructors with full profiles
- Driver pair cards
- Car performance bars: Power, Aerodynamics, Reliability, Tyre Management
- Season stats: wins, podiums, poles, fastest laps
- Technical info: chassis, power unit, base, team principal

### My Season (Championship Tracker)
- Automatically records every completed race result
- Persisted in SharedPreferences — survives app restart
- Total points counter with season progress ring
- Wins, podiums, best result, average position stats
- Cumulative points line chart with win markers
- Race‑by‑race history list with position, points, tyre, fastest lap
- Reset with confirmation dialog

### Season Picker  
- Switch between 2023, 2024, and 2025 seasons
- Each season loads its own races_YEAR.json from assets
- Custom season — paste any valid races.json content to load any season
- Custom JSON saved to SharedPreferences per season
- Active season badge shown on home screen

## Season Status

| Season | Status | Notes |
|--------|--------|-------|
| 2025 |  Upcoming | All races are set to `upcoming` — you can play and simulate every race of the 2025 season |
| 2024 |  Completed | All races are marked `completed` — final results and standings are shown |
| 2023 |  Completed | All races are marked `completed` — final results and standings are shown |

> **Want to race the 2023 or 2024 seasons?**  
> You can unlock any race for simulation by editing the season's JSON file in `assets/data/` and changing the race's `"status"` field from `"completed"` to `"upcoming"`. This lets you re-live any race from past seasons in full simulation mode.

## Design

- Neon dark theme throughout the entire app
- Google Fonts: Orbitron (headings) and Rajdhani (body)
- Fully responsive — adapts from small phones (360px) to tablets (600px+)
- Animated transitions and UI elements (20+ animations)
- Real 2024 F1 team livery colors for all cars

## Tech Stack

Framework: Flutter 3.x  
Language: Dart 3.x  
Fonts: Google Fonts — Orbitron, Rajdhani  
Storage: shared_preferences  
Architecture: Feature‑first Clean Architecture  
State: StatefulWidget + AnimationController  
Persistence: SharedPreferences (profile, championship, custom seasons)  
Backend: Zero backend — everything runs on‑device


dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0          # Orbitron + Rajdhani fonts
  animated_text_kit: ^4.2.2     # Splash screen animation
  shared_preferences: ^2.2.2    # Profile + championship + season storage


## Responsive Design

A custom R utility class (responsive_helper.dart) scales all sizes relative to a 390px baseline:

final r = R.of(context);
r.fs(16)          # responsive font size
r.sp(12)          # responsive spacing
r.navGridCols     # 2 on mobile, 3 on tablet
r.navCardRatio    # grid card aspect ratio
r.circuitMapH     # circuit map height

Tested on:
- Small phones (360px)
- Normal phones (390px)
- Large phones (430px)
- Tablets (600px+)

## Season Data Format

The app loads seasons from assets/data/races_YEAR.json.

Format for custom seasons:

{
  "season": 2025,
  "last_updated": "2025-01-01",
  "races": [
    {
      "round": 1,
      "name": "Bahrain Grand Prix",
      "circuit": "Bahrain International Circuit",
      "country": "Bahrain",
      "city": "Sakhir",
      "flag": "🇧🇭",
      "date": "2025-03-16",
      "status": "upcoming",
      "laps": 57,
      "distance_km": 308.2,
      "lap_record": {
        "time": "1:31.447",
        "driver": "Pedro de la Rosa",
        "year": 2005
      },
      "circuit_info": {
        "corners": 15,
        "drs_zones": 3
      },
      "weather": "dry"
    }
  ]
}

To use a custom season:
1. Tap the  season badge on the home screen
2. Select CUSTOM SEASON
3. Paste the JSON
4. Press LOAD SEASON

## Getting Started

Prerequisites:
- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0
- Android SDK 21+ / iOS 12+

Clone and run:
git clone https://github.com/GulrezQayyum/apex-f1
cd apex-f1
flutter pub get
flutter run

Build APK:
flutter build apk --release

Build iOS:
flutter build ios --release

## Project Stats

Metric                      Value
---------------------------------------------
Dart files                  25
Total lines of code         ~15,700
F1 circuits                 24 GPS‑accurate
GPS coordinate points       2,913
Race drivers                20 with personalities
F1 seasons included         3 (2023, 2024, 2025)
Screens                     15
Animations                  20+

## Open Source

The GPS circuit data used in this app is open‑sourced separately:
f1‑circuit‑geojson — Flutter‑ready GPS coordinate paths for all 24 F1 circuits.
Project: https://github.com/GulrezQayyum/f1_circuits-_2024_season

## License

MIT — free to use, modify, and distribute.

## About

Built by a 6th semester Software Engineering student as a university project.
What started as a simple calendar app became a full race simulation with:
- GPS circuit maps
- Qualifying sessions
- Rival AI personalities
- Championship tracker
- Multi‑season support (2023, 2024, 2025)
- Fully responsive design

Every line of Dart. Every GPS coordinate. Every rival personality. Built from scratch. 🏁

Built by: Gulrez Qayyum
