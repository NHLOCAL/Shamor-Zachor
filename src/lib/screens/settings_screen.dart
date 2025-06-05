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

  final _formKey = GlobalKey<FormState>();

  void _showAddOrEditBookDialog({BookDetails? existingBook, String? categoryOfBook, String? bookNameKey}) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final categoryNameController = TextEditingController(text: categoryOfBook ?? '');
    final bookNameController = TextEditingController(text: bookNameKey ?? '');
    final contentTypeController = TextEditingController(text: existingBook?.contentType ?? 'פרק');
    final pagesController = TextEditingController(text: existingBook?.pages.toString() ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(existingBook == null ? 'הוסף ספר חדש' : 'ערוך ספר'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: categoryNameController,
                    decoration: const InputDecoration(labelText: 'שם קטגוריה'),
                    textDirection: TextDirection.rtl,
                    validator: (value) => (value == null || value.isEmpty) ? 'נא להזין שם קטגוריה' : null,
                  ),
                  TextFormField(
                    controller: bookNameController,
                    decoration: const InputDecoration(labelText: 'שם הספר'),
                    textDirection: TextDirection.rtl,
                    validator: (value) => (value == null || value.isEmpty) ? 'נא להזין שם ספר' : null,
                  ),
                  TextFormField(
                    controller: contentTypeController,
                    decoration: const InputDecoration(labelText: 'סוג תוכן (דף, פרק, סימן)'),
                    textDirection: TextDirection.rtl,
                    validator: (value) => (value == null || value.isEmpty) ? 'נא להזין סוג תוכן' : null,
                  ),
                  TextFormField(
                    controller: pagesController,
                    decoration: const InputDecoration(labelText: 'מספר עמודים/פרקים'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'נא להזין מספר';
                      if (int.tryParse(value) == null) return 'נא להזין מספר תקין';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ביטול')),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final String contentType = contentTypeController.text;
                  final List<String> columns = (contentType == 'דף') ? ["עמוד א'", "עמוד ב'"] : [contentType];

                  if (existingBook != null && existingBook.id != null) {
                    dataProvider.editCustomBook(
                      id: existingBook.id!,
                      categoryName: categoryNameController.text,
                      bookName: bookNameController.text,
                      contentType: contentType,
                      pages: int.parse(pagesController.text),
                      columns: columns,
                    );
                  } else {
                    dataProvider.addCustomBook(
                      categoryName: categoryNameController.text,
                      bookName: bookNameController.text,
                      contentType: contentType,
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
  }

  void _confirmDeleteBook(String bookId, String bookName, String categoryName) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('אישור מחיקה'),
          content: Text('האם אתה בטוח שברצונך למחוק את הספר "$bookName" מקטגוריית "$categoryName"?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('ביטול')),
            TextButton(
              onPressed: () {
                dataProvider.deleteCustomBook(bookId);
                Navigator.of(context).pop();
              },
              child: const Text('מחק', style: TextStyle(color: Colors.red)),
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
          title: const Text('הגדרות'),
          bottom: PreferredSize( // For loading indicator
            preferredSize: const Size.fromHeight(4.0),
            child: Consumer<DataProvider>(
              builder: (context, provider, child) {
                return provider.isLoading ? const LinearProgressIndicator() : const SizedBox.shrink();
              },
            ),
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
                  customBookWidgets.add(
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                      child: ListTile(
                        title: Text(bookName),
                        subtitle: Text('קטגוריה: $categoryName, סוג: ${bookDetails.contentType}, ${bookDetails.pages} ${bookDetails.contentType == "דף" ? "דפים" : bookDetails.contentType}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddOrEditBookDialog(existingBook: bookDetails, categoryOfBook: categoryName, bookNameKey: bookName),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeleteBook(bookDetails.id!, bookName, categoryName),
                            ),
                          ],
                        ),
                      ),
                    )
                  );
                }
              });
            });

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: <Widget>[
                  Text(
                    'ניהול ספרים מותאמים אישית',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('הוסף ספר חדש'),
                    onPressed: () => _showAddOrEditBookDialog(),
                  ),
                  const SizedBox(height: 20),
                  if (customBookWidgets.isEmpty && !dataProvider.isLoading)
                    const Center(child: Text('אין ספרים מותאמים אישית עדיין.'))
                  else
                    ...customBookWidgets,
                  // Other settings sections can be added here
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
