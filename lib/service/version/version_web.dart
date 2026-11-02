// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void reloadAppPlatform() {
  try {
    html.window.localStorage.remove('orange_app_build_version');
    html.window.location.reload();
  } catch (_) {}
}
