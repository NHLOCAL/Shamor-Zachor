import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/book_card_widget.dart';
import '../utils/category_sorter.dart';
import '../models/book_model.dart';

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
      final categories =
          CategorySorter.sort(dataProvider.allBookData.keys.toList());
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
      if (mounted) setState(() {});
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

    if (targetIndex >= newTotalTabs || targetIndex < 0) targetIndex = 0;
    _tabController!.index = targetIndex;
    _currentTabIndex = targetIndex;
    _tabController!.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (!mounted || _tabController == null || _tabController!.indexIsChanging) {
      return;
    }
    final newIndex = _tabController!.index;
    if (_currentTabIndex == newIndex) return;

    final previousStableIndex = _currentTabIndex;
    _currentTabIndex = newIndex;

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
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
    final categories =
        CategorySorter.sort(dataProvider.allBookData.keys.toList());

    if (term.length < 2) {
      if (_searchResults.isNotEmpty) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            int switchToIndexAfterClear = _currentTabIndex;
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

    final uniqueResults = <String>{};

    dataProvider.allBookData.forEach((topLevelCategoryName, categoryData) {
      void processCategory(String currentCategoryName, String displayName,
          BookCategory category) {
        bool categoryNameMatches =
            displayName.toLowerCase().contains(searchTerm);
        category.books.forEach((bookName, bookDetails) {
          final uniqueKey = "$topLevelCategoryName-$bookName";
          if (!uniqueResults.contains(uniqueKey)) {
            if (bookName.toLowerCase().contains(searchTerm) ||
                categoryNameMatches) {
              results.add(SearchBookCardWidget(
                  topLevelCategoryKey: topLevelCategoryName,
                  categoryName: displayName,
                  bookName: bookName,
                  bookDetails: bookDetails));
              uniqueResults.add(uniqueKey);
            }
          }
        });

        category.subcategories?.forEach((subCat) {
          processCategory(subCat.name, subCat.name, subCat);
        });
      }

      processCategory(categoryData.name, categoryData.name, categoryData);
    });

    results.sort((a, b) {
      if (a is SearchBookCardWidget && b is SearchBookCardWidget) {
        bool aBookNameMatch = a.bookName.toLowerCase().contains(searchTerm);
        bool bBookNameMatch = b.bookName.toLowerCase().contains(searchTerm);
        if (aBookNameMatch && !bBookNameMatch) return -1;
        if (!aBookNameMatch && bBookNameMatch) return 1;
        return a.bookName.compareTo(b.bookName);
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
          int switchToIndexAfterClear =
              (_currentTabIndex < categories.length) ? _currentTabIndex : 0;
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
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
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
            onChanged: (value) => _performSearch(value, dataProvider),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final theme = Theme.of(context);
    final progressProvider =
        Provider.of<ProgressProvider>(context, listen: true);

    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (dataProvider.error != null) {
      return Center(child: Text('שגיאה: ${dataProvider.error}'));
    }

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
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (_tabController == null ||
        (_tabController!.length == 0 && _searchResults.isEmpty)) {
      return Column(
        children: [
          _buildSearchField(dataProvider),
          Expanded(
            child: Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'אין נתונים להצגה.'
                    : 'לא נמצאו תוצאות חיפוש.',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ),
          ),
        ],
      );
    }

    List<Tab> tabs = categories.map((catName) => Tab(text: catName)).toList();
    List<Widget> tabViews = categories.map((topLevelCategoryName) {
      final categoryData = dataProvider.allBookData[topLevelCategoryName]!;
      List<Widget> children = [];

      // This is a helper function to build the grid for a category.
      // It returns a list of widgets to be placed inside the main ListView.
      List<Widget> buildGridWidgetsForCategory(
          String displayName, BookCategory category) {
        List<Widget> widgets = [];
        if (category.books.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(displayName, style: theme.textTheme.titleLarge),
            ),
          );
          widgets.add(
            GridView.builder(
              key: PageStorageKey<String>(
                  '$topLevelCategoryName-$displayName-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  childAspectRatio: 150 / 75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12),
              itemCount: category.books.length,
              itemBuilder: (ctx, i) {
                final bookName = category.books.keys.elementAt(i);
                final bookDetails = category.books.values.elementAt(i);
                return BookCardWidget(
                    topLevelCategoryKey: topLevelCategoryName,
                    categoryName: displayName,
                    bookName: bookName,
                    bookDetails: bookDetails,
                    bookProgressData: progressProvider.getProgressForBook(
                        topLevelCategoryName, bookName));
              },
            ),
          );
        }
        return widgets;
      }

      if (categoryData.subcategories == null ||
          categoryData.subcategories!.isEmpty) {
        children.addAll(
            buildGridWidgetsForCategory(categoryData.name, categoryData));
      } else {
        for (var subCategory in categoryData.subcategories!) {
          children.add(
            ExpansionTile(
              key: PageStorageKey<String>(
                  '$topLevelCategoryName-${subCategory.name}'),
              title: Text(subCategory.name, style: theme.textTheme.titleMedium),
              children: [
                GridView.builder(
                  key: PageStorageKey<String>(
                      '$topLevelCategoryName-${subCategory.name}-grid'),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 170,
                      childAspectRatio: 150 / 75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12),
                  itemCount: subCategory.books.length,
                  itemBuilder: (ctx, i) {
                    final bookName = subCategory.books.keys.elementAt(i);
                    final bookDetails = subCategory.books.values.elementAt(i);
                    return BookCardWidget(
                      topLevelCategoryKey: topLevelCategoryName,
                      categoryName: subCategory.name,
                      bookName: bookName,
                      bookDetails: bookDetails,
                      bookProgressData: progressProvider.getProgressForBook(
                          topLevelCategoryName, bookName),
                    );
                  },
                ),
              ],
            ),
          );
        }
      }

      return ListView(
          key: PageStorageKey<String>(topLevelCategoryName),
          children: children);
    }).toList();

    if (_searchResults.isNotEmpty) {
      tabs.add(Tab(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search, size: 20, color: theme.tabBarTheme.labelColor),
        const SizedBox(width: 6),
        const Text("חיפוש")
      ])));
      // THE FIX: Wrap the search results GridView in a ListView to ensure consistency
      // across all children of the TabBarView.
      tabViews.add(
        ListView(
          key: const PageStorageKey<String>('searchResultsWrapper'),
          children: [
            GridView.builder(
              // No key needed here as the parent ListView handles state.
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 170,
                  childAspectRatio: 150 / 90,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) => _searchResults[index],
            )
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSearchField(dataProvider),
        TabBar(
          controller: _tabController!,
          isScrollable: true,
          tabs: tabs,
          // FIX: Explicitly set alignment to start (right in RTL) to prevent centering.
          tabAlignment: TabAlignment.start,
          // FIX: Set minimal horizontal padding to remove unwanted large gaps.
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
        ),
        Expanded(
            child: TabBarView(controller: _tabController!, children: tabViews)),
      ],
    );
  }
}
