import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../providers/data_provider.dart';
import '../models/book_model.dart';
import '../services/custom_book_service.dart';
import '../providers/theme_provider.dart';
import '../utils/external_links.dart';
import '../utils/top_app_bar_visibility.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';

import '../providers/progress_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  static final Uri _appWebsiteUrl = buildTrackedUri(
    Uri.parse('https://shamor-zachor.ze-kal.top/'),
    content: 'app_website',
  );
  static final Uri _developerWebsiteUrl = buildTrackedUri(
    Uri.parse('https://nhlocal.github.io/'),
    content: 'developer_website',
  );

  Future<void> _openExternalLink(Uri url) async {
    final opened = await openExternalUri(url);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('לא ניתן לפתוח את הקישור: $url')),
      );
    }
  }

  void _showAddOrEditBookDialog(
      {BookDetails? existingBook,
      String? topLevelCategoryOfBook,
      List<String> subCategoryPathOfBook = const [],
      String? bookNameKey}) {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final existingTopLevelCategories = dataProvider.allBookData.keys.toList()
      ..sort();
    final newTopLevelCategoryController = TextEditingController();
    final newSubCategoryController = TextEditingController();
    final bookNameController = TextEditingController(text: bookNameKey ?? '');
    final pagesController = TextEditingController(
      text: existingBook?.originalPageCount?.toString() ??
          (existingBook == null || existingBook.hasMultipleParts
              ? ''
              : existingBook.pageCountForDisplay.toString()),
    );

    final List<String> contentTypes = ['פרק', 'דף', 'סימן', 'אחר...'];
    String? selectedContentType = existingBook?.contentType;
    final customContentTypeController = TextEditingController();
    bool isCustomType = false;
    bool useExistingTopLevelCategory = topLevelCategoryOfBook != null &&
        existingTopLevelCategories.contains(topLevelCategoryOfBook);
    String? selectedTopLevelCategory = useExistingTopLevelCategory
        ? topLevelCategoryOfBook
        : (existingTopLevelCategories.isNotEmpty
            ? existingTopLevelCategories.first
            : null);
    final initialSubCategoryNames =
        _subCategoryNamesFor(dataProvider, selectedTopLevelCategory);
    String selectedSubCategoryMode = subCategoryPathOfBook.isEmpty
        ? '__none__'
        : (initialSubCategoryNames.contains(subCategoryPathOfBook.last)
            ? subCategoryPathOfBook.last
            : '__new__');
    if (selectedSubCategoryMode == '__new__' &&
        subCategoryPathOfBook.isNotEmpty) {
      newSubCategoryController.text = subCategoryPathOfBook.last;
    }
    bool useParts = existingBook?.hasMultipleParts == true ||
        (existingBook != null && existingBook.originalPageCount == null);
    final List<_EditableBookPart> editableParts =
        existingBook?.parts.isNotEmpty == true
            ? existingBook!.parts
                .map((part) => _EditableBookPart.fromBookPart(part))
                .toList()
            : [_EditableBookPart()];

    if (selectedContentType != null &&
        !['פרק', 'דף', 'סימן'].contains(selectedContentType)) {
      isCustomType = true;
      customContentTypeController.text = selectedContentType;
      selectedContentType = 'אחר...';
    }
    if (existingBook == null) {
      selectedContentType = 'פרק';
      isCustomType = false;
      useExistingTopLevelCategory = existingTopLevelCategories.isNotEmpty;
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'מיקום הספר',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.folder_open_outlined),
                            label: Text('קטגוריה קיימת'),
                          ),
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.create_new_folder_outlined),
                            label: Text('קטגוריה חדשה'),
                          ),
                        ],
                        selected: {useExistingTopLevelCategory},
                        onSelectionChanged: existingTopLevelCategories.isEmpty
                            ? null
                            : (selection) {
                                setState(() {
                                  useExistingTopLevelCategory = selection.first;
                                  selectedSubCategoryMode = '__none__';
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      if (useExistingTopLevelCategory)
                        DropdownButtonFormField<String>(
                          key: ValueKey('top-level-$selectedTopLevelCategory'),
                          initialValue: selectedTopLevelCategory,
                          decoration:
                              _dialogInputDecoration(context, 'קטגוריה ראשית'),
                          items: existingTopLevelCategories
                              .map((categoryName) => DropdownMenuItem(
                                    value: categoryName,
                                    child: Text(categoryName),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTopLevelCategory = value;
                              selectedSubCategoryMode = '__none__';
                            });
                          },
                          validator: (value) =>
                              value == null ? 'נא לבחור קטגוריה' : null,
                        )
                      else
                        TextFormField(
                          controller: newTopLevelCategoryController,
                          decoration: _dialogInputDecoration(
                              context, 'שם קטגוריה ראשית חדשה'),
                          textDirection: ui.TextDirection.rtl,
                          validator: (value) {
                            if (!useExistingTopLevelCategory &&
                                (value == null || value.trim().isEmpty)) {
                              return 'נא להזין שם קטגוריה';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey(
                            'sub-category-$selectedTopLevelCategory-$selectedSubCategoryMode'),
                        initialValue: selectedSubCategoryMode,
                        decoration:
                            _dialogInputDecoration(context, 'תת־קטגוריה'),
                        items: [
                          const DropdownMenuItem(
                              value: '__none__', child: Text('ללא')),
                          ...(useExistingTopLevelCategory
                                  ? _subCategoryNamesFor(
                                      dataProvider, selectedTopLevelCategory)
                                  : const <String>[])
                              .map((name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  )),
                          const DropdownMenuItem(
                              value: '__new__', child: Text('תת־קטגוריה חדשה')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedSubCategoryMode = value ?? '__none__';
                          });
                        },
                      ),
                      if (selectedSubCategoryMode == '__new__') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: newSubCategoryController,
                          decoration: _dialogInputDecoration(
                              context, 'שם תת־קטגוריה חדשה'),
                          textDirection: ui.TextDirection.rtl,
                          validator: (value) {
                            if (selectedSubCategoryMode == '__new__' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'נא להזין שם תת־קטגוריה';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'פרטי הספר',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: bookNameController,
                        decoration: _dialogInputDecoration(context, 'שם הספר'),
                        textDirection: ui.TextDirection.rtl,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'נא להזין שם ספר'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('content-type-$selectedContentType'),
                        decoration: _dialogInputDecoration(context, 'סוג תוכן'),
                        initialValue: selectedContentType,
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
                          decoration: _dialogInputDecoration(
                              context, 'הזן סוג תוכן מותאם'),
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
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.format_list_numbered_rtl),
                            label: Text('רציף'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.account_tree_outlined),
                            label: Text('מחולק'),
                          ),
                        ],
                        selected: {useParts},
                        onSelectionChanged: (selection) {
                          setState(() {
                            useParts = selection.first;
                            if (editableParts.isEmpty) {
                              editableParts.add(_EditableBookPart());
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (!useParts)
                        TextFormField(
                          controller: pagesController,
                          decoration: _dialogInputDecoration(
                              context, 'מספר עמודים/פרקים/סימנים'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (useParts) return null;
                            if (value == null || value.isEmpty) {
                              return 'נא להזין מספר';
                            }
                            if (num.tryParse(value) == null) {
                              return 'נא להזין מספר תקין';
                            }
                            return null;
                          },
                        )
                      else
                        Column(
                          children: [
                            for (var i = 0; i < editableParts.length; i++)
                              _buildEditablePartFields(
                                context,
                                editableParts,
                                i,
                                setState,
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    editableParts.add(_EditableBookPart());
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('הוסף חלק'),
                              ),
                            ),
                          ],
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

                      final topLevelCategoryName = useExistingTopLevelCategory
                          ? (selectedTopLevelCategory ?? '').trim()
                          : newTopLevelCategoryController.text.trim();
                      final subCategoryPath = _selectedSubCategoryPathForDialog(
                        selectedSubCategoryMode,
                        newSubCategoryController.text,
                      );
                      final parts = useParts
                          ? editableParts
                              .map((part) => part.toCustomBookPart())
                              .toList()
                          : const <CustomBookPart>[];

                      if (existingBook != null && existingBook.id != null) {
                        dataProvider.editCustomBook(
                          id: existingBook.id!,
                          topLevelCategoryName: topLevelCategoryName,
                          subCategoryPath: subCategoryPath,
                          bookName: bookNameController.text,
                          contentType: finalContentType,
                          pages:
                              useParts ? null : num.parse(pagesController.text),
                          parts: parts,
                        );
                      } else {
                        dataProvider.addCustomBook(
                          topLevelCategoryName: topLevelCategoryName,
                          subCategoryPath: subCategoryPath,
                          bookName: bookNameController.text,
                          contentType: finalContentType,
                          pages:
                              useParts ? null : num.parse(pagesController.text),
                          parts: parts,
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

  InputDecoration _dialogInputDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      filled: true,
      fillColor:
          Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(77),
    );
  }

  List<String> _subCategoryNamesFor(
      DataProvider dataProvider, String? topLevelCategoryName) {
    final category = dataProvider.allBookData[topLevelCategoryName];
    if (category?.subcategories == null) return const [];
    final names = category!.subcategories!
        .map((subCategory) => subCategory.name)
        .where((name) => name.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return names;
  }

  List<String> _selectedSubCategoryPathForDialog(
    String selectedSubCategoryMode,
    String newSubCategoryName,
  ) {
    if (selectedSubCategoryMode == '__none__') {
      return const [];
    }
    if (selectedSubCategoryMode == '__new__') {
      final trimmed = newSubCategoryName.trim();
      return trimmed.isEmpty ? const [] : [trimmed];
    }
    return [selectedSubCategoryMode];
  }

  Widget _buildEditablePartFields(
    BuildContext context,
    List<_EditableBookPart> parts,
    int index,
    void Function(void Function()) setDialogState,
  ) {
    final part = parts[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'חלק ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'מחק חלק',
                  onPressed: parts.length == 1
                      ? null
                      : () {
                          setDialogState(() {
                            parts.removeAt(index);
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextFormField(
              controller: part.nameController,
              decoration: _dialogInputDecoration(context, 'שם החלק'),
              textDirection: ui.TextDirection.rtl,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'נא להזין שם חלק';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: part.startController,
                    decoration: _dialogInputDecoration(context, 'התחלה'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      if (number == null || number <= 0) {
                        return 'מספר תקין';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: part.endController,
                    decoration: _dialogInputDecoration(context, 'סיום'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final end = int.tryParse(value ?? '');
                      final start = int.tryParse(part.startController.text);
                      if (end == null || end <= 0) {
                        return 'מספר תקין';
                      }
                      if (start != null && end < start) {
                        return 'לפחות התחלה';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: part.excludeController,
              decoration: _dialogInputDecoration(
                  context, 'דילוגים, מופרדים בפסיקים (אופציונלי)'),
              keyboardType: TextInputType.text,
              validator: (value) {
                final invalidItems = _parseExcludedPartItems(value)
                    .where((item) => item == null)
                    .toList();
                if (invalidItems.isNotEmpty) {
                  return 'נא להזין מספרים מופרדים בפסיקים';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  List<int?> _parseExcludedPartItems(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map((item) => int.tryParse(item))
        .toList();
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

  Widget _buildAboutSection() {
    final theme = Theme.of(context);

    return _buildSettingsSection(
      icon: Icons.info_outline,
      title: 'אודות',
      children: [
        Text(
          'שמור וזכור הוא כלי למעקב מסודר אחר לימוד וחזרות בספרי יסוד. ניתן לסמן התקדמות, לעקוב אחר חזרות, ולראות בצורה ברורה מה נלמד ומה עדיין דורש השלמה.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'הנתונים נשמרים במכשיר בלבד, וניתן לגבות ולשחזר אותם מקובץ דרך מסך ההגדרות.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.public, color: theme.colorScheme.primary),
          title: const Text('אתר שמור וזכור'),
          subtitle: const Text('מידע, הורדות והיכרות עם האפליקציה'),
          trailing: const Icon(Icons.open_in_new),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          onTap: () => _openExternalLink(_appWebsiteUrl),
        ),
        const Divider(indent: 16, endIndent: 16, height: 1),
        ListTile(
          leading: Icon(Icons.code_outlined, color: theme.colorScheme.primary),
          title: const Text('אתר המפתח'),
          subtitle: const Text('עוד כלים ופרויקטים מאת NH Local'),
          trailing: const Icon(Icons.open_in_new),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          onTap: () => _openExternalLink(_developerWebsiteUrl),
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
                      // UPDATED: Fixed deprecated withOpacity
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha((0.6 * 255).round()),
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
    if (!mounted) return;
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: false);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('יוצר נתוני גיבוי...')),
      );

      String? backupData = await progressProvider.backupProgress();

      if (backupData == null || backupData.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('שגיאה: לא נוצרו נתוני גיבוי.'),
              backgroundColor: Colors.red),
        );
        return;
      }

      final Uint8List fileBytes = utf8.encode(backupData);
      String formattedDate =
          DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      String fileName = 'shamor_vezachor_backup_$formattedDate.json';

      await FilePicker.platform.saveFile(
        dialogTitle: 'אנא בחר היכן לשמור את קובץ הגיבוי:',
        fileName: fileName,
        bytes: fileBytes,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('תהליך שמירת הגיבוי הסתיים.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('שגיאה בשמירת הגיבוי: $e'),
            backgroundColor: Colors.red),
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

      if (result != null &&
          (result.files.single.bytes != null ||
              result.files.single.path != null)) {
        String? fileContent;
        if (result.files.single.bytes != null) {
          fileContent = String.fromCharCodes(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          final filePath = result.files.single.path!;
          final file = File(filePath);
          fileContent = await file.readAsString();
        }

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
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
                TextButton(
                  child: const Text('שחזר'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
              ],
            );
          },
        );

        if (confirmed == true) {
          if (fileContent == null || fileContent.isEmpty) {
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
    final bool showTopAppBar = shouldShowTopAppBar(Theme.of(context).platform);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: showTopAppBar
            ? AppBar(
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
              )
            : null,
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

            void collectCustomBooks(
              String topLevelCategoryName,
              List<String> subCategoryPath,
              BookCategory category,
            ) {
              category.books.forEach((bookName, bookDetails) {
                if (bookDetails.isCustom && bookDetails.id != null) {
                  customBooksData.add({
                    'topLevelCategoryName': topLevelCategoryName,
                    'subCategoryPath': subCategoryPath,
                    'categoryName': subCategoryPath.isEmpty
                        ? topLevelCategoryName
                        : subCategoryPath.last,
                    'bookName': bookName,
                    'bookDetails': bookDetails,
                  });
                }
              });

              for (final subCategory in category.subcategories ?? []) {
                collectCustomBooks(
                  topLevelCategoryName,
                  [...subCategoryPath, subCategory.name],
                  subCategory,
                );
              }
            }

            dataProvider.allBookData.forEach((categoryName, category) {
              collectCustomBooks(categoryName, const [], category);
            });

            customBooksData.sort((a, b) =>
                (a['bookName'] as String).compareTo(b['bookName'] as String));

            List<Widget> customBookWidgets = [];
            for (var i = 0; i < customBooksData.length; i++) {
              final bookData = customBooksData[i];
              final topLevelCategoryName =
                  bookData['topLevelCategoryName'] as String;
              final subCategoryPath =
                  (bookData['subCategoryPath'] as List<String>);
              final categoryName = bookData['categoryName'] as String;
              final bookName = bookData['bookName'] as String;
              final bookDetails = bookData['bookDetails'] as BookDetails;
              final categoryPathLabel = subCategoryPath.isEmpty
                  ? topLevelCategoryName
                  : '$topLevelCategoryName > ${subCategoryPath.join(' > ')}';

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
                    'קטגוריה: $categoryPathLabel | ${bookDetails.pageCountForDisplay} ${bookDetails.contentType}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          color: Theme.of(context).colorScheme.secondary),
                      tooltip: 'ערוך ספר',
                      onPressed: () => _showAddOrEditBookDialog(
                          existingBook: bookDetails,
                          topLevelCategoryOfBook: topLevelCategoryName,
                          subCategoryPathOfBook: subCategoryPath,
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
                    topLevelCategoryOfBook: topLevelCategoryName,
                    subCategoryPathOfBook: subCategoryPath,
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
                    _buildAboutSection(),
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

class _EditableBookPart {
  final TextEditingController nameController;
  final TextEditingController startController;
  final TextEditingController endController;
  final TextEditingController excludeController;

  _EditableBookPart({
    String name = '',
    String start = '',
    String end = '',
    String exclude = '',
  })  : nameController = TextEditingController(text: name),
        startController = TextEditingController(text: start),
        endController = TextEditingController(text: end),
        excludeController = TextEditingController(text: exclude);

  factory _EditableBookPart.fromBookPart(BookPart part) {
    return _EditableBookPart(
      name: part.name,
      start: part.startPage.toString(),
      end: part.endPage.toString(),
      exclude: part.excludedPages.join(', '),
    );
  }

  CustomBookPart toCustomBookPart() {
    final exclude = excludeController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(int.parse)
        .toList();

    return CustomBookPart(
      name: nameController.text.trim(),
      start: int.parse(startController.text),
      end: int.parse(endController.text),
      exclude: exclude,
    );
  }
}

extension ColorSchemeValues on ColorScheme {
  Color get surfaceContainerHighest => brightness == Brightness.light
      ? const Color(0xFFE7E0DE)
      : const Color(0xFF4A4543);
}
