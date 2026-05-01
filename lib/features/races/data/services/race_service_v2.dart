import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/races/data/services/custom_races_manager.dart';

class RaceServiceV2 {
  static final RaceServiceV2 _instance = RaceServiceV2._internal();
  factory RaceServiceV2() => _instance;
  RaceServiceV2._internal();

  final Map<String, SeasonModel> _cachedSeasons = {};
  final Map<String, Future<SeasonModel>> _loadingFutures = {};

  /// Get all races for a season (custom if available, else default)
  Future<SeasonModel> getSeasonRaces(String season) async {
    if (_cachedSeasons.containsKey(season)) {
      return _cachedSeasons[season]!;
    }
    if (_loadingFutures.containsKey(season)) {
      return _loadingFutures[season]!;
    }

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
    SeasonModel? seasonModel;

    try {
      final customJson = await CustomRacesManager().loadCustomRaces(season);
      if (customJson != null) {
        final parsed = jsonDecode(customJson);
        seasonModel = _parseSeasonFromJson(parsed, season);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error loading custom races: $e');
    }

    if (seasonModel == null || seasonModel.races.isEmpty) {
      seasonModel = await _loadDefaultRaces(season);
    }

    return seasonModel;
  }

  /// Get all races across multiple seasons
  Future<List<RaceModel>> getAllRaces({
    List<String> seasons = const ['2023', '2024', '2025'],
  }) async {
    final List<RaceModel> allRaces = [];
    for (final season in seasons) {
      final seasonModel = await getSeasonRaces(season);
      allRaces.addAll(seasonModel.races);
    }
    return allRaces;
  }

  // FIX: r.status is a RaceStatus enum — use .isCompleted, NOT .toLowerCase()
  Future<List<RaceModel>> getCompletedRaces(String season) async {
    final seasonModel = await getSeasonRaces(season);
    return seasonModel.races
        .where((r) => r.status.isCompleted)
        .toList();
  }

  // FIX: r.status is a RaceStatus enum — use .isUpcoming, NOT .toLowerCase()
  Future<List<RaceModel>> getUpcomingRaces(String season) async {
    final seasonModel = await getSeasonRaces(season);
    return seasonModel.races
        .where((r) => r.status.isUpcoming)
        .toList();
  }

  /// Get next race sorted by round
  Future<RaceModel?> getNextRace(String season) async {
    final upcoming = await getUpcomingRaces(season);
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.round.compareTo(b.round));
    return upcoming.first;
  }

  /// Clear the cache
  void clearCache() {
    _cachedSeasons.clear();
    _loadingFutures.clear();
  }

  /// Load default races from assets
  Future<SeasonModel> _loadDefaultRaces(String season) async {
    try {
      final jsonString =
      await rootBundle.loadString('assets/data/races_$season.json');
      final parsed = jsonDecode(jsonString);
      return _parseSeasonFromJson(parsed, season);
    } catch (e) {
      // ignore: avoid_print
      print('Default asset not found for $season: $e');
      // FIX: SeasonModel requires lastUpdated — provide fallback
      return SeasonModel(
        season: int.tryParse(season) ?? 2024,
        lastUpdated: DateTime.now().toIso8601String().split('T').first,
        races: [],
      );
    }
  }

  /// Parse season from JSON with null-safe defaults
  SeasonModel _parseSeasonFromJson(dynamic json, String season) {
    try {
      final List<dynamic> racesJson = json['races'] ?? [];

      final racesList = racesJson.map((raceMap) {
        return RaceModel.fromJson(raceMap as Map<String, dynamic>);
      }).toList();

      // FIX: season must be int; lastUpdated is required by SeasonModel
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
      // FIX: all 3 required fields must be provided
      return SeasonModel(
        season: int.tryParse(season) ?? 2024,
        lastUpdated: DateTime.now().toIso8601String().split('T').first,
        races: [],
      );
    }
  }
}