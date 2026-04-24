import 'dart:math';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Race Simulation Engine
//  Location: lib/features/simulation/domain/race_sim_engine.dart
//
//  This is the brain of the race sim. It handles:
//    • Lap-by-lap position calculations
//    • Random events (safety car, weather, crashes)
//    • Pit stop strategy and timing windows
//    • Rival battles and overtakes
//    • Final result calculation
// ─────────────────────────────────────────────────────────────────

final _rng = Random();

// ─────────────────────────────────────────────────────────────────
//  ENUMS
// ─────────────────────────────────────────────────────────────────

enum TyreCompound {
  soft,
  medium,
  hard,
  intermediate,
  wet;

  String get label => switch (this) {
    TyreCompound.soft         => 'SOFT',
    TyreCompound.medium       => 'MEDIUM',
    TyreCompound.hard         => 'HARD',
    TyreCompound.intermediate => 'INTER',
    TyreCompound.wet          => 'WET',
  };

  String get shortLabel => switch (this) {
    TyreCompound.soft         => 'S',
    TyreCompound.medium       => 'M',
    TyreCompound.hard         => 'H',
    TyreCompound.intermediate => 'I',
    TyreCompound.wet          => 'W',
  };

  // How many laps before tyre starts degrading badly
  int get lifespan => switch (this) {
    TyreCompound.soft         => 20,
    TyreCompound.medium       => 35,
    TyreCompound.hard         => 50,
    TyreCompound.intermediate => 30,
    TyreCompound.wet          => 25,
  };
}

enum WeatherCondition {
  dry,
  overcast,
  lightRain,
  heavyRain;

  String get label => switch (this) {
    WeatherCondition.dry       => 'DRY',
    WeatherCondition.overcast  => 'OVERCAST',
    WeatherCondition.lightRain => 'LIGHT RAIN',
    WeatherCondition.heavyRain => 'HEAVY RAIN',
  };

  String get emoji => switch (this) {
    WeatherCondition.dry       => '☀️',
    WeatherCondition.overcast  => '⛅',
    WeatherCondition.lightRain => '🌧️',
    WeatherCondition.heavyRain => '⛈️',
  };

  bool get needsWets   => this == WeatherCondition.heavyRain;
  bool get needsInters => this == WeatherCondition.lightRain;
}

enum RaceEventType {
  safetyCar,
  virtualSafetyCar,
  weatherChange,
  crash,
  pitWindowOpen,
  pitWindowClosed,
  rivalBattle,
  fastestLap,
  radioMessage,
}

// ─────────────────────────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────────────────────────

class SimDriver {
  final String id;
  final String name;
  final String teamName;
  final String flag;
  int position;
  int gap;           // gap to leader in tenths of seconds
  TyreCompound tyre;
  int tyreLapsUsed;
  bool hasPitted;
  int pitCount;
  bool isPlayer;
  bool retired;

  SimDriver({
    required this.id,
    required this.name,
    required this.teamName,
    required this.flag,
    required this.position,
    this.gap = 0,
    required this.tyre,
    this.tyreLapsUsed = 0,
    this.hasPitted = false,
    this.pitCount = 0,
    this.isPlayer = false,
    this.retired = false,
  });

  String get gapDisplay => position == 1
      ? 'LEADER'
      : '+${(gap / 10).toStringAsFixed(1)}s';

  // Tyre health 0.0 to 1.0
  double get tyreHealth => (1.0 - (tyreLapsUsed / tyre.lifespan)).clamp(0.0, 1.0);

  bool get tyreCritical => tyreHealth < 0.25;
}

class RaceEvent {
  final int lap;
  final RaceEventType type;
  final String message;
  final String? radioMessage;

  const RaceEvent({
    required this.lap,
    required this.type,
    required this.message,
    this.radioMessage,
  });
}

class PitStopWindow {
  final int openLap;
  final int closeLap;
  final String reason;
  bool used;

  PitStopWindow({
    required this.openLap,
    required this.closeLap,
    required this.reason,
    this.used = false,
  });

  bool isOpen(int currentLap) =>
      currentLap >= openLap && currentLap <= closeLap && !used;
}

class SimState {
  final int currentLap;
  final int totalLaps;
  final List<SimDriver> drivers;
  final WeatherCondition weather;
  final bool safetyCar;
  final bool virtualSafetyCar;
  final List<RaceEvent> events;
  final List<PitStopWindow> pitWindows;
  final bool pitWindowOpen;
  final bool raceFinished;

  const SimState({
    required this.currentLap,
    required this.totalLaps,
    required this.drivers,
    required this.weather,
    required this.safetyCar,
    required this.virtualSafetyCar,
    required this.events,
    required this.pitWindows,
    required this.pitWindowOpen,
    required this.raceFinished,
  });

  SimDriver get player => drivers.firstWhere((d) => d.isPlayer);
  int get playerPosition => player.position;
  double get raceProgress => currentLap / totalLaps;

  List<RaceEvent> get latestEvents {
    final lapEvents = events.where((e) => e.lap == currentLap).toList();
    return lapEvents;
  }
}

class RaceSimResult {
  final int finalPosition;
  final int totalLaps;
  final String driverName;
  final String teamName;
  final int pitStops;
  final TyreCompound finalTyre;
  final WeatherCondition peakWeather;
  final bool surviredSafetyCar;
  final List<RaceEvent> allEvents;
  final int pointsEarned;

  const RaceSimResult({
    required this.finalPosition,
    required this.totalLaps,
    required this.driverName,
    required this.teamName,
    required this.pitStops,
    required this.finalTyre,
    required this.peakWeather,
    required this.surviredSafetyCar,
    required this.allEvents,
    required this.pointsEarned,
  });

  String get positionLabel => switch (finalPosition) {
    1 => '1ST',
    2 => '2ND',
    3 => '3RD',
    _ => '${finalPosition}TH',
  };

  String get resultEmoji => switch (finalPosition) {
    1 => '🏆',
    2 => '🥈',
    3 => '🥉',
    _ when finalPosition <= 10 => '✅',
    _ => '💨',
  };

  bool get isPodium   => finalPosition <= 3;
  bool get isPoints   => finalPosition <= 10;
  bool get isWin      => finalPosition == 1;
}

// ─────────────────────────────────────────────────────────────────
//  RACE SIM ENGINE
// ─────────────────────────────────────────────────────────────────

class RaceSimEngine {
  final String raceName;
  final int totalLaps;
  final String playerDriverId;
  final String playerDriverName;
  final String playerTeamName;
  final String playerFlag;

  late List<SimDriver> _drivers;
  late List<RaceEvent> _events;
  late List<PitStopWindow> _pitWindows;
  int _currentLap = 0;
  WeatherCondition _weather = WeatherCondition.dry;
  bool _safetyCar = false;
  bool _virtualSafetyCar = false;
  bool _raceFinished = false;
  WeatherCondition _peakWeather = WeatherCondition.dry;

  RaceSimEngine({
    required this.raceName,
    required this.totalLaps,
    required this.playerDriverId,
    required this.playerDriverName,
    required this.playerTeamName,
    required this.playerFlag,
  });

  // ── Initialize ────────────────────────────────────────────────

  void initialize() {
    _events = [];
    _pitWindows = _generatePitWindows();
    _drivers = _generateGrid();
    _currentLap = 0;
    _weather = WeatherCondition.dry;
    _safetyCar = false;
    _virtualSafetyCar = false;
    _raceFinished = false;
    _peakWeather = WeatherCondition.dry;
  }

  List<SimDriver> _generateGrid() {
    final rivals = [
      ('ver', 'Verstappen',  'Red Bull',   '🇳🇱'),
      ('per', 'Pérez',       'Red Bull',   '🇲🇽'),
      ('lec', 'Leclerc',     'Ferrari',    '🇲🇨'),
      ('nor', 'Norris',      'McLaren',    '🇬🇧'),
      ('ham', 'Hamilton',    'Mercedes',   '🇬🇧'),
      ('sai', 'Sainz',       'Ferrari',    '🇪🇸'),
      ('rus', 'Russell',     'Mercedes',   '🇬🇧'),
      ('pia', 'Piastri',     'McLaren',    '🇦🇺'),
      ('alo', 'Alonso',      'Aston M.',   '🇪🇸'),
      ('str', 'Stroll',      'Aston M.',   '🇨🇦'),
      ('gas', 'Gasly',       'Alpine',     '🇫🇷'),
      ('hul', 'Hülkenberg',  'Haas',       '🇩🇪'),
      ('alb', 'Albon',       'Williams',   '🇹🇭'),
      ('tsu', 'Tsunoda',     'RB',         '🇯🇵'),
      ('bot', 'Bottas',      'Sauber',     '🇫🇮'),
      ('mag', 'Magnussen',   'Haas',       '🇩🇰'),
      ('oco', 'Ocon',        'Alpine',     '🇫🇷'),
      ('sar', 'Sargeant',    'Williams',   '🇺🇸'),
      ('zho', 'Zhou',        'Sauber',     '🇨🇳'),
    ];

    // Shuffle to randomize starting grid
    final shuffled = [...rivals]..shuffle(_rng);

    // Player starts P10 for balance
    final grid = <SimDriver>[];
    int pos = 1;
    for (int i = 0; i < shuffled.length; i++) {
      if (pos == 10) {
        // Insert player at P10
        grid.add(SimDriver(
          id: playerDriverId,
          name: playerDriverName,
          teamName: playerTeamName,
          flag: playerFlag,
          position: 10,
          gap: 90 + _rng.nextInt(30),
          tyre: TyreCompound.medium,
          isPlayer: true,
        ));
        pos++;
      }
      final r = shuffled[i];
      grid.add(SimDriver(
        id: r.$1,
        name: r.$2,
        teamName: r.$3,
        flag: r.$4,
        position: pos,
        gap: pos == 1 ? 0 : (pos * 12) + _rng.nextInt(20),
        tyre: _randomStartTyre(),
      ));
      pos++;
    }

    return grid..sort((a, b) => a.position.compareTo(b.position));
  }

  TyreCompound _randomStartTyre() {
    final roll = _rng.nextInt(10);
    if (roll < 4) return TyreCompound.soft;
    if (roll < 8) return TyreCompound.medium;
    return TyreCompound.hard;
  }

  List<PitStopWindow> _generatePitWindows() {
    final third = totalLaps ~/ 3;
    return [
      PitStopWindow(
        openLap: third - 3,
        closeLap: third + 5,
        reason: 'OPTIMAL PIT WINDOW',
      ),
      PitStopWindow(
        openLap: (totalLaps * 0.6).round() - 3,
        closeLap: (totalLaps * 0.6).round() + 5,
        reason: 'LATE STRATEGY WINDOW',
      ),
    ];
  }

  // ── Advance one lap ───────────────────────────────────────────

  SimState advanceLap() {
    if (_raceFinished) return currentState;

    _currentLap++;

    // Tyre degradation
    _degradeAllTyres();

    // Random events
    _processRandomEvents();

    // Position changes
    _processPositionChanges();

    // Pit windows
    _checkPitWindows();

    // Check race finished
    if (_currentLap >= totalLaps) {
      _raceFinished = true;
    }

    return currentState;
  }

  void _degradeAllTyres() {
    for (final d in _drivers) {
      if (!d.retired) d.tyreLapsUsed++;
    }
  }

  void _processRandomEvents() {
    // Weather change (5% chance per lap after lap 10)
    if (_currentLap > 10 && _rng.nextInt(100) < 5) {
      final newWeather = _randomWeatherChange();
      if (newWeather != _weather) {
        _weather = newWeather;
        if (newWeather.index > _peakWeather.index) _peakWeather = newWeather;
        _events.add(RaceEvent(
          lap: _currentLap,
          type: RaceEventType.weatherChange,
          message: '${newWeather.emoji} WEATHER CHANGE — ${newWeather.label}',
          radioMessage: newWeather.needsWets
              ? 'BOX BOX BOX! WET TYRES NOW!'
              : newWeather.needsInters
              ? 'Think about intermediates, the track is getting wet.'
              : 'Track is drying. Consider slicks.',
        ));
      }
    }

    // Safety car (4% chance per lap between lap 5 and last 10)
    if (_currentLap > 5 &&
        _currentLap < totalLaps - 10 &&
        !_safetyCar &&
        _rng.nextInt(100) < 4) {
      _safetyCar = true;
      _events.add(RaceEvent(
        lap: _currentLap,
        type: RaceEventType.safetyCar,
        message: '🟡 SAFETY CAR DEPLOYED',
        radioMessage: 'Safety car, safety car. Box this lap if you need to.',
      ));
    } else if (_safetyCar && _rng.nextInt(100) < 40) {
      // Safety car ends after ~2-3 laps
      _safetyCar = false;
      _events.add(RaceEvent(
        lap: _currentLap,
        type: RaceEventType.safetyCar,
        message: '🟢 SAFETY CAR WITHDRAWN — RACING RESUMES',
        radioMessage: 'Safety car in this lap. Get ready to push.',
      ));
    }

    // VSC (3% chance)
    if (!_safetyCar &&
        !_virtualSafetyCar &&
        _currentLap > 3 &&
        _rng.nextInt(100) < 3) {
      _virtualSafetyCar = true;
      _events.add(RaceEvent(
        lap: _currentLap,
        type: RaceEventType.virtualSafetyCar,
        message: '🟡 VIRTUAL SAFETY CAR',
        radioMessage: 'VSC deployed. Maintain delta.',
      ));
    } else if (_virtualSafetyCar && _rng.nextInt(100) < 60) {
      _virtualSafetyCar = false;
      _events.add(RaceEvent(
        lap: _currentLap,
        type: RaceEventType.virtualSafetyCar,
        message: '🟢 VSC ENDING',
      ));
    }

    // Rival battle with player
    if (_rng.nextInt(100) < 8) {
      final rivals = _drivers.where((d) =>
      !d.isPlayer && !d.retired &&
          (d.position - _playerPosition).abs() <= 2
      ).toList();

      if (rivals.isNotEmpty) {
        final rival = rivals[_rng.nextInt(rivals.length)];
        _events.add(RaceEvent(
          lap: _currentLap,
          type: RaceEventType.rivalBattle,
          message: '⚔️ BATTLE — ${rival.name.toUpperCase()} IS ${rival.position < _playerPosition ? "AHEAD" : "BEHIND"} YOU',
          radioMessage: rival.position < _playerPosition
              ? 'He\'s right there. Push push push!'
              : 'Keep him behind. Defend the inside.',
        ));
      }
    }

    // Radio messages
    if (_rng.nextInt(100) < 6) {
      final messages = [
        ('📻 ENGINEER: "You\'re looking good out there. Keep it up."', null),
        ('📻 ENGINEER: "Fastest lap is yours. P${_playerPosition}."', null),
        ('📻 ENGINEER: "Gap ahead is ${_rng.nextInt(3) + 1}.${_rng.nextInt(9)} seconds."', 'Push now, we can close that gap.'),
        ('📻 ENGINEER: "Box in two laps for fresh tyres."', 'Confirm: box in two.'),
        ('📻 ENGINEER: "We are P${_playerPosition}. Target is P${max(1, _playerPosition - 1)}."', null),
      ];
      final msg = messages[_rng.nextInt(messages.length)];
      _events.add(RaceEvent(
        lap: _currentLap,
        type: RaceEventType.radioMessage,
        message: msg.$1,
        radioMessage: msg.$2,
      ));
    }
  }

  void _processPositionChanges() {
    // Under safety car — minimal changes
    if (_safetyCar) return;

    for (final driver in _drivers) {
      if (driver.retired) continue;

      // Tyre degradation affects position
      final tyreEffect = driver.tyreHealth < 0.3 ? 0.7 : 1.0;

      // Random overtake chance
      final overtakeChance = (_rng.nextDouble() * tyreEffect * 10).round();

      if (overtakeChance > 7 && driver.position > 1) {
        // Find driver ahead
        final driverAhead = _drivers.firstWhere(
              (d) => d.position == driver.position - 1 && !d.retired,
          orElse: () => driver,
        );

        if (driverAhead.id != driver.id) {
          // Swap positions
          driverAhead.position = driver.position;
          driver.position = driver.position - 1;
        }
      }

      // Update gaps
      if (driver.position > 1) {
        final gapChange = _rng.nextInt(10) - 4;
        driver.gap = max(1, driver.gap + gapChange);
      }
    }

    // Re-sort
    _drivers.sort((a, b) => a.position.compareTo(b.position));
  }

  void _checkPitWindows() {
    for (final window in _pitWindows) {
      if (window.openLap == _currentLap && !window.used) {
        _events.add(RaceEvent(
          lap: _currentLap,
          type: RaceEventType.pitWindowOpen,
          message: '🔧 PIT WINDOW OPEN — ${window.reason}',
          radioMessage: 'Pit window is open. Your call.',
        ));
      }
      if (window.closeLap == _currentLap && !window.used) {
        _events.add(RaceEvent(
          lap: _currentLap,
          type: RaceEventType.pitWindowClosed,
          message: '🔒 PIT WINDOW CLOSING',
          radioMessage: 'Last chance to box.',
        ));
      }
    }
  }

  // ── Player pit stop ───────────────────────────────────────────

  SimState playerPitStop(TyreCompound newTyre) {
    final player = _drivers.firstWhere((d) => d.isPlayer);

    // Mark pit window used
    for (final w in _pitWindows) {
      if (w.isOpen(_currentLap)) w.used = true;
    }

    // Pit stop costs ~22 seconds = 22 positions loss temporarily
    final posLoss = min(5, 20 - player.position);
    player.position = min(20, player.position + posLoss);
    player.tyre = newTyre;
    player.tyreLapsUsed = 0;
    player.hasPitted = true;
    player.pitCount++;
    player.gap += 220; // 22 second penalty in tenths

    _events.add(RaceEvent(
      lap: _currentLap,
      type: RaceEventType.pitWindowOpen,
      message: '🔧 PIT STOP — NEW ${newTyre.label} TYRES',
      radioMessage: 'Good stop. ${newTyre.label} tyres fitted. Now push.',
    ));

    // Re-sort
    _drivers.sort((a, b) => a.position.compareTo(b.position));

    return currentState;
  }

  // ── Helpers ───────────────────────────────────────────────────

  int get _playerPosition =>
      _drivers.firstWhere((d) => d.isPlayer).position;

  WeatherCondition _randomWeatherChange() {
    final conditions = WeatherCondition.values;
    final current = _weather.index;
    // Bias towards nearby conditions
    final delta = _rng.nextInt(3) - 1;
    return conditions[(current + delta).clamp(0, conditions.length - 1)];
  }

  bool get _pitWindowCurrentlyOpen =>
      _pitWindows.any((w) => w.isOpen(_currentLap));

  SimState get currentState => SimState(
    currentLap:        _currentLap,
    totalLaps:         totalLaps,
    drivers:           List.unmodifiable(_drivers),
    weather:           _weather,
    safetyCar:         _safetyCar,
    virtualSafetyCar:  _virtualSafetyCar,
    events:            List.unmodifiable(_events),
    pitWindows:        List.unmodifiable(_pitWindows),
    pitWindowOpen:     _pitWindowCurrentlyOpen,
    raceFinished:      _raceFinished,
  );

  // ── Final result ──────────────────────────────────────────────

  RaceSimResult buildResult() {
    final player = _drivers.firstWhere((d) => d.isPlayer);
    final pos = player.position;
    final points = _pointsForPosition(pos);

    return RaceSimResult(
      finalPosition:    pos,
      totalLaps:        totalLaps,
      driverName:       player.name,
      teamName:         player.teamName,
      pitStops:         player.pitCount,
      finalTyre:        player.tyre,
      peakWeather:      _peakWeather,
      surviredSafetyCar: _events.any((e) => e.type == RaceEventType.safetyCar),
      allEvents:        List.unmodifiable(_events),
      pointsEarned:     points,
    );
  }

  int _pointsForPosition(int pos) => switch (pos) {
    1  => 25,
    2  => 18,
    3  => 15,
    4  => 12,
    5  => 10,
    6  => 8,
    7  => 6,
    8  => 4,
    9  => 2,
    10 => 1,
    _  => 0,
  };
}