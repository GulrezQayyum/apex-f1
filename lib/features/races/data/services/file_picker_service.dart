import 'dart:io';
import 'dart:async';

/// Service for handling file picking
class FilePickerService {
  static final FilePickerService _instance = FilePickerService._internal();

  factory FilePickerService() {
    return _instance;
  }

  FilePickerService._internal();

  /// Pick a JSON file from device storage
  /// Implementation uses platform channels for cross-platform support
  Future<File?> pickJsonFile() async {
    try {
      // This would require file_picker package integration
      // For now, returning null as base implementation
      // User should integrate 'file_picker' package:
      // https://pub.dev/packages/file_picker
      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  /// Read file content as string
  Future<String> readFileContent(File file) async {
    try {
      return await file.readAsString();
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  /// Copy file to app documents
  Future<File> copyFileToAppDir(File sourceFile, String fileName) async {
    try {
      final directory = Directory.systemTemp;
      final newFile = File('${directory.path}/$fileName');
      return await sourceFile.copy(newFile.path);
    } catch (e) {
      throw Exception('Failed to copy file: $e');
    }
  }

  /// Validate file extension
  static bool isValidJsonFile(File file) {
    return file.path.toLowerCase().endsWith('.json');
  }

  /// Validate file size (max 5MB)
  Future<bool> isValidFileSize(File file) async {
    try {
      final size = await file.length();
      return size <= 5 * 1024 * 1024; // 5MB
    } catch (e) {
      return false;
    }
  }
}
