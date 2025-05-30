import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/book_card_widget.dart';
import '../models/book_model.dart';
import '../models/progress_model.dart'; // Added direct import for PageProgress

enum TrackingFilter { inProgress, completed }

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  TrackingFilter _selectedFilter = TrackingFilter.inProgress;

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final progressProvider = Provider.of<ProgressProvider>(context);

    if (dataProvider.isLoading || progressProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (dataProvider.error != null) {
      return Center(child: Text('שגיאה בטעינת נתונים: ${dataProvider.error}'));
    }

    final allBookData = dataProvider.allBookData;
    // getTrackedBooks might be slow if it iterates a lot. Consider optimizing if performance issues arise.
    final trackedItems = progressProvider.getTrackedBooks(allBookData);

    List<Widget> inProgressCards = [];
    List<Widget> completedCards = [];

    for (var item in trackedItems) {
      final categoryName = item['categoryName'] as String;
      final bookName = item['bookName'] as String;
      final bookDetails = item['bookDetails'] as BookDetails;
      // Explicitly cast to the correct type, PageProgress should now be recognized
      final bookProgressData =
          item['progressData'] as Map<String, Map<String, PageProgress>>;

      // Use the synchronous method from ProgressProvider
      String? completionDateForCard =
          progressProvider.getCompletionDateSync(categoryName, bookName);
      bool isActuallyCompleted = completionDateForCard != null ||
          progressProvider.isBookCompleted(categoryName, bookName, bookDetails);

      final card = BookCardWidget(
        categoryName: categoryName,
        bookName: bookName,
        bookDetails: bookDetails,
        bookProgressData: bookProgressData,
        isFromTrackingScreen: true,
        completionDateOverride:
            isActuallyCompleted ? completionDateForCard : null,
      );

      if (isActuallyCompleted) {
        // Ensure it's not already added to avoid duplicates if logic in getTrackedBooks changes
        if (!completedCards.any((c) =>
            c is BookCardWidget &&
            c.categoryName == categoryName &&
            c.bookName == bookName)) {
          completedCards.add(card);
        }
      } else {
        // Only add to inProgress if there's actual progress or it's not marked as completed elsewhere
        if (bookProgressData.isNotEmpty) {
          // Ensure it's not already added
          if (!inProgressCards.any((c) =>
              c is BookCardWidget &&
              c.categoryName == categoryName &&
              c.bookName == bookName)) {
            inProgressCards.add(card);
          }
        }
      }
    }

    // Post-processing to ensure integrity (optional if getTrackedBooks is robust)
    inProgressCards.removeWhere((cardWidget) {
      if (cardWidget is BookCardWidget) {
        // Check again with potentially more up-to-date provider state if needed
        // For now, rely on the initial check within the loop
        String? date = progressProvider.getCompletionDateSync(
            cardWidget.categoryName, cardWidget.bookName);
        bool isItemCompleted = date != null ||
            progressProvider.isBookCompleted(cardWidget.categoryName,
                cardWidget.bookName, cardWidget.bookDetails);
        return isItemCompleted;
      }
      return false;
    });

    Widget content;
    if (_selectedFilter == TrackingFilter.inProgress) {
      content = inProgressCards.isEmpty
          ? const Center(
              child: Text('אין ספרים בתהליך כעת.',
                  style: TextStyle(fontStyle: FontStyle.italic)))
          : ListView.builder(
              // Changed from GridView for consistency with Flet screenshot's vertical list
              itemCount: inProgressCards.length,
              itemBuilder: (ctx, i) => Padding(
                // Add some padding between cards
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: inProgressCards[i],
              ),
            );
    } else {
      content = completedCards.isEmpty
          ? const Center(
              child: Text('עדיין לא סיימת ספרים.',
                  style: TextStyle(fontStyle: FontStyle.italic)))
          : ListView.builder(
              itemCount: completedCards.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: completedCards[i],
              ),
            );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: SegmentedButton<TrackingFilter>(
            segments: const <ButtonSegment<TrackingFilter>>[
              ButtonSegment<TrackingFilter>(
                value: TrackingFilter.inProgress,
                label: Text('בתהליך'),
                icon: Icon(Icons.hourglass_empty_outlined),
              ),
              ButtonSegment<TrackingFilter>(
                value: TrackingFilter.completed,
                label: Text('סיימתי'),
                icon: Icon(Icons.check_circle_outline),
              ),
            ],
            selected: <TrackingFilter>{_selectedFilter},
            onSelectionChanged: (Set<TrackingFilter> newSelection) {
              // Guard against context usage if any async operation happens before this line in build
              if (mounted) {
                setState(() {
                  _selectedFilter = newSelection.first;
                });
              }
            },
            showSelectedIcon: false,
            style: Theme.of(context).segmentedButtonTheme.style,
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}
