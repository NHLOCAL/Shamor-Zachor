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

  group('shouldUseAndroidTopSafeArea', () {
    test('reserves status bar and cutout space on Android', () {
      expect(shouldUseAndroidTopSafeArea(TargetPlatform.android), isTrue);
    });

    test('does not add extra top safe area on platforms with top app bars', () {
      expect(shouldUseAndroidTopSafeArea(TargetPlatform.iOS), isFalse);
      expect(shouldUseAndroidTopSafeArea(TargetPlatform.windows), isFalse);
      expect(shouldUseAndroidTopSafeArea(TargetPlatform.macOS), isFalse);
      expect(shouldUseAndroidTopSafeArea(TargetPlatform.linux), isFalse);
      expect(shouldUseAndroidTopSafeArea(TargetPlatform.fuchsia), isFalse);
    });
  });

  group('shouldShowCompactBookTopBar', () {
    test('uses a compact book top bar on Android detail screens', () {
      expect(shouldShowCompactBookTopBar(TargetPlatform.android), isTrue);
    });

    test('keeps the standard app bar on non-Android detail screens', () {
      expect(shouldShowCompactBookTopBar(TargetPlatform.iOS), isFalse);
      expect(shouldShowCompactBookTopBar(TargetPlatform.windows), isFalse);
      expect(shouldShowCompactBookTopBar(TargetPlatform.macOS), isFalse);
      expect(shouldShowCompactBookTopBar(TargetPlatform.linux), isFalse);
      expect(shouldShowCompactBookTopBar(TargetPlatform.fuchsia), isFalse);
    });
  });
}
