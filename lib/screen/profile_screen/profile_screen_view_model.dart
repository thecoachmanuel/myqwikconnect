import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_fun.dart';
import 'package:orange_ui/model/setting_model.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/edit_profile_screen/edit_profile_screen.dart';
import 'package:orange_ui/screen/options_screen/options_screen.dart';
import 'package:orange_ui/screen/user_detail_screen/user_detail_screen.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreenViewModel extends BaseViewModel {
  UserData? userData = SessionManager.instance.getUser();
  bool isLoading = false;
  int currentImageIndex = 0;
  PageController pageController = PageController();
  Appdata? settingAppData;

  void init() {
    userData = SessionManager.instance.getUser();
    notifyListeners();

    pageController = PageController(initialPage: 0, viewportFraction: 1.01)
      ..addListener(() {
        onMainImageChange();
      });
    getSettingData();
    profileScreenApiCall();
  }

  void profileScreenApiCall() async {
    final uid = SessionManager.instance.getUserID();
    if (uid <= 0) return;

    if (userData == null) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final value = await ApiProvider().getProfile(userID: uid);
      if (value.status == true && value.data != null) {
        userData = value.data;
        SessionManager.instance.setUser(value.data);
      }
    } catch (e) {
      debugPrint('ProfileScreenApiCall error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void onEditProfileTap() {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        Get.to<UserData>(() => EditProfileScreen(userData: userData))
            ?.then((value) {
          if (value != null) {
            userData = value;
            SessionManager.instance.setUser(value);
            notifyListeners();
          }
        });
      },
    );
  }

  void _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) throw 'Could not launch ';
  }

  bool isSocialBtnVisible(String? socialLink) {
    if (socialLink != null) {
      return socialLink.contains("http://") || socialLink.contains("https://");
    } else {
      return false;
    }
  }

  void onSocialBtnTap(String? value) {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        _launchUrl(value ?? '');
      },
    );
  }

  void onMainImageChange() {
    if (pageController.page!.round() != currentImageIndex) {
      currentImageIndex = pageController.page!.round();
      notifyListeners();
    }
  }

  void onImageTap() {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        Get.to(() => UserDetailScreen(userData: userData));
      },
    );
  }

  void onMoreBtnTap() {
    Get.to(() => const OptionScreen())?.then((value) {
      userData = SessionManager.instance.getUser();
      notifyListeners();
    });
  }

  void getSettingData() {
    settingAppData = SessionManager.instance.getSettings()?.appdata;
    notifyListeners();
  }
}
