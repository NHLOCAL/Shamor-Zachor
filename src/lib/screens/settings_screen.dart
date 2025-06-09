import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/book_model.dart';
import '../providers/theme_provider.dart'; // Import ThemeProvider
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // For File operations
// import 'package:path_provider/path_provider.dart'; // Not strictly needed for saveFile dialog but good for default paths
import '../providers/progress_provider.dart';
import 'package:intl/intl.dart'; // For date formatting in filename

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
                              .withAlpha(77), // Corrected: single withAlpha
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
                              .withAlpha(77), // Corrected: .withValues to .withAlpha
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
                              .withAlpha(77), // Adjusted alpha directly
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
                                .withAlpha(77), // Adjusted alpha directly
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
                              .withAlpha(77), // Adjusted alpha directly
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

  Widget _buildCustomBooksManagement(DataProvider dataProvider, List<Widget> customBookWidgets) {
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 12.0, right: 8.0),
        child: Row( // Added Row for Icon and Text
          children: [
            Icon(Icons.edit_document_outlined, color: Theme.of(context).colorScheme.secondary), // Added Icon
            const SizedBox(width: 8), // Spacing
            Text(
              'ניהול ספרים מותאמים אישית',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary, // Using secondary color
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 15),
      Center(
        child: ElevatedButton.icon(
          onPressed: () => _showAddOrEditBookDialog(),
          icon: const Icon(Icons.add),
          label: const Text('הוסף ספר חדש'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.0),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      if (customBookWidgets.isEmpty && !dataProvider.isLoading)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Center(
            child: Text(
              'אין ספרים מותאמים אישית עדיין.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        )
      else
        ...customBookWidgets,
    ],
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

  Widget _buildThemeSelection(ThemeProvider themeProvider) {
    return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 12.0, right: 8.0),
        child: Row( // Added Row for Icon and Text
          children: [
            Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.secondary), // Added Icon
            const SizedBox(width: 8), // Spacing
            Text(
              'ערכת נושא',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary, // Using secondary color for header
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
      RadioListTile<ThemeModeOption>(
        title: const Text('בהיר'),
        value: ThemeModeOption.light,
        groupValue: themeProvider.themeModeOption,
        onChanged: (ThemeModeOption? value) {
            if (value != null) {
            themeProvider.setThemeMode(value);
            }
        },
        activeColor: Theme.of(context).colorScheme.primary,
        contentPadding: EdgeInsets.zero, // Adjust padding for RadioListTile
      ),
      RadioListTile<ThemeModeOption>(
        title: const Text('כהה'),
        value: ThemeModeOption.dark,
        groupValue: themeProvider.themeModeOption,
        onChanged: (ThemeModeOption? value) {
            if (value != null) {
            themeProvider.setThemeMode(value);
            }
        },
        activeColor: Theme.of(context).colorScheme.primary,
        contentPadding: EdgeInsets.zero,
      ),
      RadioListTile<ThemeModeOption>(
        title: const Text('ברירת מחדל של המערכת'),
        value: ThemeModeOption.system,
        groupValue: themeProvider.themeModeOption,
        onChanged: (ThemeModeOption? value) {
            if (value != null) {
            themeProvider.setThemeMode(value);
            }
        },
        activeColor: Theme.of(context).colorScheme.primary,
        contentPadding: EdgeInsets.zero,
      ),
    ],
  );
}

  Widget _buildBackupRestoreSection() {
    // Style for section title, similar to 'ניהול ספרים מותאמים אישית'
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.w600,
        );
    // Style for buttons, ensuring they are noticeable
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 12.0, right: 8.0),
          child: Row( // Added Row for Icon and Text
            children: [
              Icon(Icons.storage_outlined, color: Theme.of(context).colorScheme.secondary), // Added Icon
              const SizedBox(width: 8), // Spacing
              Text('גיבוי ושחזור נתונים', style: titleStyle),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined), // Changed Icon
              label: const Text('גיבוי לקובץ'),
              onPressed: _backupToFile,
              style: buttonStyle,
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore_page_outlined), // Icon confirmed
              label: const Text('שחזור מקובץ'),
              onPressed: _restoreFromFile,
              style: buttonStyle,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.cloud_upload_outlined, color: Theme.of(context).disabledColor), // Icon confirmed
          title: Text(
            'גיבוי לענן (בקרוב)',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
          enabled: false,
          onTap: () {
            // Non-functional, shown as disabled
          },
        ),
      ],
    );
  }

  Future<void> _backupToFile() async {
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    if (!mounted) return; // Check if the widget is still in the tree

    try {
      String? backupData = await progressProvider.backupProgress();

      if (backupData == null || backupData.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה: לא נוצרו נתוני גיבוי.')),
        );
        return;
      }

      // Generate a filename with the current date
      String formattedDate = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
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
        // User canceled the picker
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
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
    final dataProvider = Provider.of<DataProvider>(context, listen: false); // Get DataProvider
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
        // Show confirmation dialog
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('אישור שחזור'),
              content: const Text('האם אתה בטוח שברצונך לשחזר את הנתונים? הפעולה תדרוס את הנתונים הנוכחיים.'),
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

          // Pass DataProvider to restoreProgress
          bool success = await progressProvider.restoreProgress(fileContent, dataProvider);
          if (!mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('הנתונים שוחזרו בהצלחה!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('שגיאה בשחזור הנתונים. בדוק את תקינות הקובץ.')),
            );
          }
        } else {
          // User canceled the restore
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('שחזור הנתונים בוטל.')),
          );
        }
      } else {
        // User canceled the picker
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
    final themeProvider = Provider.of<ThemeProvider>(context); // Listen to ThemeProvider changes

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
                          color: Theme.of(context).colorScheme.onSurface, // Improved readability
                        ),
                      ),
                      subtitle: Text(
                        'קטגוריה: $categoryName\nסוג: ${bookDetails.contentType} (${bookDetails.pages} ${bookDetails.contentType == "דף" ? "דפים" : bookDetails.contentType})',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha((0.8 * 255).round()), // Improved readability for subtitle
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
                      _buildThemeSelection(themeProvider),
                      const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16),
                      _buildCustomBooksManagement(dataProvider, customBookWidgets),
                      const Divider(height: 32, thickness: 1, indent: 16, endIndent: 16), // Added Divider
                      _buildBackupRestoreSection(), // Added Backup/Restore section
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Helper extension for ColorScheme to more easily access surfaceContainerHighest
// This is a common pattern if you find yourself needing specific Material 3 roles
// that are not yet directly available in older Flutter versions or for custom theming.
extension ColorSchemeValues on ColorScheme {
  Color get surfaceContainerHighest => brightness == Brightness.light
      ? const Color(0xFFE7E0DE) // Example light value
      : const Color(0xFF4A4543); // Example dark value
}
