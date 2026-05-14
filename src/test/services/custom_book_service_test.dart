import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shamor_vezachor/services/custom_book_service.dart';

void main() {
  group('CustomBook serialization', () {
    test('keeps old flat custom book backups compatible', () {
      final book = CustomBook.fromJson({
        'id': 'legacy-id',
        'categoryName': 'הלכה',
        'bookName': 'קיצור שולחן ערוך',
        'contentType': 'סימן',
        'pages': 221,
      });

      expect(book.id, 'legacy-id');
      expect(book.topLevelCategoryName, 'הלכה');
      expect(book.categoryName, 'הלכה');
      expect(book.subCategoryPath, isEmpty);
      expect(book.bookName, 'קיצור שולחן ערוך');
      expect(book.contentType, 'סימן');
      expect(book.pages, 221);
      expect(book.parts, isEmpty);
    });

    test('serializes category path and internal book parts', () {
      final book = CustomBook(
        id: 'custom-id',
        topLevelCategoryName: 'הלכה',
        subCategoryPath: const ['שולחן ערוך'],
        bookName: 'ספר מותאם',
        contentType: 'סימן',
        parts: const [
          CustomBookPart(name: 'חלק א', start: 1, end: 120),
          CustomBookPart(name: 'חלק ב', start: 121, end: 221, exclude: [150]),
        ],
      );

      final decoded = json.decode(json.encode(book.toJson()));
      final restored = CustomBook.fromJson(decoded as Map<String, dynamic>);

      expect(restored.topLevelCategoryName, 'הלכה');
      expect(restored.categoryName, 'שולחן ערוך');
      expect(restored.subCategoryPath, ['שולחן ערוך']);
      expect(restored.pages, isNull);
      expect(restored.parts, hasLength(2));
      expect(restored.parts[0].name, 'חלק א');
      expect(restored.parts[0].start, 1);
      expect(restored.parts[0].end, 120);
      expect(restored.parts[1].exclude, [150]);
    });
  });
}
