import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/book_card_widget.dart';
import '../utils/category_sorter.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Widget> _searchResults = [];
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    if (dataProvider.allBookData.isNotEmpty && _tabController == null) {
      // 2. שימוש במיון כאן
      final categories =
          CategorySorter.sort(dataProvider.allBookData.keys.toList());
      print("[BooksScreen] didChangeDependencies: Categories for tabs: $categories");
      _setupTabController(categories, switchToIndex: _currentTabIndex);
    }
  }

  void _setupTabController(List<String> categories, {int? switchToIndex}) {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _tabController = null;

    int newTotalTabs = categories.length + (_searchResults.isNotEmpty ? 1 : 0);

    if (newTotalTabs == 0) {
      _currentTabIndex = 0;
      if (mounted) {
        setState(() {});
      }
      return;
    }

    _tabController = TabController(length: newTotalTabs, vsync: this);

    int targetIndex = 0;
    if (switchToIndex != null &&
        switchToIndex >= 0 &&
        switchToIndex < newTotalTabs) {
      targetIndex = switchToIndex;
    } else if (_currentTabIndex >= 0 && _currentTabIndex < newTotalTabs) {
      targetIndex = _currentTabIndex;
    }

    if (targetIndex >= newTotalTabs || targetIndex < 0) {
      targetIndex = 0;
    }

    _tabController!.index = targetIndex;
    _currentTabIndex = targetIndex;

    _tabController!.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!mounted || _tabController == null || _tabController!.indexIsChanging) {
      return;
    }

    final newIndex = _tabController!.index;

    if (_currentTabIndex == newIndex) {
      return;
    }

    final previousStableIndex = _currentTabIndex;
    _currentTabIndex = newIndex;

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    // 3. שימוש במיון כאן
    final categories =
        CategorySorter.sort(dataProvider.allBookData.keys.toList());
    final int searchTabIndexWhenVisible = categories.length;

    if (_searchResults.isNotEmpty &&
        previousStableIndex == searchTabIndexWhenVisible &&
        _currentTabIndex != searchTabIndexWhenVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _searchController.clear();
            _searchResults = [];
            _setupTabController(categories, switchToIndex: _currentTabIndex);
          });
        }
      });
    }
  }

  void _performSearch(String term, DataProvider dataProvider) {
    // 4. שימוש במיון כאן
    final categories =
        CategorySorter.sort(dataProvider.allBookData.keys.toList());

    if (term.length < 2) {
      if (_searchResults.isNotEmpty) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            int switchToIndexAfterClear = _currentTabIndex;
            if (switchToIndexAfterClear == categories.length) {
              switchToIndexAfterClear = 0;
            }
            if (switchToIndexAfterClear >= categories.length &&
                categories.isNotEmpty) {
              switchToIndexAfterClear = categories.length - 1;
            } else if (categories.isEmpty) {
              switchToIndexAfterClear = 0;
            }
            _setupTabController(categories,
                switchToIndex: switchToIndexAfterClear);
          });
        }
      }
      return;
    }

    List<Widget> results = [];
    final String searchTerm = term.toLowerCase();

    dataProvider.allBookData.forEach((categoryName, categoryData) {
      // Search in direct books of the top-level category
      categoryData.books.forEach((bookName, bookDetails) {
        if (bookName.toLowerCase().contains(searchTerm) ||
            categoryName.toLowerCase().contains(searchTerm)) {
          results.add(
            SearchBookCardWidget(
              topLevelCategoryKey: categoryName, // This is the topLevelCategoryKey
              categoryName: categoryName, // For display, this is the top-level category name
              bookName: bookName,
              bookDetails: bookDetails,
            ),
          );
        }
      });

      // Search in subcategories
      if (categoryData.subcategories != null) {
        for (var subCategory in categoryData.subcategories!) {
          // Check if subcategory name matches
          bool subCategoryNameMatches = subCategory.name.toLowerCase().contains(searchTerm);

          subCategory.books.forEach((bookName, bookDetails) {
            if (bookName.toLowerCase().contains(searchTerm) || subCategoryNameMatches) {
              // If the book name matches OR the subcategory name matches, add the book.
              // This ensures all books from a matching subcategory are shown.
              results.add(
                SearchBookCardWidget(
                  topLevelCategoryKey: categoryName, // This is the topLevelCategoryKey
                  categoryName: subCategory.name, // For display, this is the subCategory.name
                  bookName: bookName,
                  bookDetails: bookDetails,
                ),
              );
            }
          });
        }
      }
    });

    // Remove duplicates that might occur if a book is matched via its own name AND its category/subcategory name.
    // This is a simple way to do it; for performance on very large lists, a Set could be used during collection.
    if (results.isNotEmpty) {
      final uniqueResults = <String>{};
      results = results.where((widget) {
        if (widget is SearchBookCardWidget) {
          final key = "${widget.categoryName}-${widget.bookName}";
          if (uniqueResults.contains(key)) {
            return false;
          } else {
            uniqueResults.add(key);
            return true;
          }
        }
        return true; // Should not happen if results only contain SearchBookCardWidget
      }).toList();
    }

    results.sort((a, b) {
      if (a is SearchBookCardWidget && b is SearchBookCardWidget) {
        // Prioritize matches in book names, then subcategory names, then category names
        bool aBookNameMatch = a.bookName.toLowerCase().contains(searchTerm);
        bool bBookNameMatch = b.bookName.toLowerCase().contains(searchTerm);
        bool aCategoryNameMatch = a.categoryName.toLowerCase().contains(searchTerm);
        bool bCategoryNameMatch = b.categoryName.toLowerCase().contains(searchTerm);

        if (aBookNameMatch && !bBookNameMatch) return -1;
        if (!aBookNameMatch && bBookNameMatch) return 1;
        if (aBookNameMatch && bBookNameMatch) return a.bookName.compareTo(b.bookName); // Sort by book name if both match

        if (aCategoryNameMatch && !bCategoryNameMatch) return -1;
        if (!aCategoryNameMatch && bCategoryNameMatch) return 1;

        return a.bookName.compareTo(b.bookName); // Default sort by book name
      }
      return 0;
    });

    if (mounted) {
      setState(() {
        bool hadSearchResults = _searchResults.isNotEmpty;
        _searchResults = results;

        final int newSearchTabIndex = categories.length;

        if (results.isNotEmpty && !hadSearchResults) {
          _setupTabController(categories, switchToIndex: newSearchTabIndex);
        } else if (results.isEmpty && hadSearchResults) {
          int switchToIndexAfterClear = _currentTabIndex;
          if (switchToIndexAfterClear == newSearchTabIndex &&
              categories.isNotEmpty) {
            switchToIndexAfterClear = 0;
          } else if (switchToIndexAfterClear >= categories.length &&
              categories.isNotEmpty) {
            switchToIndexAfterClear = categories.length - 1;
          } else if (categories.isEmpty) {
            switchToIndexAfterClear = 0;
          }
          _setupTabController(categories,
              switchToIndex: switchToIndexAfterClear);
        } else if (results.isNotEmpty && hadSearchResults) {
          if (_tabController != null &&
              _tabController!.index != newSearchTabIndex) {
            _tabController!.animateTo(newSearchTabIndex);
            _currentTabIndex = newSearchTabIndex;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchField(DataProvider dataProvider) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'חיפוש ספר...',
              prefixIcon: Icon(Icons.search,
                  color: theme.colorScheme.onSurface.withOpacity(0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                    BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              isDense: true,
            ),
            onChanged: (value) {
              _performSearch(value, dataProvider);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);

    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (dataProvider.error != null) {
      return Center(child: Text('שגיאה: ${dataProvider.error}'));
    }

    // 5. שימוש במיון פעם אחרונה ומרכזית כאן
    final categories =
        CategorySorter.sort(dataProvider.allBookData.keys.toList());
    final expectedTabLength =
        categories.length + (_searchResults.isNotEmpty ? 1 : 0);

    if ((_tabController == null && expectedTabLength > 0) ||
        (_tabController != null &&
            _tabController!.length != expectedTabLength)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setupTabController(categories, switchToIndex: _currentTabIndex);
          if (mounted) setState(() {});
        }
      });
      return Column(
        children: [
          _buildSearchField(dataProvider),
          const Expanded(
              child: Center(
                  child: Text("מכין טאבים...",
                      style: TextStyle(fontStyle: FontStyle.italic)))),
        ],
      );
    }

    if (_tabController == null ||
        _tabController!.length == 0 && _searchController.text.isEmpty) {
      return Column(
        children: [
          _buildSearchField(dataProvider),
          Expanded(
              child: Center(
                  child: Text('אין נתונים להצגה.',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.6))))),
        ],
      );
    }
    if (_tabController == null ||
        _tabController!.length == 0 &&
            _searchController.text.isNotEmpty &&
            _searchResults.isEmpty) {
      return Column(
        children: [
          _buildSearchField(dataProvider),
          Expanded(
              child: Center(
                  child: Text('לא נמצאו תוצאות חיפוש.',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.6))))),
        ],
      );
    }

    List<Tab> tabs = categories.map((catName) => Tab(text: catName)).toList();
    List<Widget> tabViews = categories.map((categoryName) {
      final categoryData = dataProvider.allBookData[categoryName]!;
      print("[BooksScreen] Building tabView for: ${categoryData.name}");
      print("  [BooksScreen] Subcategories exist: ${categoryData.subcategories != null && categoryData.subcategories!.isNotEmpty}");
      print("  [BooksScreen] Direct books exist: ${categoryData.books.isNotEmpty}");
      final progressProvider = Provider.of<ProgressProvider>(context, listen: true);

      List<Widget> children = [];

      // Add direct books first, if any
      if (categoryData.books.isNotEmpty) {
        print("    [BooksScreen] Processing direct books for GridView. Count: ${categoryData.books.length}");
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              categoryData.name, // Or a generic title like "ספרים כלליים"
              style: Theme.of(context).textTheme.titleLarge,
            ),
          )
        );
        children.add(GridView.builder(
          shrinkWrap: true, // Important for GridView inside ListView
          physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
          key: PageStorageKey<String>('${categoryName}_direct_books'),
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170,
            childAspectRatio: 150 / 75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categoryData.books.length,
          itemBuilder: (ctx, i) {
            final bookName = categoryData.books.keys.elementAt(i);
            final bookDetails = categoryData.books.values.elementAt(i);
            return BookCardWidget(
              topLevelCategoryKey: categoryName, // This is the topLevelCategoryKey
              categoryName: categoryName, // For display, this is the top-level category name
              bookName: bookName,
              bookDetails: bookDetails,
              bookProgressData: progressProvider.getProgressForBook(categoryName, bookName),
            );
          },
        ));
      }

      // Add subcategories with ExpansionTile
      if (categoryData.subcategories != null && categoryData.subcategories!.isNotEmpty) {
        categoryData.subcategories!.forEach((subCat) {
          print("    [BooksScreen] Processing SubCategory for ExpansionTile: ${subCat.name}");
          print("      [BooksScreen] Books in ${subCat.name}: ${subCat.books.length}");
        });
        for (var subCategory in categoryData.subcategories!) {
          children.add(
            ExpansionTile(
              key: PageStorageKey<String>('${categoryName}_${subCategory.name}'),
              title: Text(subCategory.name),
              children: <Widget>[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  key: PageStorageKey<String>('${categoryName}_${subCategory.name}_grid'),
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 170,
                    childAspectRatio: 150 / 75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: subCategory.books.length,
                  itemBuilder: (ctx, i) {
                    final bookName = subCategory.books.keys.elementAt(i);
                    final bookDetails = subCategory.books.values.elementAt(i);
                    return BookCardWidget(
                      topLevelCategoryKey: categoryName, // This is the topLevelCategoryKey
                      categoryName: subCategory.name, // For display, this is the subCategory.name
                      bookName: bookName,
                      bookDetails: bookDetails,
                      bookProgressData: progressProvider.getProgressForBook(subCategory.name, bookName),
                    );
                  },
                ),
              ],
            ),
          );
        }
      }

      // If there are no direct books and no subcategories (or empty subcategories)
      // This case should ideally not happen if data is structured well,
      // but as a fallback, show a message or an empty container.
      if (children.isEmpty) {
        return Center(
          child: Text(
            'אין ספרים בקטגוריה זו: ${categoryData.name}',
            style: TextStyle(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
        );
      }

      return ListView(
        key: PageStorageKey<String>(categoryName), // Key for the outer ListView
        children: children,
      );
    }).toList();

    if (_searchResults.isNotEmpty) {
      tabs.add(Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 20, color: theme.tabBarTheme.labelColor),
            const SizedBox(width: 6),
            const Text("חיפוש")
          ],
        ),
      ));
      tabViews.add(
        GridView.builder(
          key: const PageStorageKey<String>('searchResults'),
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170,
            childAspectRatio: 150 / 90,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) => _searchResults[index],
        ),
      );
    }

    print("[BooksScreen] Final TabController length: ${_tabController?.length}");
    print("[BooksScreen] Number of generated tabs: ${tabs.length}");
    print("[BooksScreen] Number of generated tabViews: ${tabViews.length}");
    if (categories.isEmpty && _searchResults.isEmpty) {
        print("[BooksScreen] No categories and no search results. Will show 'אין נתונים להצגה'.");
    }

    return Column(
      children: [
        _buildSearchField(dataProvider),
        TabBar(
          controller: _tabController!,
          isScrollable: true,
          tabs: tabs,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: tabViews,
          ),
        ),
      ],
    );
  }
}
