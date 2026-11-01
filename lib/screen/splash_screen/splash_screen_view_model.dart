import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/model/setting_model.dart';
import 'package:orange_ui/screen/auth_screen/auth_screen.dart';
import 'package:orange_ui/screen/auth_screen/auth_screen_view_model.dart';
import 'package:orange_ui/screen/on_boarding_screen/on_boarding_screen.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:stacked/stacked.dart';

class SplashScreenViewModel extends BaseViewModel {
  bool _hasNavigated = false;

  void init() {
    bool isLogin = SessionManager.instance.getBool(key: SessionKeys.isLogin);
    final cachedUser = SessionManager.instance.getUser();

    // 🌐 Web auto-routing: redirect instantly to destination without hanging on splash
    if (kIsWeb) {
      if (isLogin && cachedUser != null && cachedUser.id != null) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AuthScreenViewModel().navigateScreen(userData: cachedUser);
        });
        _syncInBackground();
      } else {
        _navigate(() => const AuthScreen());
        _syncInBackground();
      }

      // Safety watchdog for web: if still on splash after 1.5s, force navigate
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!_hasNavigated) {
          _hasNavigated = true;
          Get.offAll(() => const AuthScreen(), routeName: '/auth');
        }
      });
      return;
    }

    // 🚀 Instant Launch for mobile: If user is logged in, navigate immediately using cached session
    if (isLogin && cachedUser != null && cachedUser.id != null) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_hasNavigated) {
          _hasNavigated = true;
          AuthScreenViewModel().navigateScreen(userData: cachedUser);
          _syncInBackground();
        }
      });
      return;
    }

    // Safety fallback: ensure screen transitions within 3 seconds even if network hangs
    Timer(const Duration(seconds: 3), () {
      if (!_hasNavigated) {
        _navigateFallback();
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
      }
    } catch (_) {}
  }

  void _settingApiCall() async {
    try {
      final value = await ApiProvider()
          .getSettingData()
          .timeout(const Duration(seconds: 3));

      if (value.status == true) {
        bool isLogin =
            SessionManager.instance.getBool(key: SessionKeys.isLogin);

        if (isLogin) {
          fetchProfile();
          return;
        } else {
          final List<Onboarding> onBoardingItems =
              value.data?.onboardingScreen ?? [];
          bool isDating = value.data?.appdata?.isDating == 1;
          if (isDating && onBoardingItems.isNotEmpty) {
            _navigate(() => OnBoardingScreen(onBoarding: onBoardingItems));
            return;
          } else {
            _navigate(() => const AuthScreen());
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('SplashScreen settingApiCall error: $e');
    }

    // Fallback if API fails, times out, or returns false
    _navigateFallback();
  }

  void _navigateFallback() {
    bool isLogin = SessionManager.instance.getBool(key: SessionKeys.isLogin);
    if (isLogin && SessionManager.instance.getUser() != null) {
      fetchProfile();
    } else {
      _navigate(() => const AuthScreen());
    }
  }

  void _navigate(Widget Function() page, {String? routeName}) {
    if (_hasNavigated) return;
    _hasNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(page, routeName: routeName ?? '/auth');
    });
  }

  void fetchProfile() async {
    final userData = SessionManager.instance.getUser();

    if (userData == null) {
      _navigate(() => const AuthScreen());
      return;
    }
    try {
      final response = await ApiProvider()
          .fetchMyUserProfile()
          .timeout(const Duration(seconds: 3));

      if (response.status == true && response.data?.id != null) {
        _hasNavigated = true;
        AuthScreenViewModel().navigateScreen(userData: response.data ?? userData);
      } else {
        _navigate(() => const AuthScreen());
      }
    } catch (e) {
      debugPrint('SplashScreen fetchProfile error: $e');
      _navigate(() => const AuthScreen());
    }
  }
}
