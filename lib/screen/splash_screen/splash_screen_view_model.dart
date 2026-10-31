import 'dart:async';
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
    // Safety fallback: ensure screen transitions within 4 seconds even if network hangs
    Timer(const Duration(seconds: 4), () {
      if (!_hasNavigated) {
        _navigateFallback();
      }
    });
    _settingApiCall();
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
    Get.off(page, routeName: routeName ?? '/auth');
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
        AuthScreenViewModel().navigateScreen(userData: userData);
      } else {
        _navigate(() => const AuthScreen());
      }
    } catch (e) {
      debugPrint('SplashScreen fetchProfile error: $e');
      _navigate(() => const AuthScreen());
    }
  }
}
