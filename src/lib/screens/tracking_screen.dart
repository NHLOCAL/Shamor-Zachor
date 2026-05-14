import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/book_card_widget.dart';
import '../models/book_model.dart';
import '../models/progress_model.dart';
import '../utils/category_sorter.dart';

enum TrackingFilter { inProgress, completed }

class TrackingScreen extends StatefulWidget {
  final ValueChanged<String>? onCategorySelected;

  const TrackingScreen({super.key, this.onCategorySelected});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  TrackingFilter _selectedFilter = TrackingFilter.inProgress;

  Map<String, List<Map<String, dynamic>>> _groupItemsByTopLevelCategory(
    List<Map<String, dynamic>> itemsData,
  ) {
    final groupedItems = <String, List<Map<String, dynamic>>>{};
    for (final itemData in itemsData) {
      final categoryKey = itemData['topLevelCategoryKey'] as String;
      groupedItems.putIfAbsent(categoryKey, () => []).add(itemData);
    }

    final sortedKeys = CategorySorter.sort(groupedItems.keys.toList());
    return {
      for (final key in sortedKeys)
        key: groupedItems[key]!
          ..sort((a, b) {
            final categoryComparison = (a['displayCategoryName'] as String)
                .compareTo(b['displayCategoryName'] as String);
            if (categoryComparison != 0) return categoryComparison;
            return (a['bookName'] as String).compareTo(b['bookName'] as String);
          })
    };
  }

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

    Widget buildCategoryHeader(
      String categoryName,
      List<Map<String, dynamic>> categoryItems,
    ) {
      final theme = Theme.of(context);
      final booksCountText = categoryItems.length == 1
          ? 'ספר אחד'
          : '${categoryItems.length} ספרים';
      final mutedTextColor =
          theme.colorScheme.onSurface.withAlpha((0.62 * 255).round());
      final dividerColor =
          theme.colorScheme.onSurface.withAlpha((0.10 * 255).round());

      final headerContent = Padding(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _selectedFilter == TrackingFilter.inProgress
              ? () => widget.onCategorySelected?.call(categoryName)
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withAlpha((0.72 * 255).round()),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        categoryName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface
                            .withAlpha((0.75 * 255).round()),
                        border: Border.all(color: dividerColor),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        child: Text(
                          booksCountText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: mutedTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    SizedBox(
                      width: 54,
                      child: Divider(
                        height: 1,
                        thickness: 2,
                        color: theme.colorScheme.primary
                            .withAlpha((0.38 * 255).round()),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: dividerColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (_selectedFilter != TrackingFilter.inProgress ||
          widget.onCategorySelected == null) {
        return headerContent;
      }

      return Tooltip(
        message: 'פתח את הקטגוריה בכרטיסית ספרים',
        child: headerContent,
      );
    }

    Widget buildTrackingCard(Map<String, dynamic> itemData) {
      return BookCardWidget(
        topLevelCategoryKey: itemData['topLevelCategoryKey'],
        categoryName: itemData['displayCategoryName'],
        bookName: itemData['bookName'],
        bookDetails: itemData['bookDetails'],
        bookProgressData: itemData['bookProgressData'],
        isFromTrackingScreen: true,
        completionDateOverride: itemData['completionDateOverride'],
        isInCompletedListContext: _selectedFilter == TrackingFilter.completed,
      );
    }

    Widget buildCategorySection(
      String categoryName,
      List<Map<String, dynamic>> categoryItems,
    ) {
      final theme = Theme.of(context);
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withAlpha((0.36 * 255).round()),
          border: Border.all(
            color: theme.colorScheme.onSurface.withAlpha((0.06 * 255).round()),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildCategoryHeader(categoryName, categoryItems),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: LayoutBuilder(
                builder: (context, sectionConstraints) {
                  const double desiredCardWidth = 350;
                  const double minCardHeightForGridView = 120;
                  var cardColumnCount =
                      (sectionConstraints.maxWidth / desiredCardWidth).floor();
                  if (cardColumnCount < 1) cardColumnCount = 1;

                  final childWidth = (sectionConstraints.maxWidth -
                          (10 * (cardColumnCount - 1))) /
                      cardColumnCount;
                  final aspectRatio = childWidth / minCardHeightForGridView;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cardColumnCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: aspectRatio > 1.8 ? aspectRatio : 1.8,
                    ),
                    itemCount: categoryItems.length,
                    itemBuilder: (ctx, i) =>
                        buildTrackingCard(categoryItems[i]),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    Widget buildCategorySectionShell(
      String categoryName,
      List<Map<String, dynamic>> categoryItems,
      double? width,
    ) {
      return Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: buildCategorySection(categoryName, categoryItems),
      );
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
      final groupedItems = _groupItemsByTopLevelCategory(itemsData);
      return LayoutBuilder(
        builder: (context, constraints) {
          const double minSectionWidth = 420;
          const double sectionSpacing = 12;
          const double horizontalPadding = 12;

          final availableWidth = constraints.maxWidth - (horizontalPadding * 2);
          final sectionColumnCount = ((availableWidth + sectionSpacing) /
                  (minSectionWidth + sectionSpacing))
              .floor();
          final useMultiColumnSections = sectionColumnCount >= 2;

          if (!useMultiColumnSections) {
            return ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              children: groupedItems.entries
                  .expand((entry) => [
                        buildCategoryHeader(entry.key, entry.value),
                        ...entry.value.map(buildTrackingCard),
                      ])
                  .toList(),
            );
          } else {
            final sectionWidth =
                (availableWidth - (sectionSpacing * (sectionColumnCount - 1))) /
                    sectionColumnCount;

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  horizontalPadding, 8.0, horizontalPadding, 14.0),
              children: [
                Wrap(
                  spacing: sectionSpacing,
                  runSpacing: sectionSpacing,
                  children: groupedItems.entries
                      .map((entry) => buildCategorySectionShell(
                            entry.key,
                            entry.value,
                            sectionWidth,
                          ))
                      .toList(),
                ),
              ],
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
