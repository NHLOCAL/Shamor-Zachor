import 'package:flutter/foundation.dart';
import '../models/progress_model.dart';
import '../models/book_model.dart';
import '../services/progress_service.dart';

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  FullProgressMap _fullProgress = {};
  CompletionDatesMap _completionDates = {}; // Cache completion dates

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
}
