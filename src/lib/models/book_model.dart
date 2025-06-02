// import 'dart:convert'; // Unused import removed

// Helper to safely get string
String _asString(dynamic value) => value is String ? value : '';
// Helper to safely get int
int _asInt(dynamic value) =>
    value is int ? value : (value is String ? (int.tryParse(value) ?? 0) : 0);
// Helper to safely get list of strings
List<String> _asListString(dynamic value) =>
    value is List ? List<String>.from(value.map((e) => e.toString())) : [];
// Helper to safely get map
Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

class BookCategory {
  final String name;
  final String contentType;
  final List<String> columns;
  final Map<String, BookDetails> books;
  final int defaultStartPage;

  BookCategory({
    required this.name,
    required this.contentType,
    required this.columns,
    required this.books,
    required this.defaultStartPage,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json, String fileName) {
    Map<String, dynamic> rawData = _asMap(json['data']);
    Map<String, BookDetails> parsedBooks = {};

    int startPageForCategory = 1;
    if (fileName == "shas.json" || fileName == "yerushalmi.json") {
      startPageForCategory = 2;
    }

    rawData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedBooks[key] = BookDetails.fromJson(
          value,
          contentType: _asString(json['content_type']),
          columns: _asListString(json['columns']),
          startPage: startPageForCategory,
        );
      }
    });

    return BookCategory(
      name: _asString(json['name']),
      contentType: _asString(json['content_type']),
      columns: _asListString(json['columns']),
      books: parsedBooks,
      defaultStartPage: startPageForCategory,
    );
  }

  int getTotalPagesForBook(String bookName) {
    final book = books[bookName];
    if (book == null) return 0;
    if (book.columns.contains("עמוד א") && book.columns.contains("עמוד ב") ||
        book.columns.contains("עמוד א'") && book.columns.contains("עמוד ב'")) {
      return 2 * book.pages;
    }
    return book.pages;
  }
}

class BookDetails {
  final int pages;
  final String contentType;
  final List<String> columns;
  final int startPage;

  BookDetails({
    required this.pages,
    required this.contentType,
    required this.columns,
    required this.startPage,
  });

  factory BookDetails.fromJson(
    Map<String, dynamic> json, {
    required String contentType,
    required List<String> columns,
    required int startPage,
  }) {
    return BookDetails(
      pages: _asInt(json['pages']),
      contentType: contentType,
      columns: columns,
      startPage: startPage,
    );
  }

  bool get isDafType => contentType == "דף";
}
