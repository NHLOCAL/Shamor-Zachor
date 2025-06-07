import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/progress_model.dart';
import '../models/book_model.dart';
import 'package:intl/intl.dart';

class ProgressService {
  static const String _appPrefix = "nhlocal.shamor_vezachor";
  static const String _progressDataKey = "$_appPrefix.progress_data";
  static const String _completionDatesKey = "$_appPrefix.completion_dates";

  Future<SharedPreferences> _getPrefs() async {
    return SharedPreferences.getInstance();
  }

  // Made public by removing '_'
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
      print("Error decoding progress data: $e");
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
    FullProgressMap fullData =
        await loadFullProgressData(); // Use public method
    return fullData[categoryName]?[bookName] ?? {};
  }

  Future<void> saveProgress(String categoryName, String bookName, int daf,
      String amudKey, String columnName, bool value) async {
    FullProgressMap fullData =
        await loadFullProgressData(); // Use public method

    fullData.putIfAbsent(categoryName, () => {});
    fullData[categoryName]!.putIfAbsent(bookName, () => {});
    fullData[categoryName]![bookName]!.putIfAbsent(daf.toString(), () => {});
    fullData[categoryName]![bookName]![daf.toString()]!
        .putIfAbsent(amudKey, () => PageProgress());

    PageProgress currentPageProgress =
        fullData[categoryName]![bookName]![daf.toString()]![amudKey]!;

    switch (columnName) {
      case 'learn':
        currentPageProgress.learn = value;
        break;
      case 'review1':
        currentPageProgress.review1 = value;
        break;
      case 'review2':
        currentPageProgress.review2 = value;
        break;
      case 'review3':
        currentPageProgress.review3 = value;
        break;
    }

    if (!currentPageProgress.learn &&
        !currentPageProgress.review1 &&
        !currentPageProgress.review2 &&
        !currentPageProgress.review3) {
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

  Future<void> saveAllMasechta(
    String categoryName,
    String bookName,
    BookDetails bookDetails,
    bool markAsLearned,
  ) async {
    FullProgressMap fullData =
        await loadFullProgressData(); // Use public method

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

      for (int i = bookDetails.startPage;
          i < bookDetails.pages + bookDetails.startPage;
          i++) {
        String dafStr = i.toString();
        currentBookProgress.putIfAbsent(dafStr, () => {});

        List<String> amudimToSet = bookDetails.isDafType ? ["a", "b"] : ["a"];
        for (String amudKey in amudimToSet) {
          currentBookProgress[dafStr]!
              .putIfAbsent(amudKey, () => PageProgress());
          currentBookProgress[dafStr]![amudKey]!.learn = true;
        }
      }
      await saveCompletionDate(categoryName, bookName);
    }
    await _saveFullProgressData(fullData);
  }

  // Made public by removing '_'
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
      print("Error decoding completion dates: $e");
      return {};
    }
  }

  Future<void> _saveCompletionDates(CompletionDatesMap dates) async {
    final prefs = await _getPrefs();
    await prefs.setString(_completionDatesKey, json.encode(dates));
  }

  Future<void> saveCompletionDate(String categoryName, String bookName) async {
    CompletionDatesMap allDates =
        await loadCompletionDates(); // Use public method
    allDates.putIfAbsent(categoryName, () => {});
    if (!allDates[categoryName]!.containsKey(bookName)) {
      allDates[categoryName]![bookName] =
          DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _saveCompletionDates(allDates);
    }
  }

  Future<String?> getCompletionDate(
      String categoryName, String bookName) async {
    CompletionDatesMap allDates =
        await loadCompletionDates(); // Use public method
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
}
