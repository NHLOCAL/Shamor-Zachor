import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/progress_provider.dart';
import '../models/book_model.dart';
// import '../models/progress_model.dart'; // Unused import removed
import '../widgets/hebrew_utils.dart';

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
      if (!mounted) return; // Check if mounted before accessing context
      final progressProvider =
          Provider.of<ProgressProvider>(context, listen: false);
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      final bookDetails =
          dataProvider.getBookDetails(widget.categoryName, widget.bookName);
      if (bookDetails != null) {
        if (mounted) {
          // Check again before setState
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

    final bookDetails =
        dataProvider.getBookDetails(widget.categoryName, widget.bookName);

    if (bookDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('שגיאה')),
        body: const Center(child: Text('פרטי הספר לא נמצאו.')),
      );
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
        ? Icon(Icons.check_circle, color: Colors.green.shade600)
        : Icon(Icons.circle_outlined, color: Colors.grey.shade400);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.bookName),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: isBookCompleteIcon,
            ),
          ],
        ),
        body: Card(
          margin: const EdgeInsets.all(10),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('סמן הכל כנלמד',
                          style: TextStyle(fontSize: 16)), // Made const
                      Checkbox(
                        value: _isSelectAllChecked,
                        onChanged: (val) => _toggleSelectAll(
                            val, progressProvider, bookDetails),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300))),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          bookDetails.contentType,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const Expanded(
                        // Made const
                        flex: 10,
                        child: Text(
                          'לימוד וחזרות',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                        color: Colors.grey.withOpacity(0.15)),
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

                      return Container(
                        color: index % (bookDetails.isDafType ? 4 : 2) <
                                (bookDetails.isDafType ? 2 : 1)
                            ? Colors.transparent
                            : Theme.of(context).primaryColor.withOpacity(0.03),
                        padding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(rowLabel,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontFamily: 'Heebo')),
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
