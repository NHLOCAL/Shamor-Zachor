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
    const Color onSurfaceTextColor =
        Color(0xFF3D2C26); // חום כהה מאוד לטקסט (כמעט שחור)

    // Dark Theme Colors (new)
    const Color darkPrimaryBrown = Color(0xFFA56A50); // A slightly lighter/desaturated brown for dark theme
    const Color darkSurfaceColor = Color(0xFF121212); // Standard dark theme surface
    const Color darkBackground = Color(0xFF1E1E1E); // Slightly lighter than surface for scaffold
    const Color darkAppBarColor = Color(0xFF2C2C2C); // Dark grey for app bar and nav
    const Color darkCardColor = Color(0xFF252525); // Dark grey for cards
    const Color onDarkSurfaceTextColor = Color(0xFFE0E0E0); // Light grey for text on dark backgrounds

    final ThemeData lightTheme = ThemeData(
        primaryColor: primaryBrown,
        scaffoldBackgroundColor: surfaceColor,
        fontFamily: 'Heebo',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBrown,
          primary: primaryBrown,
          background: surfaceColor,
          surface: lightPinkBeige, // Cards, dialogs, etc.
          onSurface: onSurfaceTextColor, // Text on cards, dialogs
          primaryContainer: lightPeachPink, // Banners, highlighted items
          onPrimaryContainer: onSurfaceTextColor,
          secondaryContainer: lightPinkBeige, // Accent elements, FABs
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
          color: lightPinkBeige, // Card background
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
              return onSurfaceTextColor.withOpacity(0.9);
            },
          ),
          side: WidgetStateProperty.all(
              BorderSide(color: primaryBrown.withOpacity(0.3))),
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
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: primaryBrown,
          linearTrackColor: primaryBrown.withOpacity(0.2),
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
            unselectedItemColor: onSurfaceTextColor.withOpacity(0.7),
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, color: primaryBrown),
            unselectedLabelStyle:
                TextStyle(color: onSurfaceTextColor.withOpacity(0.7))),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: lightPeachPink,
          indicatorColor: primaryBrown.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryBrown);
            }
            return TextStyle(
                fontSize: 12, color: onSurfaceTextColor.withOpacity(0.7));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primaryBrown);
            }
            return IconThemeData(color: onSurfaceTextColor.withOpacity(0.7));
          }),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: onSurfaceTextColor,
          unselectedLabelColor: onSurfaceTextColor.withOpacity(0.65),
          indicatorColor: primaryBrown,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15.5),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
          overlayColor:
              WidgetStateProperty.all(primaryBrown.withOpacity(0.1)),
        ));

    final ThemeData darkTheme = ThemeData(
        primaryColor: darkPrimaryBrown,
        scaffoldBackgroundColor: darkBackground, // Dark background for scaffold
        fontFamily: 'Heebo',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: darkPrimaryBrown,
          primary: darkPrimaryBrown,
          background: darkBackground, // Main background
          surface: darkSurfaceColor, // Cards, dialogs, etc.
          onSurface: onDarkSurfaceTextColor, // Text on cards, dialogs
          primaryContainer: darkAppBarColor, // Banners, highlighted items (e.g., app bar)
          onPrimaryContainer: onDarkSurfaceTextColor,
          secondaryContainer: darkCardColor, // Accent elements, FABs, selected items
          onSecondaryContainer: onDarkSurfaceTextColor,
          brightness: Brightness.dark, // Important: sets text/icon colors correctly
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
          color: darkCardColor, // Card background for dark theme
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return darkPrimaryBrown.withOpacity(0.3); // Adjusted for dark theme
              }
              return darkSurfaceColor; // Darker background for unselected
            },
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return darkPrimaryBrown; // Selected text color
              }
              return onDarkSurfaceTextColor.withOpacity(0.9); // Unselected text
            },
          ),
          side: WidgetStateProperty.all(
              BorderSide(color: darkPrimaryBrown.withOpacity(0.5))), // Adjusted border
          shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        )),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return darkPrimaryBrown;
            }
            // For dark theme, might want a border or different unchecked look
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(darkSurfaceColor), // Check color on darkPrimaryBrown
           side: WidgetStateBorderSide.resolveWith(
            (states) => BorderSide(width: 2, color: onDarkSurfaceTextColor.withOpacity(0.7)),
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: darkPrimaryBrown,
          linearTrackColor: darkPrimaryBrown.withOpacity(0.2),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkCardColor, // Button background
            foregroundColor: onDarkSurfaceTextColor, // Button text
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: darkAppBarColor, // Dark nav bar background
            selectedItemColor: darkPrimaryBrown, // Selected item color
            unselectedItemColor: onDarkSurfaceTextColor.withOpacity(0.7), // Unselected
            selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold, color: darkPrimaryBrown),
            unselectedLabelStyle: TextStyle(
                color: onDarkSurfaceTextColor.withOpacity(0.7))),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: darkAppBarColor, // Dark nav bar background
          indicatorColor: darkPrimaryBrown.withOpacity(0.3), // Indicator for selected item
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: darkPrimaryBrown);
            }
            return TextStyle(
                fontSize: 12, color: onDarkSurfaceTextColor.withOpacity(0.7));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: darkPrimaryBrown);
            }
            return IconThemeData(color: onDarkSurfaceTextColor.withOpacity(0.7));
          }),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: onDarkSurfaceTextColor,
          unselectedLabelColor: onDarkSurfaceTextColor.withOpacity(0.65),
          indicatorColor: darkPrimaryBrown,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15.5),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
          overlayColor: WidgetStateProperty.all(
              darkPrimaryBrown.withOpacity(0.1)),
        ));

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Add ThemeProvider
      ],
      child: Consumer<ThemeProvider>( // Consume ThemeProvider
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
              Locale('en', ''), // English (fallback)
            ],
            locale: const Locale('he', 'IL'),
            theme: lightTheme, // Apply light theme
            darkTheme: darkTheme, // Apply dark theme
            themeMode: themeProvider.themeMode, // Set theme mode from provider
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
          );
        },
      ),
    );
  }
}
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
              Locale('en', ''), // English (fallback)
            ],
            locale: const Locale('he', 'IL'),
            theme: lightTheme, // Apply light theme
            darkTheme: darkTheme, // Apply dark theme
            themeMode: themeProvider.themeMode, // Set theme mode from provider
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
          );
        },
      ),
    );
  }
}
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryBrown,
            theme: lightTheme, // Apply light theme
            darkTheme: darkTheme, // Apply dark theme
            themeMode: themeProvider.themeMode, // Set theme mode from provider
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
          );
        },
      ),
    );
  }
}
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
                  return onSurfaceTextColor.withOpacity(0.9);
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
                foregroundColor: onSurfaceTextColor,
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
                unselectedItemColor: onSurfaceTextColor.withOpacity(0.7),
                selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, color: primaryBrown),
                unselectedLabelStyle:
                    TextStyle(color: onSurfaceTextColor.withOpacity(0.7))),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: lightPeachPink,
              indicatorColor: primaryBrown.withOpacity(0.2),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryBrown);
                }
                return TextStyle(
                    fontSize: 12, color: onSurfaceTextColor.withOpacity(0.7));
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: primaryBrown);
                }
                return IconThemeData(
                    color: onSurfaceTextColor.withOpacity(0.7));
              }),
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: onSurfaceTextColor, // צבע טקסט לטאב נבחר (כמעט שחור)
              unselectedLabelColor:
                  onSurfaceTextColor.withOpacity(0.65), // צבע טקסט לטאב לא נבחר
              indicatorColor: primaryBrown, // צבע הקו התחתון של הטאב הנבחר
              indicatorSize:
            themeMode: themeProvider.themeMode, // Set theme mode from provider
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
          );
        },
      ),
    );
  }
}
