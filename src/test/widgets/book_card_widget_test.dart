import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamor_vezachor/models/book_model.dart';
import 'package:shamor_vezachor/providers/progress_provider.dart';
import 'package:shamor_vezachor/widgets/book_card_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const progressDataKey = 'nhlocal.shamor_vezachor.progress_data';

  BookDetails testBookDetails() {
    return BookDetails.fromJson(
      {'pages': 2},
      contentType: 'פרק',
    );
  }

  Future<void> pumpBookCard(
    WidgetTester tester, {
    required String progressJson,
  }) async {
    SharedPreferences.setMockInitialValues({
      progressDataKey: progressJson,
    });

    final progressProvider = ProgressProvider();
    addTearDown(progressProvider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<ProgressProvider>.value(
        value: progressProvider,
        child: MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: BookCardWidget(
                topLevelCategoryKey: 'category',
                categoryName: 'category',
                bookName: 'book',
                bookDetails: testBookDetails(),
                bookProgressData: const {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an in-progress marker for started incomplete books',
      (tester) async {
    await pumpBookCard(
      tester,
      progressJson: '{"category":{"book":{"0":{"learn":true}}}}',
    );

    expect(find.byIcon(Icons.auto_stories), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('keeps the completed marker for completed books', (tester) async {
    await pumpBookCard(
      tester,
      progressJson:
          '{"category":{"book":{"0":{"learn":true},"1":{"learn":true}}}}',
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories), findsNothing);
  });
}
