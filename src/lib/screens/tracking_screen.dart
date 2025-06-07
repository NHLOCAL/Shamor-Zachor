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

    List<Map<String, dynamic>> inProgressItemsData = [];
    List<Map<String, dynamic>> completedItemsData = [];

    for (var item in trackedItems) {
      final categoryName = item['categoryName'] as String;
      final bookName = item['bookName'] as String;
      final bookDetails = item['bookDetails'] as BookDetails;
      final bookProgressData =
          item['progressData'] as Map<String, Map<String, PageProgress>>;

      final String? completionDateForCard =
          progressProvider.getCompletionDateSync(categoryName, bookName);

      final cardData = {
        'categoryName': categoryName,
        'bookName': bookName,
        'bookDetails': bookDetails,
        'bookProgressData': bookProgressData,
        'completionDateOverride': completionDateForCard, // Pass it consistently
      };

      // Use new provider methods to determine list placement
      if (progressProvider.isBookCompleted(
          categoryName, bookName, bookDetails)) {
        // Check if it's already added to avoid duplicates if getTrackedBooks could somehow return duplicates
        // (though it shouldn't based on its current logic)
        if (!completedItemsData.any((c) =>
            c['categoryName'] == categoryName && c['bookName'] == bookName)) {
          completedItemsData.add(cardData);
        }
      }

      // A book can be completed AND in progress (e.g. learning done, but reviews in progress)
      // The current UI shows them in "completed" once learning is done.
      // If we want books that are also in active review to appear in "in progress",
      // we would add them here as well or instead.
      // Based on the new definition, `isBookConsideredInProgress` handles this.
      // If a book is 100% learned AND 100% all reviews, `isBookConsideredInProgress` will be false.
      // If a book is 100% learned but reviews are ongoing, it will be true.
      // If a book is completed (learning done) and also in progress (reviews ongoing),
      // it will appear in BOTH lists if we simply do:
      //
      // if (progressProvider.isBookConsideredInProgress(categoryName, bookName, bookDetails)) {
      //   if (!inProgressItemsData.any((c) => c['categoryName'] == categoryName && c['bookName'] == bookName)) {
      //     inProgressItemsData.add(cardData);
      //   }
      // }
      //
      // The original logic implicitly prioritized "completed" if a completion date existed.
      // Let's maintain that: if it's in `completedItemsData`, it shouldn't also be in `inProgressItemsData`
      // for the purpose of these two distinct lists in the UI.
      // Determine if the book is completed (learn cycle done)
      if (progressProvider.isBookCompleted(
          categoryName, bookName, bookDetails)) {
        if (!completedItemsData.any((c) =>
            c['categoryName'] == categoryName && c['bookName'] == bookName)) {
          completedItemsData.add(cardData);
        }
      }

      // Determine if the book is considered in progress (active learning or review)
      // This is independent of whether it's "completed" in terms of the learn cycle.
      // A book can be completed (learning done) and still be in progress (reviews ongoing).
      if (progressProvider.isBookConsideredInProgress(
              categoryName, bookName, bookDetails)) {
        if (!inProgressItemsData.any((c) =>
            c['categoryName'] == categoryName && c['bookName'] == bookName)) {
          inProgressItemsData.add(cardData);
        }
      }
    }

    // The removeWhere block is no longer needed as the new provider methods handle the logic.

    Widget buildList(List<Map<String, dynamic>> itemsData) {
      if (itemsData.isEmpty) {
        return Center(
          child: Text(
            _selectedFilter == TrackingFilter.inProgress
                ? 'אין ספרים בתהליך כעת.'
                : 'עדיין לא סיימת ספרים.',
            style: TextStyle(
                fontStyle: FontStyle.italic,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
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
                final item = itemsData[i];
                return BookCardWidget(
                  categoryName: item['categoryName'],
                  bookName: item['bookName'],
                  bookDetails: item['bookDetails'],
                  bookProgressData: item['bookProgressData'],
                  isFromTrackingScreen: true,
                  completionDateOverride: item['completionDateOverride'],
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
                final item = itemsData[i];
                return BookCardWidget(
                  categoryName: item['categoryName'],
                  bookName: item['bookName'],
                  bookDetails: item['bookDetails'],
                  bookProgressData: item['bookProgressData'],
                  isFromTrackingScreen: true,
                  completionDateOverride: item['completionDateOverride'],
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
