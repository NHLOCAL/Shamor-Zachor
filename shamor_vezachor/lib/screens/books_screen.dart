import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/book_card_widget.dart';

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
      final categories = dataProvider.allBookData.keys.toList();
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
      // אם האינדקס באמצע שינוי (אנימציה), נחכה שהוא יתייצב.
      // notifyListeners ייקרא שוב כשהשינוי יסתיים וה-indexIsChanging יהיה false.
      return;
    }

    final newIndex = _tabController!.index;

    if (_currentTabIndex == newIndex) {
      // האינדקס לא השתנה מאז הפעם האחרונה שטיפלנו בו (כאשר indexIsChanging היה false).
      return;
    }

    final previousStableIndex = _currentTabIndex; // שמור את האינדקס היציב הקודם
    _currentTabIndex = newIndex; // עדכן את האינדקס היציב הנוכחי

    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    final categories = dataProvider.allBookData.keys.toList();
    final int searchTabIndexWhenVisible = categories.length;

    // אם עברנו מטאב החיפוש (כאשר היו תוצאות) לטאב אחר
    if (_searchResults.isNotEmpty &&
        previousStableIndex == searchTabIndexWhenVisible && // היינו בטאב חיפוש
        _currentTabIndex != searchTabIndexWhenVisible) {
      // עברנו לטאב אחר (שאינו חיפוש)

      // דחיית הפעולה לסוף הפרריים כדי למנוע את השגיאה
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // בדיקה חוזרת של mounted כי זה async
          setState(() {
            _searchController.clear();
            _searchResults = [];
            // _currentTabIndex כבר מכיל את האינדקס החדש (הלא-חיפוש) שאליו עברנו
            _setupTabController(categories, switchToIndex: _currentTabIndex);
          });
        }
      });
    }
  }

  void _performSearch(String term, DataProvider dataProvider) {
    final categories = dataProvider.allBookData.keys.toList();

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
        if (bookName.toLowerCase().contains(term.toLowerCase())) {
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

    if (mounted) {
      setState(() {
        bool hadSearchResults = _searchResults.isNotEmpty;
        _searchResults = results;

        final int newSearchTabIndex = categories.length;

        if (results.isNotEmpty && !hadSearchResults) {
          _setupTabController(categories, switchToIndex: newSearchTabIndex);
        } else if (results.isEmpty && hadSearchResults) {
          int switchToIndexAfterClear = _currentTabIndex;
          if (switchToIndexAfterClear == newSearchTabIndex + 1) {
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 20, right: 20, top: 5),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'חיפוש ספר...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
          isDense: true,
        ),
        onChanged: (value) {
          _performSearch(value, dataProvider);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (dataProvider.error != null) {
      return Center(child: Text('שגיאה: ${dataProvider.error}'));
    }

    final categories = dataProvider.allBookData.keys.toList();
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
          const Expanded(child: Center(child: Text("מכין טאבים..."))),
        ],
      );
    }

    if (_tabController == null || _tabController!.length == 0) {
      return Column(
        children: [
          _buildSearchField(dataProvider),
          const Expanded(
              child: Center(child: Text('אין נתונים להצגה או תוצאות חיפוש.'))),
        ],
      );
    }

    List<Tab> tabs = categories.map((catName) => Tab(text: catName)).toList();
    List<Widget> tabViews = categories.map((categoryName) {
      final category = dataProvider.allBookData[categoryName]!;
      return GridView.builder(
        key: PageStorageKey<String>(categoryName),
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 170,
          childAspectRatio: 150 / 75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
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
                Provider.of<ProgressProvider>(context, listen: false)
                    .getProgressForBook(categoryName, bookName),
          );
        },
      );
    }).toList();

    if (_searchResults.isNotEmpty) {
      tabs.add(const Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(Icons.search), SizedBox(width: 5), Text("חיפוש")],
        ),
      ));
      tabViews.add(
        GridView.builder(
          key: const PageStorageKey<String>('searchResults'),
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 170,
            childAspectRatio: 150 / 85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
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
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Theme.of(context).primaryColor,
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
