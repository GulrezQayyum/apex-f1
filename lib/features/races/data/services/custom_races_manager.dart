import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

/// Service for managing custom race files
class CustomRacesManager {
  static final CustomRacesManager _instance = CustomRacesManager._internal();

  factory CustomRacesManager() {
    return _instance;
  }

  CustomRacesManager._internal();

  /// Get custom races directory
  Future<Directory> _getCustomRacesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final customDir = Directory('${appDir.path}/apex_f1/custom_races');
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }
    return customDir;
  }

  /// Save custom races.json for a season
  Future<void> saveCustomRaces(String season, String jsonContent) async {
    try {
      // Validate JSON
      jsonDecode(jsonContent);
      
      final dir = await _getCustomRacesDir();
      final file = File('${dir.path}/races_$season.json');
      await file.writeAsString(jsonContent);
    } catch (e) {
      throw Exception('Invalid JSON format: $e');
    }
  }

  /// Load custom races for a season
  Future<String?> loadCustomRaces(String season) async {
    try {
      final dir = await _getCustomRacesDir();
      final file = File('${dir.path}/races_$season.json');
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if custom races exist for season
  Future<bool> hasCustomRaces(String season) async {
    try {
      final dir = await _getCustomRacesDir();
      final file = File('${dir.path}/races_$season.json');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get list of available seasons with custom races
  Future<List<String>> getAvailableCustomSeasons() async {
    try {
      final dir = await _getCustomRacesDir();
      if (!await dir.exists()) return [];
      
      final files = dir.listSync();
      const prefix = 'races_';
      const suffix = '.json';
      
      return files
          .whereType<File>()
          .map((f) => f.path.split('/').last)
          .where((name) => name.startsWith(prefix) && name.endsWith(suffix))
          .map((name) => name.substring(prefix.length, name.length - suffix.length))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Delete custom races for a season
  Future<void> deleteCustomRaces(String season) async {
    try {
      final dir = await _getCustomRacesDir();
      final file = File('${dir.path}/races_$season.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete custom races: $e');
    }
  }

  /// Validate races.json structure
  static bool validateRacesStructure(dynamic json) {
    try {
      if (json is! Map) return false;
      if (json['races'] is! List) return false;
      
      final races = json['races'] as List;
      if (races.isEmpty) return false;
      
      for (var race in races) {
        if (race is! Map) return false;
        final required = ['round', 'name', 'circuit', 'country', 'date'];
        for (var field in required) {
          if (!race.containsKey(field)) return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}
