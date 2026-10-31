import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

class AppPlatform {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && io.Platform.isAndroid;
  static bool get isIOS => !kIsWeb && io.Platform.isIOS;
  static bool get isWindows => !kIsWeb && io.Platform.isWindows;
  static bool get isMacOS => !kIsWeb && io.Platform.isMacOS;
  static bool get isLinux => !kIsWeb && io.Platform.isLinux;

  static String get localeName {
    if (kIsWeb) {
      try {
        return ui.PlatformDispatcher.instance.locale.toString();
      } catch (_) {
        return 'en_US';
      }
    }
    try {
      return io.Platform.localeName;
    } catch (_) {
      return 'en_US';
    }
  }

  static String get languageCode {
    if (kIsWeb) {
      try {
        final code = ui.PlatformDispatcher.instance.locale.languageCode;
        return code.isNotEmpty ? code : 'en';
      } catch (_) {
        return 'en';
      }
    }
    try {
      return io.Platform.localeName.split('_')[0];
    } catch (_) {
      return 'en';
    }
  }
}

