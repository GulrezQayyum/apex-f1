import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Race Service (Fixed)
//  Location: lib/features/races/data/services/race_service.dart
// ─────────────────────────────────────────────────────────────────

class RaceService {
  // ── Singleton ────────────────────────────────────────────────
  static final RaceService _instance = RaceService._internal();
  factory RaceService() => _instance;
  RaceService._internal();

  // ── Cache & State ────────────────────────────────────────────
  SeasonModel? _cachedSeason;
  int _currentSeason = 2025; // FIX: was nullable, defaulting to 2024 in weird places
  String? _customJsonData;

  // In-flight guard so concurrent calls don't double-load
  Future<SeasonModel>? _loadingFuture;

  // ─────────────────────────────────────────────────────────────
  //  FIX: These two methods were MISSING — calendar_screen.dart
  //  was calling them but they didn't exist, so switching season
  //  had no effect and always fell back to 2024.
  // ─────────────────────────────────────────────────────────────

  /// Called by the season picker to update the active season.
  void setCurrentSeason(int season) {
    if (_currentSeason != season) {
      _currentSeason = season;
      // Bust cache so next load fetches the new season's file
      _cachedSeason = null;
      _loadingFuture = null;
      _customJsonData = null;
    }
  }

  /// Called by _loadRaces() in CalendarScreen.
  /// Returns races for the given season, loading from the correct asset file.
  Future<List<RaceModel>> getAllRacesForSeason(int season) async {
    // If caller passes a different season than what's cached, update first
    if (_currentSeason != season) {
      setCurrentSeason(season);
    }
    final seasonModel = await loadSeasonFromAssets(season: season);
    return seasonModel.races;
  }

  // ── Load & Parse ─────────────────────────────────────────────

  /// Load season from custom JSON string (e.g. file picker)
  Future<SeasonModel> loadFromCustomJson(String jsonString) async {
    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _cachedSeason = SeasonModel.fromJson(jsonMap);
      _currentSeason = _cachedSeason?.season ?? _currentSeason;
      _customJsonData = jsonString;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_season', _currentSeason);
      await prefs.setString('custom_races_json', jsonString);

      return _cachedSeason!;
    } catch (e) {
      throw RaceServiceException(
        'Failed to parse custom races.json: ${e.toString()}',
      );
    }
  }

  /// Load a season from assets.
  /// Loads 'assets/data/races_<season>.json'.
  /// Falls back to 'assets/data/races.json' for backward compatibility.
  Future<SeasonModel> loadSeasonFromAssets({int? season}) async {
    final targetSeason = season ?? _currentSeason;

    // Return cache only if it matches the requested season
    if (_cachedSeason != null && _cachedSeason!.season == targetSeason) {
      return _cachedSeason!;
    }

    // Race-condition guard — reuse in-flight future if one exists for same season
    if (_loadingFuture != null && _currentSeason == targetSeason) {
      return _loadingFuture!;
    }

    _loadingFuture = _doLoadFromAssets(targetSeason);
    try {
      final result = await _loadingFuture!;
      return result;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<SeasonModel> _doLoadFromAssets(int targetSeason) async {
    final specificPath = 'assets/data/races_$targetSeason.json';
    const fallbackPath = 'assets/data/races.json';

    String jsonString;
    try {
      jsonString = await rootBundle.loadString(specificPath);
    } catch (_) {
      try {
        jsonString = await rootBundle.loadString(fallbackPath);
      } catch (e) {
        throw RaceServiceException(
          'No asset found for season $targetSeason. '
              'Make sure assets/data/races_$targetSeason.json exists '
              'and is listed in pubspec.yaml.',
        );
      }
    }

    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _cachedSeason = SeasonModel.fromJson(jsonMap);
      _currentSeason = targetSeason;
      _customJsonData = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_season', targetSeason);
      await prefs.remove('custom_races_json');

      return _cachedSeason!;
    } catch (e) {
      throw RaceServiceException(
        'Failed to parse races for season $targetSeason: ${e.toString()}',
      );
    }
  }

  /// Initialize — loads user's last selected season or default
  Future<SeasonModel> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSeason = prefs.getInt('selected_season') ?? 2025;
    final customJson = prefs.getString('custom_races_json');

    _currentSeason = savedSeason;

    if (customJson != null && customJson.isNotEmpty) {
      return loadFromCustomJson(customJson);
    } else {
      return loadSeasonFromAssets(season: savedSeason);
    }
  }

  /// Legacy method — uses current season
  Future<SeasonModel> loadSeason() async {
    if (_cachedSeason != null && _cachedSeason!.season == _currentSeason) {
      return _cachedSeason!;
    }
    return loadSeasonFromAssets(season: _currentSeason);
  }

  /// Force reload from current source
  Future<SeasonModel> reloadSeason() async {
    _cachedSeason = null;
    _loadingFuture = null;
    if (_customJsonData != null) {
      return loadFromCustomJson(_customJsonData!);
    } else {
      return loadSeasonFromAssets(season: _currentSeason);
    }
  }

  /// Clear cache and reset to default
  Future<void> clearCache() async {
    _cachedSeason = null;
    _customJsonData = null;
    _loadingFuture = null;
    _currentSeason = 2025;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_season', 2025);
    await prefs.remove('custom_races_json');
  }

  int get currentSeason => _currentSeason;
  bool get isUsingCustomJson => _customJsonData != null;

  // ── Race Queries ──────────────────────────────────────────────

  Future<List<RaceModel>> getAllRaces() async {
    final season = await loadSeason();
    return season.races;
  }

  Future<List<RaceModel>> getCompletedRaces() async {
    final season = await loadSeason();
    return season.completedRaces;
  }

  Future<List<RaceModel>> getUpcomingRaces() async {
    final season = await loadSeason();
    return season.upcomingRaces;
  }

  Future<RaceModel?> getNextRace() async {
    final season = await loadSeason();
    return season.nextRace;
  }

  Future<RaceModel?> getRaceByRound(int round) async {
    final season = await loadSeason();
    try {
      return season.races.firstWhere((r) => r.round == round);
    } catch (_) {
      return null;
    }
  }

  Future<List<RaceModel>> getRacesByCountry(String country) async {
    final season = await loadSeason();
    return season.races
        .where((r) => r.country.toLowerCase() == country.toLowerCase())
        .toList();
  }

  // ── Driver Queries ────────────────────────────────────────────

  Future<List<RaceResult>> getDriverResults(String driverId) async {
    final season = await loadSeason();
    final List<RaceResult> results = [];
    for (final race in season.completedRaces) {
      final result = race.resultForDriver(driverId);
      if (result != null) results.add(result);
    }
    return results;
  }

  Future<int> getDriverPoints(String driverId) async {
    final results = await getDriverResults(driverId);
    return results.fold<int>(0, (int sum, r) => sum + r.points);
  }

  Future<int> getDriverWins(String driverId) async {
    final results = await getDriverResults(driverId);
    return results.where((r) => r.pos == 1).length;
  }

  Future<int> getDriverPodiums(String driverId) async {
    final results = await getDriverResults(driverId);
    return results.where((r) => r.isPodium).length;
  }

  // ── Season Stats ──────────────────────────────────────────────

  Future<SeasonSummary> getSeasonSummary() async {
    final season = await loadSeason();
    return SeasonSummary(
      season: season.season,
      totalRaces: season.totalRaces,
      completedRaces: season.completedCount,
      upcomingRaces: season.totalRaces - season.completedCount,
      nextRace: season.nextRace,
      lastUpdated: season.lastUpdated,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SEASON SUMMARY
// ─────────────────────────────────────────────────────────────────

class SeasonSummary {
  final int season;
  final int totalRaces;
  final int completedRaces;
  final int upcomingRaces;
  final RaceModel? nextRace;
  final String lastUpdated;

  const SeasonSummary({
    required this.season,
    required this.totalRaces,
    required this.completedRaces,
    required this.upcomingRaces,
    required this.nextRace,
    required this.lastUpdated,
  });

  double get seasonProgress =>
      totalRaces == 0 ? 0 : completedRaces / totalRaces;
  String get progressLabel => '$completedRaces of $totalRaces races completed';
}

// ─────────────────────────────────────────────────────────────────
//  CUSTOM EXCEPTION
// ─────────────────────────────────────────────────────────────────

class RaceServiceException implements Exception {
  final String message;
  const RaceServiceException(this.message);

  @override
  String toString() => 'RaceServiceException: $message';
}