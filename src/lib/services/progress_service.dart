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
              bookValue.forEach((pageKey, pageValue) {
                if (pageValue is Map) {
                  progressMap[categoryKey]![bookKey]![pageKey] = {};
                  pageValue.forEach((amudKey, amudValue) {
                    if (amudValue is Map) {
                      progressMap[categoryKey]![bookKey]![pageKey]![amudKey] =
                          PageProgress.fromJson(
                              Map<String, dynamic>.from(amudValue));
                    }
                  });
                }
              });
            }
          });
        }
      });
      return progressMap;
    } catch (e) {
      // "Error decoding progress data: $e"
      return {};
    }
  }

  Future<void> _saveFullProgressData(FullProgressMap data) async {
    final prefs = await _getPrefs();
    Map<String, dynamic> serializableData = {};
    data.forEach((catKey, catValue) {
      serializableData[catKey] = {};
      catValue.forEach((bookKey, bookValue) {
        serializableData[catKey][bookKey] = {};
        bookValue.forEach((pageKey, pageValue) {
          serializableData[catKey][bookKey][pageKey] = {};
          pageValue.forEach((amudKey, amudProgress) {
            serializableData[catKey][bookKey][pageKey][amudKey] =
                amudProgress.toJson();
          });
        });
      });
    });
    await prefs.setString(_progressDataKey, json.encode(serializableData));
  }

  Future<Map<String, Map<String, PageProgress>>> loadBookProgress(
      String categoryName, String bookName) async {
    FullProgressMap fullData = await loadFullProgressData();
    return fullData[categoryName]?[bookName] ?? {};
  }

  Future<void> saveProgress(String categoryName, String bookName, int daf,
      String amudKey, String columnName, bool value) async {
    FullProgressMap fullData = await loadFullProgressData();

    fullData.putIfAbsent(categoryName, () => {});
    fullData[categoryName]!.putIfAbsent(bookName, () => {});
    fullData[categoryName]![bookName]!.putIfAbsent(daf.toString(), () => {});
    fullData[categoryName]![bookName]![daf.toString()]!
        .putIfAbsent(amudKey, () => PageProgress());

    PageProgress currentPageProgress =
        fullData[categoryName]![bookName]![daf.toString()]![amudKey]!;

    currentPageProgress.setProperty(columnName, value);

    if (currentPageProgress.isEmpty) {
      fullData[categoryName]![bookName]![daf.toString()]!.remove(amudKey);
    }
    if (fullData[categoryName]![bookName]![daf.toString()]!.isEmpty) {
      fullData[categoryName]![bookName]!.remove(daf.toString());
    }
    if (fullData[categoryName]![bookName]!.isEmpty) {
      fullData[categoryName]!.remove(bookName);
    }
    if (fullData[categoryName]!.isEmpty) {
      fullData.remove(categoryName);
    }

    await _saveFullProgressData(fullData);
  }

  // UPDATED to use learnableItems
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
      Map<String, Map<String, PageProgress>> currentBookProgress =
          fullData[categoryName]![bookName]!;

      final learnableItems = bookDetails.learnableItems;
      for (final item in learnableItems) {
        final pageStr = item.pageNumber.toString();
        currentBookProgress.putIfAbsent(pageStr, () => {});
        currentBookProgress[pageStr]!
            .putIfAbsent(item.amudKey, () => PageProgress());
        currentBookProgress[pageStr]![item.amudKey]!.learn = true;
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
      // "Error decoding completion dates: $e"
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

  static int getCompletedPagesCount(
      Map<String, Map<String, PageProgress>> bookProgress) {
    int count = 0;
    bookProgress.forEach((pageKey, amudimMap) {
      amudimMap.forEach((amudKey, progress) {
        if (progress.learn) {
          count++;
        }
      });
    });
    return count;
  }

  static int getReview1CompletedPagesCount(
      Map<String, Map<String, PageProgress>> bookProgress) {
    int count = 0;
    bookProgress.forEach((pageKey, amudimMap) {
      amudimMap.forEach((amudKey, progress) {
        if (progress.review1) {
          count++;
        }
      });
    });
    return count;
  }

  static int getReview2CompletedPagesCount(
      Map<String, Map<String, PageProgress>> bookProgress) {
    int count = 0;
    bookProgress.forEach((pageKey, amudimMap) {
      amudimMap.forEach((amudKey, progress) {
        if (progress.review2) {
          count++;
        }
      });
    });
    return count;
  }

  static int getReview3CompletedPagesCount(
      Map<String, Map<String, PageProgress>> bookProgress) {
    int count = 0;
    bookProgress.forEach((pageKey, amudimMap) {
      amudimMap.forEach((amudKey, progress) {
        if (progress.review3) {
          count++;
        }
      });
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

      if (progressDataString != null && progressDataString.isNotEmpty) {
        try {
          final decodedProgress = json.decode(progressDataString);
          if (decodedProgress is Map) {
            await prefs.setString(_progressDataKey, progressDataString);
          } else {
            await prefs.setString(_progressDataKey, '{}');
          }
        } catch (e) {
          await prefs.setString(_progressDataKey, '{}');
        }
      } else {
        await prefs.setString(_progressDataKey, '{}');
      }

      if (completionDatesString != null && completionDatesString.isNotEmpty) {
        try {
          final decodedDates = json.decode(completionDatesString);
          if (decodedDates is Map) {
            await prefs.setString(_completionDatesKey, completionDatesString);
          } else {
            await prefs.setString(_completionDatesKey, '{}');
          }
        } catch (e) {
          await prefs.setString(_completionDatesKey, '{}');
        }
      } else {
        await prefs.setString(_completionDatesKey, '{}');
      }

      if (customBooksDataString != null && customBooksDataString.isNotEmpty) {
        try {
          final decodedCustomBooks = json.decode(customBooksDataString);
          if (decodedCustomBooks is List) {
            await prefs.setString(
                CustomBookService.customBooksKey, customBooksDataString);
          } else {
            await prefs.setString(CustomBookService.customBooksKey, '[]');
          }
        } catch (e) {
          await prefs.setString(CustomBookService.customBooksKey, '[]');
        }
      } else {
        await prefs.setString(CustomBookService.customBooksKey, '[]');
      }

      return true;
    } catch (e) {
      // "Error importing combined data: $e"
      await prefs.setString(_progressDataKey, '{}');
      await prefs.setString(_completionDatesKey, '{}');
      await prefs.setString(CustomBookService.customBooksKey, '[]');
      return false;
    }
  }
}
