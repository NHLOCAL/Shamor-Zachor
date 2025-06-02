import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p; // For basename
import '../models/book_model.dart';

class DataLoaderService {
  // Cache to prevent repeated loading, similar to lru_cache
  Map<String, BookCategory>? _cachedData;

  Future<Map<String, BookCategory>> loadData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    // Filter keys to get only JSON files from assets/data/
    final List<String> jsonFilesPaths = manifestMap.keys
        .where((String key) =>
            key.startsWith('assets/data/') && key.endsWith('.json'))
        .toList();

    Map<String, BookCategory> combinedData = {};

    for (String path in jsonFilesPaths) {
      try {
        final String jsonString = await rootBundle.loadString(path);
        final Map<String, dynamic> jsonData = json.decode(jsonString);

        // Basic validation (can be expanded)
        if (jsonData['name'] == null ||
            jsonData['name'] is! String ||
            jsonData['content_type'] == null ||
            jsonData['content_type'] is! String ||
            jsonData['columns'] == null ||
            jsonData['columns'] is! List ||
            jsonData['data'] == null ||
            jsonData['data'] is! Map) {
          print("Skipping invalid JSON file: $path");
          continue;
        }

        String fileName =
            p.basename(path); // Gets "shas.json" from "assets/data/shas.json"
        BookCategory category = BookCategory.fromJson(jsonData, fileName);
        combinedData[category.name] = category;
      } catch (e) {
        print("Error loading or parsing $path: $e");
      }
    }
    _cachedData = combinedData;
    return combinedData;
  }
}
