String _asString(dynamic value) => value is String ? value : '';
int _asInt(dynamic value) =>
    value is int ? value : (value is String ? (int.tryParse(value) ?? 0) : 0);
num _asNum(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

class BookSearchResult {
  final BookDetails bookDetails;
  final String categoryName;
  final BookCategory category;

  BookSearchResult(this.bookDetails, this.categoryName, this.category);
}

class BookCategory {
  final String name;
  final String contentType;
  final Map<String, BookDetails> books;
  final int defaultStartPage;
  final bool isCustom;
  final String sourceFile;
  final List<BookCategory>? subcategories;
  final String? parentCategoryName;

  BookCategory({
    required this.name,
    required this.contentType,
    required this.books,
    required this.defaultStartPage,
    required this.isCustom,
    required this.sourceFile,
    this.subcategories,
    this.parentCategoryName,
  });

  factory BookCategory.fromJson(Map<String, dynamic> json, String sourceFile,
      {bool isCustom = false, String? parentCategoryName}) {
    Map<String, dynamic> rawData = _asMap(json['books'] ?? json['data']);
    Map<String, BookDetails> parsedBooks = {};

    int defaultStartPage = _asString(json['content_type']) == "דף" ? 2 : 1;

    rawData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedBooks[key] = BookDetails.fromJson(
          value,
          contentType: _asString(json['content_type']),
          isCustom: isCustom,
        );
      }
    });

    List<BookCategory>? subcategories;
    if (json['subcategories'] is List) {
      subcategories = (json['subcategories'] as List)
          .map((subJson) => BookCategory.fromJson(
                _asMap(subJson),
                sourceFile,
                isCustom: isCustom,
                parentCategoryName: _asString(json['name']),
              ))
          .toList();
    }

    return BookCategory(
      name: _asString(json['name']),
      contentType: _asString(json['content_type']),
      books: parsedBooks,
      defaultStartPage: defaultStartPage,
      isCustom: isCustom,
      sourceFile: sourceFile,
      subcategories: subcategories,
      parentCategoryName: parentCategoryName,
    );
  }

  BookSearchResult? findBookRecursive(String bookNameToFind) {
    if (books.containsKey(bookNameToFind)) {
      return BookSearchResult(books[bookNameToFind]!, name, this);
    }
    if (subcategories != null) {
      for (final subCategory in subcategories!) {
        final result = subCategory.findBookRecursive(bookNameToFind);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }
}

class LearnableItem {
  final String partName;
  final int pageNumber;
  final String amudKey;
  final int absoluteIndex;

  LearnableItem({
    required this.partName,
    required this.pageNumber,
    required this.amudKey,
    required this.absoluteIndex,
  });
}

class BookPart {
  final String name;
  final int startPage;
  final int endPage;
  final List<int> excludedPages;
  final bool hasHalfPageAtEnd;

  BookPart({
    required this.name,
    required this.startPage,
    required this.endPage,
    this.excludedPages = const [],
    this.hasHalfPageAtEnd = false,
  });

  factory BookPart.fromJson(Map<String, dynamic> json) {
    return BookPart(
      name: _asString(json['name']),
      startPage: _asInt(json['start']),
      endPage: _asInt(json['end']),
      excludedPages:
          (json['exclude'] as List<dynamic>?)?.map((e) => _asInt(e)).toList() ??
              [],
    );
  }
}

class BookDetails {
  final String contentType;
  final bool isCustom;
  final String? id;
  final List<BookPart> parts;
  final num? originalPageCount;

  List<LearnableItem>? _learnableItemsCache;

  BookDetails({
    required this.contentType,
    required this.parts,
    this.isCustom = false,
    this.id,
    this.originalPageCount,
  });

  factory BookDetails.fromJson(
    Map<String, dynamic> json, {
    required String contentType,
    bool isCustom = false,
    String? id,
  }) {
    List<BookPart> parts = [];
    num? pageCount;

    if (json['parts'] is List) {
      parts = (json['parts'] as List)
          .map((partJson) => BookPart.fromJson(_asMap(partJson)))
          .toList();
    } else if (json.containsKey('pages')) {
      pageCount = _asNum(json['pages']);
      int startPage =
          _asInt(json['startPage'] ?? (contentType == "דף" ? 2 : 1));

      int endPage;
      bool lastPageIsHalf = false;

      if (contentType == "דף") {
        endPage = startPage + pageCount.ceil() - 1;
        if (pageCount.floor() != pageCount) {
          lastPageIsHalf = true;
        }
      } else {
        endPage = startPage + pageCount.toInt() - 1;
      }

      parts.add(BookPart(
        name: "ראשי",
        startPage: startPage,
        endPage: endPage,
        hasHalfPageAtEnd: lastPageIsHalf,
      ));
    }

    return BookDetails(
      contentType: contentType,
      parts: parts,
      isCustom: isCustom,
      id: id,
      originalPageCount: pageCount,
    );
  }

  num get pageCountForDisplay {
    if (originalPageCount != null) {
      return originalPageCount!;
    }
    if (parts.isEmpty) return 0;

    // Fallback for older data structures
    return parts
        .map((p) => p.endPage - p.startPage + 1)
        .reduce((a, b) => a + b);
  }

  bool get isDafType => contentType == "דף";

  List<LearnableItem> get learnableItems {
    if (_learnableItemsCache != null) return _learnableItemsCache!;

    final List<LearnableItem> items = [];
    int currentIndex = 0;
    for (final part in parts) {
      for (int i = part.startPage; i <= part.endPage; i++) {
        if (part.excludedPages.contains(i)) {
          continue;
        }

        if (isDafType) {
          items.add(LearnableItem(
              partName: part.name,
              pageNumber: i,
              amudKey: 'a',
              absoluteIndex: currentIndex++));

          if (!(part.hasHalfPageAtEnd && i == part.endPage)) {
            items.add(LearnableItem(
                partName: part.name,
                pageNumber: i,
                amudKey: 'b',
                absoluteIndex: currentIndex++));
          }
        } else {
          items.add(LearnableItem(
              partName: part.name,
              pageNumber: i,
              amudKey: 'a',
              absoluteIndex: currentIndex++));
        }
      }
    }
    _learnableItemsCache = items;
    return items;
  }

  int get totalLearnableItems => learnableItems.length;

  bool get hasMultipleParts => parts.length > 1;
}
