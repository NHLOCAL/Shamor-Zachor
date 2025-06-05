import 'package:flutter/material.dart';
import './tracking_screen.dart';
import './books_screen.dart';
import './settings_screen.dart'; // Assuming settings_screen.dart is in the same directory

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
    SettingsScreen(), // New screen added
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color appBarFgColor = Theme.of(context).appBarTheme.foregroundColor ??
        const Color(0xFF8F4C33);
    final TextStyle? appBarTitleTextStyle =
        Theme.of(context).appBarTheme.titleTextStyle;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _selectedIndex != 2
            ? AppBar(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // ממורכז כבר
                  children: [
                    ImageIcon(
                      const AssetImage('assets/images/app_icon_for_bar.png'),
                      color: appBarFgColor,
                      size: 28, // הגדלתי קצת את האייקון
                    ),
                    const SizedBox(width: 8),
                    Text('שמור וזכור', style: appBarTitleTextStyle),
                  ],
                ),
                centerTitle: true, // מוודא שהכותרת ממורכזת
              )
            : null, // אין AppBar במסך הגדרות
        body: IndexedStack(
          // Padding הוסר מכאן ויושם בתוך המסכים עצמם
          index: _selectedIndex,
          children: _widgetOptions,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.timeline_outlined),
              selectedIcon: Icon(Icons.timeline),
              label: 'מעקב',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'ספרים',
            ),
            NavigationDestination(
              // New destination added
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'הגדרות',
            ),
          ],
        ),
      ),
    );
  }
}
