import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../models/progress_model.dart';
import '../providers/progress_provider.dart';
import '../screens/book_detail_screen.dart';
import './hebrew_utils.dart';

class BookCardWidget extends StatelessWidget {
  final String categoryName;
  final String bookName;
  final BookDetails bookDetails;
  final Map<String, Map<String, PageProgress>> bookProgressData;
  final bool isFromTrackingScreen;
  final String? completionDateOverride;
  final bool isInCompletedListContext;

  const BookCardWidget({
    super.key,
    required this.categoryName,
    required this.bookName,
    required this.bookDetails,
    required this.bookProgressData,
    this.isFromTrackingScreen = false,
    this.completionDateOverride,
    this.isInCompletedListContext = false,
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

    if (isFromTrackingScreen) {
      Widget progressWidget;
      String statusText;
      String percentageTextForOverlay;
      Color textColorOnProgress;

      if (isInCompletedListContext) {
        final numCompletedCycles = progressProvider.getNumberOfCompletedCycles(
            categoryName, bookName, bookDetails);

        Color displayColor = Colors.green[400]!;
        if (numCompletedCycles == 2) displayColor = Colors.green[600]!;
        if (numCompletedCycles == 3) displayColor = Colors.green[800]!;
        if (numCompletedCycles >= 4) displayColor = Colors.green[900]!;

        progressWidget = LinearProgressIndicator(
          value: 1.0,
          minHeight: 24,
          backgroundColor: theme.primaryColor.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation<Color>(displayColor),
          borderRadius: BorderRadius.circular(4),
        );

        percentageTextForOverlay = "${numCompletedCycles * 100}%";

        if (numCompletedCycles < 1) percentageTextForOverlay = "100%";

        textColorOnProgress =
            ThemeData.estimateBrightnessForColor(displayColor) ==
                    Brightness.dark
                ? Colors.white
                : Colors.black;

        final hebrewDate =
            HebrewUtils.getCompletionDateString(completionDateOverride);
        statusText = hebrewDate != null
            ? "סיימת לאחרונה ב$hebrewDate"
            : "סיימת (תאריך לא ידוע)";
        if (completionDateOverride == null) {
          statusText = "סיימת (תאריך לא נשמר)";
        }
      } else {
        final learnProgress = progressProvider.getLearnProgressPercentage(
            categoryName, bookName, bookDetails);
        final review1Progress = progressProvider.getReview1ProgressPercentage(
            categoryName, bookName, bookDetails);
        final review2Progress = progressProvider.getReview2ProgressPercentage(
            categoryName, bookName, bookDetails);
        final review3Progress = progressProvider.getReview3ProgressPercentage(
            categoryName, bookName, bookDetails);

        final progressBarBackgroundColor = theme.primaryColor.withOpacity(0.15);

        progressWidget = Stack(
          children: [
            LinearProgressIndicator(
              value: learnProgress,
              minHeight: 24,
              backgroundColor: progressBarBackgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            LinearProgressIndicator(
              value: review1Progress,
              minHeight: 24,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            LinearProgressIndicator(
              value: review2Progress,
              minHeight: 24,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor.withOpacity(0.7)),
              borderRadius: BorderRadius.circular(4),
            ),
            LinearProgressIndicator(
              value: review3Progress,
              minHeight: 24,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor.withOpacity(0.9)),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );

        Color colorUnderText;
        if (review3Progress >= 0.5) {
          colorUnderText = theme.primaryColor.withOpacity(0.9);
        } else if (review2Progress >= 0.5) {
          colorUnderText = theme.primaryColor.withOpacity(0.7);
        } else if (review1Progress >= 0.5) {
          colorUnderText = theme.primaryColor.withOpacity(0.5);
        } else if (learnProgress >= 0.5) {
          colorUnderText = theme.primaryColor.withOpacity(0.3);
        } else {
          colorUnderText = progressBarBackgroundColor;
        }

        textColorOnProgress =
            ThemeData.estimateBrightnessForColor(colorUnderText) ==
                    Brightness.dark
                ? Colors.white
                : Colors.black;

        double textPercentageToShow;
        if (learnProgress < 1.0) {
          textPercentageToShow = learnProgress;
        } else if (review1Progress < 1.0) {
          textPercentageToShow = review1Progress;
        } else if (review2Progress < 1.0) {
          textPercentageToShow = review2Progress;
        } else {
          textPercentageToShow = review3Progress;
        }
        percentageTextForOverlay = "${(textPercentageToShow * 100).round()}%";
        statusText = _getLastPageDisplay(context);
      }

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              BookDetailScreen.routeName,
              arguments: {'categoryName': categoryName, 'bookName': bookName},
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$bookName ($categoryName)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    progressWidget,
                    Text(
                      percentageTextForOverlay,
                      style: TextStyle(
                        color: textColorOnProgress,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  statusText,
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.8)),
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

    final bool isCompleted =
        progressProvider.isBookCompleted(categoryName, bookName, bookDetails);
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
