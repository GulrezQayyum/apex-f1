import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:apex_f1/features/races/data/models/race_model.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Race Service
//  Location: lib/features/races/data/services/race_service.dart
//
//  Responsibilities:
//    • Load races.json from assets
//    • Parse it into SeasonModel
//    • Expose clean helper methods to screens
//    • Cache the data so we don't reload every time
// ─────────────────────────────────────────────────────────────────

class RaceService {
  // ── Singleton pattern ─────────────────────────────────────────
  // Only one instance of RaceService exists in the whole app
  static final RaceService _instance = RaceService._internal();
  factory RaceService() => _instance;
  RaceService._internal();

  // ── Cache ─────────────────────────────────────────────────────
  SeasonModel? _cachedSeason;

  // ── Load & Parse ──────────────────────────────────────────────

  /// Loads races.json from assets and returns a SeasonModel.
  /// Caches the result — subsequent calls return instantly.
  Future<SeasonModel> loadSeason() async {
    // Return cached data if already loaded
    if (_cachedSeason != null) return _cachedSeason!;

    try {
      // Load raw JSON string from assets
      final String jsonString = await rootBundle.loadString(
        'assets/data/races.json',
      );

      // Decode JSON string into a Map
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      // Parse into SeasonModel
      _cachedSeason = SeasonModel.fromJson(jsonMap);

      return _cachedSeason!;
    } catch (e) {
      throw RaceServiceException(
        'Failed to load races.json: ${e.toString()}',
      );
    }
  }

  /// Force reload from file — call this after updating races.json
  Future<SeasonModel> reloadSeason() async {
    _cachedSeason = null;
    return loadSeason();
  }

  /// Clear the cache
  void clearCache() => _cachedSeason = null;

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
    // Add <int> and type the sum parameter
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