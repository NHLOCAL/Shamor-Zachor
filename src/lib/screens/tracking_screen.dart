import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/book_card_widget.dart';
import '../models/book_model.dart';
import '../models/progress_model.dart';

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
    final trackedItems = progressProvider.getTrackedBooks(allBookData);
    print("[TrackingScreen] Received ${trackedItems.length} tracked items from ProgressProvider.");

    List<Map<String, dynamic>> inProgressItemsData = [];
    List<Map<String, dynamic>> completedItemsData = [];

    for (var item in trackedItems) {
      // Correctly extract keys based on the updated ProgressProvider.getTrackedBooks
      final topLevelCategoryKey = item['topLevelCategoryKey'] as String;
      final displayCategoryName = item['displayCategoryName'] as String; // For UI
      final bookName = item['bookName'] as String;
      print("[TrackingScreen] Processing item: Book='$bookName', DisplayCat='$displayCategoryName', TopLevelKey='$topLevelCategoryKey'");
      final bookDetails = item['bookDetails'] as BookDetails;
      final bookProgressData =
          item['progressData'] as Map<String, Map<String, PageProgress>>;
      // item['completionDate'] is also available if needed directly, but getCompletionDateSync is fine

      // Use topLevelCategoryKey for progress provider calls
      final String? completionDateForCard =
          progressProvider.getCompletionDateSync(topLevelCategoryKey, bookName);

      final cardData = {
        'topLevelCategoryKey': topLevelCategoryKey, // Store for potential future use or checks
        'displayCategoryName': displayCategoryName, // Use this for display
        'bookName': bookName,
        'bookDetails': bookDetails,
        'bookProgressData': bookProgressData,
        'completionDateOverride': completionDateForCard,
      };

      // Determine if the book is completed (learn cycle done)
      // Use topLevelCategoryKey for progress provider calls
      if (progressProvider.isBookCompleted(
          topLevelCategoryKey, bookName, bookDetails)) {
        // Ensure checks for adding to lists use a consistent key, e.g., bookName + topLevelCategoryKey
        // or rely on the fact that getTrackedBooks should ideally not produce functional duplicates
        // if a book is uniquely identified by its original category and name.
        // For simplicity, assuming bookName + topLevelCategoryKey is unique enough for list membership here.
        if (!completedItemsData.any((c) =>
            c['topLevelCategoryKey'] == topLevelCategoryKey && c['bookName'] == bookName)) {
          completedItemsData.add(cardData);
        }
      }

      // Determine if the book is considered in progress (active learning or review)
      // Use topLevelCategoryKey for progress provider calls
      if (progressProvider.isBookConsideredInProgress(
              topLevelCategoryKey, bookName, bookDetails)) {
        if (!inProgressItemsData.any((c) =>
            c['topLevelCategoryKey'] == topLevelCategoryKey && c['bookName'] == bookName)) {
          inProgressItemsData.add(cardData);
        }
      }
    }

    // This logic ensures a book doesn't appear in "In Progress" if it's fully completed (all review cycles done).
    // However, if a book is completed (learning cycle) but has ongoing reviews, it will be in "In Progress".
    // If such a book should *also* be in "Completed", the above logic handles it.
    // If it should *only* be in "Completed" once the learning cycle is done,
    // then items added to completedItemsData should be removed from inProgressItemsData.
    // The current logic allows a book completed (learning) but with ongoing reviews to appear in BOTH lists
    // if not filtered. Let's refine to ensure a book in completedItemsData is not in inProgressItemsData
    // if that's the desired distinct view.
    // The current filter _selectedFilter handles which list is shown, so overlap in underlying data is fine
    // unless we want to strictly categorize even before filtering.
    // The existing logic seems to create two lists, and then the UI picks one.
    // This is fine. The `isBookCompleted` and `isBookConsideredInProgress` flags correctly categorize them.
    print("[TrackingScreen] inProgressItemsData count: ${inProgressItemsData.length}");
    print("[TrackingScreen] completedItemsData count: ${completedItemsData.length}");

    Widget buildList(List<Map<String, dynamic>> itemsData) {
      print("[TrackingScreen] buildList called for filter: $_selectedFilter. Item count: ${itemsData.length}");
      if (itemsData.isEmpty) {
        print("[TrackingScreen] buildList: itemsData is empty. Displaying empty message.");
        return Center(
          child: Text(
            _selectedFilter == TrackingFilter.inProgress
                ? 'אין ספרים בתהליך כעת.'
                : 'עדיין לא סיימת ספרים.',
            style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha((0.6 * 255).round())),
          ),
        );
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          // הגדרות לרוחב כרטיס וגובה מינימלי רצוי
          const double desiredCardWidth =
              350; // רוחב רצוי/מינימלי לכרטיס לפני שהוא נדחס מדי
          const double minCardHeightForGridView =
              120; // גובה מינימלי שאנחנו רוצים לכרטיס ב-GridView

          int crossAxisCount =
              (constraints.maxWidth / desiredCardWidth).floor();
          if (crossAxisCount < 1) crossAxisCount = 1;

          // אם הרוחב הכולל קטן מדי, או אם החישוב נותן רק עמודה אחת, נעבור ל-ListView
          // או אם הרוחב המוקצה לכל כרטיס קטן מדי
          if (constraints.maxWidth < 500 || crossAxisCount == 1) {
            // הוגדל הערך ל-500
            crossAxisCount = 1; // כפה ListView
          }

          if (crossAxisCount == 1) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10.0, vertical: 6.0), // הקטנת Padding
              itemCount: itemsData.length,
              itemBuilder: (ctx, i) {
                final itemData = itemsData[i]; // Renamed for clarity
                return BookCardWidget(
                  topLevelCategoryKey: itemData['topLevelCategoryKey'], // Added
                  categoryName: itemData['topLevelCategoryKey'], // Changed to use topLevelCategoryKey
                  bookName: itemData['bookName'],
                  bookDetails: itemData['bookDetails'],
                  bookProgressData: itemData['bookProgressData'],
                  isFromTrackingScreen: true,
                  completionDateOverride: itemData['completionDateOverride'],
                  isInCompletedListContext:
                      _selectedFilter == TrackingFilter.completed,
                );
              },
            );
          } else {
            // חישוב childAspectRatio כדי לנסות לשמור על גובה מינימלי
            double childWidth =
                (constraints.maxWidth - (10 * (crossAxisCount + 1))) /
                    crossAxisCount;
            double aspectRatio = childWidth / minCardHeightForGridView;
            if (childWidth < desiredCardWidth * 0.8) {
              // אם הרוחב קטן מדי, אולי עדיף פחות עמודות
              // אפשר לשקול היגיון נוסף כאן, למשל להקטין crossAxisCount
            }

            return GridView.builder(
              padding: const EdgeInsets.all(10.0), // הקטנת Padding
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10, // הקטנת מרווח
                mainAxisSpacing: 10, // הקטנת מרווח
                childAspectRatio: aspectRatio > 1.8
                    ? aspectRatio
                    : 1.8, //  הבטחת יחס מינימלי כדי לתת גובה
              ),
              itemCount: itemsData.length,
              itemBuilder: (ctx, i) {
                final itemData = itemsData[i]; // Renamed for clarity
                return BookCardWidget(
                  topLevelCategoryKey: itemData['topLevelCategoryKey'], // Added
                  categoryName: itemData['topLevelCategoryKey'], // Changed to use topLevelCategoryKey
                  bookName: itemData['bookName'],
                  bookDetails: itemData['bookDetails'],
                  bookProgressData: itemData['bookProgressData'],
                  isFromTrackingScreen: true,
                  completionDateOverride: itemData['completionDateOverride'],
                  isInCompletedListContext:
                      _selectedFilter == TrackingFilter.completed,
                );
              },
            );
          }
        },
      );
    }

    Widget content;
    if (_selectedFilter == TrackingFilter.inProgress) {
      content = buildList(inProgressItemsData);
    } else {
      content = buildList(completedItemsData);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: 15.0, bottom: 15.0, left: 15, right: 15),
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
              if (mounted) {
                setState(() {
                  _selectedFilter = newSelection.first;
                });
              }
            },
            showSelectedIcon: false,
            style: Theme.of(context).segmentedButtonTheme.style?.copyWith(),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}
