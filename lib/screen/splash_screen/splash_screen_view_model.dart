import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
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

    // Check Firebase Auth in case session in local storage was reset or not yet synced
    final fbUser = FirebaseAuth.instance.currentUser;
    if (fbUser != null && ((fbUser.email ?? '').isNotEmpty || (fbUser.phoneNumber ?? '').isNotEmpty)) {
      final identity = (fbUser.email?.isNotEmpty == true) ? fbUser.email! : (fbUser.phoneNumber ?? '');
      ApiProvider().registration(
        email: identity,
        fullName: fbUser.displayName ?? '',
        deviceToken: '',
        loginType: fbUser.providerData.any((p) => p.providerId == 'google.com') ? 1 : 2,
        firebaseUid: fbUser.uid,
      ).then((res) {
        if (!_hasNavigated) {
          _hasNavigated = true;
          if (res.status == true && res.data != null && (res.data?.id ?? 0) > 0) {
            SessionManager.instance.setUser(res.data);
            SessionManager.instance.setBool(key: SessionKeys.isLogin, value: true);
            Get.offAllNamed('/dashboard');
          } else {
            Get.offAllNamed('/auth');
          }
        }
      }).catchError((_) {
        if (!_hasNavigated) {
          _hasNavigated = true;
          Get.offAllNamed('/auth');
        }
      });
      return;
    }

    // Safety watchdog: ensure screen transitions within 800ms
    Timer(const Duration(milliseconds: 800), () {
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
