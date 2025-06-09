import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/progress_model.dart';
import '../models/book_model.dart';
import '../services/progress_service.dart';
import './data_provider.dart';

enum CompletionEventType {
  bookCompleted,
  reviewCycleCompleted,
}

class CompletionEvent {
  final CompletionEventType type;
  final String? bookName;
  final int? reviewCycleNumber;

  CompletionEvent(this.type, {this.bookName, this.reviewCycleNumber});
}

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  FullProgressMap _fullProgress = {};
  CompletionDatesMap _completionDates = {};

  static const String learnColumn = 'learn';
  static const String review1Column = 'review1';
  static const String review2Column = 'review2';
  static const String review3Column = 'review3';
  static const List<String> allColumnNames = [
    learnColumn,
    review1Column,
    review2Column,
    review3Column
  ];

  final _completionEventController =
      StreamController<CompletionEvent>.broadcast();
  Stream<CompletionEvent> get completionEvents =>
      _completionEventController.stream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ProgressProvider() {
    _loadInitialProgress();
  }

  Future<void> _loadInitialProgress() async {
    _isLoading = true;
    notifyListeners();

    _fullProgress = await _progressService.loadFullProgressData();
    _completionDates = await _progressService.loadCompletionDates();
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> backupProgress() async {
    try {
      return await _progressService.exportProgressData();
    } catch (e) {
      print("Error during backupProgress in Provider: $e");
      return null;
    }
  }

  Future<bool> restoreProgress(
      String jsonData, DataProvider dataProvider) async {
    try {
      bool importSuccess = await _progressService.importProgressData(jsonData);
      if (importSuccess) {
        // The service layer correctly restored all data (progress, completion, custom books)
        // to SharedPreferences. Now we need to tell the providers to reload their state
        // from SharedPreferences.

        // 1. Reload book data (including the restored custom books) in DataProvider.
        await dataProvider.loadAllData();

        // 2. Reload progress data in this ProgressProvider.
        await _loadInitialProgress();
      }
      return importSuccess;
    } catch (e) {
      print("Error during restoreProgress in ProgressProvider: $e");
      return false;
    }
  }

  Map<String, Map<String, PageProgress>> getProgressForBook(
      String categoryName, String bookName) {
    return _fullProgress[categoryName]?[bookName] ?? {};
  }

  PageProgress getProgressForPageAmud(
      String categoryName, String bookName, String pageStr, String amudKey) {
    return _fullProgress[categoryName]?[bookName]?[pageStr]?[amudKey] ??
        PageProgress();
  }

  Future<void> updateProgress(String categoryName, String bookName, int daf,
      String amudKey, String columnName, bool value, BookDetails bookDetails,
      {bool isBulkUpdate = false}) async {
    await _progressService.saveProgress(
        categoryName, bookName, daf, amudKey, columnName, value);

    _fullProgress.putIfAbsent(categoryName, () => {});
    _fullProgress[categoryName]!.putIfAbsent(bookName, () => {});
    _fullProgress[categoryName]![bookName]!
        .putIfAbsent(daf.toString(), () => {});
    _fullProgress[categoryName]![bookName]![daf.toString()]!
        .putIfAbsent(amudKey, () => PageProgress());

    PageProgress pageProgress =
        _fullProgress[categoryName]![bookName]![daf.toString()]![amudKey]!;
    switch (columnName) {
      case 'learn':
        pageProgress.learn = value;
        break;
      case 'review1':
        pageProgress.review1 = value;
        break;
      case 'review2':
        pageProgress.review2 = value;
        break;
      case 'review3':
        pageProgress.review3 = value;
        break;
    }

    if (pageProgress.isEmpty) {
      _fullProgress[categoryName]![bookName]![daf.toString()]!.remove(amudKey);
      if (_fullProgress[categoryName]![bookName]![daf.toString()]!.isEmpty) {
        _fullProgress[categoryName]![bookName]!.remove(daf.toString());
        if (_fullProgress[categoryName]![bookName]!.isEmpty) {
          _fullProgress[categoryName]!.remove(bookName);
          if (_fullProgress[categoryName]!.isEmpty) {
            _fullProgress.remove(categoryName);
          }
        }
      }
    }

    if (value && columnName == 'learn') {
      bool wasAlreadyCompleted =
          getCompletionDateSync(categoryName, bookName) != null;
      bool isNowComplete = isBookCompleted(categoryName, bookName, bookDetails);

      if (isNowComplete && !wasAlreadyCompleted && !isBulkUpdate) {
        await _progressService.saveCompletionDate(categoryName, bookName);
        _completionDates = await _progressService.loadCompletionDates();
        _completionEventController.add(CompletionEvent(
            CompletionEventType.bookCompleted,
            bookName: bookName));
      }
    } else if (value &&
        (columnName == 'review1' ||
            columnName == 'review2' ||
            columnName == 'review3') &&
        !isBulkUpdate) {
      int? reviewCycleNumber;
      if (columnName == 'review1') {
        reviewCycleNumber = 1;
      } else if (columnName == 'review2') {
        reviewCycleNumber = 2;
      } else if (columnName == 'review3') {
        reviewCycleNumber = 3;
      }

      if (reviewCycleNumber != null) {
        bool cycleJustCompleted = _isReviewCycleCompleted(
            categoryName, bookName, reviewCycleNumber, bookDetails);

        if (cycleJustCompleted) {
          _completionEventController.add(CompletionEvent(
            CompletionEventType.reviewCycleCompleted,
            bookName: bookName,
            reviewCycleNumber: reviewCycleNumber,
          ));
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _completionEventController.close();
    super.dispose();
  }

  Future<void> toggleSelectAll(String categoryName, String bookName,
      BookDetails bookDetails, bool markAsLearned) async {
    await _progressService.saveAllMasechta(
        categoryName, bookName, bookDetails, markAsLearned);
    await _loadInitialProgress();
  }

  String? getCompletionDateSync(String categoryName, String bookName) {
    return _completionDates[categoryName]?[bookName];
  }

  Future<String?> getCompletionDateAsync(
      String categoryName, String bookName) async {
    return _completionDates[categoryName]?[bookName] ??
        await _progressService.getCompletionDate(categoryName, bookName);
  }

  bool isBookCompleted(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetPages =
        bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;
    if (totalTargetPages == 0) return false;

    int learnedPagesCount =
        ProgressService.getCompletedPagesCount(bookProgress);
    return learnedPagesCount >= totalTargetPages;
  }

  bool _isReviewCycleCompleted(
    String categoryName,
    String bookName,
    int reviewCycleNumber,
    BookDetails bookDetails,
  ) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    if (bookProgress.isEmpty && bookDetails.pages > 0) return false;

    final totalItems =
        bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;
    if (totalItems == 0) return false;

    int completedItemsInCycle = 0;

    for (int i = 0; i < bookDetails.pages; i++) {
      final pageNumber = bookDetails.startPage + i;
      final List<String> amudKeys = bookDetails.isDafType ? ['a', 'b'] : ['a'];

      for (String amudKey in amudKeys) {
        final pageProgress = getProgressForPageAmud(
            categoryName, bookName, pageNumber.toString(), amudKey);

        bool isItemCompletedInCycle = false;
        switch (reviewCycleNumber) {
          case 1:
            isItemCompletedInCycle = pageProgress.review1;
            break;
          case 2:
            isItemCompletedInCycle = pageProgress.review2;
            break;
          case 3:
            isItemCompletedInCycle = pageProgress.review3;
            break;
          default:
            return false;
        }
        if (isItemCompletedInCycle) {
          completedItemsInCycle++;
        }
      }
    }
    return completedItemsInCycle >= totalItems;
  }

  List<Map<String, dynamic>> getTrackedBooks(
      Map<String, BookCategory> allBookData) {
    List<Map<String, dynamic>> tracked = [];
    Set<String> processedBookKeys = {};

    _fullProgress.forEach((topLevelCategoryKey, booksProgressMap) {
      print(
          "[ProgressProvider] getTrackedBooks: Processing topLevelCategoryKey: $topLevelCategoryKey");
      final topLevelCategoryObject = allBookData[topLevelCategoryKey];
      if (topLevelCategoryObject == null) {
        if (kDebugMode) {
          print(
              "Error: Top-level category '$topLevelCategoryKey' not found in allBookData.");
        }
        print(
            "[ProgressProvider] WARN: Top-level category '$topLevelCategoryKey' not found in allBookData.");
        return;
      }

      booksProgressMap.forEach((bookNameFromProgress, progressDataForBook) {
        print(
            "  [ProgressProvider] Processing book: $bookNameFromProgress under $topLevelCategoryKey");
        final searchResult =
            topLevelCategoryObject.findBookRecursive(bookNameFromProgress);
        if (searchResult == null) {
          print(
              "    [ProgressProvider] WARN: Book '$bookNameFromProgress' not found via findBookRecursive in '$topLevelCategoryKey'.");
        } else {
          print(
              "    [ProgressProvider] Found book: ID (usually bookName for non-custom) '$bookNameFromProgress' in category '${searchResult.categoryName}'. Display name: ${searchResult.categoryName}");

          final String uniqueKey =
              '$topLevelCategoryKey-${searchResult.categoryName}-$bookNameFromProgress';
          if (!processedBookKeys.contains(uniqueKey)) {
            tracked.add({
              'topLevelCategoryKey': topLevelCategoryKey,
              'displayCategoryName': searchResult.categoryName,
              'bookName': bookNameFromProgress,
              'bookDetails': searchResult.bookDetails,
              'progressData': progressDataForBook,
            });
            processedBookKeys.add(uniqueKey);
          }
        }
      });
    });

    _completionDates.forEach((topLevelCategoryKey, booksCompletionMap) {
      print(
          "[ProgressProvider] getTrackedBooks: Processing topLevelCategoryKey from _completionDates: $topLevelCategoryKey");
      final topLevelCategoryObject = allBookData[topLevelCategoryKey];
      if (topLevelCategoryObject == null) {
        if (kDebugMode) {
          print(
              "Error: Top-level category '$topLevelCategoryKey' from completionDates not found in allBookData.");
        }
        print(
            "[ProgressProvider] WARN: Top-level category '$topLevelCategoryKey' from completionDates not found in allBookData.");
        return;
      }

      booksCompletionMap.forEach((bookNameFromCompletion, completionDate) {
        print(
            "  [ProgressProvider] Processing completed book: $bookNameFromCompletion under $topLevelCategoryKey");
        final searchResult =
            topLevelCategoryObject.findBookRecursive(bookNameFromCompletion);
        if (searchResult == null) {
          print(
              "    [ProgressProvider] WARN: Completed book '$bookNameFromCompletion' not found via findBookRecursive in '$topLevelCategoryKey'.");
        } else {
          print(
              "    [ProgressProvider] Found completed book: ID (usually bookName) '$bookNameFromCompletion' in category '${searchResult.categoryName}'. Display name: ${searchResult.categoryName}");
          final String uniqueKey =
              '$topLevelCategoryKey-${searchResult.categoryName}-$bookNameFromCompletion';

          if (!processedBookKeys.contains(uniqueKey)) {
            tracked.add({
              'topLevelCategoryKey': topLevelCategoryKey,
              'displayCategoryName': searchResult.categoryName,
              'bookName': bookNameFromCompletion,
              'bookDetails': searchResult.bookDetails,
              'progressData': getProgressForBook(
                  topLevelCategoryKey, bookNameFromCompletion),
              'completionDate': completionDate,
            });
            processedBookKeys.add(uniqueKey);
          } else {
            final existingEntry = tracked.firstWhere((item) =>
                item['topLevelCategoryKey'] == topLevelCategoryKey &&
                item['displayCategoryName'] == searchResult.categoryName &&
                item['bookName'] == bookNameFromCompletion);
            existingEntry['completionDate'] = completionDate;
          }
        }
      });
    });
    print(
        "[ProgressProvider] getTrackedBooks: Returning ${tracked.length} tracked items.");
    return tracked;
  }

  Future<void> toggleSelectAllForColumn(
    String categoryName,
    String bookName,
    BookDetails bookDetails,
    String columnName,
    bool select,
  ) async {
    if (!allColumnNames.contains(columnName)) {
      if (kDebugMode) {
        print("Invalid column name: $columnName");
      }
      return;
    }

    _fullProgress.putIfAbsent(categoryName, () => {});
    _fullProgress[categoryName]!.putIfAbsent(bookName, () => {});
    final bookProgress = _fullProgress[categoryName]![bookName]!;

    for (int i = 0; i < bookDetails.pages; i++) {
      final pageNumber = bookDetails.startPage + i;
      final pageStr = pageNumber.toString();
      final List<String> amudKeys = bookDetails.isDafType ? ['a', 'b'] : ['a'];

      for (String amudKey in amudKeys) {
        bookProgress.putIfAbsent(pageStr, () => {});
        bookProgress[pageStr]!.putIfAbsent(amudKey, () => PageProgress());

        await updateProgress(
          categoryName,
          bookName,
          pageNumber,
          amudKey,
          columnName,
          select,
          bookDetails,
          isBulkUpdate: true,
        );
      }
    }

    notifyListeners();
  }

  Map<String, bool?> getColumnSelectionStates(
    String categoryName,
    String bookName,
    BookDetails? bookDetails,
  ) {
    Map<String, bool?> columnStates = {
      learnColumn: null,
      review1Column: null,
      review2Column: null,
      review3Column: null,
    };

    if (bookDetails == null) {
      return columnStates;
    }

    final bookProgress = _fullProgress[categoryName]?[bookName];
    final totalItems =
        bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;

    if (totalItems == 0) {
      columnStates.updateAll((key, value) => false);
      return columnStates;
    }

    for (String currentColumnName in allColumnNames) {
      bool allSelectedInColumn = true;
      bool noneSelectedInColumn = true;

      if (bookProgress == null || bookProgress.isEmpty) {
        allSelectedInColumn = false;
      } else {
        int itemsChecked = 0;
        for (int i = 0; i < bookDetails.pages; i++) {
          final pageNumber = bookDetails.startPage + i;
          final pageStr = pageNumber.toString();
          final List<String> amudKeys =
              bookDetails.isDafType ? ['a', 'b'] : ['a'];

          for (String amudKey in amudKeys) {
            final pageAmudProgress = bookProgress[pageStr]?[amudKey];
            bool itemSelected =
                pageAmudProgress?.getProperty(currentColumnName) ?? false;

            if (itemSelected) {
              noneSelectedInColumn = false;
              itemsChecked++;
            } else {
              allSelectedInColumn = false;
            }
          }
        }

        if (itemsChecked == 0 && totalItems > 0) {
          noneSelectedInColumn = true;
          allSelectedInColumn = false;
        } else if (itemsChecked == totalItems) {
          allSelectedInColumn = true;
          noneSelectedInColumn = false;
        } else {
          allSelectedInColumn = false;
          noneSelectedInColumn = false;
        }
      }

      if (allSelectedInColumn && totalItems > 0) {
        columnStates[currentColumnName] = true;
      } else if (noneSelectedInColumn) {
        columnStates[currentColumnName] = false;
      } else {
        columnStates[currentColumnName] = null;
      }
    }
    return columnStates;
  }

  double getLearnProgressPercentage(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetPages =
        bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;

    int learnedPagesCount =
        ProgressService.getCompletedPagesCount(bookProgress);

    print("[ProgressProvider LPP] Book: $bookName ($categoryName)");
    print(
        "  LPP Details: isDafType=${bookDetails.isDafType}, pages=${bookDetails.pages}, totalTargetPages=$totalTargetPages");
    print("  LPP Progress: learnedPagesCount=$learnedPagesCount");
    if (totalTargetPages == 0) {
      print("  LPP WARN: totalTargetPages is 0, will return 0.0");
      return 0.0;
    }
    return learnedPagesCount / totalTargetPages;
  }

  double getReview1ProgressPercentage(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetPages =
        bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;

    int review1PagesCount =
        ProgressService.getReview1CompletedPagesCount(bookProgress);

    print("[ProgressProvider R1PP] Book: $bookName ($categoryName)");
    print(
        "  R1PP Details: isDafType=${bookDetails.isDafType}, pages=${bookDetails.pages}, totalTargetPages=$totalTargetPages");
    print("  R1PP Progress: review1PagesCount=$review1PagesCount");
    if (totalTargetPages == 0) {
      print("  R1PP WARN: totalTargetPages is 0, will return 0.0");
      return 0.0;
    }
    return review1PagesCount / totalTargetPages;
  }

  double getReview2ProgressPercentage(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetPages =
        bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;
    if (totalTargetPages == 0) return 0.0;

    int review2PagesCount =
        ProgressService.getReview2CompletedPagesCount(bookProgress);
    return review2PagesCount / totalTargetPages;
  }

  double getReview3ProgressPercentage(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetPages =
        bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;
    if (totalTargetPages == 0) return 0.0;

    int review3PagesCount =
        ProgressService.getReview3CompletedPagesCount(bookProgress);
    return review3PagesCount / totalTargetPages;
  }

  int getNumberOfCompletedCycles(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetPages =
        bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;
    if (totalTargetPages == 0) return 0;

    int cycles = 0;
    if (ProgressService.getCompletedPagesCount(bookProgress) >=
        totalTargetPages) {
      cycles++;
    }
    if (ProgressService.getReview1CompletedPagesCount(bookProgress) >=
        totalTargetPages) {
      cycles++;
    }
    if (ProgressService.getReview2CompletedPagesCount(bookProgress) >=
        totalTargetPages) {
      cycles++;
    }
    if (ProgressService.getReview3CompletedPagesCount(bookProgress) >=
        totalTargetPages) {
      cycles++;
    }
    return cycles;
  }

  bool isBookInActiveReview(
      String categoryName, String bookName, BookDetails bookDetails) {
    if (!isBookCompleted(categoryName, bookName, bookDetails)) {
      return false;
    }

    double r1Prog =
        getReview1ProgressPercentage(categoryName, bookName, bookDetails);
    double r2Prog =
        getReview2ProgressPercentage(categoryName, bookName, bookDetails);
    double r3Prog =
        getReview3ProgressPercentage(categoryName, bookName, bookDetails);

    bool r1Active = r1Prog > 0 && r1Prog < 1.0;
    bool r2Active = r1Prog == 1.0 && r2Prog > 0 && r2Prog < 1.0;
    bool r3Active =
        r1Prog == 1.0 && r2Prog == 1.0 && r3Prog > 0 && r3Prog < 1.0;

    return r1Active || r2Active || r3Active;
  }

  bool isBookConsideredInProgress(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgressData = getProgressForBook(categoryName, bookName);
    if (bookProgressData.isEmpty) {
      return false;
    }

    double learnProgress =
        getLearnProgressPercentage(categoryName, bookName, bookDetails);
    double review1Progress =
        getReview1ProgressPercentage(categoryName, bookName, bookDetails);
    double review2Progress =
        getReview2ProgressPercentage(categoryName, bookName, bookDetails);
    double review3Progress =
        getReview3ProgressPercentage(categoryName, bookName, bookDetails);

    if (learnProgress > 0 && learnProgress < 1.0) {
      return true;
    }
    if (learnProgress == 1.0 && review1Progress > 0 && review1Progress < 1.0) {
      return true;
    }
    if (learnProgress == 1.0 &&
        review1Progress == 1.0 &&
        review2Progress > 0 &&
        review2Progress < 1.0) {
      return true;
    }
    if (learnProgress == 1.0 &&
        review1Progress == 1.0 &&
        review2Progress == 1.0 &&
        review3Progress > 0 &&
        review3Progress < 1.0) {
      return true;
    }

    return false;
  }
}
