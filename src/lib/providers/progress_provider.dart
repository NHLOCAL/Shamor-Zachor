import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/progress_model.dart';
import '../models/book_model.dart';
import '../services/progress_service.dart';

enum CompletionEventType {
  bookCompleted,
  reviewCycleCompleted,
}

class CompletionEvent {
  final CompletionEventType type;
  final String? bookName; // Optional: To specify which book
  final int? reviewCycleNumber; // Optional: To specify which review cycle (1, 2, or 3)

  CompletionEvent(this.type, {this.bookName, this.reviewCycleNumber});
}

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  FullProgressMap _fullProgress = {};
  CompletionDatesMap _completionDates = {}; // Cache completion dates

  final _completionEventController = StreamController<CompletionEvent>.broadcast();
  Stream<CompletionEvent> get completionEvents => _completionEventController.stream;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ProgressProvider() {
    _loadInitialProgress();
  }

  Future<void> _loadInitialProgress() async {
    _isLoading = true;
    notifyListeners();
    // Use public methods from ProgressService
    _fullProgress = await _progressService.loadFullProgressData();
    _completionDates = await _progressService.loadCompletionDates();
    _isLoading = false;
    notifyListeners();
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

  Future<void> updateProgress(
      String categoryName,
      String bookName,
      int daf,
      String amudKey,
      String columnName,
      bool value,
      BookDetails bookDetails) async {
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
      bool wasAlreadyCompleted = getCompletionDateSync(categoryName, bookName) != null;
      bool isNowComplete = isBookCompleted(categoryName, bookName, bookDetails);

      if (isNowComplete && !wasAlreadyCompleted) {
        await _progressService.saveCompletionDate(categoryName, bookName);
        _completionDates = await _progressService.loadCompletionDates();
        // Fire event for manual book completion
        _completionEventController.add(CompletionEvent(CompletionEventType.bookCompleted, bookName: bookName));
      }
    } else if (value && (columnName == 'review1' || columnName == 'review2' || columnName == 'review3')) {
      int? reviewCycleNumber;
      if (columnName == 'review1') reviewCycleNumber = 1;
      else if (columnName == 'review2') reviewCycleNumber = 2;
      else if (columnName == 'review3') reviewCycleNumber = 3;

      if (reviewCycleNumber != null) {
        // Check if this specific change led to the completion of the review cycle
        // We assume `updateProgress` has already updated the specific `pageProgress` object in `_fullProgress`
        bool cycleJustCompleted = _isReviewCycleCompleted(categoryName, bookName, reviewCycleNumber, bookDetails);
        
        if (cycleJustCompleted) {
          // To prevent firing multiple times if already completed and another item is checked,
          // ideally we'd check a persisted state (e.g., a completion date for this specific review cycle).
          // For now, based on the request, if checking an item *completes* the cycle, we fire.
          // A simple way to avoid REPEATEDLY firing for a cycle that's already complete
          // is to check if the item *just before this update* was NOT part of a completed cycle.
          // However, the current `_isReviewCycleCompleted` checks the current state.
          // The prompt implies the animation happens when "משתמש מסיים בהצלחה את אחד החזרות".
          // So, if the state *after* the update is "completed", we fire.
          // Consider if we need to prevent firing if the book itself was just completed by 'learn' in the same action.
          // The current structure means a 'learn' completion takes precedence if it happens.
          
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

  // Renamed to getCompletionDateSync to reflect its synchronous nature based on cached data
  String? getCompletionDateSync(String categoryName, String bookName) {
    return _completionDates[categoryName]?[bookName];
  }

  // Kept the async version in case it's needed elsewhere, though UI might prefer sync access
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
      int reviewCycleNumber, // 1, 2, or 3
      BookDetails bookDetails,
  ) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    if (bookProgress.isEmpty && bookDetails.pages > 0) return false;

    final totalItems = bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;
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
            return false; // Invalid review cycle number
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
    _fullProgress.forEach((categoryName, books) {
      books.forEach((bookName, progressData) {
        if (allBookData.containsKey(categoryName) &&
            allBookData[categoryName]!.books.containsKey(bookName)) {
          tracked.add({
            'categoryName': categoryName,
            'bookName': bookName,
            'bookDetails': allBookData[categoryName]!.books[bookName]!,
            'progressData': progressData,
            // 'isLikelyCompleted' will be determined by isBookCompleted or completionDate presence
          });
        }
      });
    });

    _completionDates.forEach((categoryName, books) {
      books.forEach((bookName, date) {
        if (allBookData.containsKey(categoryName) &&
            allBookData[categoryName]!.books.containsKey(bookName)) {
          if (!tracked.any((item) =>
              item['categoryName'] == categoryName &&
              item['bookName'] == bookName)) {
            tracked.add({
              'categoryName': categoryName,
              'bookName': bookName,
              'bookDetails': allBookData[categoryName]!.books[bookName]!,
              'progressData': getProgressForBook(categoryName, bookName),
              // 'isLikelyCompleted': true // This flag can be inferred now
            });
          }
        }
      });
    });
    return tracked;
  }
}
