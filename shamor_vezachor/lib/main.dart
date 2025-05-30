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
    const Color surfaceColor = Color(0xFFFAF6F4);
    const Color onSurfaceTextColor = Color(0xFF3D2C26); // חום כהה מאוד לטקסט

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
              background: surfaceColor,
              surface: lightPinkBeige,
              onSurface: onSurfaceTextColor, // שינוי צבע טקסט על משטחים
              primaryContainer: lightPeachPink,
              onPrimaryContainer:
                  onSurfaceTextColor, // שינוי צבע טקסט על קונטיינר ראשי
              secondaryContainer: lightPinkBeige,
              onSecondaryContainer:
                  onSurfaceTextColor, // שינוי צבע טקסט על קונטיינר משני
            ),
            textTheme: ThemeData.light()
                .textTheme
                .apply(
                  fontFamily: 'Heebo',
                  bodyColor: onSurfaceTextColor,
                  displayColor: onSurfaceTextColor,
                )
                .copyWith(
                  titleLarge: TextStyle(
                      color: onSurfaceTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                  titleMedium: TextStyle(
                      color: onSurfaceTextColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 18),
                  bodyLarge: TextStyle(color: onSurfaceTextColor, fontSize: 16),
                  bodyMedium:
                      TextStyle(color: onSurfaceTextColor, fontSize: 14),
                  labelLarge: TextStyle(
                      color: onSurfaceTextColor,
                      fontWeight: FontWeight.bold), // For buttons
                ),
            appBarTheme: AppBarTheme(
              backgroundColor: lightPeachPink,
              foregroundColor:
                  onSurfaceTextColor, // צבע טקסט ואייקונים ב-AppBar
              elevation: 1,
              titleTextStyle: TextStyle(
                fontFamily: 'Heebo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: onSurfaceTextColor, // צבע טקסט כותרת ב-AppBar
              ),
              iconTheme: IconThemeData(
                  color: onSurfaceTextColor), // צבע אייקונים ב-AppBar
            ),
            cardTheme: CardTheme(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: lightPinkBeige,
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
                  return onSurfaceTextColor
                      .withOpacity(0.9); // צבע טקסט לא נבחר
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
                foregroundColor:
                    onSurfaceTextColor, // צבע טקסט על כפתורים מוגבהים
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
                backgroundColor: lightPeachPink,
                selectedItemColor: primaryBrown,
                unselectedItemColor:
                    onSurfaceTextColor.withOpacity(0.7), // צבע פריט לא נבחר
                selectedLabelStyle:
                    TextStyle(fontWeight: FontWeight.bold, color: primaryBrown),
                unselectedLabelStyle: TextStyle(
                    color: onSurfaceTextColor
                        .withOpacity(0.7)) // צבע תווית לא נבחרת
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
                    fontSize: 12,
                    color: onSurfaceTextColor
                        .withOpacity(0.7)); // צבע תווית לא נבחרת
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return IconThemeData(color: primaryBrown);
                }
                return IconThemeData(
                    color: onSurfaceTextColor
                        .withOpacity(0.7)); // צבע אייקון לא נבחר
              }),
            ),
            tabBarTheme: TabBarTheme(
                labelColor: primaryBrown, // צבע תווית נבחרת
                unselectedLabelColor:
                    onSurfaceTextColor.withOpacity(0.7), // צבע תווית לא נבחרת
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
