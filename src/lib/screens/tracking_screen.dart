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

      String? completionDateForCard =
          progressProvider.getCompletionDateSync(categoryName, bookName);
      bool isActuallyCompleted = completionDateForCard != null ||
          progressProvider.isBookCompleted(categoryName, bookName, bookDetails);

      final cardData = {
        'categoryName': categoryName,
        'bookName': bookName,
        'bookDetails': bookDetails,
        'bookProgressData': bookProgressData,
        'completionDateOverride':
            isActuallyCompleted ? completionDateForCard : null,
      };

      if (isActuallyCompleted) {
        if (!completedItemsData.any((c) =>
            c['categoryName'] == categoryName && c['bookName'] == bookName)) {
          completedItemsData.add(cardData);
        }
      } else {
        if (bookProgressData.isNotEmpty) {
          if (!inProgressItemsData.any((c) =>
              c['categoryName'] == categoryName && c['bookName'] == bookName)) {
            inProgressItemsData.add(cardData);
          }
        }
      }
    }

    inProgressItemsData.removeWhere((itemData) {
      String? date = progressProvider.getCompletionDateSync(
          itemData['categoryName'], itemData['bookName']);
      bool isItemCompleted = date != null ||
          progressProvider.isBookCompleted(itemData['categoryName'],
              itemData['bookName'], itemData['bookDetails']);
      return isItemCompleted;
    });

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
