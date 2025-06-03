import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/progress_provider.dart';
import '../models/book_model.dart';
import '../widgets/hebrew_utils.dart';
import '../widgets/completion_animation_overlay.dart';

class BookDetailScreen extends StatefulWidget {
  static const routeName = '/book-detail';

  final String categoryName;
  final String bookName;

  const BookDetailScreen({
    super.key,
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

    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    _completionSubscription = progressProvider.completionEvents.listen((event) {
      if (!mounted) return; // Ensure widget is still in the tree

      if (event.type == CompletionEventType.bookCompleted) {
        CompletionAnimationOverlay.show(
          context,
          "אשריך! תזכה ללמוד ספרים אחרים ולסיימם!",
        );
      } else if (event.type == CompletionEventType.reviewCycleCompleted) {
        CompletionAnimationOverlay.show(
          context,
          "מזל טוב! הלומד וחוזר כזורע וקוצר!",
        );
      }
    });

    // WidgetsBinding.instance.addPostFrameCallback((_) { // This logic for _isSelectAllChecked is no longer needed
    //   if (!mounted) return;
    //   final dataProvider = Provider.of<DataProvider>(context, listen: false);
    //   final bookDetails =
    //       dataProvider.getBookDetails(widget.categoryName, widget.bookName);
    //   if (bookDetails != null) {
    //     if (mounted) {
    //       // setState(() {
    //       //   _isSelectAllChecked = progressProvider.isBookCompleted( 
    //       //       widget.categoryName, widget.bookName, bookDetails);
    //       // });
    //     }
    //   }
    // });
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
          content: const Text("פעולה זו תאפס את הנתונים שסימנת! האם להמשיך?"),
          actions: <Widget>[
            TextButton(
              child: const Text("לא"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text("כן"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    return result ?? false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final progressProvider = Provider.of<ProgressProvider>(context);
    final theme = Theme.of(context);

    final bookDetails =
        dataProvider.getBookDetails(widget.categoryName, widget.bookName);

    if (bookDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('שגיאה')),
        body: const Center(child: Text('פרטי הספר לא נמצאו.')),
      );
    }
    
    final columnSelectionStates = progressProvider.getColumnSelectionStates(
        widget.categoryName, widget.bookName, bookDetails);

    final currentCompletionStatus = progressProvider.isBookCompleted(
        widget.categoryName, widget.bookName, bookDetails);
    
    final isBookCompleteIcon = currentCompletionStatus
        ? Icon(Icons.check_circle, color: Colors.green.shade700)
        : Icon(Icons.circle_outlined,
            color: theme.colorScheme.onSurface.withOpacity(0.5));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.bookName),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0), // הגדלתי Padding
              child: isBookCompleteIcon,
            ),
          ],
        ),
        body: Card(
          margin: const EdgeInsets.all(12), // מרווח סביב הכרטיס
          elevation: 2, // הצללה קלה
          color: theme.colorScheme.surface, // צבע רקע לכרטיס
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                // Padding( // Global "Select All" checkbox removed
                //   padding: const EdgeInsets.only(bottom: 10.0),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.end,
                //     children: [
                //       Text('סמן הכל כנלמד',
                //           style: TextStyle(
                //               fontSize: 16,
                //               color: theme.colorScheme.onSurface)),
                //       const SizedBox(width: 8),
                //       Checkbox(
                //         value: _isSelectAllChecked,
                //         onChanged: (val) => _toggleSelectAll(
                //             val, progressProvider, bookDetails),
                //         activeColor: theme.primaryColor,
                //       ),
                //     ],
                //   ),
                // ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // Adjusted padding
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
                              fontSize: 14, // Adjusted font size
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
                            final bool? checkboxValue = columnSelectionStates[columnId];

                            return Expanded( // Use Expanded to ensure columns take available space
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    visualDensity: VisualDensity.compact,
                                    value: checkboxValue,
                                    onChanged: (bool? newValue) async {
                                      // Determine the intended 'select' action for toggleSelectAllForColumn
                                      // If newValue is true, user wants to select all.
                                      // If newValue is false or null (when tristate cycles), user wants to deselect all for that column.
                                      final bool selectAction = newValue == true;
                                      
                                      // Only show warning if attempting to check (select) or if it's mixed and becoming unchecked
                                      // Or, more simply, always show if there's an actual change intended by user click
                                      // The current logic in _showWarningDialog is generic enough.
                                      // Let's refine: warning is about RESETTING data. 
                                      // Selecting a column resets other columns. Deselecting just deselects.
                                      // So, warning is most critical when selectAction is true.
                                      // However, the prompt implies the warning is for *any* such bulk action.
                                      
                                      // If current state is already what newValue suggests (e.g. already true, newValue is true), do nothing.
                                      // This can happen if the state update from provider is faster than expected.
                                      // However, `onChanged` for a checkbox usually fires only on actual user interaction that changes the state.
                                      // Let's assume `newValue` represents a state the user *wants* to transition to.

                                      final confirmed = await _showWarningDialog();
                                      if (confirmed && mounted) {
                                        // Use listen:false for actions
                                        await Provider.of<ProgressProvider>(context, listen: false)
                                            .toggleSelectAllForColumn(
                                          widget.categoryName,
                                          widget.bookName,
                                          bookDetails, // bookDetails is already confirmed not null
                                          columnId,
                                          selectAction, 
                                        );
                                      }
                                    },
                                    tristate: true,
                                    activeColor: theme.primaryColor,
                                  ),
                                  FittedBox( // Ensure text fits, especially for longer labels if any
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      columnLabel, 
                                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface),
                                      overflow: TextOverflow.ellipsis, // Prevent overflow with ellipsis
                                    ),
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
                Expanded(
                  child: ListView.separated(
                    itemCount:
                        bookDetails.pages * (bookDetails.isDafType ? 2 : 1),
                    separatorBuilder: (context, index) => Divider(
                        height: 1,
                        thickness: 0.5,
                        color: theme.dividerColor.withOpacity(0.2)),
                    itemBuilder: (ctx, index) {
                      int pageNumber;
                      String amudKey;
                      String rowLabel;

                      if (bookDetails.isDafType) {
                        pageNumber = bookDetails.startPage + (index ~/ 2);
                        amudKey = (index % 2 == 0) ? "a" : "b";
                        final amudSymbol = (amudKey == "b") ? ":" : ".";
                        rowLabel =
                            "${HebrewUtils.intToGematria(pageNumber)}$amudSymbol";
                      } else {
                        pageNumber = bookDetails.startPage + index;
                        amudKey = "a";
                        rowLabel = HebrewUtils.intToGematria(pageNumber);
                      }

                      final pageProgress =
                          progressProvider.getProgressForPageAmud(
                              widget.categoryName,
                              widget.bookName,
                              pageNumber.toString(),
                              amudKey);

                      // רקע מתחלף לשורות
                      final rowBackgroundColor =
                          index % (bookDetails.isDafType ? 4 : 2) <
                                  (bookDetails.isDafType ? 2 : 1)
                              ? Colors.transparent
                              : theme.colorScheme.primaryContainer
                                  .withOpacity(0.15);

                      return Container(
                        color: rowBackgroundColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 8), // הקטנתי Padding אנכי
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
                                children: [
                                  Tooltip(
                                      message: "לימוד",
                                      child: Checkbox(
                                          visualDensity: VisualDensity
                                              .compact, // צפוף יותר
                                          value: pageProgress.learn,
                                          onChanged: (val) =>
                                              progressProvider.updateProgress(
                                                  widget.categoryName,
                                                  widget.bookName,
                                                  pageNumber,
                                                  amudKey,
                                                  'learn',
                                                  val ?? false,
                                                  bookDetails))),
                                  Tooltip(
                                      message: "חזרה 1",
                                      child: Checkbox(
                                          visualDensity: VisualDensity.compact,
                                          value: pageProgress.review1,
                                          onChanged: (val) =>
                                              progressProvider.updateProgress(
                                                  widget.categoryName,
                                                  widget.bookName,
                                                  pageNumber,
                                                  amudKey,
                                                  'review1',
                                                  val ?? false,
                                                  bookDetails))),
                                  Tooltip(
                                      message: "חזרה 2",
                                      child: Checkbox(
                                          visualDensity: VisualDensity.compact,
                                          value: pageProgress.review2,
                                          onChanged: (val) =>
                                              progressProvider.updateProgress(
                                                  widget.categoryName,
                                                  widget.bookName,
                                                  pageNumber,
                                                  amudKey,
                                                  'review2',
                                                  val ?? false,
                                                  bookDetails))),
                                  Tooltip(
                                      message: "חזרה 3",
                                      child: Checkbox(
                                          visualDensity: VisualDensity.compact,
                                          value: pageProgress.review3,
                                          onChanged: (val) =>
                                              progressProvider.updateProgress(
                                                  widget.categoryName,
                                                  widget.bookName,
                                                  pageNumber,
                                                  amudKey,
                                                  'review3',
                                                  val ?? false,
                                                  bookDetails))),
                                ],
                              ),
                            ),
                          ],
                        ),
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
