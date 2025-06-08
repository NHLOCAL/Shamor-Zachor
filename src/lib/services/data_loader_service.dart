import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p; // For basename
import '../models/book_model.dart';
import './custom_book_service.dart';

class DataLoaderService {
  // Cache to prevent repeated loading, similar to lru_cache
  Map<String, BookCategory>? _cachedData;

  void clearCache() {
    _cachedData = null;
  }

  Future<Map<String, BookCategory>> loadData() async {
    final customBookService = CustomBookService(); // Added
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
            (jsonData['data'] == null && jsonData['books'] == null) || // Check for 'data' or 'books'
            (jsonData['data'] != null && jsonData['data'] is! Map) ||   // Validate 'data' if it exists
            (jsonData['books'] != null && jsonData['books'] is! Map)) {  // Validate 'books' if it exists
          print("Skipping invalid JSON file: $path (missing or invalid 'data' or 'books' field)");
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

    // Load and merge custom books
    final List<CustomBook> customBooksList = await customBookService.loadCustomBooks();
    for (final customBook in customBooksList) {
        int startPageForCustomBook = (customBook.contentType == "דף") ? 2 : 1;
        final bookDetails = BookDetails(
            pages: customBook.pages,
            contentType: customBook.contentType,
            columns: customBook.columns.isNotEmpty ? customBook.columns : [customBook.contentType],
            startPage: startPageForCustomBook,
            isCustom: true,
            id: customBook.id, // <<< Add this line
        );
        if (combinedData.containsKey(customBook.categoryName)) {
            combinedData[customBook.categoryName]!.books[customBook.bookName] = bookDetails;
        } else {
            combinedData[customBook.categoryName] = BookCategory(
                name: customBook.categoryName,
                contentType: customBook.contentType,
                columns: customBook.columns.isNotEmpty ? customBook.columns : [customBook.contentType],
                books: {customBook.bookName: bookDetails},
                defaultStartPage: startPageForCustomBook,
                isCustom: true,
                sourceFile: "custom_books.json",
            );
        }
    }
    // End of custom book loading

    _cachedData = combinedData;
    return combinedData;
  }
}
