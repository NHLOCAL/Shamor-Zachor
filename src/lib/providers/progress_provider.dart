import 'package:flutter/foundation.dart';
import '../models/progress_model.dart';
import '../models/book_model.dart';
import '../services/progress_service.dart';

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService; // Changed: no direct instantiation
  FullProgressMap _fullProgress = {};
  CompletionDatesMap _completionDates = {}; // Cache completion dates
  Map<String, String>? justManuallyCompletedBook;
  Map<String, dynamic>? justCompletedReviewDetails; 
  // Will store {'category': String, 'book': String, 'reviewType': String}

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ProgressProvider({ProgressService? progressService}) // Changed: constructor takes optional service
      : _progressService = progressService ?? ProgressService() { // Changed: initializer list
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
    // The wasCompletedBeforeUpdate logic is now part of the new block below.

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

    // Start of new flag logic block
    // Ensure 'bookDetails' is available and non-null in this scope.
    // The method signature is: updateProgress(..., BookDetails bookDetails)

    // 1. Handle Main Book Completion ('learn' column)
    if (columnName == 'learn') {
      // Store the actual current value of pageProgress.learn (which is 'value')
      bool currentItemLearnStatus = pageProgress.learn; 

      // Temporarily set item's learn status to its opposite to check 'before' state
      pageProgress.learn = !currentItemLearnStatus; 
      bool wasBookCompletedBeforeThis = isBookCompleted(categoryName, bookName, bookDetails);
      
      // Restore item's actual current learn status
      pageProgress.learn = currentItemLearnStatus; 

      if (value == true) { // Current action is marking 'learn' as true
        bool isBookNowCompleted = isBookCompleted(categoryName, bookName, bookDetails);
        if (isBookNowCompleted && !wasBookCompletedBeforeThis) {
          justManuallyCompletedBook = {'category': categoryName, 'book': bookName};
        } else {
          justManuallyCompletedBook = null; // Not newly completed or was already complete
        }
      } else { // Current action is marking 'learn' as false
        justManuallyCompletedBook = null;
      }
      // A 'learn' action should clear any pending review completion flag
      justCompletedReviewDetails = null; 
    }
    // 2. Handle Review Type Completion ('review1', 'review2', 'review3' columns)
    else if (columnName == 'review1' || columnName == 'review2' || columnName == 'review3') {
      // Store the actual current value of the specific review status
      bool currentItemReviewStatus = false;
      switch(columnName) {
        case 'review1': currentItemReviewStatus = pageProgress.review1; break;
        case 'review2': currentItemReviewStatus = pageProgress.review2; break;
        case 'review3': currentItemReviewStatus = pageProgress.review3; break;
      }

      // Temporarily set item's review status to its opposite to check 'before' state
      switch(columnName) {
        case 'review1': pageProgress.review1 = !currentItemReviewStatus; break;
        case 'review2': pageProgress.review2 = !currentItemReviewStatus; break;
        case 'review3': pageProgress.review3 = !currentItemReviewStatus; break;
      }
      bool wasReviewTypeCompletedBeforeThis = isReviewTypeCompleted(categoryName, bookName, columnName, bookDetails);
      
      // Restore item's actual current review status
      switch(columnName) {
        case 'review1': pageProgress.review1 = currentItemReviewStatus; break;
        case 'review2': pageProgress.review2 = currentItemReviewStatus; break;
        case 'review3': pageProgress.review3 = currentItemReviewStatus; break;
      }

      if (value == true) { // Current action is marking a review as true
        bool isReviewTypeNowCompleted = isReviewTypeCompleted(categoryName, bookName, columnName, bookDetails);
        if (isReviewTypeNowCompleted && !wasReviewTypeCompletedBeforeThis) {
          justCompletedReviewDetails = {
            'category': categoryName,
            'book': bookName,
            'reviewType': columnName,
          };
        } else {
          justCompletedReviewDetails = null; // Not newly completed or was already complete
        }
      } else { // Current action is marking a review as false
        justCompletedReviewDetails = null;
      }
      // A review action should clear any pending main book completion flag
      justManuallyCompletedBook = null; 
    }
    // 3. Default: if not 'learn' or a known 'reviewX' column, clear both flags
    else {
      justManuallyCompletedBook = null;
      justCompletedReviewDetails = null;
    }
    // End of new flag logic block

    if (value && columnName == 'learn') {
      bool isNowComplete = isBookCompleted(categoryName, bookName, bookDetails);
      // Check completion date from sync method before attempting to save
      if (isNowComplete &&
          getCompletionDateSync(categoryName, bookName) == null) {
        await _progressService.saveCompletionDate(categoryName, bookName);
        _completionDates = await _progressService.loadCompletionDates();
      }
    }

    notifyListeners();
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

  bool isReviewTypeCompleted(String categoryName, String bookName, String reviewType, BookDetails bookDetails) {
    final bookProgress = getProgressForBook(categoryName, bookName);
    if (bookProgress.isEmpty && bookDetails.pages > 0) return false; // No progress but book has pages

    final totalTargetItems = bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;
    if (totalTargetItems == 0) return false;

    int completedReviewItems = 0;
    bookProgress.forEach((pageStr, amudim) {
      amudim.forEach((amudKey, pageProgress) {
        bool isReviewDone = false;
        switch (reviewType) {
          case 'review1':
            isReviewDone = pageProgress.review1;
            break;
          case 'review2':
            isReviewDone = pageProgress.review2;
            break;
          case 'review3':
            isReviewDone = pageProgress.review3;
            break;
        }
        if (isReviewDone) {
          completedReviewItems++;
        }
      });
    });
    return completedReviewItems >= totalTargetItems;
  }

  void clearJustManuallyCompletedBookFlag() {
    if (justManuallyCompletedBook != null) {
      justManuallyCompletedBook = null;
      // notifyListeners(); // Optional: UI will likely call this after consuming the flag
                         // and then trigger its own rebuild if needed.
                         // Let's include it for now to be safe, can be removed if it causes issues.
                         // Re-thinking: It's better to notify if the state it controls changes.
      notifyListeners();
    }
  }

  void clearJustCompletedReviewDetailsFlag() {
    if (justCompletedReviewDetails != null) {
      justCompletedReviewDetails = null;
      notifyListeners();
    }
  }
}
