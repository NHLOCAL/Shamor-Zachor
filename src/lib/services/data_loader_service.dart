import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import '../models/book_model.dart';
import './custom_book_service.dart';

class DataLoaderService {
  Map<String, BookCategory>? _cachedData;

  void clearCache() {
    _cachedData = null;
  }

  Future<Map<String, BookCategory>> loadData() async {
    final customBookService = CustomBookService();
    if (_cachedData != null) {
      return _cachedData!;
    }

    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final List<String> jsonFilesPaths = manifestMap.keys
        .where((String key) =>
            key.startsWith('assets/data/') && key.endsWith('.json'))
        .toList();

    Map<String, BookCategory> combinedData = {};

    for (String path in jsonFilesPaths) {
      try {
        final String jsonString = await rootBundle.loadString(path);
        final Map<String, dynamic> jsonData = json.decode(jsonString);

        if (jsonData['name'] == null ||
            jsonData['name'] is! String ||
            jsonData['content_type'] == null ||
            jsonData['content_type'] is! String ||
            (jsonData['data'] == null &&
                jsonData['books'] == null &&
                jsonData['subcategories'] == null) ||
            (jsonData['data'] != null && jsonData['data'] is! Map) ||
            (jsonData['books'] != null && jsonData['books'] is! Map) ||
            (jsonData['subcategories'] != null &&
                jsonData['subcategories'] is! List)) {
          print(
              "Skipping invalid JSON file (missing name, content_type, or any data/books/subcategories, or invalid types): $path");
          continue;
        }

        String fileName = p.basename(path);
        BookCategory category = BookCategory.fromJson(jsonData, fileName);
        combinedData[category.name] = category;
      } catch (e) {
        print("Error loading or parsing $path: $e");
      }
    }

    final List<CustomBook> customBooksList =
        await customBookService.loadCustomBooks();
    for (final customBook in customBooksList) {
      final bookDetails = BookDetails(
          contentType: customBook.contentType,
          isCustom: true,
          id: customBook.id,
          parts: [
            BookPart(
              name: customBook.bookName,
              startPage: customBook.contentType == "דף" ? 2 : 1,
              endPage:
                  (customBook.contentType == "דף" ? 1 : 0) + customBook.pages,
              excludedPages: [],
            )
          ]);

      if (combinedData.containsKey(customBook.categoryName)) {
        combinedData[customBook.categoryName]!.books[customBook.bookName] =
            bookDetails;
      } else {
        combinedData[customBook.categoryName] = BookCategory(
          name: customBook.categoryName,
          contentType: customBook.contentType,
          books: {customBook.bookName: bookDetails},
          defaultStartPage: customBook.contentType == "דף" ? 2 : 1,
          isCustom: true,
          sourceFile: "custom_books.json",
        );
      }
    }

    _cachedData = combinedData;
    return combinedData;
  }
}
