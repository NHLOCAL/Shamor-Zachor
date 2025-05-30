import 'package:flutter/material.dart';
import './tracking_screen.dart';
import './books_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    TrackingScreen(),
    BooksScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarBgColor =
        Theme.of(context).appBarTheme.backgroundColor ?? Colors.brown.shade100;
    final Color appBarFgColor =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.brown.shade900;
    final TextStyle? appBarTitleTextStyle =
        Theme.of(context).appBarTheme.titleTextStyle;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // שינוי: החלפת האייקון הקיים בתמונה
              ImageIcon(
                const AssetImage(
                    'assets/images/app_icon_for_bar.png'), // ודא שהנתיב תואם לקובץ שיצרת
                color: appBarFgColor,
                size: 24, // ניתן להתאים את הגודל לפי הצורך
              ),
              const SizedBox(width: 8),
              Text('שמור וזכור', style: appBarTitleTextStyle),
            ],
          ),
          centerTitle: true,
          backgroundColor: appBarBgColor,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          child: IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.timeline_outlined),
              label: 'מעקב',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'ספרים',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
