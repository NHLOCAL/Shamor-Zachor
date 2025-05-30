import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../models/progress_model.dart';
import '../providers/progress_provider.dart';
import '../screens/book_detail_screen.dart';
import './hebrew_utils.dart';
import '../services/progress_service.dart'; // For getCompletedPagesCount

class BookCardWidget extends StatelessWidget {
  final String categoryName;
  final String bookName;
  final BookDetails bookDetails;
  final Map<String, Map<String, PageProgress>>
      bookProgressData; // Progress for this specific book
  final bool isFromTrackingScreen;
  final String?
      completionDateOverride; // Used if book is completed but no active progress

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
    // isBookCompleted is synchronous and relies on provider's current state
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
        // Ensure 100% if marked complete
        percentage = 1.0;
      }

      final String statusText;
      if (isCompleted) {
        // Use the synchronous getCompletionDateSync from the provider
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
          isCompleted ? Colors.green.shade700 : Theme.of(context).primaryColor;
      final textColorOnProgress = percentage >= 0.4
          ? Colors.white
          : Theme.of(context).colorScheme.onPrimaryContainer;

      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Theme.of(context).cardTheme.color,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushNamed(
              BookDetailScreen.routeName,
              arguments: {'categoryName': categoryName, 'bookName': bookName},
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$bookName ($categoryName)',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    LinearProgressIndicator(
                      value: percentage,
                      minHeight: 25,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      borderRadius: BorderRadius.circular(
                          5), // For newer Flutter versions, use `borderRadius`
                    ),
                    Text(
                      '${(percentage * 100).round()}%',
                      style: TextStyle(
                        color: textColorOnProgress,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  statusText,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // For books screen cards (simpler)
    return SizedBox(
      height: 75,
      width: 150,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context)
              .colorScheme
              .surface, // Changed from surfaceVariant
          foregroundColor: Theme.of(context)
              .colorScheme
              .onSurface, // Corresponding onSurface
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          elevation: 1,
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
                  Icon(Icons.check_circle,
                      color: Colors.green.shade600, size: 18),
                if (isCompleted) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    bookName,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
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
    final bool isCompleted =
        progressProvider.isBookCompleted(categoryName, bookName, bookDetails);

    return SizedBox(
      height: 75,
      width: 150,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context)
              .colorScheme
              .surface, // Changed from surfaceVariant
          foregroundColor: Theme.of(context)
              .colorScheme
              .onSurface, // Corresponding onSurface
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          elevation: 1,
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
                  Icon(Icons.check_circle,
                      color: Colors.green.shade600, size: 18),
                if (isCompleted) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    bookName,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              categoryName,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
