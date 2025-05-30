import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import './providers/data_provider.dart';
import './providers/progress_provider.dart';
import './screens/main_layout_screen.dart';
import './screens/book_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFF8F4C33);
    const Color lightPinkBeige = Color(0xFFF1DFD9);
    const Color lightPeachPink = Color(0xFFFFDBCF);
    const Color surfaceColor =
        Color(0xFFFAF6F4); // רקע כללי בהיר מאוד, כמעט לבן עם נגיעה של בז'

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: MaterialApp(
        title: 'שמור וזכור',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('he', 'IL'),
          Locale('en', ''), // English (fallback)
        ],
        locale: const Locale('he', 'IL'),
        theme: ThemeData(
            primaryColor: primaryBrown,
            scaffoldBackgroundColor: surfaceColor,
            fontFamily: 'Heebo',
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryBrown,
              primary: primaryBrown,
              background: surfaceColor, // רקע כללי של האפליקציה
              surface: lightPinkBeige, // רקע לכרטיסים, קונטיינרים
              onSurface: primaryBrown, // טקסט על רקע surface
              primaryContainer: lightPeachPink, // צבע לקונטיינרים מודגשים קלות
              onPrimaryContainer: primaryBrown, // טקסט על primaryContainer
              secondaryContainer: lightPinkBeige, // לשימוש בטאבים, רקעים משניים
              onSecondaryContainer: primaryBrown,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: lightPeachPink,
              foregroundColor: primaryBrown,
              elevation: 1,
              titleTextStyle: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryBrown,
              ),
              iconTheme: IconThemeData(color: primaryBrown),
            ),
            cardTheme: CardTheme(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: lightPinkBeige, // רקע לכרטיסים במסך המעקב
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
                style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return primaryBrown.withOpacity(0.2);
                  }
                  return lightPinkBeige;
                },
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return primaryBrown;
                  }
                  return primaryBrown.withOpacity(0.7);
                },
              ),
              side: WidgetStateProperty.all(
                  BorderSide(color: primaryBrown.withOpacity(0.3))),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
            )),
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryBrown;
                }
                return null;
              }),
              checkColor: WidgetStateProperty.all(Colors.white),
            ),
            progressIndicatorTheme: ProgressIndicatorThemeData(
              color: primaryBrown,
              linearTrackColor: primaryBrown.withOpacity(0.2),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: lightPinkBeige,
                foregroundColor: primaryBrown,
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: lightPeachPink, // רקע הסרגל התחתון
              selectedItemColor: primaryBrown,
              unselectedItemColor: primaryBrown.withOpacity(0.6),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: lightPeachPink,
              indicatorColor: primaryBrown.withOpacity(0.2),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryBrown);
                }
                return TextStyle(
                    fontSize: 12, color: primaryBrown.withOpacity(0.7));
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(color: primaryBrown);
                }
                return IconThemeData(color: primaryBrown.withOpacity(0.7));
              }),
            ),
            tabBarTheme: TabBarTheme(
                labelColor: primaryBrown,
                unselectedLabelColor: primaryBrown.withOpacity(0.7),
                indicatorColor: primaryBrown,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: primaryBrown.withOpacity(0.2))),
        initialRoute: '/',
        routes: {
          '/': (ctx) => const MainLayoutScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == BookDetailScreen.routeName) {
            final args = settings.arguments as Map<String, String>;
            final categoryName = args['categoryName']!;
            final bookName = args['bookName']!;
            return MaterialPageRoute(
              builder: (context) {
                return BookDetailScreen(
                  categoryName: categoryName,
                  bookName: bookName,
                );
              },
            );
          }
          return null;
        },
      ),
    );
  }
}
