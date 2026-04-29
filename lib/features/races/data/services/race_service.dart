import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Race Service (Enhanced)
//  Location: lib/features/races/data/services/race_service.dart
//
//  Responsibilities:
//    • Load races.json from assets or custom JSON
//    • Support multiple seasons (2023, 2024, 2025)
//    • Parse it into SeasonModel
//    • Expose clean helper methods to screens
//    • Cache the data so we don't reload every time
//    • Persist user's selected season
// ─────────────────────────────────────────────────────────────────

class RaceService {
  // ── Singleton pattern ─────────────────────────────────────────
  static final RaceService _instance = RaceService._internal();
  factory RaceService() => _instance;
  RaceService._internal();

  // ── Cache & State ─────────────────────────────────────────────
  SeasonModel? _cachedSeason;
  int? _currentSeason;
  String? _customJsonData;

  // ── Load & Parse ──────────────────────────────────────────────

  /// Load season from custom JSON string
  Future<SeasonModel> loadFromCustomJson(String jsonString) async {
    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _cachedSeason = SeasonModel.fromJson(jsonMap);
      _currentSeason = _cachedSeason?.season;
      _customJsonData = jsonString;
      
      // Save preference
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

  /// Load season year from assets (default behavior)
  Future<SeasonModel> loadSeasonFromAssets({int? season}) async {
    final targetSeason = season ?? _currentSeason ?? 2024;
    final assetPath = 'assets/data/races.json';
    
    if (_cachedSeason != null && _currentSeason == targetSeason) {
      return _cachedSeason!;
    }

    try {
      final String jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _cachedSeason = SeasonModel.fromJson(jsonMap);
      _currentSeason = targetSeason;
      _customJsonData = null;

      // Clear custom data and save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selected_season', targetSeason);
      await prefs.remove('custom_races_json');

      return _cachedSeason!;
    } catch (e) {
      throw RaceServiceException(
        'Failed to load races from assets: ${e.toString()}',
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_season', 2024);
    await prefs.remove('custom_races_json');
  }

  /// Get current loaded season year
  int? get currentSeason => _currentSeason ?? _cachedSeason?.season;

  /// Check if using custom JSON
  bool get isUsingCustomJson => _customJsonData != null;

  // ── Race Queries ──────────────────────────────────────────────

  /// Get all races in the season
  Future<List<RaceModel>> getAllRaces() async {
    final season = await loadSeason();
    return season.races;
  }

  /// Get only completed races
  Future<List<RaceModel>> getCompletedRaces() async {
    final season = await loadSeason();
    return season.completedRaces;
  }

  /// Get only upcoming races
  Future<List<RaceModel>> getUpcomingRaces() async {
    final season = await loadSeason();
    return season.upcomingRaces;
  }

  /// Get the next upcoming race
  Future<RaceModel?> getNextRace() async {
    final season = await loadSeason();
    return season.nextRace;
  }

  /// Get a single race by its round number
  Future<RaceModel?> getRaceByRound(int round) async {
    final season = await loadSeason();
    try {
      return season.races.firstWhere((r) => r.round == round);
    } catch (_) {
      return null;
    }
  }

  /// Get races for a specific country
  Future<List<RaceModel>> getRacesByCountry(String country) async {
    final season = await loadSeason();
    return season.races
        .where((r) => r.country.toLowerCase() == country.toLowerCase())
        .toList();
  }

  // ── Driver Queries ────────────────────────────────────────────

  /// Get all results for a specific driver across the season
  Future<List<RaceResult>> getDriverResults(String driverId) async {
    final season = await loadSeason();
    final List<RaceResult> results = [];

    for (final race in season.completedRaces) {
      final result = race.resultForDriver(driverId);
      if (result != null) results.add(result);
    }

    return results;
  }

  /// Get total points for a driver across the season
  Future<int> getDriverPoints(String driverId) async {
    final results = await getDriverResults(driverId);
    return results.fold<int>(0, (int sum, r) => sum + r.points);
  }

  /// Get total wins for a driver across the season
  Future<int> getDriverWins(String driverId) async {
    final results = await getDriverResults(driverId);
    return results.where((r) => r.pos == 1).length;
  }

  /// Get total podiums for a driver across the season
  Future<int> getDriverPodiums(String driverId) async {
    final results = await getDriverResults(driverId);
    return results.where((r) => r.isPodium).length;
  }

  // ── Season Stats ──────────────────────────────────────────────

  /// Get season summary info
  Future<SeasonSummary> getSeasonSummary() async {
    final season = await loadSeason();
    return SeasonSummary(
      season:         season.season,
      totalRaces:     season.totalRaces,
      completedRaces: season.completedCount,
      upcomingRaces:  season.totalRaces - season.completedCount,
      nextRace:       season.nextRace,
      lastUpdated:    season.lastUpdated,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  SEASON SUMMARY — lightweight object for home screen
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

  /// Progress through the season e.g. 0.08 = 8%
  double get seasonProgress => completedRaces / totalRaces;

  /// e.g. "2 of 24 races completed"
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