import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/races/data/services/custom_races_manager.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Race Service V2
//  Location: lib/features/races/data/services/race_service_v2.dart
// ─────────────────────────────────────────────────────────────────

class RaceServiceV2 {
  static final RaceServiceV2 _instance = RaceServiceV2._internal();
  factory RaceServiceV2() => _instance;
  RaceServiceV2._internal();

  final _manager = CustomRacesManager();
  final Map<String, SeasonModel> _cachedSeasons = {};
  final Map<String, Future<SeasonModel>> _loadingFutures = {};

  // ── Core load ─────────────────────────────────────────────────

  /// Get all races for a season (custom if available, else asset default).
  Future<SeasonModel> getSeasonRaces(String season) async {
    if (_cachedSeasons.containsKey(season)) return _cachedSeasons[season]!;
    if (_loadingFutures.containsKey(season)) return _loadingFutures[season]!;

    final future = _doLoadSeason(season);
    _loadingFutures[season] = future;
    try {
      final result = await future;
      _cachedSeasons[season] = result;
      return result;
    } finally {
      _loadingFutures.remove(season);
    }
  }

  Future<SeasonModel> _doLoadSeason(String season) async {
    // 1. Try custom saved data first
    try {
      final customJson = await _manager.loadCustomRaces(season);
      if (customJson != null) {
        final parsed = jsonDecode(customJson);
        final model  = _parseSeasonFromJson(parsed, season);
        if (model.races.isNotEmpty) return model;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Custom races load error ($season): $e');
    }

    // 2. Fall back to bundled asset
    return _loadDefaultRaces(season);
  }

  // ── Season switching ──────────────────────────────────────────

  /// Switch to a built-in or previously saved season and return its model.
  /// Updates the active season in SharedPreferences.
  Future<SeasonModel> switchSeason(String season) async {
    // Bust cache so we always re-read the latest custom data
    _cachedSeasons.remove(season);

    final model = await getSeasonRaces(season);
    await _manager.setActiveSeason(season);
    return model;
  }

  /// Save [rawJson] as custom data for the season it declares, switch to it,
  /// and return the parsed model.
  ///
  /// The JSON must contain a top-level `"season"` field (int or string).
  /// If omitted, the key `'custom'` is used.
  Future<SeasonModel> saveAndSwitchCustom(String season, String rawJson) async {
    // Save to disk
    await _manager.saveCustomRaces(season, rawJson);

    // Bust cache so next load reads the fresh file
    _cachedSeasons.remove(season);

    // Load and activate
    final model = await getSeasonRaces(season);
    await _manager.setActiveSeason(season);
    return model;
  }

  // ── Multi-season helpers ──────────────────────────────────────

  Future<List<RaceModel>> getAllRaces({
    List<String> seasons = const ['2023', '2024', '2025'],
  }) async {
    final all = <RaceModel>[];
    for (final s in seasons) {
      final m = await getSeasonRaces(s);
      all.addAll(m.races);
    }
    return all;
  }

  Future<List<RaceModel>> getCompletedRaces(String season) async {
    final m = await getSeasonRaces(season);
    return m.races.where((r) => r.status.isCompleted).toList();
  }

  Future<List<RaceModel>> getUpcomingRaces(String season) async {
    final m = await getSeasonRaces(season);
    return m.races.where((r) => r.status.isUpcoming).toList();
  }

  Future<RaceModel?> getNextRace(String season) async {
    final upcoming = await getUpcomingRaces(season);
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.round.compareTo(b.round));
    return upcoming.first;
  }

  // ── Cache ─────────────────────────────────────────────────────

  void clearCache() {
    _cachedSeasons.clear();
    _loadingFutures.clear();
  }

  // ── Private helpers ───────────────────────────────────────────

  Future<SeasonModel> _loadDefaultRaces(String season) async {
    try {
      final jsonString =
      await rootBundle.loadString('assets/data/races_$season.json');
      final parsed = jsonDecode(jsonString);
      return _parseSeasonFromJson(parsed, season);
    } catch (e) {
      // ignore: avoid_print
      print('Default asset not found for $season: $e');
      return SeasonModel(
        season: int.tryParse(season) ?? 2024,
        lastUpdated: DateTime.now().toIso8601String().split('T').first,
        races: [],
      );
    }
  }

  SeasonModel _parseSeasonFromJson(dynamic json, String season) {
    try {
      final racesJson = json['races'] as List<dynamic>? ?? [];
      final racesList = racesJson
          .map((r) => RaceModel.fromJson(r as Map<String, dynamic>))
          .toList();

      final seasonInt =
          (json['season'] as int?) ?? int.tryParse(season) ?? 2024;
      final lastUpdated = (json['last_updated'] as String?) ??
          DateTime.now().toIso8601String().split('T').first;

      return SeasonModel(
        season: seasonInt,
        lastUpdated: lastUpdated,
        races: racesList,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Parsing error in $season: $e');
      return SeasonModel(
        season: int.tryParse(season) ?? 2024,
        lastUpdated: DateTime.now().toIso8601String().split('T').first,
        races: [],
      );
    }
  }
}