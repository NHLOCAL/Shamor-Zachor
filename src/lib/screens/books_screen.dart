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
    dataProvider.allBookData.forEach((categoryName, categoryData) {
      categoryData.books.forEach((bookName, bookDetails) {
        if (bookName.toLowerCase().contains(term.toLowerCase()) ||
            categoryName.toLowerCase().contains(term.toLowerCase())) {
          results.add(
            SearchBookCardWidget(
              categoryName: categoryName,
              bookName: bookName,
              bookDetails: bookDetails,
            ),
          );
        }
      });
    });
    results.sort((a, b) {
      if (a is SearchBookCardWidget && b is SearchBookCardWidget) {
        bool aNameMatch = a.bookName.toLowerCase().contains(term.toLowerCase());
        bool bNameMatch = b.bookName.toLowerCase().contains(term.toLowerCase());
        if (aNameMatch && !bNameMatch) return -1;
        if (!aNameMatch && bNameMatch) return 1;
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
      final category = dataProvider.allBookData[categoryName]!;
      return GridView.builder(
        key: PageStorageKey<String>(categoryName),
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 170,
          childAspectRatio: 150 / 75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: category.books.length,
        itemBuilder: (ctx, i) {
          final bookName = category.books.keys.elementAt(i);
          final bookDetails = category.books.values.elementAt(i);
          return BookCardWidget(
            categoryName: categoryName,
            bookName: bookName,
            bookDetails: bookDetails,
            bookProgressData:
                Provider.of<ProgressProvider>(context, listen: true)
                    .getProgressForBook(categoryName, bookName),
          );
        },
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
