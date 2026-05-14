import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamor_vezachor/utils/top_app_bar_visibility.dart';

void main() {
  group('shouldShowTopAppBar', () {
    test('hides the top app bar on Android', () {
      expect(shouldShowTopAppBar(TargetPlatform.android), isFalse);
    });

    test('keeps the top app bar on non-Android platforms', () {
      expect(shouldShowTopAppBar(TargetPlatform.iOS), isTrue);
      expect(shouldShowTopAppBar(TargetPlatform.windows), isTrue);
      expect(shouldShowTopAppBar(TargetPlatform.macOS), isTrue);
      expect(shouldShowTopAppBar(TargetPlatform.linux), isTrue);
      expect(shouldShowTopAppBar(TargetPlatform.fuchsia), isTrue);
    });
  });
}
