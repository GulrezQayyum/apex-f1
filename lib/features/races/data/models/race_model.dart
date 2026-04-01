// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Race Model
//  Location: lib/features/races/data/models/race_model.dart
//
//  Parses races.json into strongly typed Dart objects.
//  Each class has:
//    • fromJson()  — parse from JSON map
//    • toJson()    — convert back to JSON map
// ─────────────────────────────────────────────────────────────────

// ── Race Status ───────────────────────────────────────────────────

enum RaceStatus {
  completed,
  upcoming;

  static RaceStatus fromString(String value) {
    return switch (value.toLowerCase()) {
      'completed' => RaceStatus.completed,
      _           => RaceStatus.upcoming,
    };
  }

  String toJson() => name;

  bool get isCompleted => this == RaceStatus.completed;
  bool get isUpcoming  => this == RaceStatus.upcoming;
}

// ── Circuit Type ──────────────────────────────────────────────────

enum CircuitType {
  permanent,
  street;

  static CircuitType fromString(String value) {
    return switch (value.toLowerCase()) {
      'street' => CircuitType.street,
      _        => CircuitType.permanent,
    };
  }

  String toJson() => name;
}

// ── Lap Record ────────────────────────────────────────────────────

class LapRecord {
  final String time;
  final String driver;
  final int year;

  const LapRecord({
    required this.time,
    required this.driver,
    required this.year,
  });

  factory LapRecord.fromJson(Map<String, dynamic> json) {
    return LapRecord(
      time:   json['time']   as String,
      driver: json['driver'] as String,
      year:   json['year']   as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'time':   time,
    'driver': driver,
    'year':   year,
  };
}

// ── Circuit Info ──────────────────────────────────────────────────

class CircuitInfo {
  final double lengthKm;
  final int corners;
  final int drsZones;
  final CircuitType type;

  const CircuitInfo({
    required this.lengthKm,
    required this.corners,
    required this.drsZones,
    required this.type,
  });

  factory CircuitInfo.fromJson(Map<String, dynamic> json) {
    return CircuitInfo(
      lengthKm: (json['length_km'] as num).toDouble(),
      corners:   json['corners']   as int,
      drsZones:  json['drs_zones'] as int,
      type:      CircuitType.fromString(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'length_km': lengthKm,
    'corners':   corners,
    'drs_zones': drsZones,
    'type':      type.toJson(),
  };
}

// ── Race Result (single driver result) ───────────────────────────

class RaceResult {
  final int pos;
  final String driver;
  final String driverId;
  final String team;
  final String time;
  final bool fastestLap;
  final int points;

  const RaceResult({
    required this.pos,
    required this.driver,
    required this.driverId,
    required this.team,
    required this.time,
    required this.fastestLap,
    required this.points,
  });

  factory RaceResult.fromJson(Map<String, dynamic> json) {
    return RaceResult(
      pos:        json['pos']          as int,
      driver:     json['driver']       as String,
      driverId:   json['driver_id']    as String,
      team:       json['team']         as String,
      time:       json['time']         as String,
      fastestLap: json['fastest_lap']  as bool,
      points:     json['points']       as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'pos':          pos,
    'driver':       driver,
    'driver_id':    driverId,
    'team':         team,
    'time':         time,
    'fastest_lap':  fastestLap,
    'points':       points,
  };

  /// Returns medal emoji for podium positions
  String get medalEmoji => switch (pos) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '',
  };

  bool get isPodium => pos <= 3;
  bool get isPointsFinish => pos <= 10;
}

// ── Race Model (main) ─────────────────────────────────────────────

class RaceModel {
  final int round;
  final String name;
  final String circuit;
  final String country;
  final String city;
  final String flag;
  final DateTime date;
  final RaceStatus status;
  final int laps;
  final double distanceKm;
  final LapRecord lapRecord;
  final CircuitInfo circuitInfo;
  final String? weather;
  final List<RaceResult> results;

  const RaceModel({
    required this.round,
    required this.name,
    required this.circuit,
    required this.country,
    required this.city,
    required this.flag,
    required this.date,
    required this.status,
    required this.laps,
    required this.distanceKm,
    required this.lapRecord,
    required this.circuitInfo,
    required this.weather,
    required this.results,
  });

  factory RaceModel.fromJson(Map<String, dynamic> json) {
    return RaceModel(
      round:       json['round']       as int,
      name:        json['name']        as String,
      circuit:     json['circuit']     as String,
      country:     json['country']     as String,
      city:        json['city']        as String,
      flag:        json['flag']        as String,
      date:        DateTime.parse(json['date'] as String),
      status:      RaceStatus.fromString(json['status'] as String),
      laps:        json['laps']        as int,
      distanceKm:  (json['distance_km'] as num).toDouble(),
      lapRecord:   LapRecord.fromJson(json['lap_record'] as Map<String, dynamic>),
      circuitInfo: CircuitInfo.fromJson(json['circuit_info'] as Map<String, dynamic>),
      weather:     json['weather']     as String?,
      results: (json['results'] as List<dynamic>)
          .map((r) => RaceResult.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'round':       round,
    'name':        name,
    'circuit':     circuit,
    'country':     country,
    'city':        city,
    'flag':        flag,
    'date':        date.toIso8601String().split('T').first,
    'status':      status.toJson(),
    'laps':        laps,
    'distance_km': distanceKm,
    'lap_record':  lapRecord.toJson(),
    'circuit_info': circuitInfo.toJson(),
    'weather':     weather,
    'results':     results.map((r) => r.toJson()).toList(),
  };

  // ── Computed helpers ─────────────────────────────────────────

  /// Winner of the race — null if upcoming
  RaceResult? get winner =>
      results.isEmpty ? null : results.first;

  /// Podium top 3 — empty list if upcoming
  List<RaceResult> get podium =>
      results.where((r) => r.isPodium).toList();

  /// Days until race from today
  int get daysUntil =>
      date.difference(DateTime.now()).inDays;

  /// Short date string e.g. "24 MAR"
  String get shortDate {
    const months = [
      'JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Full date string e.g. "24 March 2024"
  String get fullDate {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Circuit type label
  String get circuitTypeLabel =>
      circuitInfo.type == CircuitType.street ? 'Street Circuit' : 'Permanent Circuit';

  /// True if this is the next upcoming race
  bool get isNextRace =>
      status.isUpcoming && daysUntil >= 0;

  /// Result for a specific driver by their id
  RaceResult? resultForDriver(String driverId) {
    try {
      return results.firstWhere((r) => r.driverId == driverId);
    } catch (_) {
      return null;
    }
  }
}

// ── Season Model (wraps the full races.json) ──────────────────────

class SeasonModel {
  final int season;
  final String lastUpdated;
  final List<RaceModel> races;

  const SeasonModel({
    required this.season,
    required this.lastUpdated,
    required this.races,
  });

  factory SeasonModel.fromJson(Map<String, dynamic> json) {
    return SeasonModel(
      season:      json['season']       as int,
      lastUpdated: json['last_updated'] as String,
      races: (json['races'] as List<dynamic>)
          .map((r) => RaceModel.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Computed helpers ─────────────────────────────────────────

  /// All completed races
  List<RaceModel> get completedRaces =>
      races.where((r) => r.status.isCompleted).toList();

  /// All upcoming races
  List<RaceModel> get upcomingRaces =>
      races.where((r) => r.status.isUpcoming).toList();

  /// The very next race
  RaceModel? get nextRace {
    try {
      return races.firstWhere((r) => r.status.isUpcoming);
    } catch (_) {
      return null;
    }
  }

  /// Total races completed so far
  int get completedCount => completedRaces.length;

  /// Total races in season
  int get totalRaces => races.length;
}