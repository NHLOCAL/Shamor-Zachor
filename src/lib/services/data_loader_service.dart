import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
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

    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final List<String> jsonFilesPaths = manifest
        .listAssets()
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
          debugPrint(
              "Skipping invalid JSON file (missing name, content_type, or any data/books/subcategories, or invalid types): $path");
          continue;
        }

        String fileName = p.basename(path);
        BookCategory category = BookCategory.fromJson(jsonData, fileName);
        combinedData[category.name] = category;
      } catch (e) {
        debugPrint("Error loading or parsing $path: $e");
      }
    }

    final List<CustomBook> customBooksList =
        await customBookService.loadCustomBooks();
    for (final customBook in customBooksList) {
      final bookDetails = BookDetails.fromJson(
        customBook.parts.isNotEmpty
            ? {
                'parts': customBook.parts
                    .map((part) => {
                          'name': part.name,
                          'start': part.start,
                          'end': part.end,
                          if (part.exclude.isNotEmpty) 'exclude': part.exclude,
                        })
                    .toList(),
              }
            : {'pages': customBook.pages ?? 0},
        contentType: customBook.contentType,
        isCustom: true,
        id: customBook.id,
      );

      _addCustomBookToCombinedData(combinedData, customBook, bookDetails);
    }

    _cachedData = combinedData;
    return combinedData;
  }

  void _addCustomBookToCombinedData(
    Map<String, BookCategory> combinedData,
    CustomBook customBook,
    BookDetails bookDetails,
  ) {
    final topLevelCategoryName = customBook.topLevelCategoryName.trim();
    if (topLevelCategoryName.isEmpty) return;

    final topLevelCategory = combinedData.putIfAbsent(
      topLevelCategoryName,
      () => BookCategory(
        name: topLevelCategoryName,
        contentType: customBook.contentType,
        books: {},
        defaultStartPage: customBook.contentType == "דף" ? 2 : 1,
        isCustom: true,
        sourceFile: "custom_books.json",
        subcategories: <BookCategory>[],
      ),
    );

    if (customBook.subCategoryPath.isEmpty) {
      topLevelCategory.books[customBook.bookName] = bookDetails;
      return;
    }

    BookCategory currentCategory = topLevelCategory;
    for (final rawSubCategoryName in customBook.subCategoryPath) {
      final subCategoryName = rawSubCategoryName.trim();
      if (subCategoryName.isEmpty) continue;

      final subcategories = currentCategory.subcategories!;
      BookCategory? matchingSubCategory;
      for (final subCategory in subcategories) {
        if (subCategory.name == subCategoryName) {
          matchingSubCategory = subCategory;
          break;
        }
      }

      if (matchingSubCategory == null) {
        matchingSubCategory = BookCategory(
          name: subCategoryName,
          contentType: customBook.contentType,
          books: {},
          defaultStartPage: customBook.contentType == "דף" ? 2 : 1,
          isCustom: true,
          sourceFile: "custom_books.json",
          subcategories: <BookCategory>[],
          parentCategoryName: currentCategory.name,
        );
        subcategories.add(matchingSubCategory);
      }

      currentCategory = matchingSubCategory;
    }

    currentCategory.books[customBook.bookName] = bookDetails;
  }
}
