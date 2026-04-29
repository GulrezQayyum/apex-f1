import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:apex_f1/features/races/data/models/race_model.dart';
import 'package:apex_f1/features/races/data/services/custom_races_manager.dart';

class RaceServiceV2 {
  // 1. Correct Singleton Implementation
  static final RaceServiceV2 _instance = RaceServiceV2._internal();
  factory RaceServiceV2() => _instance;
  RaceServiceV2._internal();

  // 2. Initialized instance cache (fixes the .clear() error)
  final Map<String, SeasonModel> _cachedSeasons = {};

  /// Get all races for a season (custom if available, else default)
  Future<SeasonModel> getSeasonRaces(String season) async {
    // Check cache first
    if (_cachedSeasons.containsKey(season)) {
      return _cachedSeasons[season]!;
    }

    SeasonModel? seasonModel;

    // Try to load custom races first
    try {
      final customJson = await CustomRacesManager().loadCustomRaces(season);
      if (customJson != null) {
        final parsed = jsonDecode(customJson);
        seasonModel = _parseSeasonFromJson(parsed, season);
      }
    } catch (e) {
      print('Error loading custom races: $e');
    }

    // Fallback to default asset if custom fails or doesn't exist
    if (seasonModel == null || seasonModel.races.isEmpty) {
      seasonModel = await _loadDefaultRaces(season);
    }

    _cachedSeasons[season] = seasonModel;
    return seasonModel;
  }

  /// Refactored to avoid hardcoded years
  Future<List<RaceModel>> getAllRaces({List<String> seasons = const ['2023', '2024', '2025']}) async {
    final List<RaceModel> allRaces = [];
    for (final season in seasons) {
      final seasonModel = await getSeasonRaces(season);
      allRaces.addAll(seasonModel.races);
    }
    return allRaces;
  }

  /// Fixed: Null-safe status check
  Future<List<RaceModel>> getCompletedRaces(String season) async {
    final seasonModel = await getSeasonRaces(season);
    return seasonModel.races
        .where((r) => (r.status?.toLowerCase() ?? '') == 'completed')
        .toList();
  }

  /// Fixed: Null-safe status check
  Future<List<RaceModel>> getUpcomingRaces(String season) async {
    final seasonModel = await getSeasonRaces(season);
    return seasonModel.races
        .where((r) => (r.status?.toLowerCase() ?? '') == 'upcoming')
        .toList();
  }

  /// Get next race (Sorted by round)
  Future<RaceModel?> getNextRace(String season) async {
    final upcoming = await getUpcomingRaces(season);
    if (upcoming.isEmpty) return null;

    // Sort to ensure we get the actual "next" one
    upcoming.sort((a, b) => a.round.compareTo(b.round));
    return upcoming.first;
  }

  /// Clear the cache
  void clearCache() {
    _cachedSeasons.clear();
  }

  /// Load default races from assets
  Future<SeasonModel> _loadDefaultRaces(String season) async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/races_$season.json');
      final parsed = jsonDecode(jsonString);
      return _parseSeasonFromJson(parsed, season);
    } catch (e) {
      print('Default asset not found for $season: $e');
      return SeasonModel(season: season, races: []);
    }
  }

  /// Improved parsing with proper type casting and null-safe defaults
  SeasonModel _parseSeasonFromJson(dynamic json, String season) {
    try {
      // Ensure we have a list to work with
      final List<dynamic> racesJson = json['races'] ?? [];

      final racesList = racesJson.map((raceMap) {
        // Use the Factory constructor from your RaceModel
        return RaceModel.fromJson(raceMap as Map<String, dynamic>);
      }).toList();

      return SeasonModel(
        season: season,
        races: racesList,
      );
    } catch (e) {
      print('Parsing error in $season: $e');
      return SeasonModel(season: season, races: []);
    }
  }
}