import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';
import '../models/book_model.dart';
import 'package:intl/intl.dart';
import './custom_book_service.dart';

class ProgressService {
  static const String _appPrefix = "nhlocal.shamor_vezachor";
  static const String _progressDataKey = "$_appPrefix.progress_data";
  static const String _completionDatesKey = "$_appPrefix.completion_dates";

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  Future<FullProgressMap> loadFullProgressData() async {
    final prefs = await _getPrefs();
    String? jsonString = prefs.getString(_progressDataKey);
    if (jsonString == null) {
      return {};
    }
    try {
      Map<String, dynamic> decodedOuter = json.decode(jsonString);
      FullProgressMap progressMap = {};
      decodedOuter.forEach((categoryKey, categoryValue) {
        if (categoryValue is Map) {
          progressMap[categoryKey] = {};
          categoryValue.forEach((bookKey, bookValue) {
            if (bookValue is Map) {
              progressMap[categoryKey]![bookKey] = {};
              bookValue.forEach((itemIndexKey, itemProgressValue) {
                if (itemProgressValue is Map) {
                  progressMap[categoryKey]![bookKey]![itemIndexKey] =
                      PageProgress.fromJson(
                          Map<String, dynamic>.from(itemProgressValue));
                }
              });
            }
          });
        }
      });
      return progressMap;
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveFullProgressData(FullProgressMap data) async {
    final prefs = await _getPrefs();
    await prefs.setString(_progressDataKey, json.encode(data));
  }

  Future<void> saveProgress(String categoryName, String bookName,
      String itemIndexKey, String columnName, bool value) async {
    FullProgressMap fullData = await loadFullProgressData();

    fullData.putIfAbsent(categoryName, () => {});
    fullData[categoryName]!.putIfAbsent(bookName, () => {});
    fullData[categoryName]![bookName]!
        .putIfAbsent(itemIndexKey, () => PageProgress());

    PageProgress currentItemProgress =
        fullData[categoryName]![bookName]![itemIndexKey]!;

    currentItemProgress.setProperty(columnName, value);

    if (currentItemProgress.isEmpty) {
      fullData[categoryName]![bookName]!.remove(itemIndexKey);
      if (fullData[categoryName]![bookName]!.isEmpty) {
        fullData[categoryName]!.remove(bookName);
        if (fullData[categoryName]!.isEmpty) {
          fullData.remove(categoryName);
        }
      }
    }
    await _saveFullProgressData(fullData);
  }

  Future<void> saveAllMasechta(
    String categoryName,
    String bookName,
    BookDetails bookDetails,
    bool markAsLearned,
  ) async {
    FullProgressMap fullData = await loadFullProgressData();

    if (!markAsLearned) {
      if (fullData.containsKey(categoryName) &&
          fullData[categoryName]!.containsKey(bookName)) {
        fullData[categoryName]!.remove(bookName);
        if (fullData[categoryName]!.isEmpty) {
          fullData.remove(categoryName);
        }
      }
    } else {
      fullData.putIfAbsent(categoryName, () => {});
      fullData[categoryName]!.putIfAbsent(bookName, () => {});
      Map<String, PageProgress> currentBookProgress =
          fullData[categoryName]![bookName]!;

      final learnableItems = bookDetails.learnableItems;
      for (final item in learnableItems) {
        final itemIndexKey = item.absoluteIndex.toString();
        currentBookProgress.putIfAbsent(itemIndexKey, () => PageProgress());
        currentBookProgress[itemIndexKey]!.learn = true;
      }

      await saveCompletionDate(categoryName, bookName);
    }
    await _saveFullProgressData(fullData);
  }

  Future<CompletionDatesMap> loadCompletionDates() async {
    final prefs = await _getPrefs();
    String? jsonString = prefs.getString(_completionDatesKey);
    if (jsonString == null) return {};
    try {
      Map<String, dynamic> decoded = json.decode(jsonString);
      CompletionDatesMap datesMap = {};
      decoded.forEach((categoryKey, categoryValue) {
        if (categoryValue is Map) {
          datesMap[categoryKey] = Map<String, String>.from(categoryValue
              .map((key, value) => MapEntry(key.toString(), value.toString())));
        }
      });
      return datesMap;
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveCompletionDates(CompletionDatesMap dates) async {
    final prefs = await _getPrefs();
    await prefs.setString(_completionDatesKey, json.encode(dates));
  }

  Future<void> saveCompletionDate(String categoryName, String bookName) async {
    CompletionDatesMap allDates = await loadCompletionDates();
    allDates.putIfAbsent(categoryName, () => {});
    if (!allDates[categoryName]!.containsKey(bookName)) {
      allDates[categoryName]![bookName] =
          DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _saveCompletionDates(allDates);
    }
  }

  Future<String?> getCompletionDate(
      String categoryName, String bookName) async {
    CompletionDatesMap allDates = await loadCompletionDates();
    return allDates[categoryName]?[bookName];
  }

  static int getCompletedPagesCount(Map<String, PageProgress> bookProgress) {
    int count = 0;
    bookProgress.forEach((itemIndexKey, progress) {
      if (progress.learn) {
        count++;
      }
    });
    return count;
  }

  static int getReview1CompletedPagesCount(
      Map<String, PageProgress> bookProgress) {
    int count = 0;
    bookProgress.forEach((itemIndexKey, progress) {
      if (progress.review1) {
        count++;
      }
    });
    return count;
  }

  static int getReview2CompletedPagesCount(
      Map<String, PageProgress> bookProgress) {
    int count = 0;
    bookProgress.forEach((itemIndexKey, progress) {
      if (progress.review2) {
        count++;
      }
    });
    return count;
  }

  static int getReview3CompletedPagesCount(
      Map<String, PageProgress> bookProgress) {
    int count = 0;
    bookProgress.forEach((itemIndexKey, progress) {
      if (progress.review3) {
        count++;
      }
    });
    return count;
  }

  Future<String> exportProgressData() async {
    final prefs = await _getPrefs();
    final progressJsonString = prefs.getString(_progressDataKey);
    final completionDatesJsonString = prefs.getString(_completionDatesKey);
    final customBooksJsonString =
        prefs.getString(CustomBookService.customBooksKey);

    final Map<String, String?> dataToExport = {
      'progress_data': progressJsonString,
      'completion_dates': completionDatesJsonString,
      'custom_books_data': customBooksJsonString,
    };

    return json.encode(dataToExport);
  }

  Future<bool> importProgressData(String jsonData) async {
    final prefs = await _getPrefs();
    try {
      final Map<String, dynamic> decodedData = json.decode(jsonData);

      final String? progressDataString =
          decodedData['progress_data'] as String?;
      final String? completionDatesString =
          decodedData['completion_dates'] as String?;
      final String? customBooksDataString =
          decodedData['custom_books_data'] as String?;

      await prefs.setString(_progressDataKey, progressDataString ?? '{}');
      await prefs.setString(_completionDatesKey, completionDatesString ?? '{}');
      await prefs.setString(
          CustomBookService.customBooksKey, customBooksDataString ?? '[]');

      return true;
    } catch (e) {
      await prefs.setString(_progressDataKey, '{}');
      await prefs.setString(_completionDatesKey, '{}');
      await prefs.setString(CustomBookService.customBooksKey, '[]');
      return false;
    }
  }
}
