import 'dart:async';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_fun.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/model/chat_and_live_stream/chat.dart';
import 'package:orange_ui/model/setting_model.dart';
import 'package:orange_ui/model/social/post/add_post.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/create_profile_screen/create_profile_screen_view_model.dart';
import 'package:orange_ui/screen/live_grid_screen/live_grid_screen.dart';
import 'package:orange_ui/screen/notification_screen/notification_screen.dart';
import 'package:orange_ui/screen/search_screen/search_screen.dart';
import 'package:orange_ui/screen/single_post_screen/single_post_screen.dart';
import 'package:orange_ui/screen/subscription_sheet/subscription_sheet_controller.dart';
import 'package:orange_ui/screen/user_detail_screen/user_detail_screen.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/service/share_manager.dart';
import 'package:orange_ui/service/subscription/subscription_manager.dart';
import 'package:orange_ui/utils/app_platform.dart';
import 'package:orange_ui/utils/firebase_res.dart';
import 'package:orange_ui/utils/urls.dart';
import 'package:stacked/stacked.dart';

class DashboardScreenViewModel extends BaseViewModel
    with WidgetsBindingObserver {
  static const String keyActiveTabIndex = 'dashboard_active_tab_index';
  int pageIndex = 0;
  int unreadNotificationCount = 0;
  int unreadMessageCount = 0;
  StreamSubscription<QuerySnapshot<Conversation>>? chatBadgeSubscription;
  Timer? notificationPollTimer;
  UserData? userData;

  Appdata? settingAppData = SessionManager.instance.getSettings()?.appdata;
  BannerAd? bannerAd;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    final bool isLogin =
        SessionManager.instance.getBool(key: SessionKeys.isLogin);
    final cachedUser = SessionManager.instance.getUser();
    if (!isLogin || cachedUser == null || (cachedUser.id ?? 0) <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/auth');
      });
      return;
    }

    final savedIndex = SessionManager.instance.getInt(key: keyActiveTabIndex);
    if (savedIndex >= 0 && savedIndex <= 4) {
      pageIndex = savedIndex;
    }
    if (!AppPlatform.isWeb) {
      try {
        AppBadgePlus.updateBadge(0);
      } catch (_) {}
    }
    initBranch();
    getProfileApiCall();
    fetchUnreadNotifications();
    notificationPollTimer?.cancel();
    notificationPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchUnreadNotifications();
    });

    final uid = cachedUser.id ?? SessionManager.instance.getUserID();
    if (uid > 0) {
      chatBadgeSubscription?.cancel();
      chatBadgeSubscription = FirebaseFirestore.instance
          .collection(FirebaseRes.userChatList)
          .doc('$uid')
          .collection(FirebaseRes.userList)
          .withConverter(
            fromFirestore: Conversation.fromFirestore,
            toFirestore: (Conversation value, options) => value.toFirestore(),
          )
          .snapshots()
          .listen((snapshot) {
        int count = 0;
        for (final doc in snapshot.docs) {
          final conv = doc.data();
          if (conv.isDeleted != true && conv.user?.isNewMsg == true) {
            count++;
          }
        }
        unreadMessageCount = count;
        notifyListeners();
      }, onError: (_) {});
    }

    ApiProvider().getSettingData().then((value) {
      if (value.status == true && value.data != null) {
        SessionManager.instance.setSettings(value.data);
        settingAppData = value.data?.appdata;
        notifyListeners();
      }
    }).catchError((_) {});
  }

  void getProfileApiCall() {
    userData = SessionManager.instance.getUser();
    notifyListeners();
    final uid = SessionManager.instance.getUserID();
    if (uid <= 0) return;
    ApiProvider().getProfile(userID: uid).then((value) {
      if (value.status == true && value.data != null) {
        userData = value.data;
        SessionManager.instance.setUser(value.data);
        notifyListeners();
      }
    }).catchError((e) {});
    notifyListeners();
    final isRegister = Get.isRegistered<CreateProfileScreenViewModel>();
    if (isRegister) {
      Get.delete<CreateProfileScreenViewModel>();
    }
    SubscriptionManager.shared.subscriptionListener();
    Get.put(SubscriptionSheetController());
  }

  void onBottomBarTap(int index) {
    if (userData?.isBlock == 1 && index == 4) {
      pageIndex = index;
      SessionManager.instance.setInt(key: keyActiveTabIndex, value: pageIndex);
    } else {
      CommonFun.isBloc(
        userData,
        onCompletion: () {
          pageIndex = index;
          SessionManager.instance
              .setInt(key: keyActiveTabIndex, value: pageIndex);
        },
      );
    }
    notifyListeners();
  }

  void initBranch() {
    ShareManager.shared.listen((key, value) {
      switch (key) {
        case ShareKeys.post:
          ApiProvider().callPost(
              completion: (response) {
                AddPost post = AddPost.fromJson(response);
                if (post.status == true) {
                  Get.to(() => SinglePostScreen(post: post.data));
                } else {
                  CommonUI.snackBar(message: post.message ?? '');
                }
              },
              url: Urls.aFetchPostByPostId,
              param: {
                Urls.userId: SessionManager.instance.getUserID().toString(),
                Urls.aPostId: value
              });
        case ShareKeys.user:
          Get.to(() => UserDetailScreen(userId: value));
      }
    });
  }

  void fetchUnreadNotifications() {
    ApiProvider().getUserNotification(0).then((value) {
      if (value.status == true && value.data != null) {
        unreadNotificationCount =
            value.data!.where((n) => n.isRead != 1).length;
        notifyListeners();
      }
    }).catchError((_) {});
  }

  void onNotificationTap() {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        unreadNotificationCount = 0;
        notifyListeners();
        Get.to(() => const NotificationScreen())?.then((_) {
          fetchUnreadNotifications();
        });
      },
    );
  }

  void onLivesBtnClick() {
    Get.to(() => const LiveGridScreen());
  }

  void onSearchTap() {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        Get.to(() => const SearchScreen());
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getProfileApiCall();
      fetchUnreadNotifications();
      ApiProvider().getSettingData().then((value) {
        if (value.status == true && value.data != null) {
          SessionManager.instance.setSettings(value.data);
          settingAppData = value.data?.appdata;
          notifyListeners();
        }
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    notificationPollTimer?.cancel();
    chatBadgeSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class ImageText {
  final String image;
  final String title;

  ImageText(this.image, this.title);
}
