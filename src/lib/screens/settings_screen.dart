import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../providers/data_provider.dart';
import '../models/book_model.dart';
import '../providers/theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../providers/progress_provider.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

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
                              .withAlpha(77),
                        ),
                        textDirection: ui.TextDirection.rtl,
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
                              .withAlpha(77),
                        ),
                        textDirection: ui.TextDirection.rtl,
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
                              .withAlpha(77),
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
                                .withAlpha(77),
                          ),
                          textDirection: ui.TextDirection.rtl,
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
                              .withAlpha(77),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('אישור מחיקה',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          content: Text(
              'האם אתה בטוח שברצונך למחוק את הספר "$bookName"?\nפעולה זו אינה ניתנת לשחזור.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ביטול',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Provider.of<DataProvider>(context, listen: false)
                    .deleteCustomBook(bookId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
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

  Widget _buildSettingsSection(
      {required IconData icon,
      required String title,
      required List<Widget> children}) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelection(ThemeProvider themeProvider) {
    final theme = Theme.of(context);
    final segmentedButtonStyle = theme.segmentedButtonTheme.style;

    return _buildSettingsSection(
      icon: Icons.palette_outlined,
      title: 'ערכת נושא',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final bool useCompactLayout = constraints.maxWidth < 360;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SegmentedButton<ThemeModeOption>(
                  style: segmentedButtonStyle?.copyWith(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    ),
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  segments: <ButtonSegment<ThemeModeOption>>[
                    ButtonSegment<ThemeModeOption>(
                      value: ThemeModeOption.light,
                      label: useCompactLayout ? null : const Text('בהיר'),
                      icon: const Tooltip(
                        message: 'בהיר',
                        child: Icon(Icons.light_mode_outlined),
                      ),
                    ),
                    ButtonSegment<ThemeModeOption>(
                      value: ThemeModeOption.dark,
                      label: useCompactLayout ? null : const Text('כהה'),
                      icon: const Tooltip(
                        message: 'כהה',
                        child: Icon(Icons.dark_mode_outlined),
                      ),
                    ),
                    ButtonSegment<ThemeModeOption>(
                      value: ThemeModeOption.system,
                      label: useCompactLayout ? null : const Text('מערכת'),
                      icon: const Tooltip(
                        message: 'ברירת מחדל של המערכת',
                        child: Icon(Icons.settings_system_daydream_outlined),
                      ),
                    ),
                  ],
                  selected: <ThemeModeOption>{themeProvider.themeModeOption},
                  onSelectionChanged: (Set<ThemeModeOption> newSelection) {
                    if (newSelection.isNotEmpty) {
                      themeProvider.setThemeMode(newSelection.first);
                    }
                  },
                  showSelectedIcon: false,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackupRestoreSection() {
    return _buildSettingsSection(
      icon: Icons.storage_outlined,
      title: 'גיבוי ושחזור',
      children: [
        Text(
          'שמור את ההתקדמות והספרים המותאמים אישית שלך לקובץ, או שחזר מגיבוי קיים.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt),
              label: const Text('גיבוי'),
              onPressed: _backupToFile,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('שחזור'),
              onPressed: _restoreFromFile,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListTile(
          leading: Icon(Icons.cloud_upload_outlined,
              color: Theme.of(context).disabledColor),
          title: Text(
            'גיבוי לענן (בקרוב)',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
          dense: true,
          enabled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      ],
    );
  }

  Widget _buildCustomBooksManagement(List<Widget> customBookWidgets) {
    return _buildSettingsSection(
      icon: Icons.article_outlined,
      title: 'ספרים מותאמים אישית',
      children: [
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _showAddOrEditBookDialog(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('הוסף ספר חדש'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (customBookWidgets.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'אין ספרים מותאמים אישית עדיין.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ),
          )
        else
          ...customBookWidgets,
      ],
    );
  }

  Future<void> _backupToFile() async {
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    if (!mounted) return;

    try {
      String? backupData = await progressProvider.backupProgress();

      if (backupData == null || backupData.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה: לא נוצרו נתוני גיבוי.')),
        );
        return;
      }

      String formattedDate =
          DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      String fileName = 'shamor_vezachor_backup_$formattedDate.json';

      String? result = await FilePicker.platform.saveFile(
        dialogTitle: 'אנא בחר היכן לשמור את קובץ הגיבוי:',
        fileName: fileName,
        allowedExtensions: ['json'],
        type: FileType.custom,
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(backupData);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('הגיבוי נשמר בהצלחה!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שמירת הגיבוי בוטלה.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בשמירת הגיבוי: $e')),
      );
    }
  }

  Future<void> _restoreFromFile() async {
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    if (!mounted) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'אנא בחר קובץ גיבוי לשחזור:',
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        if (!mounted) return;

        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('אישור שחזור'),
              content: const Text(
                  'האם אתה בטוח שברצונך לשחזר את הנתונים? הפעולה תדרוס את הנתונים הנוכחיים.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('ביטול'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('שחזר'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        );

        if (confirmed == true) {
          String fileContent = await file.readAsString();
          if (fileContent.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('שגיאה: קובץ הגיבוי ריק.')),
            );
            return;
          }

          bool success =
              await progressProvider.restoreProgress(fileContent, dataProvider);
          if (!mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('הנתונים שוחזרו בהצלחה!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('שגיאה בשחזור הנתונים. בדוק את תקינות הקובץ.')),
            );
          }
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('שחזור הנתונים בוטל.')),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('בחירת קובץ בוטלה.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בתהליך השחזור: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings_outlined,
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
            if (dataProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (dataProvider.error != null && dataProvider.error!.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('שגיאה: ${dataProvider.error}'),
                      backgroundColor: Theme.of(context).colorScheme.error),
                );
              });
            }

            List<Map<String, dynamic>> customBooksData = [];
            dataProvider.allBookData.forEach((categoryName, category) {
              category.books.forEach((bookName, bookDetails) {
                if (bookDetails.isCustom && bookDetails.id != null) {
                  customBooksData.add({
                    'categoryName': categoryName,
                    'bookName': bookName,
                    'bookDetails': bookDetails,
                  });
                }
              });
            });

            customBooksData.sort((a, b) =>
                (a['bookName'] as String).compareTo(b['bookName'] as String));

            List<Widget> customBookWidgets = [];
            for (var i = 0; i < customBooksData.length; i++) {
              final bookData = customBooksData[i];
              final categoryName = bookData['categoryName'] as String;
              final bookName = bookData['bookName'] as String;
              final bookDetails = bookData['bookDetails'] as BookDetails;

              customBookWidgets.add(ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Icon(Icons.menu_book,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(bookName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'קטגוריה: $categoryName | ${bookDetails.pages} ${bookDetails.contentType}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          color: Theme.of(context).colorScheme.secondary),
                      tooltip: 'ערוך ספר',
                      onPressed: () => _showAddOrEditBookDialog(
                          existingBook: bookDetails,
                          categoryOfBook: categoryName,
                          bookNameKey: bookName),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error),
                      tooltip: 'מחק ספר',
                      onPressed: () => _confirmDeleteBook(
                          bookDetails.id!, bookName, categoryName),
                    ),
                  ],
                ),
                onTap: () => _showAddOrEditBookDialog(
                    existingBook: bookDetails,
                    categoryOfBook: categoryName,
                    bookNameKey: bookName),
              ));
              if (i < customBooksData.length - 1) {
                customBookWidgets
                    .add(const Divider(indent: 16, endIndent: 16, height: 1));
              }
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: <Widget>[
                    _buildThemeSelection(themeProvider),
                    _buildCustomBooksManagement(customBookWidgets),
                    _buildBackupRestoreSection(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension ColorSchemeValues on ColorScheme {
  Color get surfaceContainerHighest => brightness == Brightness.light
      ? const Color(0xFFE7E0DE)
      : const Color(0xFF4A4543);
}
