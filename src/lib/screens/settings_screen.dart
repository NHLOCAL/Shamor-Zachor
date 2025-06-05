import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/book_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>(); // State member _formKey

  void _showAddOrEditBookDialog(
      {BookDetails? existingBook,
      String? categoryOfBook,
      String? bookNameKey}) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final categoryNameController =
        TextEditingController(text: categoryOfBook ?? '');
    final bookNameController = TextEditingController(text: bookNameKey ?? '');
    final pagesController =
        TextEditingController(text: existingBook?.pages.toString() ?? '');

    final List<String> contentTypes = ['פרק', 'דף', 'סימן', 'אחר...'];
    String? selectedContentType = existingBook?.contentType;
    final customContentTypeController = TextEditingController();
    bool isCustomType = false;

    // Detect if existingBook has a custom type
    if (selectedContentType != null &&
        !['פרק', 'דף', 'סימן'].contains(selectedContentType)) {
      isCustomType = true;
      customContentTypeController.text = selectedContentType;
      selectedContentType = 'אחר...';
    }
    if (existingBook == null) {
      selectedContentType = 'פרק';
      isCustomType = false;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                existingBook == null ? 'הוסף ספר חדש' : 'ערוך ספר',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              content: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: categoryNameController,
                        decoration: InputDecoration(
                          labelText: 'שם קטגוריה',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 77),
                        ),
                        textDirection: TextDirection.rtl,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'נא להזין שם קטגוריה'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bookNameController,
                        decoration: InputDecoration(
                          labelText: 'שם הספר',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 77),
                        ),
                        textDirection: TextDirection.rtl,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'נא להזין שם ספר'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'סוג תוכן',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 77),
                        ),
                        value: selectedContentType,
                        items: contentTypes.map((String value) {
                          return DropdownMenuItem<String>(
                              value: value, child: Text(value));
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedContentType = newValue;
                            isCustomType = newValue == 'אחר...';
                            if (!isCustomType) {
                              customContentTypeController.clear();
                            }
                          });
                        },
                        validator: (value) =>
                            value == null ? 'נא לבחור סוג תוכן' : null,
                      ),
                      if (isCustomType) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: customContentTypeController,
                          decoration: InputDecoration(
                            labelText: 'הזן סוג תוכן מותאם',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 77),
                          ),
                          textDirection: TextDirection.rtl,
                          validator: (value) {
                            if (isCustomType &&
                                (value == null || value.isEmpty)) {
                              return 'נא להזין סוג תוכן מותאם';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: pagesController,
                        decoration: InputDecoration(
                          labelText: 'מספר עמודים/פרקים',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          filled: true,
                          fillColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 77),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'נא להזין מספר';
                          }
                          if (int.tryParse(value) == null) {
                            return 'נא להזין מספר תקין';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ביטול',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      String finalContentType;
                      if (selectedContentType == 'אחר...') {
                        finalContentType =
                            customContentTypeController.text.trim();
                      } else {
                        finalContentType = selectedContentType ?? 'פרק';
                      }
                      final List<String> columns = (finalContentType == 'דף')
                          ? ["עמוד א'", "עמוד ב'"]
                          : [finalContentType];

                      if (existingBook != null && existingBook.id != null) {
                        dataProvider.editCustomBook(
                          id: existingBook.id!,
                          categoryName: categoryNameController.text,
                          bookName: bookNameController.text,
                          contentType: finalContentType,
                          pages: int.parse(pagesController.text),
                          columns: columns,
                        );
                      } else {
                        dataProvider.addCustomBook(
                          categoryName: categoryNameController.text,
                          bookName: bookNameController.text,
                          contentType: finalContentType,
                          pages: int.parse(pagesController.text),
                          columns: columns,
                        );
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('שמור'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteBook(String bookId, String bookName, String categoryName) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'אישור מחיקה',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .error), // Use error color for delete confirmation title
          ),
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12.0)), // Consistent rounded corners
          content: Text(
            'האם אתה בטוח שברצונך למחוק את הספר "$bookName" מקטגוריית "$categoryName"?\nפעולה זו אינה ניתנת לשחזור.', // Added a warning
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ביטול',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary), // Themed cancel button
              ),
            ),
            ElevatedButton(
              // Changed to ElevatedButton for more prominence for the destructive action
              onPressed: () {
                dataProvider.deleteCustomBook(bookId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .error, // Error color for background
                foregroundColor: Theme.of(context)
                    .colorScheme
                    .onError, // Text color for contrast
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
              ),
              child: const Text('מחק'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  size: 26),
              const SizedBox(width: 8),
              Text('הגדרות',
                  style: Theme.of(context).appBarTheme.titleTextStyle),
            ],
          ),
        ),
        body: Consumer<DataProvider>(
          builder: (context, dataProvider, child) {
            if (dataProvider.error != null && dataProvider.error!.isNotEmpty) {
              // Simple error display, could be a SnackBar too
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('שגיאה: ${dataProvider.error}')),
                );
                // Consider clearing error in provider after showing
              });
            }

            List<Widget> customBookWidgets = [];
            dataProvider.allBookData.forEach((categoryName, category) {
              category.books.forEach((bookName, bookDetails) {
                if (bookDetails.isCustom && bookDetails.id != null) {
                  customBookWidgets.add(Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 6.0, horizontal: 4.0), // Adjusted margin
                    elevation: 2.0, // Slight elevation
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            8.0)), // Rounded corners for the card
                    child: ListTile(
                      leading: Icon(
                        Icons.menu_book, // Icon representing a book
                        color: Theme.of(context)
                            .colorScheme
                            .secondary, // Themed color for the icon
                      ),
                      title: Text(
                        bookName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600, // Bolder title
                          fontSize:
                              Theme.of(context).textTheme.titleMedium?.fontSize,
                          color: Colors.black, // Improved readability
                        ),
                      ),
                      subtitle: Text(
                        'קטגוריה: $categoryName\nסוג: ${bookDetails.contentType} (${bookDetails.pages} ${bookDetails.contentType == "דף" ? "דפים" : bookDetails.contentType})',
                        style: const TextStyle(
                          color: Colors
                              .black87, // Improved readability for subtitle
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: 'ערוך ספר',
                            child: IconButton(
                              icon: Icon(Icons.edit_note,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary), // Themed edit icon
                              onPressed: () => _showAddOrEditBookDialog(
                                  existingBook: bookDetails,
                                  categoryOfBook: categoryName,
                                  bookNameKey: bookName),
                            ),
                          ),
                          Tooltip(
                            message: 'מחק ספר',
                            child: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .error), // Themed delete icon
                              onPressed: () => _confirmDeleteBook(
                                  bookDetails.id!, bookName, categoryName),
                            ),
                          ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0), // Adjust ListTile padding
                    ),
                  ));
                }
              });
            });

            return Center(
              // Center the constrained content
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 700), // Max width for content
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Existing padding
                  child: ListView(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Center(
                          child: Text(
                            'ניהול ספרים מותאמים אישית',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          22, // Slightly smaller for a subtler look
                                    ) ??
                                const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(
                          height:
                              10), // This SizedBox can be adjusted or removed if bottom padding is sufficient
                      Center(
                        child: FloatingActionButton.extended(
                          onPressed: () => _showAddOrEditBookDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('הוסף ספר חדש'),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.0),
                          ),
                          extendedPadding:
                              const EdgeInsets.symmetric(horizontal: 24.0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...(customBookWidgets.isEmpty && !dataProvider.isLoading
                          ? [
                              const Center(
                                  child: Text('אין ספרים מותאמים אישית עדיין.'))
                            ]
                          : customBookWidgets),
                      // Other settings sections can be added here
                    ],
                  ),
                ), // Padding
              ), // ConstrainedBox
            ); // Center
          }, // Consumer<DataProvider>
        ), // body
      ), // Scaffold
    ); // Directionality
  }
} // class
