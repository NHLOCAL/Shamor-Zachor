import 'dart:convert';
// import 'dart:io'; // No longer needed for file operations
// import 'package:path_provider/path_provider.dart'; // No longer needed
import 'package:shared_preferences/shared_preferences.dart'; // Added
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
  // static const String _customBooksFilename = "custom_books.json"; // No longer needed
  static const String _appPrefix = "nhlocal.shamor_vezachor"; // Consistent prefix
  static const String customBooksKey = "$_appPrefix.custom_books_data"; // Key for SharedPreferences - MADE PUBLIC
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
      final String? jsonString = prefs.getString(customBooksKey); // Use public key
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((jsonItem) => CustomBook.fromJson(jsonItem as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading custom books from SharedPreferences: $e');
      // Consider clearing corrupted data or providing a default:
      // await prefs.remove(customBooksKey);
      return []; // Return empty list on error
    }
  }

  Future<void> _saveCustomBooks(List<CustomBook> books) async {
    final prefs = await _getPrefs();
    try {
      final jsonList = books.map((book) => book.toJson()).toList();
      await prefs.setString(customBooksKey, json.encode(jsonList)); // Use public key
    } catch (e) {
      print('Error saving custom books to SharedPreferences: $e');
    }
  }

  Future<String?> exportCustomBooksJsonString() async {
    final prefs = await _getPrefs();
    return prefs.getString(customBooksKey); // Use public key
  }

  Future<void> importCustomBooksJsonString(String? jsonString) async {
    final prefs = await _getPrefs();
    if (jsonString != null && jsonString.isNotEmpty) {
      // Basic validation: check if it's a valid JSON array (optional but good)
      try {
        final decoded = json.decode(jsonString);
        if (decoded is List) {
          await prefs.setString(customBooksKey, jsonString); // Use public key
        } else {
          print('Import failed: Provided string is not a valid JSON list for custom books.');
          // Fallback to empty list if structure is wrong but it's a valid JSON
          await prefs.setString(customBooksKey, '[]'); // Use public key
        }
      } catch (e) {
        print('Import failed: Provided string is not valid JSON. Error: $e');
        // Optionally, clear if data is malformed
        await prefs.setString(customBooksKey, '[]'); // Use public key
      }
    } else {
      // If jsonString is null or empty, effectively clear custom books
      await prefs.setString(customBooksKey, '[]'); // Use public key
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
