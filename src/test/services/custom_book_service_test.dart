import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shamor_vezachor/services/custom_book_service.dart'; // Adjusted 'your_app_name'

// Mock PathProviderPlatform to control `getApplicationDocumentsDirectory`
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  String? temporaryPath;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return temporaryPath;
  }

  // Implement other necessary overrides if your service uses them,
  // otherwise, they can return null or throw UnimplementedError.
  @override
  Future<String?> getApplicationSupportPath() async => temporaryPath;
  @override
  Future<String?> getDownloadsPath() async => null;
  @override
  Future<List<String>?> getExternalCachePaths() async => null;
  @override
  Future<String?> getExternalStoragePath() async => null;
  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async => null;
  @override
  Future<String?> getLibraryPath() async => null;
  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}


void main() {
  late CustomBookService customBookService;
  late Directory temporaryDirectory;
  late MockPathProviderPlatform mockPathProviderPlatform;

  setUp(() async {
    // Create a temporary directory for each test
    temporaryDirectory = await Directory.systemTemp.createTemp('test_custom_books_');

    // Setup mock for path_provider
    mockPathProviderPlatform = MockPathProviderPlatform();
    mockPathProviderPlatform.temporaryPath = temporaryDirectory.path;
    PathProviderPlatform.instance = mockPathProviderPlatform;

    customBookService = CustomBookService();
  });

  tearDown(() async {
    // Clean up the temporary directory after each test
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  // Helper to get the file
  File getExpectedFile(Directory dir) {
    return File('${dir.path}/custom_books.json');
  }

  group('CustomBookService Tests', () {
    test('loadCustomBooks returns empty list when no file exists', () async {
      final books = await customBookService.loadCustomBooks();
      expect(books, isEmpty);
    });

    test('addCustomBook creates file and adds a book', () async {
      final newBook = await customBookService.addCustomBook(
        categoryName: 'Test Category 1',
        bookName: 'Test Book 1',
        contentType: 'פרק',
        pages: 10,
        columns: ['פרק'],
      );
      expect(newBook, isNotNull);
      expect(newBook!.categoryName, 'Test Category 1');

      final books = await customBookService.loadCustomBooks();
      expect(books, hasLength(1));
      expect(books.first.id, newBook.id);
      expect(books.first.bookName, 'Test Book 1');

      final file = getExpectedFile(temporaryDirectory);
      expect(await file.exists(), isTrue);
      final fileContent = json.decode(await file.readAsString());
      expect(fileContent, isA<List>());
      expect(fileContent, hasLength(1));
      expect(fileContent.first['bookName'], 'Test Book 1');
    });

    test('addCustomBook adds to existing books', () async {
      // Add initial book
      await customBookService.addCustomBook(
        categoryName: 'Cat1', bookName: 'Book1', contentType: 'פרק', pages: 10, columns: ['פרק']);

      // Add second book
      final newBook2 = await customBookService.addCustomBook(
        categoryName: 'Cat2', bookName: 'Book2', contentType: 'דף', pages: 20, columns: ["עמוד א'", "עמוד ב'"]);
      expect(newBook2, isNotNull);

      final books = await customBookService.loadCustomBooks();
      expect(books, hasLength(2));
      expect(books.any((b) => b.bookName == 'Book1'), isTrue);
      expect(books.any((b) => b.bookName == 'Book2'), isTrue);
    });

    test('loadCustomBooks loads existing books correctly', () async {
      // Manually create a file with some books
      final file = getExpectedFile(temporaryDirectory);
      final initialBooks = [
        CustomBook(id: 'id1', categoryName: 'LoadCat', bookName: 'LoadBook1', contentType: 'פרק', pages: 5, columns: ['פרק']).toJson(),
        CustomBook(id: 'id2', categoryName: 'LoadCat', bookName: 'LoadBook2', contentType: 'דף', pages: 8, columns: ["עמוד א'", "עמוד ב'"]).toJson(),
      ];
      await file.writeAsString(json.encode(initialBooks));

      final books = await customBookService.loadCustomBooks();
      expect(books, hasLength(2));
      expect(books.first.bookName, 'LoadBook1');
      expect(books.last.bookName, 'LoadBook2');
    });

    test('editCustomBook modifies an existing book', () async {
      final addedBook = await customBookService.addCustomBook(
        categoryName: 'EditCat', bookName: 'EditBookOriginal', contentType: 'פרק', pages: 15, columns: ['פרק']);
      expect(addedBook, isNotNull);

      final success = await customBookService.editCustomBook(
        id: addedBook!.id,
        categoryName: 'EditCat Updated', // Changed
        bookName: 'EditBookModified',    // Changed
        contentType: 'דף',               // Changed
        pages: 25,                       // Changed
        columns: ["עמוד א'", "עמוד ב'"],    // Changed
      );
      expect(success, isTrue);

      final books = await customBookService.loadCustomBooks();
      expect(books, hasLength(1));
      final editedBook = books.first;
      expect(editedBook.id, addedBook.id);
      expect(editedBook.categoryName, 'EditCat Updated');
      expect(editedBook.bookName, 'EditBookModified');
      expect(editedBook.contentType, 'דף');
      expect(editedBook.pages, 25);
      expect(editedBook.columns, ["עמוד א'", "עמוד ב'"]);
    });

    test('editCustomBook returns false for non-existent book ID', () async {
      await customBookService.addCustomBook(
        categoryName: 'Cat', bookName: 'Book', contentType: 'פרק', pages: 10, columns: ['פרק']);

      final success = await customBookService.editCustomBook(
        id: 'non-existent-id',
        categoryName: 'NoCat', bookName: 'NoBook', contentType: 'פרק', pages: 1, columns: ['פרק']);
      expect(success, isFalse);
    });

    test('deleteCustomBook removes an existing book', () async {
      final book1 = await customBookService.addCustomBook(
        categoryName: 'DelCat', bookName: 'DelBook1', contentType: 'פרק', pages: 10, columns: ['פרק']);
      final book2 = await customBookService.addCustomBook(
        categoryName: 'DelCat', bookName: 'DelBook2', contentType: 'דף', pages: 5, columns: ["עמוד א'", "עמוד ב'"]);
      expect(book1, isNotNull);
      expect(book2, isNotNull);

      final booksBeforeDelete = await customBookService.loadCustomBooks();
      expect(booksBeforeDelete, hasLength(2));

      final success = await customBookService.deleteCustomBook(book1!.id);
      expect(success, isTrue);

      final booksAfterDelete = await customBookService.loadCustomBooks();
      expect(booksAfterDelete, hasLength(1));
      expect(booksAfterDelete.first.id, book2!.id);
      expect(booksAfterDelete.first.bookName, 'DelBook2');
    });

    test('deleteCustomBook returns false for non-existent book ID', () async {
      await customBookService.addCustomBook(
        categoryName: 'Cat', bookName: 'Book', contentType: 'פרק', pages: 10, columns: ['פרק']);

      final success = await customBookService.deleteCustomBook('non-existent-id');
      expect(success, isFalse);

      final books = await customBookService.loadCustomBooks();
      expect(books, hasLength(1)); // Ensure no book was accidentally deleted
    });
     test('loadCustomBooks handles empty file content', () async {
      final file = getExpectedFile(temporaryDirectory);
      await file.writeAsString(''); // Write empty string

      final books = await customBookService.loadCustomBooks();
      expect(books, isEmpty);
    });

    test('loadCustomBooks handles malformed JSON', () async {
      final file = getExpectedFile(temporaryDirectory);
      await file.writeAsString('[{not json]'); // Malformed JSON

      // Expect it to return empty list and print an error (error printing not testable here)
      final books = await customBookService.loadCustomBooks();
      expect(books, isEmpty);
    });
  });
}

// Helper Fake class for MockPlatformInterfaceMixin
class Fake extends Mock implements PathProviderPlatform {}
