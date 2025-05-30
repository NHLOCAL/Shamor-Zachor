import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../models/progress_model.dart';
import '../providers/progress_provider.dart';
import '../screens/book_detail_screen.dart';
import './hebrew_utils.dart';
import '../services/progress_service.dart';

class BookCardWidget extends StatelessWidget {
  final String categoryName;
  final String bookName;
  final BookDetails bookDetails;
  final Map<String, Map<String, PageProgress>> bookProgressData;
  final bool isFromTrackingScreen;
  final String? completionDateOverride;

  const BookCardWidget({
    super.key,
    required this.categoryName,
    required this.bookName,
    required this.bookDetails,
    required this.bookProgressData,
    this.isFromTrackingScreen = false,
    this.completionDateOverride,
  });

  String _getLastPageDisplay(BuildContext context) {
    if (bookProgressData.isEmpty && completionDateOverride == null) {
      return "עדיין לא התחלת";
    }

    int lastPageNum = 0;
    String lastAmud = "";
    bool found = false;

    List<int> pageNumbers = bookProgressData.keys
        .map((e) => int.tryParse(e) ?? 0)
        .toList()
      ..sort((a, b) => b.compareTo(a));

    for (int pageNum in pageNumbers) {
      final pageStr = pageNum.toString();
      final amudim = bookProgressData[pageStr];
      if (amudim != null) {
        if (bookDetails.isDafType) {
          if (amudim["b"]?.learn == true) {
            lastPageNum = pageNum;
            lastAmud = "ב";
            found = true;
            break;
          }
          if (amudim["a"]?.learn == true) {
            lastPageNum = pageNum;
            lastAmud = "א";
            found = true;
            break;
          }
        } else {
          if (amudim["a"]?.learn == true) {
            lastPageNum = pageNum;
            found = true;
            break;
          }
        }
      }
    }

    if (!found && completionDateOverride == null) {
      return "עדיין לא התחלת";
    }
    if (!found && completionDateOverride != null) {
      return "";
    }

    if (bookDetails.isDafType) {
      return "הגעת ל${bookDetails.contentType} ${HebrewUtils.intToGematria(lastPageNum)} עמוד $lastAmud";
    } else {
      return "הגעת ל${bookDetails.contentType} ${HebrewUtils.intToGematria(lastPageNum)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    final theme = Theme.of(context);

    final bool isCompleted = completionDateOverride != null ||
        progressProvider.isBookCompleted(categoryName, bookName, bookDetails);

    if (isFromTrackingScreen) {
      final totalTargetPages =
          bookDetails.isDafType ? bookDetails.pages * 2 : bookDetails.pages;
      final completedPages =
          ProgressService.getCompletedPagesCount(bookProgressData);
      double percentage = 0;
      if (totalTargetPages > 0) {
        percentage = (completedPages / totalTargetPages);
      }
      if (isCompleted) {
        percentage = 1.0;
      }

      final String statusText;
      if (isCompleted) {
        final String? dateFromProvider =
            progressProvider.getCompletionDateSync(categoryName, bookName);
        final hebrewDate = HebrewUtils.getCompletionDateString(
            completionDateOverride ?? dateFromProvider);
        statusText =
            hebrewDate != null ? "סיימת ב$hebrewDate" : "סיימת (תאריך לא נשמר)";
      } else {
        statusText = _getLastPageDisplay(context);
      }

      final progressColor =
          isCompleted ? Colors.green.shade600 : theme.primaryColor;

      final textColorOnProgress = percentage >= 0.45
          ? Colors.white
          : theme.colorScheme.onPrimaryContainer;

      return Card(
        margin: const EdgeInsets.symmetric(
            vertical: 5, horizontal: 4), // הקטנת מרווח אנכי
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              BookDetailScreen.routeName,
              arguments: {'categoryName': categoryName, 'bookName': bookName},
            );
          },
          borderRadius: BorderRadius.circular(10), // רדיוס קטן יותר
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 10.0, vertical: 8.0), // הקטנת Padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // נשאר מרכוז
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize
                  .min, // ננסה לגרום ל-Column לתפוס רק את הגובה שהוא צריך
              children: [
                Text(
                  '$bookName ($categoryName)',
                  style: TextStyle(
                      fontSize: 16, // הקטנת פונט
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6), // הקטנת מרווח
                Stack(
                  alignment: Alignment.center,
                  children: [
                    LinearProgressIndicator(
                      value: percentage,
                      minHeight: 24, // הקטנת גובה סרגל
                      backgroundColor:
                          theme.colorScheme.primaryContainer.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      borderRadius: BorderRadius.circular(4), // רדיוס קטן יותר
                    ),
                    Text(
                      '${(percentage * 100).round()}%',
                      style: TextStyle(
                        color: textColorOnProgress,
                        fontWeight: FontWeight.bold,
                        fontSize: 11, // הקטנת פונט אחוזים
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6), // הקטנת מרווח
                Text(
                  statusText,
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface
                          .withOpacity(0.8)), // הקטנת פונט סטטוס
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Card for BooksScreen
    return SizedBox(
      height: 70,
      child: ElevatedButton(
        style: theme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(theme.colorScheme.surface),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onSurface),
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 8, vertical: 5)),
          minimumSize: WidgetStateProperty.all(const Size(140, 70)),
          maximumSize: WidgetStateProperty.all(const Size(180, 70)),
        ),
        onPressed: () {
          Navigator.of(context).pushNamed(
            BookDetailScreen.routeName,
            arguments: {'categoryName': categoryName, 'bookName': bookName},
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Icon(Icons.check_circle,
                        color: Colors.green.shade600, size: 18),
                  ),
                Flexible(
                  child: Text(
                    bookName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBookCardWidget extends StatelessWidget {
  final String categoryName;
  final String bookName;
  final BookDetails bookDetails;

  const SearchBookCardWidget({
    super.key,
    required this.categoryName,
    required this.bookName,
    required this.bookDetails,
  });

  @override
  Widget build(BuildContext context) {
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    final theme = Theme.of(context);
    final bool isCompleted =
        progressProvider.isBookCompleted(categoryName, bookName, bookDetails);

    return SizedBox(
      height: 85,
      child: ElevatedButton(
        style: theme.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(theme.colorScheme.surface),
          foregroundColor: WidgetStateProperty.all(theme.colorScheme.onSurface),
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
          minimumSize: WidgetStateProperty.all(const Size(140, 85)),
          maximumSize: WidgetStateProperty.all(const Size(180, 85)),
        ),
        onPressed: () {
          Navigator.of(context).pushNamed(
            BookDetailScreen.routeName,
            arguments: {'categoryName': categoryName, 'bookName': bookName},
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Icon(Icons.check_circle,
                        color: Colors.green.shade600, size: 18),
                  ),
                Flexible(
                  child: Text(
                    bookName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              categoryName,
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7)),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
