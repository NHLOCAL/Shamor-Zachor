import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shamor_vezachor/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressService scroll positions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns zero when no saved scroll position exists', () async {
      final service = ProgressService();

      final offset = await service.loadBookScrollOffset('tanach', 'בראשית');

      expect(offset, 0);
    });

    test('stores scroll positions independently per category and book',
        () async {
      final service = ProgressService();

      await service.saveBookScrollOffset('tanach', 'בראשית', 432.5);
      await service.saveBookScrollOffset('tanach', 'שמות', 88);
      await service.saveBookScrollOffset('mishna', 'ברכות', 12.25);

      expect(await service.loadBookScrollOffset('tanach', 'בראשית'), 432.5);
      expect(await service.loadBookScrollOffset('tanach', 'שמות'), 88);
      expect(await service.loadBookScrollOffset('mishna', 'ברכות'), 12.25);
      expect(await service.loadBookScrollOffset('mishna', 'פאה'), 0);
    });
  });
}
