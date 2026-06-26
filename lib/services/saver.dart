import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:preference/types/types.dart';

class GameStorage {
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
