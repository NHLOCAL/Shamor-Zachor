import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shamor_vezachor/utils/external_links.dart';

void main() {
  group('buildTrackedUri', () {
    test('adds settings about UTM parameters and content label', () {
      final uri = buildTrackedUri(
        Uri.parse('https://shamor-zachor.ze-kal.top/'),
        content: 'app_website',
      );

      expect(uri.toString(),
          'https://shamor-zachor.ze-kal.top/?utm_source=shamor_vezachor_app&utm_medium=settings_about&utm_campaign=about_links&utm_content=app_website');
    });

    test('preserves existing query parameters', () {
      final uri = buildTrackedUri(
        Uri.parse('https://example.com/?lang=he'),
        content: 'developer_website',
      );

      expect(uri.queryParameters['lang'], 'he');
      expect(uri.queryParameters['utm_source'], 'shamor_vezachor_app');
      expect(uri.queryParameters['utm_medium'], 'settings_about');
      expect(uri.queryParameters['utm_campaign'], 'about_links');
      expect(uri.queryParameters['utm_content'], 'developer_website');
    });
  });

  group('openExternalUri', () {
    test('falls back when the url_launcher platform channel is unavailable',
        () async {
      final uri = Uri.parse('https://example.com/');
      Uri? fallbackUri;

      final opened = await openExternalUri(
        uri,
        primaryLauncher: (_) => throw PlatformException(
          code: 'channel-error',
          message: 'Unable to establish connection on channel',
        ),
        fallbackLauncher: (url) async {
          fallbackUri = url;
          return true;
        },
      );

      expect(opened, isTrue);
      expect(fallbackUri, uri);
    });
  });
}
