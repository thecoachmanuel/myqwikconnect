import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:stacked/stacked.dart';

class SplashScreenViewModel extends BaseViewModel {
  bool _hasNavigated = false;

  void init() {
    final bool isLogin = SessionManager.instance.getBool(key: SessionKeys.isLogin);
    final cachedUser = SessionManager.instance.getUser();

    // 🚀 Instant Navigation: if user is logged in with valid session, go directly to Dashboard
    if (isLogin && cachedUser != null && (cachedUser.id ?? 0) > 0) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/dashboard');
      });
      _syncInBackground();
      return;
    }

    // 🌐 If not logged in on Web, immediately route to /auth
    if (kIsWeb) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/auth');
      });
      _syncInBackground();
      return;
    }

    // Safety watchdog: ensure screen transitions within 1200ms
    Timer(const Duration(milliseconds: 1200), () {
      if (!_hasNavigated) {
        _hasNavigated = true;
        final loggedIn = SessionManager.instance.getBool(key: SessionKeys.isLogin);
        final user = SessionManager.instance.getUser();
        if (loggedIn && user != null && (user.id ?? 0) > 0) {
          Get.offAllNamed('/dashboard');
        } else {
          Get.offAllNamed('/auth');
        }
      }
    });

    _settingApiCall();
  }

  void _syncInBackground() async {
    try {
      final value = await ApiProvider()
          .getSettingData()
          .timeout(const Duration(seconds: 4));
      if (value.status == true && value.data != null) {
        SessionManager.instance.setSettings(value.data);
      }
    } catch (_) {}

    try {
      final response = await ApiProvider()
          .fetchMyUserProfile()
          .timeout(const Duration(seconds: 4));
      if (response.status == true && response.data != null) {
        SessionManager.instance.setUser(response.data);
      } else if (response.status == false &&
          response.message?.toLowerCase().contains('block') == true) {
        // ONLY log out if explicitly blocked by admin
        SessionManager.instance.cleanSession();
        Get.offAllNamed('/auth');
      }
    } catch (_) {}
  }

  void _settingApiCall() async {
    try {
      final value = await ApiProvider()
          .getSettingData()
          .timeout(const Duration(seconds: 3));

      if (value.status == true && value.data != null) {
        SessionManager.instance.setSettings(value.data);
      }
    } catch (e) {
      debugPrint('SplashScreen settingApiCall error: $e');
    }

    if (!_hasNavigated) {
      _hasNavigated = true;
      final bool isLogin = SessionManager.instance.getBool(key: SessionKeys.isLogin);
      final cachedUser = SessionManager.instance.getUser();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isLogin && cachedUser != null && (cachedUser.id ?? 0) > 0) {
          Get.offAllNamed('/dashboard');
        } else {
          Get.offAllNamed('/auth');
        }
      });
    }
  }
}
