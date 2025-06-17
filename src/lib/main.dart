import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import './providers/data_provider.dart';
import './providers/progress_provider.dart';
import './providers/theme_provider.dart'; // Import ThemeProvider
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
    const Color onSurfaceTextColor = Color(0xFF3D2C26);

    const Color darkPrimaryBrown = Color(0xFFA56A50);
    const Color darkSurfaceColor = Color(0xFF121212);
    const Color darkBackground = Color(0xFF1E1E1E);
    const Color darkAppBarColor = Color(0xFF2C2C2C);
    const Color darkCardColor = Color(0xFF252525);
    const Color onDarkSurfaceTextColor = Color(0xFFE0E0E0);

    final ThemeData lightTheme = ThemeData(
        primaryColor: primaryBrown,
        scaffoldBackgroundColor: surfaceColor,
        fontFamily: 'Heebo',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBrown,
          primary: primaryBrown,
          background: surfaceColor,
          surface: lightPinkBeige,
          onSurface: onSurfaceTextColor,
          primaryContainer: lightPeachPink,
          onPrimaryContainer: onSurfaceTextColor,
          secondaryContainer: lightPinkBeige,
          onSecondaryContainer: onSurfaceTextColor,
          brightness: Brightness.light,
        ),
        textTheme: ThemeData.light()
            .textTheme
            .apply(
              fontFamily: 'Heebo',
              bodyColor: onSurfaceTextColor,
              displayColor: onSurfaceTextColor,
            )
            .copyWith(
              titleLarge: const TextStyle(
                  color: onSurfaceTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
              titleMedium: const TextStyle(
                  color: onSurfaceTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
              bodyLarge:
                  const TextStyle(color: onSurfaceTextColor, fontSize: 16),
              bodyMedium:
                  const TextStyle(color: onSurfaceTextColor, fontSize: 14),
              labelLarge: const TextStyle(
                  color: onSurfaceTextColor, fontWeight: FontWeight.bold),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: lightPeachPink,
          foregroundColor: onSurfaceTextColor,
          elevation: 1,
          titleTextStyle: TextStyle(
            fontFamily: 'Heebo',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onSurfaceTextColor,
          ),
          iconTheme: IconThemeData(color: onSurfaceTextColor),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: lightPinkBeige,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return primaryBrown.withAlpha((0.2 * 255).round());
              }
              return lightPinkBeige;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return primaryBrown;
              }
              return onSurfaceTextColor.withAlpha((0.9 * 255).round());
            },
          ),
          side: WidgetStateProperty.all(
              BorderSide(color: primaryBrown.withAlpha((0.3 * 255).round()))),
          shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        )),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryBrown;
            }
            return null;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          // No 'side' defined for light theme by default, which is fine.
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: primaryBrown,
          linearTrackColor: primaryBrown.withAlpha((0.2 * 255).round()),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: lightPinkBeige,
            foregroundColor: onSurfaceTextColor,
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: lightPeachPink,
            selectedItemColor: primaryBrown,
            unselectedItemColor: onSurfaceTextColor.withAlpha((0.7 * 255).round()),
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, color: primaryBrown),
            unselectedLabelStyle:
                TextStyle(color: onSurfaceTextColor.withAlpha((0.7 * 255).round()))),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: lightPeachPink,
          indicatorColor: primaryBrown.withAlpha((0.2 * 255).round()),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryBrown);
            }
            return TextStyle(
                fontSize: 12, color: onSurfaceTextColor.withAlpha((0.7 * 255).round()));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primaryBrown);
            }
            return IconThemeData(color: onSurfaceTextColor.withAlpha((0.7 * 255).round()));
          }),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: onSurfaceTextColor,
          unselectedLabelColor: onSurfaceTextColor.withAlpha((0.65 * 255).round()),
          indicatorColor: primaryBrown,
          indicatorSize: TabBarIndicatorSize.label,
          // dividerColor: Colors.transparent, // Removed as per M3 guidance
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15.5),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
          overlayColor:
              WidgetStateProperty.all(primaryBrown.withAlpha((0.1 * 255).round())),
        ));

    final ThemeData darkTheme = ThemeData(
        primaryColor: darkPrimaryBrown,
        scaffoldBackgroundColor: darkBackground,
        fontFamily: 'Heebo',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkPrimaryBrown,
          primary: darkPrimaryBrown,
          background: darkBackground,
          surface: darkSurfaceColor,
          onSurface: onDarkSurfaceTextColor,
          primaryContainer: darkAppBarColor,
          onPrimaryContainer: onDarkSurfaceTextColor,
          secondaryContainer: darkCardColor,
          onSecondaryContainer: onDarkSurfaceTextColor,
          brightness: Brightness.dark,
        ),
        textTheme: ThemeData.dark()
            .textTheme
            .apply(
              fontFamily: 'Heebo',
              bodyColor: onDarkSurfaceTextColor,
              displayColor: onDarkSurfaceTextColor,
            )
            .copyWith(
              titleLarge: const TextStyle(
                  color: onDarkSurfaceTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
              titleMedium: const TextStyle(
                  color: onDarkSurfaceTextColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 18),
              bodyLarge:
                  const TextStyle(color: onDarkSurfaceTextColor, fontSize: 16),
              bodyMedium:
                  const TextStyle(color: onDarkSurfaceTextColor, fontSize: 14),
              labelLarge: const TextStyle(
                  color: onDarkSurfaceTextColor, fontWeight: FontWeight.bold),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkAppBarColor,
          foregroundColor: onDarkSurfaceTextColor,
          elevation: 1,
          titleTextStyle: TextStyle(
            fontFamily: 'Heebo',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: onDarkSurfaceTextColor,
          ),
          iconTheme: IconThemeData(color: onDarkSurfaceTextColor),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: darkCardColor,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return darkPrimaryBrown.withAlpha((0.3 * 255).round());
              }
              return darkSurfaceColor;
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return darkPrimaryBrown;
              }
              return onDarkSurfaceTextColor.withAlpha((0.9 * 255).round());
            },
          ),
          side: WidgetStateProperty.all(
              BorderSide(color: darkPrimaryBrown.withAlpha((0.5 * 255).round()))),
          shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        )),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return darkPrimaryBrown;
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(darkSurfaceColor),
           side: WidgetStateBorderSide.resolveWith(
            (states) => BorderSide(width: 2, color: onDarkSurfaceTextColor.withAlpha((0.7 * 255).round())),
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: darkPrimaryBrown,
          linearTrackColor: darkPrimaryBrown.withAlpha((0.2 * 255).round()),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkCardColor,
            foregroundColor: onDarkSurfaceTextColor,
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: darkAppBarColor,
            selectedItemColor: darkPrimaryBrown,
            unselectedItemColor: onDarkSurfaceTextColor.withAlpha((0.7 * 255).round()),
            selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold, color: darkPrimaryBrown),
            unselectedLabelStyle: TextStyle(
                color: onDarkSurfaceTextColor.withAlpha((0.7 * 255).round()))),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkAppBarColor,
          indicatorColor: darkPrimaryBrown.withAlpha((0.3 * 255).round()),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: darkPrimaryBrown);
            }
            return TextStyle(
                fontSize: 12, color: onDarkSurfaceTextColor.withAlpha((0.7 * 255).round()));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: darkPrimaryBrown);
            }
            return IconThemeData(color: onDarkSurfaceTextColor.withAlpha((0.7 * 255).round()));
          }),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: onDarkSurfaceTextColor,
          unselectedLabelColor: onDarkSurfaceTextColor.withAlpha((0.65 * 255).round()),
          indicatorColor: darkPrimaryBrown,
          indicatorSize: TabBarIndicatorSize.label,
          // dividerColor: Colors.transparent, // Removed
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15.5),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
          overlayColor: WidgetStateProperty.all(
              darkPrimaryBrown.withAlpha((0.1 * 255).round())),
        ));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'שמור וזכור',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('he', 'IL'),
              Locale('en', ''),
            ],
            locale: const Locale('he', 'IL'),
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (ctx) => const MainLayoutScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == BookDetailScreen.routeName) {
                final args = settings.arguments as Map<String, String>;
                final topLevelCategoryKey = args['topLevelCategoryKey']!;
                final categoryName = args['categoryName']!; // This is the display name
                final bookName = args['bookName']!;
                return MaterialPageRoute(
                  builder: (context) {
                    return BookDetailScreen(
                      topLevelCategoryKey: topLevelCategoryKey,
                      categoryName: categoryName,
                      bookName: bookName,
                    );
                  },
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
