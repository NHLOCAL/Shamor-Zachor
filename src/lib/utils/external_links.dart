import 'dart:io';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalUriLauncher = Future<bool> Function(Uri uri);

Uri buildTrackedUri(Uri uri, {required String content}) {
  return uri.replace(
    queryParameters: {
      ...uri.queryParameters,
      'utm_source': 'shamor_vezachor_app',
      'utm_medium': 'settings_about',
      'utm_campaign': 'about_links',
      'utm_content': content,
    },
  );
}

Future<bool> openExternalUri(
  Uri uri, {
  ExternalUriLauncher? primaryLauncher,
  ExternalUriLauncher? fallbackLauncher,
}) async {
  final launch = primaryLauncher ??
      (url) => launchUrl(url, mode: LaunchMode.externalApplication);
  final fallback = fallbackLauncher ?? _openWithPlatformHandler;

  try {
    if (await launch(uri)) {
      return true;
    }
  } on PlatformException {
    // A stale Windows build can have Dart code for url_launcher without the
    // native plugin channel registered. Fall through to the OS URL handler.
  }

  return fallback(uri);
}

Future<bool> _openWithPlatformHandler(Uri uri) async {
  if (Platform.isWindows) {
    final result = await Process.run(
      'rundll32',
      ['url.dll,FileProtocolHandler', uri.toString()],
    );
    return result.exitCode == 0;
  }

  if (Platform.isMacOS) {
    final result = await Process.run('open', [uri.toString()]);
    return result.exitCode == 0;
  }

  if (Platform.isLinux) {
    final result = await Process.run('xdg-open', [uri.toString()]);
    return result.exitCode == 0;
  }

  return false;
}
