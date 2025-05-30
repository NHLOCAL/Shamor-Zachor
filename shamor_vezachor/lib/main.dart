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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: MaterialApp(
        title: 'שמור וזכור',
        debugShowCheckedModeBanner: false,
        // RTL Support
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('he', 'IL'), // Hebrew
          Locale('en', ''), // English (fallback)
        ],
        locale: const Locale('he', 'IL'), // Set Hebrew as default

        theme: ThemeData(
            primarySwatch: Colors.brown,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.brown,
              primaryContainer: Colors.brown.shade100,
              onPrimaryContainer: Colors.brown.shade900,
              // For Material 3, surfaceVariant is less common.
              // Using surfaceContainerHighest or similar as a replacement, or just surface.
              // Let's use surface for general card backgrounds if surfaceVariant was for that.
              // If it was for specific variant cards, surfaceContainer might be better.
              // Flet used surface_variant for tracking cards, which were light.
              surface: Colors.brown.shade50, // General background for cards
              surfaceContainerHighest: Colors.brown
                  .shade50, // Alternative if surfaceVariant was meant for elevation
            ),
            fontFamily: 'Heebo',
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.brown.shade100,
              foregroundColor: Colors.brown.shade900,
              elevation: 1,
              titleTextStyle: TextStyle(
                // Making it const requires all inner parts to be const
                fontFamily: 'Heebo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade900,
              ),
            ),
            scaffoldBackgroundColor: Colors.grey[50],
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              color: Colors.brown.shade50, // Used surface (was surfaceVariant)
            ),
            segmentedButtonTheme: SegmentedButtonThemeData(
                style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.brown.shade200;
                  }
                  return Colors.brown.shade50;
                },
              ),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.brown.shade900;
                  }
                  return Colors.brown.shade700;
                },
              ),
              side: WidgetStateProperty.all(
                  BorderSide(color: Colors.brown.shade300)),
            )),
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.brown;
                }
                return null;
              }),
              checkColor: WidgetStateProperty.all(Colors.white),
            ),
            progressIndicatorTheme: ProgressIndicatorThemeData(
              color: Colors.brown,
              linearTrackColor: Colors.brown.shade100,
            )),
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
