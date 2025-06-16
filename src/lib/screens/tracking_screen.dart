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
      final topLevelCategoryKey = item['topLevelCategoryKey'] as String;
      final bookName = item['bookName'] as String;
      final bookDetails = item['bookDetails'] as BookDetails;

      // THIS IS THE FIX: Changed the cast to the correct, flat map type.
      final bookProgressData =
          item['progressData'] as Map<String, PageProgress>;

      final String? completionDateForCard =
          progressProvider.getCompletionDateSync(topLevelCategoryKey, bookName);

      final cardData = {
        'topLevelCategoryKey': item['topLevelCategoryKey'],
        'displayCategoryName': item['displayCategoryName'],
        'bookName': bookName,
        'bookDetails': bookDetails,
        'bookProgressData': bookProgressData,
        'completionDateOverride': completionDateForCard,
      };

      if (progressProvider.isBookCompleted(
          topLevelCategoryKey, bookName, bookDetails)) {
        if (!completedItemsData.any((c) =>
            c['topLevelCategoryKey'] == topLevelCategoryKey &&
            c['bookName'] == bookName)) {
          completedItemsData.add(cardData);
        }
      }

      if (progressProvider.isBookConsideredInProgress(
          topLevelCategoryKey, bookName, bookDetails)) {
        if (!inProgressItemsData.any((c) =>
            c['topLevelCategoryKey'] == topLevelCategoryKey &&
            c['bookName'] == bookName)) {
          inProgressItemsData.add(cardData);
        }
      }
    }

    Widget buildList(List<Map<String, dynamic>> itemsData) {
      if (itemsData.isEmpty) {
        return Center(
          child: Text(
            _selectedFilter == TrackingFilter.inProgress
                ? 'אין ספרים בתהליך כעת'
                : 'עדיין לא סיימת ספרים',
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
          const double desiredCardWidth = 350;
          const double minCardHeightForGridView = 120;
          int crossAxisCount =
              (constraints.maxWidth / desiredCardWidth).floor();
          if (crossAxisCount < 1) crossAxisCount = 1;
          if (constraints.maxWidth < 500 || crossAxisCount == 1) {
            crossAxisCount = 1;
          }

          if (crossAxisCount == 1) {
            return ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              itemCount: itemsData.length,
              itemBuilder: (ctx, i) {
                final itemData = itemsData[i];
                return BookCardWidget(
                  topLevelCategoryKey: itemData['topLevelCategoryKey'],
                  // Pass the display name for the card
                  categoryName: itemData['displayCategoryName'],
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
            double childWidth =
                (constraints.maxWidth - (10 * (crossAxisCount + 1))) /
                    crossAxisCount;
            double aspectRatio = childWidth / minCardHeightForGridView;

            return GridView.builder(
              padding: const EdgeInsets.all(10.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: aspectRatio > 1.8 ? aspectRatio : 1.8,
              ),
              itemCount: itemsData.length,
              itemBuilder: (ctx, i) {
                final itemData = itemsData[i];
                return BookCardWidget(
                  topLevelCategoryKey: itemData['topLevelCategoryKey'],
                  // Pass the display name for the card
                  categoryName: itemData['displayCategoryName'],
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
                label: Text('הסתיים'),
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
