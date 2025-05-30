import 'package:flutter/material.dart';
import './tracking_screen.dart';
import './books_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0; // 0 for Tracking, 1 for Books

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
    // Get theme colors
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
              Icon(Icons.book_outlined, color: appBarFgColor),
              const SizedBox(width: 8),
              Text('שמור וזכור', style: appBarTitleTextStyle),
            ],
          ),
          centerTitle: true,
          backgroundColor: appBarBgColor,
          automaticallyImplyLeading: false, // No back button
        ),
        body: Padding(
          // Add padding around the body content of Tracking/Books screens
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
          child: IndexedStack(
            // Use IndexedStack to keep state of screens
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
          type: BottomNavigationBarType
              .fixed, // Ensures labels are always visible
        ),
      ),
    );
  }
}
