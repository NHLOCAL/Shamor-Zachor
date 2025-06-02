import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/progress_provider.dart';
import '../models/book_model.dart';
import '../widgets/hebrew_utils.dart';
import '../widgets/completion_animation_widget.dart';
import '../widgets/review_completion_animation_widget.dart';

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
  bool _isSelectAllChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final progressProvider =
          Provider.of<ProgressProvider>(context, listen: false);
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final bookDetails =
          dataProvider.getBookDetails(widget.categoryName, widget.bookName);
      if (bookDetails != null) {
        if (mounted) {
          setState(() {
            _isSelectAllChecked = progressProvider.isBookCompleted(
                widget.categoryName, widget.bookName, bookDetails);
          });
        }
      }
    });
  }

  void _toggleSelectAll(
      bool? value, ProgressProvider progressProvider, BookDetails bookDetails) {
    if (value == null) return;
    if (mounted) {
      setState(() {
        _isSelectAllChecked = value;
      });
    }
    progressProvider.toggleSelectAll(
        widget.categoryName, widget.bookName, bookDetails, value);
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

    // Check if the book completion animation should be shown and clear the flag
    bool shouldShowBookCompletionAnimation = progressProvider.justManuallyCompletedBook != null &&
        progressProvider.justManuallyCompletedBook!['category'] == widget.categoryName &&
        progressProvider.justManuallyCompletedBook!['book'] == widget.bookName;

    if (shouldShowBookCompletionAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { 
          progressProvider.clearJustManuallyCompletedBookFlag();
        }
      });
    }

    // Check if the review completion animation should be shown and clear the flag
    bool shouldShowReviewAnimation = progressProvider.justCompletedReviewDetails != null &&
        progressProvider.justCompletedReviewDetails!['category'] == widget.categoryName &&
        progressProvider.justCompletedReviewDetails!['book'] == widget.bookName;

    if (shouldShowReviewAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { 
          progressProvider.clearJustCompletedReviewDetailsFlag();
        }
      });
    }

    final currentCompletionStatus = progressProvider.isBookCompleted(
        widget.categoryName, widget.bookName, bookDetails);
    if (_isSelectAllChecked != currentCompletionStatus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isSelectAllChecked = currentCompletionStatus;
          });
        }
      });
    }

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
        body: Stack( // Wrap existing body content with a Stack
          children: [
            // Original body content (the Card)
            Card(
              margin: const EdgeInsets.all(12), // מרווח סביב הכרטיס
              elevation: 2, // הצללה קלה
              color: theme.colorScheme.surface, // צבע רקע לכרטיס
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('סמן הכל כנלמד',
                          style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface)),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _isSelectAllChecked,
                        onChanged: (val) => _toggleSelectAll(
                            val, progressProvider, bookDetails),
                        activeColor: theme.primaryColor,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
                              color: theme.colorScheme.onSurface),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: Text(
                          'לימוד וחזרות',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface),
                          textAlign: TextAlign.center,
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

        // Conditional Animation Overlay for main book completion
        if (shouldShowBookCompletionAnimation)
          Positioned.fill(
            child: Container(
              color: Colors.blue.withOpacity(0.7), // Use a distinct color
              alignment: Alignment.center,
              child: const Text(
                'בדיקה: סיום ספר!',
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),

        // Conditional Animation Overlay for review completion
        if (shouldShowReviewAnimation)
          Positioned.fill(
            child: Container(
              color: Colors.green.withOpacity(0.7), // Use a different distinct color
              alignment: Alignment.center,
              child: const Text(
                'בדיקה: סיום חזרה!',
                textDirection: TextDirection.rtl,
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
