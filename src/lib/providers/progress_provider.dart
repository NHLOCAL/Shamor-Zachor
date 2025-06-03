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

  // Column Name Constants
  static const String learnColumn = 'learn';
  static const String review1Column = 'review1';
  static const String review2Column = 'review2';
  static const String review3Column = 'review3';
  static const List<String> allColumnNames = [learnColumn, review1Column, review2Column, review3Column];


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

  Future<void> _saveProgress() async {
    // This is a simplified stand-in. The actual implementation might involve
    // iterating _fullProgress and calling _progressService.saveProgress for each modified item,
    // or having a bulk save method in _progressService.
    // For now, we assume _progressService.saveAllMasechta (or a similar method)
    // would be adapted or a new method created in ProgressService to persist _fullProgress.
    // However, the original saveProgress in this class calls the service for individual items.
    // To align with the existing pattern, toggleSelectAllForColumn will call updateProgress internally,
    // which in turn calls _progressService.saveProgress.
    // So, a separate _saveProgress might not be strictly needed here if we structure it that way.
    // Let's assume for now that individual calls to updateProgress handle saving.
    // If a full overwrite save is needed: await _progressService.saveFullProgress(_fullProgress);
    // For now, this method can be a no-op if individual updates handle their own saving.
  }

  Future<void> toggleSelectAllForColumn(
    String categoryName,
    String bookName,
    BookDetails bookDetails,
    String columnName, // e.g., 'learn', 'review1'
    bool select,
  ) async {
    if (!allColumnNames.contains(columnName)) {
      if (kDebugMode) {
        print("Invalid column name: $columnName");
      }
      return;
    }

    // Access the current progress for the book or initialize if it doesn't exist
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
        PageProgress currentAmudProgress = bookProgress[pageStr]![amudKey]!;

        if (select) {
          // Set the target column to true
          currentAmudProgress.setProperty(columnName, true);
          // Set all other progress columns to false for this amud
          for (String col in allColumnNames) {
            if (col != columnName) {
              currentAmudProgress.setProperty(col, false);
            }
          }
        } else {
          // Deselecting: Set the target column to false
          currentAmudProgress.setProperty(columnName, false);
        }
        // Persist change for this specific item (mimicking how updateProgress works)
        // This is less efficient than a bulk save but reuses existing save logic.
        // Consider a bulk save in ProgressService if performance becomes an issue.
        await _progressService.saveProgress(
            categoryName, bookName, pageNumber, amudKey, columnName, currentAmudProgress.getProperty(columnName));
        if (select) { // If we selected one column, others were deselected. Save those too.
            for (String col in allColumnNames) {
                if (col != columnName) {
                     await _progressService.saveProgress(
                        categoryName, bookName, pageNumber, amudKey, col, currentAmudProgress.getProperty(col));
                }
            }
        }


        if (currentAmudProgress.isEmpty) {
          bookProgress[pageStr]!.remove(amudKey);
          if (bookProgress[pageStr]!.isEmpty) {
            bookProgress.remove(pageStr);
          }
        }
      }
    }
    if (bookProgress.isEmpty) {
        _fullProgress[categoryName]!.remove(bookName);
        if(_fullProgress[categoryName]!.isEmpty){
            _fullProgress.remove(categoryName);
        }
    }


    // After all updates, check for completion events
    // This part reuses logic from the existing updateProgress method's completion checks.
    if (select && columnName == learnColumn) {
      bool wasAlreadyCompleted = getCompletionDateSync(categoryName, bookName) != null;
      bool isNowComplete = isBookCompleted(categoryName, bookName, bookDetails);
      if (isNowComplete && !wasAlreadyCompleted) {
        await _progressService.saveCompletionDate(categoryName, bookName);
        _completionDates = await _progressService.loadCompletionDates();
        _completionEventController.add(CompletionEvent(CompletionEventType.bookCompleted, bookName: bookName));
      }
    } else if (select && (columnName == review1Column || columnName == review2Column || columnName == review3Column)) {
      int? reviewCycleNumber;
      if (columnName == review1Column) reviewCycleNumber = 1;
      else if (columnName == review2Column) reviewCycleNumber = 2;
      else if (columnName == review3Column) reviewCycleNumber = 3;

      if (reviewCycleNumber != null) {
        bool cycleJustCompleted = _isReviewCycleCompleted(categoryName, bookName, reviewCycleNumber, bookDetails);
        if (cycleJustCompleted) {
          _completionEventController.add(CompletionEvent(
            CompletionEventType.reviewCycleCompleted,
            bookName: bookName,
            reviewCycleNumber: reviewCycleNumber,
          ));
        }
      }
    }
    // If deselecting, a book might become "not completed"
    // The current completion check logic in `isBookCompleted` reads the live state, so it will reflect changes.
    // If a "book uncompleted" event were needed, logic would go here.

    notifyListeners();
  }

  Map<String, bool?> getColumnSelectionStates(
    String categoryName,
    String bookName,
    BookDetails? bookDetails, // Make bookDetails nullable
  ) {
    Map<String, bool?> columnStates = {
      learnColumn: null,
      review1Column: null,
      review2Column: null,
      review3Column: null,
    };

    if (bookDetails == null) {
      // If bookDetails is null, we can't determine the items, so return indeterminate for all.
      return columnStates;
    }
    
    final bookProgress = _fullProgress[categoryName]?[bookName];
    final totalItems = bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;

    if (totalItems == 0) { // If there are no items in the book, treat columns as unselected.
        columnStates.updateAll((key, value) => false);
        return columnStates;
    }


    for (String currentColumnName in allColumnNames) {
      bool allSelectedInColumn = true;
      bool noneSelectedInColumn = true; // Assume none selected until one is found

      if (bookProgress == null || bookProgress.isEmpty) { // No progress data for the book
          allSelectedInColumn = false; // Cannot be all selected if no progress
          // noneSelectedInColumn remains true
      } else {
        int itemsChecked = 0;
        for (int i = 0; i < bookDetails.pages; i++) {
          final pageNumber = bookDetails.startPage + i;
          final pageStr = pageNumber.toString();
          final List<String> amudKeys = bookDetails.isDafType ? ['a', 'b'] : ['a'];

          for (String amudKey in amudKeys) {
            final pageAmudProgress = bookProgress[pageStr]?[amudKey];
            bool itemSelected = pageAmudProgress?.getProperty(currentColumnName) ?? false;

            if (itemSelected) {
              noneSelectedInColumn = false; // Found at least one selected
              itemsChecked++;
            } else {
              allSelectedInColumn = false; // Found at least one not selected
            }
          }
        }
         // Refined check after loop:
        if (itemsChecked == 0 && totalItems > 0) { // No items were checked for this column
            noneSelectedInColumn = true;
            allSelectedInColumn = false;
        } else if (itemsChecked == totalItems) { // All items were checked
            allSelectedInColumn = true;
            noneSelectedInColumn = false;
        } else { // Mixed state
            allSelectedInColumn = false;
            noneSelectedInColumn = false;
        }
      }


      if (allSelectedInColumn && totalItems > 0) { // totalItems > 0 condition added
        columnStates[currentColumnName] = true;
      } else if (noneSelectedInColumn) {
        columnStates[currentColumnName] = false;
      } else {
        columnStates[currentColumnName] = null; // Mixed
      }
    }
    return columnStates;
  }
}
