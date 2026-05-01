import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Race Service (Enhanced)
//  Location: lib/features/races/data/services/race_service.dart
// ─────────────────────────────────────────────────────────────────

class RaceService {
  // ── Singleton ────────────────────────────────────────────────
  static final RaceService _instance = RaceService._internal();
  factory RaceService() => _instance;
  RaceService._internal();

  // ── Cache & State ────────────────────────────────────────────
  SeasonModel? _cachedSeason;
  int? _currentSeason;
  String? _customJsonData;

  // FIX: in-flight guard so concurrent calls don't double-load
  Future<SeasonModel>? _loadingFuture;

  // ── Load & Parse ─────────────────────────────────────────────

  /// Load season from custom JSON string
  Future<SeasonModel> loadFromCustomJson(String jsonString) async {
    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _cachedSeason = SeasonModel.fromJson(jsonMap);
      _currentSeason = _cachedSeason?.season;
      _customJsonData = jsonString;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_season', _currentSeason ?? 2024);
      await prefs.setString('custom_races_json', jsonString);

      return _cachedSeason!;
    } catch (e) {
      throw RaceServiceException(
        'Failed to parse custom races.json: ${e.toString()}',
      );
    }
  }

  /// Load a season from assets.
  /// FIX: was always loading 'assets/data/races.json' regardless of the
  /// season parameter — now loads 'assets/data/races_<season>.json'.
  /// Falls back to 'assets/data/races.json' for backward compatibility.
  Future<SeasonModel> loadSeasonFromAssets({int? season}) async {
    final targetSeason = season ?? _currentSeason ?? 2024;

    // Return cache if we already have this season loaded
    if (_cachedSeason != null && _currentSeason == targetSeason) {
      return _cachedSeason!;
    }

    // FIX: race-condition guard — reuse in-flight future if one exists
    if (_loadingFuture != null) return _loadingFuture!;

    _loadingFuture = _doLoadFromAssets(targetSeason);
    try {
      final result = await _loadingFuture!;
      return result;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<SeasonModel> _doLoadFromAssets(int targetSeason) async {
    // Try season-specific file first (e.g. races_2025.json)
    // FIX: original code always loaded 'assets/data/races.json', ignoring year
    const seasonSpecificPath = 'assets/data/races_';
    final specificPath = '${seasonSpecificPath}$targetSeason.json';
    const fallbackPath = 'assets/data/races.json';

    String jsonString;
    try {
      jsonString = await rootBundle.loadString(specificPath);
    } catch (_) {
      // Graceful fallback for projects with a single races.json
      try {
        jsonString = await rootBundle.loadString(fallbackPath);
      } catch (e) {
        throw RaceServiceException(
          'No asset found for season $targetSeason: ${e.toString()}',
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
    final savedSeason = prefs.getInt('selected_season') ?? 2024;
    final customJson = prefs.getString('custom_races_json');

    if (customJson != null && customJson.isNotEmpty) {
      return loadFromCustomJson(customJson);
    } else {
      return loadSeasonFromAssets(season: savedSeason);
    }
  }

  /// Legacy method — uses default asset loading
  Future<SeasonModel> loadSeason() async {
    if (_cachedSeason != null) return _cachedSeason!;
    return loadSeasonFromAssets();
  }

  /// Force reload from current source
  Future<SeasonModel> reloadSeason() async {
    _cachedSeason = null;
    _loadingFuture = null;
    if (_customJsonData != null) {
      return loadFromCustomJson(_customJsonData!);
    } else {
      return loadSeasonFromAssets(season: _currentSeason ?? 2024);
    }
  }

  /// Clear cache and reset to default
  Future<void> clearCache() async {
    _cachedSeason = null;
    _customJsonData = null;
    _loadingFuture = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_season', 2024);
    await prefs.remove('custom_races_json');
  }

  int? get currentSeason => _currentSeason ?? _cachedSeason?.season;
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

  double get seasonProgress => totalRaces == 0 ? 0 : completedRaces / totalRaces;
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