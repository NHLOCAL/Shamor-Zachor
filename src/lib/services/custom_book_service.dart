import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

// Define a simple class for custom book data structure for JSON serialization
class CustomBook {
  final String id;
  final String categoryName;
  final String bookName;
  final String contentType;
  final int pages;
  final List<String> columns;

  CustomBook({
    required this.id,
    required this.categoryName,
    required this.bookName,
    required this.contentType,
    required this.pages,
    required this.columns,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryName': categoryName,
      'bookName': bookName,
      'contentType': contentType,
      'pages': pages,
      'columns': columns,
    };
  }

  factory CustomBook.fromJson(Map<String, dynamic> json) {
    return CustomBook(
      id: json['id'] as String? ?? const Uuid().v4(), // Ensure ID exists, generate if missing (for older data if any)
      categoryName: json['categoryName'] as String? ?? 'קטגוריה לא ידועה',
      bookName: json['bookName'] as String? ?? 'ספר לא ידוע',
      contentType: json['contentType'] as String? ?? 'פרק',
      pages: json['pages'] as int? ?? 0,
      columns: (json['columns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? ['פרק'],
    );
  }
}

class CustomBookService {
  static const String _customBooksFilename = "custom_books.json";
  final Uuid _uuid = const Uuid();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_customBooksFilename');
  }

  String generateId() {
    return _uuid.v4();
  }

  Future<List<CustomBook>> loadCustomBooks() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      if (contents.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((jsonItem) => CustomBook.fromJson(jsonItem as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading custom books: $e');
      return []; // Return empty list on error
    }
  }

  Future<void> _saveCustomBooks(List<CustomBook> books) async {
    try {
      final file = await _localFile;
      final jsonList = books.map((book) => book.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Error saving custom books: $e');
    }
  }

  Future<CustomBook?> addCustomBook({
    required String categoryName,
    required String bookName,
    required String contentType,
    required int pages,
    required List<String> columns,
  }) async {
    final books = await loadCustomBooks();
    // Optional: Check for duplicates if necessary, though ID makes them unique
    // For now, allowing multiple books with same name/category but different IDs
    final newBook = CustomBook(
      id: generateId(),
      categoryName: categoryName,
      bookName: bookName,
      contentType: contentType,
      pages: pages,
      columns: columns,
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
    required int pages,
    required List<String> columns,
  }) async {
    final books = await loadCustomBooks();
    final index = books.indexWhere((book) => book.id == id);
    if (index != -1) {
      books[index] = CustomBook(
        id: id, // Keep original ID
        categoryName: categoryName,
        bookName: bookName,
        contentType: contentType,
        pages: pages,
        columns: columns,
      );
      await _saveCustomBooks(books);
      return true;
    }
    return false; // Book not found
  }

  Future<bool> deleteCustomBook(String id) async {
    final books = await loadCustomBooks();
    final initialLength = books.length;
    books.removeWhere((book) => book.id == id);
    if (books.length < initialLength) {
      await _saveCustomBooks(books);
      return true; // Book was deleted
    }
    return false; // Book not found
  }
}
