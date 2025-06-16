import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/hebrew_utils.dart';
import '../widgets/completion_animation_overlay.dart';

class BookDetailScreen extends StatefulWidget {
  static const routeName = '/book-detail';

  final String topLevelCategoryKey;
  final String categoryName;
  final String bookName;

  const BookDetailScreen({
    super.key,
    required this.topLevelCategoryKey,
    required this.categoryName,
    required this.bookName,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  StreamSubscription<CompletionEvent>? _completionSubscription;

  final List<Map<String, String>> _columnData = [
    {'id': ProgressProvider.learnColumn, 'label': 'לימוד'},
    {'id': ProgressProvider.review1Column, 'label': 'חזרה 1'},
    {'id': ProgressProvider.review2Column, 'label': 'חזרה 2'},
    {'id': ProgressProvider.review3Column, 'label': 'חזרה 3'},
  ];

  @override
  void initState() {
    super.initState();
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    _completionSubscription = progressProvider.completionEvents.listen((event) {
      if (!mounted) return;
      if (event.type == CompletionEventType.bookCompleted) {
        CompletionAnimationOverlay.show(
            context, "אשריך! תזכה ללמוד ספרים אחרים ולסיימם!");
      } else if (event.type == CompletionEventType.reviewCycleCompleted) {
        CompletionAnimationOverlay.show(
            context, "מזל טוב! הלומד וחוזר כזורע וקוצר!");
      }
    });
  }

  @override
  void dispose() {
    _completionSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _showWarningDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("אזהרה"),
          content:
              const Text("פעולה זו תשנה את כל הסימונים בעמודה זו. האם להמשיך?"),
          actions: <Widget>[
            TextButton(
                child: const Text("לא"),
                onPressed: () => Navigator.of(context).pop(false)),
            TextButton(
                child: const Text("כן"),
                onPressed: () => Navigator.of(context).pop(true)),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final progressProvider = Provider.of<ProgressProvider>(context);
    final theme = Theme.of(context);

    final topLevelCategory =
        dataProvider.allBookData[widget.topLevelCategoryKey];
    final bookSearchResult =
        topLevelCategory?.findBookRecursive(widget.bookName);
    final bookDetails = bookSearchResult?.bookDetails;

    if (bookDetails == null) {
      return Scaffold(
        appBar: AppBar(title: Text('שגיאה: ${widget.bookName}')),
        body: Center(child: Text('פרטי הספר \'${widget.bookName}\' לא נמצאו.')),
      );
    }

    final columnSelectionStates = progressProvider.getColumnSelectionStates(
        widget.topLevelCategoryKey, widget.bookName, bookDetails);

    final currentCompletionStatus = progressProvider.isBookCompleted(
        widget.topLevelCategoryKey, widget.bookName, bookDetails);

    final isBookCompleteIcon = currentCompletionStatus
        ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
        : Icon(Icons.circle_outlined,
            color: theme.colorScheme.onSurface.withOpacity(0.5));

    // NEW: Get the list of learnable items from the model
    final learnableItems = bookDetails.learnableItems;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.bookName),
          actions: [
            Padding(
                padding: const EdgeInsets.all(12.0), child: isBookCompleteIcon)
          ],
        ),
        body: Card(
          margin: const EdgeInsets.all(12),
          elevation: 2,
          color: theme.colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: theme.dividerColor.withOpacity(0.5)))),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          bookDetails.contentType,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _columnData.map((col) {
                            final columnId = col['id']!;
                            final columnLabel = col['label']!;
                            final bool? checkboxValue =
                                columnSelectionStates[columnId];

                            return Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    visualDensity: VisualDensity.compact,
                                    value: checkboxValue,
                                    onChanged: (bool? newValue) async {
                                      final bool selectAction =
                                          newValue == true;
                                      final confirmed =
                                          await _showWarningDialog();
                                      if (confirmed && mounted) {
                                        await Provider.of<ProgressProvider>(
                                                context,
                                                listen: false)
                                            .toggleSelectAllForColumn(
                                          widget.topLevelCategoryKey,
                                          widget.bookName,
                                          bookDetails,
                                          columnId,
                                          selectAction,
                                        );
                                      }
                                    },
                                    tristate: true,
                                    activeColor: theme.primaryColor,
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(columnLabel,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: theme.colorScheme.onSurface),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                // NEW: ListView.builder based on learnableItems
                Expanded(
                  child: ListView.builder(
                    itemCount: learnableItems.length,
                    itemBuilder: (ctx, index) {
                      final item = learnableItems[index];
                      final pageNumber = item.pageNumber;
                      final amudKey = item.amudKey;
                      final partName = item.partName;

                      // Check if a header for a new part is needed
                      bool showHeader = bookDetails.hasMultipleParts &&
                          (index == 0 ||
                              partName != learnableItems[index - 1].partName);

                      String rowLabel;
                      if (bookDetails.isDafType) {
                        final amudSymbol = (amudKey == "b") ? ":" : ".";
                        rowLabel =
                            "${HebrewUtils.intToGematria(pageNumber)}$amudSymbol";
                      } else {
                        rowLabel = HebrewUtils.intToGematria(pageNumber);
                      }

                      final pageProgress =
                          progressProvider.getProgressForPageAmud(
                              widget.topLevelCategoryKey,
                              widget.bookName,
                              pageNumber.toString(),
                              amudKey);

                      final rowBackgroundColor =
                          index % (bookDetails.isDafType ? 4 : 2) <
                                  (bookDetails.isDafType ? 2 : 1)
                              ? Colors.transparent
                              : theme.colorScheme.primaryContainer
                                  .withOpacity(0.15);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, right: 8.0, bottom: 4.0),
                              child: Text(
                                partName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          if (showHeader) const Divider(height: 1),
                          Container(
                            color: rowBackgroundColor,
                            padding: const EdgeInsets.symmetric(
                                vertical: 2, horizontal: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(rowLabel,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontFamily: 'Heebo',
                                          color: theme.colorScheme.onSurface)),
                                ),
                                Expanded(
                                  flex: 10,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: _columnData.map((col) {
                                      final columnName = col['id']!;
                                      return Expanded(
                                        child: Tooltip(
                                          message: col['label']!,
                                          child: Checkbox(
                                            visualDensity:
                                                VisualDensity.compact,
                                            value: pageProgress
                                                .getProperty(columnName),
                                            onChanged: (val) =>
                                                progressProvider.updateProgress(
                                                    widget.topLevelCategoryKey,
                                                    widget.bookName,
                                                    pageNumber,
                                                    amudKey,
                                                    columnName,
                                                    val ?? false,
                                                    bookDetails),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
