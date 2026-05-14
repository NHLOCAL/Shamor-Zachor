import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

num? _asOptionalNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

class CustomBookPart {
  final String name;
  final int start;
  final int end;
  final List<int> exclude;

  const CustomBookPart({
    required this.name,
    required this.start,
    required this.end,
    this.exclude = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'start': start,
      'end': end,
      if (exclude.isNotEmpty) 'exclude': exclude,
    };
  }

  factory CustomBookPart.fromJson(Map<String, dynamic> json) {
    return CustomBookPart(
      name: json['name'] as String? ?? '',
      start: _asInt(json['start']),
      end: _asInt(json['end']),
      exclude: (json['exclude'] as List<dynamic>?)
              ?.map((value) => _asInt(value))
              .where((value) => value > 0)
              .toList() ??
          const [],
    );
  }
}

class CustomBook {
  final String id;
  final String topLevelCategoryName;
  final List<String> subCategoryPath;
  final String bookName;
  final String contentType;
  final num? pages;
  final List<CustomBookPart> parts;

  CustomBook({
    required this.id,
    required this.topLevelCategoryName,
    this.subCategoryPath = const [],
    required this.bookName,
    required this.contentType,
    this.pages,
    this.parts = const [],
  });

  String get categoryName =>
      subCategoryPath.isNotEmpty ? subCategoryPath.last : topLevelCategoryName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topLevelCategoryName': topLevelCategoryName,
      'subCategoryPath': subCategoryPath,
      'categoryName': categoryName,
      'bookName': bookName,
      'contentType': contentType,
      if (pages != null) 'pages': pages,
      if (parts.isNotEmpty)
        'parts': parts.map((part) => part.toJson()).toList(),
    };
  }

  factory CustomBook.fromJson(Map<String, dynamic> json) {
    final topLevelCategoryName = (json['topLevelCategoryName'] as String?) ??
        (json['categoryName'] as String?) ??
        'קטגוריה לא ידועה';
    final parts = (json['parts'] as List<dynamic>?)
            ?.whereType<Map>()
            .map((part) =>
                CustomBookPart.fromJson(Map<String, dynamic>.from(part)))
            .where((part) =>
                part.name.trim().isNotEmpty && part.start > 0 && part.end > 0)
            .toList() ??
        const <CustomBookPart>[];

    return CustomBook(
      id: json['id'] as String? ?? const Uuid().v4(),
      topLevelCategoryName: topLevelCategoryName,
      subCategoryPath: _asStringList(json['subCategoryPath']),
      bookName: json['bookName'] as String? ?? 'ספר לא ידוע',
      contentType: json['contentType'] as String? ?? 'פרק',
      pages: _asOptionalNum(json['pages']),
      parts: parts,
    );
  }
}

class CustomBookService {
  static const String _appPrefix = "nhlocal.shamor_vezachor";
  static const String customBooksKey = "$_appPrefix.custom_books_data";
  final Uuid _uuid = const Uuid();

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  String generateId() {
    return _uuid.v4();
  }

  Future<List<CustomBook>> loadCustomBooks() async {
    final prefs = await _getPrefs();
    try {
      final String? jsonString = prefs.getString(customBooksKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((jsonItem) =>
              CustomBook.fromJson(jsonItem as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading custom books from SharedPreferences: $e');

      return [];
    }
  }

  Future<void> _saveCustomBooks(List<CustomBook> books) async {
    final prefs = await _getPrefs();
    try {
      final jsonList = books.map((book) => book.toJson()).toList();
      await prefs.setString(customBooksKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving custom books to SharedPreferences: $e');
    }
  }

  Future<String?> exportCustomBooksJsonString() async {
    final prefs = await _getPrefs();
    return prefs.getString(customBooksKey);
  }

  Future<void> importCustomBooksJsonString(String? jsonString) async {
    final prefs = await _getPrefs();
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final decoded = json.decode(jsonString);
        if (decoded is List) {
          await prefs.setString(customBooksKey, jsonString);
        } else {
          debugPrint(
              'Import failed: Provided string is not a valid JSON list for custom books.');

          await prefs.setString(customBooksKey, '[]');
        }
      } catch (e) {
        debugPrint(
            'Import failed: Provided string is not valid JSON. Error: $e');

        await prefs.setString(customBooksKey, '[]');
      }
    } else {
      await prefs.setString(customBooksKey, '[]');
    }
  }

  Future<CustomBook?> addCustomBook({
    required String topLevelCategoryName,
    List<String> subCategoryPath = const [],
    required String bookName,
    required String contentType,
    num? pages,
    List<CustomBookPart> parts = const [],
  }) async {
    final books = await loadCustomBooks();

    final newBook = CustomBook(
      id: generateId(),
      topLevelCategoryName: topLevelCategoryName,
      subCategoryPath: subCategoryPath,
      bookName: bookName,
      contentType: contentType,
      pages: pages,
      parts: parts,
    );
    books.add(newBook);
    await _saveCustomBooks(books);
    return newBook;
  }

  Future<bool> editCustomBook({
    required String id,
    required String topLevelCategoryName,
    List<String> subCategoryPath = const [],
    required String bookName,
    required String contentType,
    num? pages,
    List<CustomBookPart> parts = const [],
  }) async {
    final books = await loadCustomBooks();
    final index = books.indexWhere((book) => book.id == id);
    if (index != -1) {
      books[index] = CustomBook(
        id: id,
        topLevelCategoryName: topLevelCategoryName,
        subCategoryPath: subCategoryPath,
        bookName: bookName,
        contentType: contentType,
        pages: pages,
        parts: parts,
      );
      await _saveCustomBooks(books);
      return true;
    }
    return false;
  }

  Future<bool> deleteCustomBook(String id) async {
    final books = await loadCustomBooks();
    final initialLength = books.length;
    books.removeWhere((book) => book.id == id);
    if (books.length < initialLength) {
      await _saveCustomBooks(books);
      return true;
    }
    return false;
  }
}
