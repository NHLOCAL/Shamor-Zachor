import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shamor_vezachor/models/book_model.dart';
import 'package:shamor_vezachor/services/custom_book_service.dart';
import 'package:shamor_vezachor/services/data_loader_service.dart';
import 'package:shamor_vezachor/providers/data_provider.dart';

// Generate mocks
@GenerateMocks([DataLoaderService, CustomBookService])
import 'data_provider_test.mocks.dart'; // Generated file

void main() {
  late DataProvider dataProvider;
  late MockDataLoaderService mockDataLoaderService;
  late MockCustomBookService mockCustomBookService;

  // Listener utility
  int notifyCount = 0;
  void listener() {
    notifyCount++;
  }

  setUp(() {
    mockDataLoaderService = MockDataLoaderService();
    mockCustomBookService = MockCustomBookService();

    // Create DataProvider instance and inject mocks.
    // This requires DataProvider to be modifiable for testing,
    // e.g. by having a constructor that accepts these services,
    // or by having setters.
    // For now, let's assume DataProvider is structured like this:
    // class DataProvider with ChangeNotifier {
    //   final DataLoaderService _dataLoaderService;
    //   final CustomBookService _customBookService;
    //   DataProvider({DataLoaderService? dataLoaderService, CustomBookService? customBookService})
    //       : _dataLoaderService = dataLoaderService ?? DataLoaderService(),
    //         _customBookService = customBookService ?? CustomBookService();
    //   // ...
    // }
    // If not, this test setup will need adjustment or DataProvider needs refactoring for testability.
    // The current DataProvider in the project creates its own instances.
    // To properly test, we will need to modify DataProvider to allow injection.

    // For this subtask, we will write tests *as if* DI is possible.
    // The subtask to modify DataProvider for DI should ideally precede this.
    // If DataProvider is not changed, these tests will not correctly use mocks for internal calls.
    // Let's assume DataProvider *is* modified for DI for this test:
    dataProvider = DataProvider.test(mockDataLoaderService, mockCustomBookService);


    // Reset listener count
    notifyCount = 0;
    dataProvider.addListener(listener);

    // Default mock behaviors
    when(mockDataLoaderService.loadData()).thenAnswer((_) async => {});
    when(mockDataLoaderService.clearCache()).thenAnswer((_) {}); // void return
    when(mockCustomBookService.addCustomBook(
      categoryName: anyNamed('categoryName'),
      bookName: anyNamed('bookName'),
      contentType: anyNamed('contentType'),
      pages: anyNamed('pages'),
      columns: anyNamed('columns')))
    .thenAnswer((_) async => CustomBook(id: '1', categoryName: 'test', bookName: 'test', contentType: 'פרק', pages: 10, columns: ['פרק']));

    when(mockCustomBookService.editCustomBook(
      id: anyNamed('id'),
      categoryName: anyNamed('categoryName'),
      bookName: anyNamed('bookName'),
      contentType: anyNamed('contentType'),
      pages: anyNamed('pages'),
      columns: anyNamed('columns')))
    .thenAnswer((_) async => true);

    when(mockCustomBookService.deleteCustomBook(any)).thenAnswer((_) async => true);
  });

  tearDown(() {
    dataProvider.removeListener(listener);
  });

  group('DataProvider Tests', () {
    final BookCategory testCategory1 = BookCategory(
        name: 'Cat1', contentType: 'פרק', columns: ['פרק'], books: {
          'Book1': BookDetails(pages: 10, contentType: 'פרק', columns: ['פרק'], startPage: 1)
        }, defaultStartPage: 1, sourceFile: 'test.json');
    final Map<String, BookCategory> testData = {'Cat1': testCategory1};

    test('initial values are correct', () {
      expect(dataProvider.allBookData, isEmpty);
      expect(dataProvider.isLoading, isFalse); // Should be false after constructor's initial load if any
      expect(dataProvider.error, isNull);
    });

    test('loadAllData success flow', () async {
      when(mockDataLoaderService.loadData()).thenAnswer((_) async => testData);

      await dataProvider.loadAllData();

      verify(mockDataLoaderService.clearCache()).called(1);
      verify(mockDataLoaderService.loadData()).called(1);
      expect(dataProvider.allBookData, testData);
      expect(dataProvider.isLoading, isFalse);
      expect(dataProvider.error, isNull);
      expect(notifyCount, greaterThanOrEqualTo(2)); // At least start and end loading
    });

    test('loadAllData error flow', () async {
      when(mockDataLoaderService.loadData()).thenThrow(Exception('Failed to load'));

      await dataProvider.loadAllData();

      verify(mockDataLoaderService.clearCache()).called(1);
      verify(mockDataLoaderService.loadData()).called(1);
      expect(dataProvider.allBookData, isEmpty); // Should remain empty or be cleared
      expect(dataProvider.isLoading, isFalse);
      expect(dataProvider.error, contains('Failed to load'));
      expect(notifyCount, greaterThanOrEqualTo(2));
    });

    test('addCustomBook success flow', () async {
      when(mockDataLoaderService.loadData()).thenAnswer((_) async => testData); // For the reload

      await dataProvider.addCustomBook(categoryName: 'NewCat', bookName: 'NewBook', contentType: 'דף', pages: 20, columns: ['דף']);

      verify(mockCustomBookService.addCustomBook(
          categoryName: 'NewCat', bookName: 'NewBook', contentType: 'דף', pages: 20, columns: ['דף'])).called(1);
      verify(mockDataLoaderService.clearCache()).called(1); // From subsequent loadAllData
      verify(mockDataLoaderService.loadData()).called(1);  // From subsequent loadAllData
      expect(dataProvider.isLoading, isFalse);
      expect(dataProvider.error, isNull);
      // notifyCount will be higher due to multiple notifications
    });

    test('addCustomBook error flow', () async {
      when(mockCustomBookService.addCustomBook(
        categoryName: anyNamed('categoryName'),
        bookName: anyNamed('bookName'),
        contentType: anyNamed('contentType'),
        pages: anyNamed('pages'),
        columns: anyNamed('columns')))
      .thenThrow(Exception('Failed to add'));

      await dataProvider.addCustomBook(categoryName: 'ErrCat', bookName: 'ErrBook', contentType: 'פרק', pages: 1, columns: ['פרק']);

      expect(dataProvider.isLoading, isFalse);
      expect(dataProvider.error, contains('Failed to add'));
      verifyNever(mockDataLoaderService.loadData()); // Should not reload if add fails before that
    });


    test('editCustomBook success flow', () async {
      when(mockDataLoaderService.loadData()).thenAnswer((_) async => testData);

      await dataProvider.editCustomBook(id: '123', categoryName: 'UpdCat', bookName: 'UpdBook', contentType: 'פרק', pages: 10, columns: ['פרק']);

      verify(mockCustomBookService.editCustomBook(id: '123', categoryName: 'UpdCat', bookName: 'UpdBook', contentType: 'פרק', pages: 10, columns: ['פרק'])).called(1);
      verify(mockDataLoaderService.loadData()).called(1);
      expect(dataProvider.isLoading, isFalse);
    });

    test('editCustomBook returns error if service call returns false', () async {
      when(mockCustomBookService.editCustomBook(
        id: anyNamed('id'),
        categoryName: anyNamed('categoryName'),
        bookName: anyNamed('bookName'),
        contentType: anyNamed('contentType'),
        pages: anyNamed('pages'),
        columns: anyNamed('columns')))
      .thenAnswer((_) async => false); // Simulate book not found by service

      await dataProvider.editCustomBook(id: 'badId', categoryName: 'Cat', bookName: 'Book', contentType: 'פרק', pages: 1, columns: ['פרק']);

      expect(dataProvider.isLoading, isFalse);
      expect(dataProvider.error, contains('Failed to find custom book to edit'));
      verifyNever(mockDataLoaderService.loadData());
    });


    test('deleteCustomBook success flow', () async {
      when(mockDataLoaderService.loadData()).thenAnswer((_) async => testData);

      await dataProvider.deleteCustomBook('123');

      verify(mockCustomBookService.deleteCustomBook('123')).called(1);
      verify(mockDataLoaderService.loadData()).called(1);
      expect(dataProvider.isLoading, isFalse);
    });

    test('deleteCustomBook returns error if service call returns false', () async {
        when(mockCustomBookService.deleteCustomBook(any)).thenAnswer((_) async => false);

        await dataProvider.deleteCustomBook('badId');
        expect(dataProvider.isLoading, isFalse);
        expect(dataProvider.error, contains('Failed to find custom book to delete'));
        verifyNever(mockDataLoaderService.loadData());
    });


    test('getCategory returns correct category', () async {
      when(mockDataLoaderService.loadData()).thenAnswer((_) async => testData);
      await dataProvider.loadAllData();

      final category = dataProvider.getCategory('Cat1');
      expect(category, testCategory1);
      expect(dataProvider.getCategory('NonExistent'), isNull);
    });

    test('getBookDetails returns correct book details', () async {
      when(mockDataLoaderService.loadData()).thenAnswer((_) async => testData);
      await dataProvider.loadAllData();

      final details = dataProvider.getBookDetails('Cat1', 'Book1');
      expect(details, testCategory1.books['Book1']);
      expect(dataProvider.getBookDetails('Cat1', 'NonExistent'), isNull);
      expect(dataProvider.getBookDetails('NonExistent', 'Book1'), isNull);
    });

  });
}
