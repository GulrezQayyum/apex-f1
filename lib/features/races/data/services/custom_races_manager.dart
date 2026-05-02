import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
//  APEX F1 — Custom Races Manager
//  Location: lib/features/races/data/services/custom_races_manager.dart
// ─────────────────────────────────────────────────────────────────

class CustomRacesManager {
  static final CustomRacesManager _instance = CustomRacesManager._internal();
  factory CustomRacesManager() => _instance;
  CustomRacesManager._internal();

  static const _prefActiveSeason = 'apex_active_season';
  static const _defaultSeason    = '2025';

  // ── Directory ─────────────────────────────────────────────────

  Future<Directory> _getCustomRacesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/apex_f1/custom_races');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ── Active Season ─────────────────────────────────────────────

  /// Returns the currently active season key (e.g. '2025' or 'custom').
  Future<String> getActiveSeason() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefActiveSeason) ?? _defaultSeason;
  }

  /// Persists the active season key.
  Future<void> setActiveSeason(String season) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefActiveSeason, season);
  }

  // ── CRUD ──────────────────────────────────────────────────────

  /// Save custom races JSON for a season key.
  Future<void> saveCustomRaces(String season, String jsonContent) async {
    try {
      jsonDecode(jsonContent); // validate before saving
      final dir  = await _getCustomRacesDir();
      final file = File('${dir.path}/races_$season.json');
      await file.writeAsString(jsonContent);
    } catch (e) {
      throw Exception('Invalid JSON format: $e');
    }
  }

  /// Load raw JSON string for a season, or null if not saved.
  Future<String?> loadCustomRaces(String season) async {
    try {
      final dir  = await _getCustomRacesDir();
      final file = File('${dir.path}/races_$season.json');
      if (await file.exists()) return await file.readAsString();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Whether custom race data exists for [season].
  Future<bool> hasCustomRaces(String season) async {
    try {
      final dir  = await _getCustomRacesDir();
      final file = File('${dir.path}/races_$season.json');
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  /// All seasons that have a saved custom file.
  Future<List<String>> getAvailableCustomSeasons() async {
    try {
      final dir = await _getCustomRacesDir();
      if (!await dir.exists()) return [];
      const prefix = 'races_';
      const suffix = '.json';
      return dir
          .listSync()
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .where((n) => n.startsWith(prefix) && n.endsWith(suffix))
          .map((n) => n.substring(prefix.length, n.length - suffix.length))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Delete custom data for [season].
  Future<void> deleteCustomRaces(String season) async {
    try {
      final dir  = await _getCustomRacesDir();
      final file = File('${dir.path}/races_$season.json');
      if (await file.exists()) await file.delete();
    } catch (e) {
      throw Exception('Failed to delete custom races: $e');
    }
  }

  // ── Validation ────────────────────────────────────────────────

  /// Returns true when the JSON has the minimum required structure.
  static bool validateRacesStructure(dynamic json) {
    try {
      if (json is! Map) return false;
      if (json['races'] is! List) return false;
      final races = json['races'] as List;
      if (races.isEmpty) return false;
      for (final race in races) {
        if (race is! Map) return false;
        for (final f in ['round', 'name', 'flag', 'laps']) {
          if (!race.containsKey(f)) return false;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}