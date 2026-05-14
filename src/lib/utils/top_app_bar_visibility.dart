import 'package:flutter/material.dart';

bool shouldShowTopAppBar(TargetPlatform platform) {
  return platform != TargetPlatform.android;
}
