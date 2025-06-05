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
  final bool isCustom;
  final String sourceFile;

  BookCategory({
    required this.name,
    required this.contentType,
    required this.columns,
    required this.books,
    required this.defaultStartPage,
    required this.isCustom,
    required this.sourceFile,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json, String sourceFile, { bool isCustom = false}) {
    Map<String, dynamic> rawData = _asMap(json['data']);
    Map<String, BookDetails> parsedBooks = {};

    // Adjust defaultStartPage logic
    int defaultStartPage = _asString(json['content_type']) == "דף" ? 2 : 1;

    rawData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedBooks[key] = BookDetails.fromJson(
          value,
          contentType: _asString(json['content_type']),
          columns: _asListString(json['columns']),
          startPage: defaultStartPage, // Use the new defaultStartPage logic
          isCustom: isCustom, // Pass isCustom
        );
      }
    });

    return BookCategory(
      name: _asString(json['name']),
      contentType: _asString(json['content_type']),
      columns: _asListString(json['columns']),
      books: parsedBooks,
      defaultStartPage: defaultStartPage, // Use the new defaultStartPage logic
      isCustom: isCustom, // Pass isCustom
      sourceFile: sourceFile, // Pass sourceFile
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
  final bool isCustom;
  final String? id; // Added id field

  BookDetails({
    required this.pages,
    required this.contentType,
    required this.columns,
    required this.startPage,
    this.isCustom = false, // Default value for isCustom
    this.id, // Added id to constructor
  });

  factory BookDetails.fromJson(
    Map<String, dynamic> json, {
    required String contentType,
    required List<String> columns,
    required int startPage,
    bool isCustom = false,
    String? id, // Added id to factory parameters
  }) {
    return BookDetails(
      pages: _asInt(json['pages']),
      contentType: contentType,
      columns: columns,
      startPage: startPage,
      isCustom: isCustom,
      id: id, // Passed id to constructor
    );
  }

  bool get isDafType => contentType == "דף";
}
