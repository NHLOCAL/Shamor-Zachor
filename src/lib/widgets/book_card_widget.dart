import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../models/progress_model.dart';
import '../providers/progress_provider.dart';
import '../screens/book_detail_screen.dart';
import './hebrew_utils.dart';

class BookCardWidget extends StatelessWidget {
  final String topLevelCategoryKey;
  final String categoryName;
  final String bookName;
  final BookDetails bookDetails;
  // THIS IS THE FIX: Changed the type of this property.
  final Map<String, PageProgress> bookProgressData;
  final bool isFromTrackingScreen;
  final String? completionDateOverride;
  final bool isInCompletedListContext;

  const BookCardWidget({
    super.key,
    required this.topLevelCategoryKey,
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

    int maxLearnedIndex = -1;
    bookProgressData.forEach((key, progress) {
      final index = int.tryParse(key);
      if (index != null && progress.learn && index > maxLearnedIndex) {
        maxLearnedIndex = index;
      }
    });

    if (maxLearnedIndex == -1) {
      return completionDateOverride != null ? "" : "עדיין לא התחלת";
    }

    final learnableItems = bookDetails.learnableItems;
    if (learnableItems.isEmpty) return "";

    // Find the learnable item corresponding to the highest learned index
    final lastLearnedItem = learnableItems.firstWhere(
      (item) => item.absoluteIndex == maxLearnedIndex,
      // Fallback in case of data inconsistency
      orElse: () => learnableItems.last,
    );

    final pageNum = lastLearnedItem.pageNumber;
    final partName = lastLearnedItem.partName;

    String locationString;
    if (bookDetails.isDafType) {
      final amudSymbol = lastLearnedItem.amudKey == 'a' ? 'ע"א' : 'ע"ב';
      locationString =
          "${bookDetails.contentType} ${HebrewUtils.intToGematria(pageNum)} $amudSymbol";
    } else {
      locationString =
          "${bookDetails.contentType} ${HebrewUtils.intToGematria(pageNum)}";
    }

    if (bookDetails.hasMultipleParts) {
      return "הגעת ל$locationString ב$partName";
    } else {
      return "הגעת ל$locationString";
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
            topLevelCategoryKey, bookName, bookDetails);

        Color displayColor = theme.primaryColor.withAlpha((0.4 * 255).round());
        if (numCompletedCycles == 2)
          displayColor = theme.primaryColor.withAlpha((0.6 * 255).round());
        if (numCompletedCycles == 3)
          displayColor = theme.primaryColor.withAlpha((0.8 * 255).round());
        if (numCompletedCycles >= 4) displayColor = theme.primaryColor;

        progressWidget = LinearProgressIndicator(
          value: 1.0,
          minHeight: 24,
          backgroundColor: theme.primaryColor.withAlpha((0.15 * 255).round()),
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
            topLevelCategoryKey, bookName, bookDetails);
        final review1Progress = progressProvider.getReview1ProgressPercentage(
            topLevelCategoryKey, bookName, bookDetails);
        final review2Progress = progressProvider.getReview2ProgressPercentage(
            topLevelCategoryKey, bookName, bookDetails);
        final review3Progress = progressProvider.getReview3ProgressPercentage(
            topLevelCategoryKey, bookName, bookDetails);

        final progressBarBackgroundColor =
            theme.primaryColor.withAlpha((0.15 * 255).round());

        progressWidget = Stack(
          children: [
            LinearProgressIndicator(
              value: learnProgress,
              minHeight: 24,
              backgroundColor: progressBarBackgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor.withAlpha((0.3 * 255).round())),
              borderRadius: BorderRadius.circular(4),
            ),
            LinearProgressIndicator(
              value: review1Progress,
              minHeight: 24,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor.withAlpha((0.5 * 255).round())),
              borderRadius: BorderRadius.circular(4),
            ),
            LinearProgressIndicator(
              value: review2Progress,
              minHeight: 24,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor.withAlpha((0.7 * 255).round())),
              borderRadius: BorderRadius.circular(4),
            ),
            LinearProgressIndicator(
              value: review3Progress,
              minHeight: 24,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                  theme.primaryColor.withAlpha((0.9 * 255).round())),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );

        Color colorUnderText;
        if (review3Progress >= 0.5) {
          colorUnderText = theme.primaryColor.withAlpha((0.9 * 255).round());
        } else if (review2Progress >= 0.5) {
          colorUnderText = theme.primaryColor.withAlpha((0.7 * 255).round());
        } else if (review1Progress >= 0.5) {
          colorUnderText = theme.primaryColor.withAlpha((0.5 * 255).round());
        } else if (learnProgress >= 0.5) {
          colorUnderText = theme.primaryColor.withAlpha((0.3 * 255).round());
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
              arguments: {
                'topLevelCategoryKey': topLevelCategoryKey,
                'categoryName': categoryName,
                'bookName': bookName,
              },
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
                      color: theme.colorScheme.onSurface
                          .withAlpha((0.8 * 255).round())),
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

    final bool isCompleted = progressProvider.isBookCompleted(
        topLevelCategoryKey, bookName, bookDetails);
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
            arguments: {
              'topLevelCategoryKey': topLevelCategoryKey,
              'categoryName': categoryName,
              'bookName': bookName,
            },
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
                        size: 18, color: theme.colorScheme.primary),
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
  final String topLevelCategoryKey;
  final String categoryName;
  final String bookName;
  final BookDetails bookDetails;

  const SearchBookCardWidget({
    super.key,
    required this.topLevelCategoryKey,
    required this.categoryName,
    required this.bookName,
    required this.bookDetails,
  });

  @override
  Widget build(BuildContext context) {
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    final theme = Theme.of(context);

    final bool isCompleted = progressProvider.isBookCompleted(
        topLevelCategoryKey, bookName, bookDetails);

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
            arguments: {
              'topLevelCategoryKey': topLevelCategoryKey,
              'categoryName': categoryName,
              'bookName': bookName,
            },
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
                        size: 18, color: theme.colorScheme.primary),
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
                  color: theme.colorScheme.onSurface
                      .withAlpha((0.7 * 255).round())),
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
