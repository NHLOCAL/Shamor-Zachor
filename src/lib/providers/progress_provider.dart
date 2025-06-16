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
        await dataProvider.loadAllData();
        await _loadInitialProgress();
      }
      return importSuccess;
    } catch (e) {
      print("Error during restoreProgress in ProgressProvider: $e");
      return false;
    }
  }

  Map<String, PageProgress> getProgressForBook(
      String categoryName, String bookName) {
    return _fullProgress[categoryName]?[bookName] ?? {};
  }

  PageProgress getProgressForItem(
      String categoryName, String bookName, int absoluteIndex) {
    return _fullProgress[categoryName]?[bookName]?[absoluteIndex.toString()] ??
        PageProgress();
  }

  Future<void> updateProgress(String categoryName, String bookName,
      int absoluteIndex, String columnName, bool value, BookDetails bookDetails,
      {bool isBulkUpdate = false}) async {
    final itemIndexKey = absoluteIndex.toString();
    await _progressService.saveProgress(
        categoryName, bookName, itemIndexKey, columnName, value);

    _fullProgress.putIfAbsent(categoryName, () => {});
    _fullProgress[categoryName]!.putIfAbsent(bookName, () => {});
    _fullProgress[categoryName]![bookName]!
        .putIfAbsent(itemIndexKey, () => PageProgress());

    PageProgress pageProgress =
        _fullProgress[categoryName]![bookName]![itemIndexKey]!;
    pageProgress.setProperty(columnName, value);

    if (pageProgress.isEmpty) {
      _fullProgress[categoryName]![bookName]!.remove(itemIndexKey);
      if (_fullProgress[categoryName]![bookName]!.isEmpty) {
        _fullProgress[categoryName]!.remove(bookName);
        if (_fullProgress[categoryName]!.isEmpty) {
          _fullProgress.remove(categoryName);
        }
      }
    }

    if (value && !isBulkUpdate) {
      if (columnName == 'learn') {
        bool wasAlreadyCompleted =
            getCompletionDateSync(categoryName, bookName) != null;
        bool isNowComplete =
            isBookCompleted(categoryName, bookName, bookDetails);

        if (isNowComplete && !wasAlreadyCompleted) {
          await _progressService.saveCompletionDate(categoryName, bookName);
          _completionDates = await _progressService.loadCompletionDates();
          _completionEventController.add(CompletionEvent(
              CompletionEventType.bookCompleted,
              bookName: bookName));
        }
      } else if (columnName.startsWith('review')) {
        int? reviewCycleNumber;
        if (columnName == 'review1')
          reviewCycleNumber = 1;
        else if (columnName == 'review2')
          reviewCycleNumber = 2;
        else if (columnName == 'review3') reviewCycleNumber = 3;

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
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _completionEventController.close();
    super.dispose();
  }

  String? getCompletionDateSync(String categoryName, String bookName) {
    return _completionDates[categoryName]?[bookName];
  }

  bool isBookCompleted(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetItems = bookDetails.totalLearnableItems;
    if (totalTargetItems == 0) return false;

    int learnedItemsCount =
        ProgressService.getCompletedPagesCount(bookProgress);
    return learnedItemsCount >= totalTargetItems;
  }

  bool _isReviewCycleCompleted(
    String categoryName,
    String bookName,
    int reviewCycleNumber,
    BookDetails bookDetails,
  ) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalItems = bookDetails.totalLearnableItems;
    if (totalItems == 0 || bookProgress.isEmpty) return false;

    int completedItemsInCycle = 0;

    bookProgress.forEach((itemIndexKey, pageProgress) {
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
      }
      if (isItemCompletedInCycle) {
        completedItemsInCycle++;
      }
    });

    return completedItemsInCycle >= totalItems;
  }

  List<Map<String, dynamic>> getTrackedBooks(
      Map<String, BookCategory> allBookData) {
    List<Map<String, dynamic>> tracked = [];
    Set<String> processedBookKeys = {};

    _fullProgress.forEach((topLevelCategoryKey, booksProgressMap) {
      final topLevelCategoryObject = allBookData[topLevelCategoryKey];
      if (topLevelCategoryObject == null) {
        return;
      }
      booksProgressMap.forEach((bookNameFromProgress, progressDataForBook) {
        final searchResult =
            topLevelCategoryObject.findBookRecursive(bookNameFromProgress);
        if (searchResult != null) {
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
      final topLevelCategoryObject = allBookData[topLevelCategoryKey];
      if (topLevelCategoryObject == null) {
        return;
      }
      booksCompletionMap.forEach((bookNameFromCompletion, completionDate) {
        final searchResult =
            topLevelCategoryObject.findBookRecursive(bookNameFromCompletion);
        if (searchResult != null) {
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
      return;
    }

    for (final item in bookDetails.learnableItems) {
      await updateProgress(
        categoryName,
        bookName,
        item.absoluteIndex,
        columnName,
        select,
        bookDetails,
        isBulkUpdate: true,
      );
    }

    if (select && columnName == 'learn') {
      bool wasAlreadyCompleted =
          getCompletionDateSync(categoryName, bookName) != null;
      bool isNowComplete = isBookCompleted(categoryName, bookName, bookDetails);
      if (isNowComplete && !wasAlreadyCompleted) {
        await _progressService.saveCompletionDate(categoryName, bookName);
        _completionDates = await _progressService.loadCompletionDates();
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

    if (bookDetails == null) return columnStates;

    final bookProgress = _fullProgress[categoryName]?[bookName];
    final totalItems = bookDetails.totalLearnableItems;
    if (totalItems == 0) {
      columnStates.updateAll((key, value) => false);
      return columnStates;
    }

    for (String currentColumnName in allColumnNames) {
      int itemsChecked = 0;
      if (bookProgress != null) {
        bookDetails.learnableItems.forEach((item) {
          final itemProgress = bookProgress[item.absoluteIndex.toString()];
          if (itemProgress?.getProperty(currentColumnName) ?? false) {
            itemsChecked++;
          }
        });
      }

      if (itemsChecked == 0) {
        columnStates[currentColumnName] = false;
      } else if (itemsChecked == totalItems) {
        columnStates[currentColumnName] = true;
      } else {
        columnStates[currentColumnName] = null;
      }
    }
    return columnStates;
  }

  double getLearnProgressPercentage(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetItems = bookDetails.totalLearnableItems;
    if (totalTargetItems == 0) return 0.0;

    int learnedPagesCount =
        ProgressService.getCompletedPagesCount(bookProgress);
    return learnedPagesCount / totalTargetItems;
  }

  double getReview1ProgressPercentage(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetItems = bookDetails.totalLearnableItems;
    if (totalTargetItems == 0) return 0.0;

    int review1PagesCount =
        ProgressService.getReview1CompletedPagesCount(bookProgress);
    return review1PagesCount / totalTargetItems;
  }

  double getReview2ProgressPercentage(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetItems = bookDetails.totalLearnableItems;
    if (totalTargetItems == 0) return 0.0;

    int review2PagesCount =
        ProgressService.getReview2CompletedPagesCount(bookProgress);
    return review2PagesCount / totalTargetItems;
  }

  double getReview3ProgressPercentage(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetItems = bookDetails.totalLearnableItems;
    if (totalTargetItems == 0) return 0.0;

    int review3PagesCount =
        ProgressService.getReview3CompletedPagesCount(bookProgress);
    return review3PagesCount / totalTargetItems;
  }

  int getNumberOfCompletedCycles(
      String categoryName, String bookName, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    final totalTargetItems = bookDetails.totalLearnableItems;
    if (totalTargetItems == 0) return 0;

    int cycles = 0;
    if (ProgressService.getCompletedPagesCount(bookProgress) >=
        totalTargetItems) cycles++;
    if (ProgressService.getReview1CompletedPagesCount(bookProgress) >=
        totalTargetItems) cycles++;
    if (ProgressService.getReview2CompletedPagesCount(bookProgress) >=
        totalTargetItems) cycles++;
    if (ProgressService.getReview3CompletedPagesCount(bookProgress) >=
        totalTargetItems) cycles++;
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

    if (learnProgress > 0 && learnProgress < 1.0) return true;
    if (learnProgress == 1.0 && review1Progress > 0 && review1Progress < 1.0)
      return true;
    if (learnProgress == 1.0 &&
        review1Progress == 1.0 &&
        review2Progress > 0 &&
        review2Progress < 1.0) return true;
    if (learnProgress == 1.0 &&
        review1Progress == 1.0 &&
        review2Progress == 1.0 &&
        review3Progress > 0 &&
        review3Progress < 1.0) return true;

    return false;
  }
}
