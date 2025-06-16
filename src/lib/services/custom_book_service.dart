import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class CustomBook {
  final String id;
  final String categoryName;
  final String bookName;
  final String contentType;
  final num pages;

  CustomBook({
    required this.id,
    required this.categoryName,
    required this.bookName,
    required this.contentType,
    required this.pages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
      'bookName': bookName,
      'contentType': contentType,
      'pages': pages,
    };
  }

  factory CustomBook.fromJson(Map<String, dynamic> json) {
    return CustomBook(
      id: json['id'] as String? ?? const Uuid().v4(),
      categoryName: json['categoryName'] as String? ?? 'קטגוריה לא ידועה',
      bookName: json['bookName'] as String? ?? 'ספר לא ידוע',
      contentType: json['contentType'] as String? ?? 'פרק',
      pages: json['pages'] as num? ?? 0,
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
      print('Error loading custom books from SharedPreferences: $e');

      return [];
    }
  }

  Future<void> _saveCustomBooks(List<CustomBook> books) async {
    final prefs = await _getPrefs();
    try {
      final jsonList = books.map((book) => book.toJson()).toList();
      await prefs.setString(customBooksKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving custom books to SharedPreferences: $e');
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
          print(
              'Import failed: Provided string is not a valid JSON list for custom books.');

          await prefs.setString(customBooksKey, '[]');
        }
      } catch (e) {
        print('Import failed: Provided string is not valid JSON. Error: $e');

        await prefs.setString(customBooksKey, '[]');
      }
    } else {
      await prefs.setString(customBooksKey, '[]');
    }
  }

  Future<CustomBook?> addCustomBook({
    required String categoryName,
    required String bookName,
    required String contentType,
    required num pages,
  }) async {
    final books = await loadCustomBooks();

    final newBook = CustomBook(
      id: generateId(),
      categoryName: categoryName,
      bookName: bookName,
      contentType: contentType,
      pages: pages,
    );
    books.add(newBook);
    await _saveCustomBooks(books);
    return newBook;
  }

  Future<bool> editCustomBook({
    required String id,
    required String categoryName,
    required String bookName,
    required String contentType,
    required num pages,
  }) async {
    final books = await loadCustomBooks();
    final index = books.indexWhere((book) => book.id == id);
    if (index != -1) {
      books[index] = CustomBook(
        id: id,
        categoryName: categoryName,
        bookName: bookName,
        contentType: contentType,
        pages: pages,
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
