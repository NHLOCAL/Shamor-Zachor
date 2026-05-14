import 'package:flutter/material.dart';

bool shouldShowTopAppBar(TargetPlatform platform) {
  return platform != TargetPlatform.android;
}

bool shouldUseAndroidTopSafeArea(TargetPlatform platform) {
  return platform == TargetPlatform.android;
}

bool shouldShowCompactBookTopBar(TargetPlatform platform) {
  return platform == TargetPlatform.android;
}
