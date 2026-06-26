import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:preference/types/types.dart';

class GameStorage {
  static Future<bool> removeGame(FileSystemEntity file) async {
    await file.delete();
    return true;
  }

  static Future<List<FileSystemEntity>> getiOSFileList() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String dirPath = appDocDir.path;

      final Directory myDir = Directory(dirPath);

      List<FileSystemEntity> files = myDir.listSync(
        recursive: false,
        followLinks: false,
      );

      List<FileSystemEntity> onlyFiles = files
          .where((entity) => entity is File)
          .toList();

      return onlyFiles;
    } catch (e) {
      debugPrint("Error reading directory: $e");
      return [];
    }
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  static Future<bool> saveGame(GameState state) async {
    try {
      final jsonString = jsonEncode(state.toJson());
      final Directory appDocDir = await getApplicationDocumentsDirectory();

      // 3. Create a clean, filesystem-safe timestamp (e.g., 2026-06-26_22-11-46)
      final now = DateTime.now();
      final timestampStr =
          "${now.year}.${_twoDigits(now.month)}.${_twoDigits(now.day)} at "
          "${_twoDigits(now.hour)}:${_twoDigits(now.minute)}:${_twoDigits(now.second)}";

      final String outputPath = '${appDocDir.path}/$timestampStr.json';

      final File file = File(outputPath);
      await file.writeAsString(jsonString);

      debugPrint('Game saved successfully to: $outputPath');
      return true;
    } catch (e) {
      debugPrint('Error saving game file: $e');
      return false;
    }
  }

  static Future<bool> saveGameWithSelection(GameState state) async {
    try {
      final jsonString = jsonEncode(state.toJson());
      final Uint8List bytes = utf8.encode(jsonString);
      final timestampStr = DateTime.now().toString().split(" ")[0];

      final String? outputPath = await FilePicker.saveFile(
        bytes: bytes,
        dialogTitle: 'Save Preference Game',
        fileName: 'game_$timestampStr.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      return outputPath != null;
    } catch (e) {
      debugPrint('Error saving game file: $e');
      return false;
    }
  }

  static Future<GameState?> openGame(FileSystemEntity fileEntity) async {
    try {
      final file = fileEntity as File;
      final jsonString = await file.readAsString();
      final Map<String, dynamic> decodedJson = jsonDecode(jsonString);
      return GameState.fromJson(decodedJson);
    } catch (e) {
      debugPrint('Error opening game file: $e');
      return null;
    }
  }

  static Future<GameState?> openGameWithSelection() async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return null;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      final Map<String, dynamic> decodedJson = jsonDecode(jsonString);
      return GameState.fromJson(decodedJson);
    } catch (e) {
      debugPrint('Error opening game file: $e');
      return null;
    }
  }
}
