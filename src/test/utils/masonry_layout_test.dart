import 'package:flutter_test/flutter_test.dart';
import 'package:shamor_vezachor/utils/masonry_layout.dart';

void main() {
  group('buildBalancedMasonryColumns', () {
    test('packs later groups under shorter columns instead of row wrapping',
        () {
      final columns = buildBalancedMasonryColumns<String>(
        ['tanach', 'bavli', 'rambam', 'chasidut', 'halacha'],
        columnCount: 3,
        weightOf: (category) => switch (category) {
          'bavli' => 3,
          'halacha' => 3,
          _ => 1,
        },
      );

      expect(columns, [
        ['tanach', 'chasidut'],
        ['bavli'],
        ['rambam', 'halacha'],
      ]);
    });

    test('never creates more columns than items', () {
      final columns = buildBalancedMasonryColumns<String>(
        ['tanach', 'mishna'],
        columnCount: 4,
        weightOf: (_) => 1,
      );

      expect(columns, [
        ['tanach'],
        ['mishna'],
      ]);
    });
  });
}
