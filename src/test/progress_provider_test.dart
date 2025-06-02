import 'package:flutter_test/flutter_test.dart';
import 'package:shamor_vezachor/providers/progress_provider.dart';
import 'package:shamor_vezachor/models/book_model.dart';
import 'package:shamor_vezachor/models/progress_model.dart';
import 'package:shamor_vezachor/services/progress_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// This annotation is needed if you run build_runner
// For this exercise, the mocks file is created manually.
// @GenerateMocks([ProgressService])
import 'progress_provider_test.mocks.dart'; // Generated file

void main() {
  late ProgressProvider progressProvider;
  late MockProgressService mockProgressService;

  // Helper function to create BookDetails for tests
  BookDetails createBookDetails(String name, int pages, {bool isDafType = true, int startPage = 1, String contentType = "דף"}) {
    // Based on the actual BookDetails model
    return BookDetails(
      pages: pages,
      contentType: isDafType ? 'דף' : contentType, // if not daf type, allow custom content type
      columns: isDafType ? ['עמוד א', 'עמוד ב'] : ['פרק'], // Simplified columns
      startPage: startPage,
    );
  }

  setUp(() {
    mockProgressService = MockProgressService();

    // Mock default behaviors for load methods to return empty data or valid defaults
    when(mockProgressService.loadFullProgressData())
        .thenAnswer((_) async => FullProgressMap());
    when(mockProgressService.loadCompletionDates())
        .thenAnswer((_) async => CompletionDatesMap());
    when(mockProgressService.saveProgress(any, any, any, any, any, any)) // Corrected to 6 args
        .thenAnswer((_) async {});
    when(mockProgressService.saveCompletionDate(any, any))
        .thenAnswer((_) async {});
    
    // IMPORTANT ASSUMPTION: ProgressProvider is refactored to accept ProgressService via constructor
    // e.g., ProgressProvider({ProgressService? progressService})
    // For now, the test structure assumes ProgressProvider might need to be refactored
    // for proper dependency injection. If ProgressProvider instantiates its own service,
    // these mocks won't be used by the instance unless the provider's code is changed.
    // The prompt mentioned: progressProvider = ProgressProvider(progressService: mockProgressService);
    // This implies ProgressProvider's constructor is like:
    // ProgressProvider({ProgressService? progressService}) : _progressService = progressService ?? ProgressService() { _loadInitialProgress(); }
    // And _loadInitialProgress calls _progressService.loadFullProgressData() and _progressService.loadCompletionDates()
    
    progressProvider = ProgressProvider(progressService: mockProgressService);
  });

  // --- Tests for justManuallyCompletedBook ---
  group('justManuallyCompletedBook flag', () {
    test('is set when last "learn" item completes a book', () async {
      final bookDetails = createBookDetails('Book1', 1); // 1 daf = 2 amudim
      const category = 'CategoryA';
      const bookName = 'Book1';

      // Mark first amud as learned
      await progressProvider.updateProgress(category, bookName, 1, 'a', 'learn', true, bookDetails);
      expect(progressProvider.justManuallyCompletedBook, isNull, reason: "Book not yet complete");

      // Mark second amud as learned - completing the book
      await progressProvider.updateProgress(category, bookName, 1, 'b', 'learn', true, bookDetails);
      expect(progressProvider.justManuallyCompletedBook, isNotNull);
      expect(progressProvider.justManuallyCompletedBook!['category'], category);
      expect(progressProvider.justManuallyCompletedBook!['book'], bookName);
    });

    test('is null if "learn" item is checked but book not yet complete', () async {
      final bookDetails = createBookDetails('Book2', 2); // 2 daf = 4 amudim
      await progressProvider.updateProgress('CatB', 'Book2', 1, 'a', 'learn', true, bookDetails);
      expect(progressProvider.justManuallyCompletedBook, isNull);
    });

    test('is null if "learn" item is checked in an already completed book', () async {
      final bookDetails = createBookDetails('Book3', 1);
      // Manually complete the book first
      await progressProvider.updateProgress('CatC', 'Book3', 1, 'a', 'learn', true, bookDetails);
      await progressProvider.updateProgress('CatC', 'Book3', 1, 'b', 'learn', true, bookDetails);
      // Flag should be set now, clear it for the next part of the test
      expect(progressProvider.justManuallyCompletedBook, isNotNull, reason: "Book should be completed now");
      progressProvider.clearJustManuallyCompletedBookFlag(); 
      expect(progressProvider.justManuallyCompletedBook, isNull, reason: "Flag should be clear after clearing");


      // Uncheck then recheck an item
      await progressProvider.updateProgress('CatC', 'Book3', 1, 'a', 'learn', false, bookDetails);
      expect(progressProvider.justManuallyCompletedBook, isNull, reason: "Unchecking should clear/set to null");
      
      await progressProvider.updateProgress('CatC', 'Book3', 1, 'a', 'learn', true, bookDetails);
      expect(progressProvider.justManuallyCompletedBook, isNull, reason: "Re-checking item in an already complete book should not set flag");
    });
    
    test('is null when a review item is checked', () async {
      final bookDetails = createBookDetails('Book4', 1);
      await progressProvider.updateProgress('CatD', 'Book4', 1, 'a', 'review1', true, bookDetails);
      expect(progressProvider.justManuallyCompletedBook, isNull);
    });

    test('clearJustManuallyCompletedBookFlag clears the flag', () async {
      final bookDetails = createBookDetails('Book5', 1);
      // Complete book
      await progressProvider.updateProgress('CatE', 'Book5', 1, 'a', 'learn', true, bookDetails);
      await progressProvider.updateProgress('CatE', 'Book5', 1, 'b', 'learn', true, bookDetails);
      expect(progressProvider.justManuallyCompletedBook, isNotNull);
      
      progressProvider.clearJustManuallyCompletedBookFlag();
      expect(progressProvider.justManuallyCompletedBook, isNull);
    });
  });

  // --- Tests for justCompletedReviewDetails ---
  group('justCompletedReviewDetails flag', () {
    test('is set when last "review1" item completes all review1s for a book', () async {
      final bookDetails = createBookDetails('BookR1', 1); // 1 daf = 2 amudim
      const category = 'ReviewCat';
      const bookName = 'BookR1';
      const reviewType = 'review1';

      await progressProvider.updateProgress(category, bookName, 1, 'a', reviewType, true, bookDetails);
      expect(progressProvider.justCompletedReviewDetails, isNull, reason: "Review type not yet complete");
      
      await progressProvider.updateProgress(category, bookName, 1, 'b', reviewType, true, bookDetails);
      expect(progressProvider.justCompletedReviewDetails, isNotNull);
      expect(progressProvider.justCompletedReviewDetails!['category'], category);
      expect(progressProvider.justCompletedReviewDetails!['book'], bookName);
      expect(progressProvider.justCompletedReviewDetails!['reviewType'], reviewType);
    });

    test('is null if "review1" item is checked but not all review1s are complete', () async {
      final bookDetails = createBookDetails('BookR2', 2); // 2 daf = 4 amudim
      await progressProvider.updateProgress('RCat2', 'BookR2', 1, 'a', 'review1', true, bookDetails);
      expect(progressProvider.justCompletedReviewDetails, isNull);
    });

    test('is null if "review1" item is checked when all review1s already complete', () async {
      final bookDetails = createBookDetails('BookR3', 1);
      // Complete review1 for the book
      await progressProvider.updateProgress('RCat3', 'BookR3', 1, 'a', 'review1', true, bookDetails);
      await progressProvider.updateProgress('RCat3', 'BookR3', 1, 'b', 'review1', true, bookDetails);
      // Flag should be set, clear it for test
      expect(progressProvider.justCompletedReviewDetails, isNotNull);
      progressProvider.clearJustCompletedReviewDetailsFlag();
      expect(progressProvider.justCompletedReviewDetails, isNull);


      // Uncheck and recheck
      await progressProvider.updateProgress('RCat3', 'BookR3', 1, 'a', 'review1', false, bookDetails);
      expect(progressProvider.justCompletedReviewDetails, isNull);
      await progressProvider.updateProgress('RCat3', 'BookR3', 1, 'a', 'review1', true, bookDetails);
      expect(progressProvider.justCompletedReviewDetails, isNull);
    });

    test('is null when a "learn" item is checked (for review flag)', () async {
      final bookDetails = createBookDetails('BookR4', 1);
      // Mark one part of review as true, but not complete
      await progressProvider.updateProgress('RCat4', 'BookR4', 1, 'a', 'review1', true, bookDetails);
      expect(progressProvider.justCompletedReviewDetails, isNull);

      // Then check a learn item
      await progressProvider.updateProgress('RCat4', 'BookR4', 1, 'a', 'learn', true, bookDetails);
      expect(progressProvider.justCompletedReviewDetails, isNull, reason: "Learn action should clear review flag, even if it was already null");
    });

    test('clearJustCompletedReviewDetailsFlag clears the flag', () async {
      final bookDetails = createBookDetails('BookR5', 1);
      // Complete review1
      await progressProvider.updateProgress('RCat5', 'BookR5', 1, 'a', 'review1', true, bookDetails);
      await progressProvider.updateProgress('RCat5', 'BookR5', 1, 'b', 'review1', true, bookDetails);
      expect(progressProvider.justCompletedReviewDetails, isNotNull);
      
      progressProvider.clearJustCompletedReviewDetailsFlag();
      expect(progressProvider.justCompletedReviewDetails, isNull);
    });
  });
  
  // --- Test for mutual exclusivity ---
  test('learn action clears review flag and vice-versa', () async {
    final bookDetails = createBookDetails('BookM', 1); // 2 amudim

    // 1. Complete a review type
    await progressProvider.updateProgress('CatM', 'BookM', 1, 'a', 'review1', true, bookDetails);
    await progressProvider.updateProgress('CatM', 'BookM', 1, 'b', 'review1', true, bookDetails);
    expect(progressProvider.justCompletedReviewDetails, isNotNull, reason: "Review1 should be complete");
    expect(progressProvider.justCompletedReviewDetails!['reviewType'], 'review1');
    expect(progressProvider.justManuallyCompletedBook, isNull, reason: "Book learn should not be complete yet");
    
    // Clear the flag for the next step by "consuming" it
    progressProvider.clearJustCompletedReviewDetailsFlag();
    expect(progressProvider.justCompletedReviewDetails, isNull);

    // 2. Perform a learn action that does NOT complete the book
    await progressProvider.updateProgress('CatM', 'BookM', 1, 'a', 'learn', true, bookDetails);
    // The logic in updateProgress states: "A 'learn' action should clear any pending review completion flag"
    // Since it was already cleared above, this mainly ensures it doesn't get SET by a learn action.
    expect(progressProvider.justCompletedReviewDetails, isNull, reason: "Learn action should ensure review flag is null");
    expect(progressProvider.justManuallyCompletedBook, isNull, reason: "Book not complete by this single learn action");

    // 3. Now complete the book with another learn action
    await progressProvider.updateProgress('CatM', 'BookM', 1, 'b', 'learn', true, bookDetails);
    expect(progressProvider.justManuallyCompletedBook, isNotNull, reason: "Book should now be complete");
    expect(progressProvider.justCompletedReviewDetails, isNull, reason: "Final learn action should ensure review flag is clear");
    
    // Clear the book completion flag
    progressProvider.clearJustManuallyCompletedBookFlag();
    expect(progressProvider.justManuallyCompletedBook, isNull);

    // 4. Now, if we make a review action (e.g. uncheck and recheck to complete review again)
    // it should clear the book flag (which is already null but good to test the logic path)
    // and set the review flag.
    await progressProvider.updateProgress('CatM', 'BookM', 1, 'a', 'review1', false, bookDetails); // uncheck
    expect(progressProvider.justCompletedReviewDetails, isNull);
    await progressProvider.updateProgress('CatM', 'BookM', 1, 'a', 'review1', true, bookDetails); // recheck (book still has 1b for review1)
    
    // This specific re-check of 'a' does not re-complete the entire review type, because 'b' is still checked.
    // So the review flag should be null.
    expect(progressProvider.justCompletedReviewDetails, isNull, reason: "Review type not newly completed");
    expect(progressProvider.justManuallyCompletedBook, isNull, reason: "Review action should ensure learn flag is null");

  });
}

// The prompt's TestProgressProvider extension is not needed if ProgressProvider
// is correctly refactored for dependency injection of ProgressService,
// as mockService.loadFullProgressData() can then control initial state.
// The tests assume ProgressProvider calls _loadInitialProgress in its constructor,
// which in turn calls the (mocked) service's load methods.
```
