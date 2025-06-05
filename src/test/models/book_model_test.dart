import 'package:flutter_test/flutter_test.dart';
import 'package:shamor_vezachor/models/book_model.dart';

void main() {
  group('BookDetails', () {
    test('fromJson creates correctly for a custom book', () {
      final json = {'pages': 50}; // Other fields are passed as parameters to fromJson
      final details = BookDetails.fromJson(
        json,
        contentType: 'פרק',
        columns: ['פרק'],
        startPage: 1,
        isCustom: true,
        id: 'custom-id-123',
      );

      expect(details.pages, 50);
      expect(details.contentType, 'פרק');
      expect(details.columns, ['פרק']);
      expect(details.startPage, 1);
      expect(details.isCustom, isTrue);
      expect(details.id, 'custom-id-123');
      expect(details.isDafType, isFalse);
    });

    test('fromJson creates correctly for a standard book', () {
      final json = {'pages': 100};
      final details = BookDetails.fromJson(
        json,
        contentType: 'דף',
        columns: ["עמוד א'", "עמוד ב'"],
        startPage: 2,
        // isCustom defaults to false
        // id defaults to null
      );

      expect(details.pages, 100);
      expect(details.contentType, 'דף');
      expect(details.columns, ["עמוד א'", "עמוד ב'"]);
      expect(details.startPage, 2);
      expect(details.isCustom, isFalse);
      expect(details.id, isNull);
      expect(details.isDafType, isTrue);
    });
  });

  group('BookCategory', () {
    test('fromJson creates correctly for a custom category', () {
      final json = {
        'name': 'My Custom Seforim',
        'content_type': 'סימן',
        'columns': ['סימן'],
        'data': {
          'BookA': {'pages': 20},
          'BookB': {'pages': 30},
        }
      };
      final category = BookCategory.fromJson(
        json,
        sourceFile: 'custom_books.json',
        isCustom: true,
      );

      expect(category.name, 'My Custom Seforim');
      expect(category.contentType, 'סימן');
      expect(category.columns, ['סימן']);
      expect(category.defaultStartPage, 1); // 'סימן' is not 'דף'
      expect(category.isCustom, isTrue);
      expect(category.sourceFile, 'custom_books.json');
      expect(category.books.length, 2);

      expect(category.books['BookA']?.pages, 20);
      expect(category.books['BookA']?.isCustom, isTrue); // Passed down from category
      expect(category.books['BookA']?.contentType, 'סימן');
      expect(category.books['BookA']?.startPage, 1);


      expect(category.books['BookB']?.pages, 30);
      expect(category.books['BookB']?.isCustom, isTrue);
    });

    test('fromJson creates correctly for a standard "Shas" category (daf type)', () {
      final json = {
        'name': 'תלמוד בבלי',
        'content_type': 'דף',
        'columns': ["עמוד א'", "עמוד ב'"],
        'data': {
          'ברכות': {'pages': 64},
          'שבת': {'pages': 157},
        }
      };
      // For standard books, isCustom is false (default)
      // sourceFile is the original asset file name
      final category = BookCategory.fromJson(json, sourceFile: 'shas.json');

      expect(category.name, 'תלמוד בבלי');
      expect(category.contentType, 'דף');
      expect(category.columns, ["עמוד א'", "עמוד ב'"]);
      expect(category.defaultStartPage, 2); // 'דף' content type
      expect(category.isCustom, isFalse);
      expect(category.sourceFile, 'shas.json');
      expect(category.books.length, 2);

      expect(category.books['ברכות']?.pages, 64);
      expect(category.books['ברכות']?.isCustom, isFalse);
      expect(category.books['ברכות']?.contentType, 'דף');
      expect(category.books['ברכות']?.startPage, 2);


      expect(category.books['שבת']?.isCustom, isFalse);
    });

    test('fromJson sets defaultStartPage to 1 for non-"דף" contentType', () {
      final json = {
        'name': 'Rambam',
        'content_type': 'פרק', // Not 'דף'
        'columns': ['פרק'],
        'data': {'Hilchot Tefillah': {'pages': 20}}
      };
      final category = BookCategory.fromJson(json, sourceFile: 'rambam.json');
      expect(category.defaultStartPage, 1);
      expect(category.books['Hilchot Tefillah']?.startPage, 1);

    });

    group('getTotalPagesForBook', () {
      final categoryJsonDaf = {
        'name': 'CategoryDaf',
        'content_type': 'דף',
        'columns': ["עמוד א'", "עמוד ב'"], // Two columns indicating daf has two sides
        'data': {
          'Masechet1': {'pages': 10}, // Represents 10 blatt (20 actual pages/sides)
        }
      };
      final categoryDaf = BookCategory.fromJson(categoryJsonDaf, sourceFile: 'test.json');

      final categoryJsonPerek = {
        'name': 'CategoryPerek',
        'content_type': 'פרק',
        'columns': ['פרק'], // Single column
        'data': {
          'Sefer1': {'pages': 25}, // Represents 25 chapters
        }
      };
      final categoryPerek = BookCategory.fromJson(categoryJsonPerek, sourceFile: 'test2.json');

      final categoryJsonDafOneSidedColumn = { // Edge case: content_type is daf, but columns only list one side
        'name': 'CategoryDafOneSided',
        'content_type': 'דף',
        'columns': ["עמוד א'"],
        'data': {
          'Masechet2': {'pages': 15},
        }
      };
      final categoryDafOneSided = BookCategory.fromJson(categoryJsonDafOneSidedColumn, sourceFile: 'test3.json');


      test('returns double pages for "דף" type with two columns', () {
        expect(categoryDaf.getTotalPagesForBook('Masechet1'), 20);
      });

      test('returns direct pages for "פרק" type', () {
        expect(categoryPerek.getTotalPagesForBook('Sefer1'), 25);
      });

      test('returns direct pages for "דף" type with only one column listed', () {
        // This depends on the exact logic in getTotalPagesForBook.
        // The current logic is:
        // if (book.columns.contains("עמוד א") && book.columns.contains("עמוד ב") ||
        //     book.columns.contains("עמוד א'") && book.columns.contains("עמוד ב'")) {
        //   return 2 * book.pages;
        // }
        // So, if only one column is listed, it should return book.pages.
        expect(categoryDafOneSided.getTotalPagesForBook('Masechet2'), 15);
      });

      test('returns 0 if book not found', () {
        expect(categoryDaf.getTotalPagesForBook('NonExistentBook'), 0);
      });
    });
  });
}
