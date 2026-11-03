import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_fun.dart';
import 'package:orange_ui/common/confirmation_dialog.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/chat_and_live_stream/chat.dart';
import 'package:orange_ui/model/setting_model.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/chat_screen/chat_screen.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/utils/firebase_res.dart';
import 'package:stacked/stacked.dart';

class MessageScreenViewModel extends BaseViewModel {
  FirebaseFirestore db = FirebaseFirestore.instance;
  List<Conversation> userList = [];
  Conversation? conversation;
  bool isLoading = false;
  StreamSubscription<QuerySnapshot<Conversation>>? subscription;
  UserData? userData;
  Appdata? settingAppData;
  Map<int, bool> onlineUsers = {};
  final Map<int, StreamSubscription> _presenceSubs = {};

  bool isUserOnline(int? userId) {
    if (userId == null) return false;
    return onlineUsers[userId] ?? false;
  }

  void _listenToUsersPresence(List<Conversation> list) {
    for (var conv in list) {
      final targetId = conv.user?.userid;
      if (targetId != null && targetId > 0 && !_presenceSubs.containsKey(targetId)) {
        _presenceSubs[targetId] = db
            .collection('user_presence')
            .doc('$targetId')
            .snapshots()
            .listen((doc) {
          if (doc.exists && doc.data() != null) {
            onlineUsers[targetId] = doc.data()!['isOnline'] == true;
          } else {
            onlineUsers[targetId] = false;
          }
          notifyListeners();
        }, onError: (_) {});
      }
    }
  }

  void init() {
    getSettingData();
    getChatUsers();
    getProfileApi();
  }


  void getProfileApi() {
    ApiProvider()
        .getProfile(userID: SessionManager.instance.getUserID())
        .then((value) {
      userData = value.data;
      notifyListeners();
    });
  }

  void onUserTap(Conversation conversation) {
    CommonFun.isBloc(
      userData,
      onCompletion: () {
        Get.to(() => ChatScreen(conversation: conversation));
      },
    );
  }

  void getChatUsers() {
    int userId = SessionManager.instance.getUser()?.id ?? SessionManager.instance.getUserID();
    _loadCachedUserList(userId);
    isLoading = userList.isEmpty;

    try {
      subscription?.cancel();
      subscription = db
          .collection(FirebaseRes.userChatList)
          .doc('$userId')
          .collection(FirebaseRes.userList)
          .orderBy(FirebaseRes.time, descending: true)
          .withConverter(
              fromFirestore: Conversation.fromFirestore,
              toFirestore: (Conversation value, options) => value.toFirestore())
          .snapshots()
          .listen((element) {
        List<Conversation> list = [];
        for (int i = 0; i < element.docs.length; i++) {
          final conv = element.docs[i].data();
          if (conv.isDeleted != true) {
            list.add(conv);
          }
        }
        userList = list;
        isLoading = false;
        _saveCachedUserList(userId, list);
        _listenToUsersPresence(list);
        notifyListeners();
      }, onError: (err) {
        Get.log('MessageScreen getChatUsers stream error: $err');
        isLoading = false;
        notifyListeners();
      });

      // Safety timeout so web never hangs indefinitely
      Future.delayed(const Duration(seconds: 3), () {
        if (isLoading) {
          isLoading = false;
          notifyListeners();
        }
      });
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  void _loadCachedUserList(int userId) {
    try {
      if (userId <= 0) return;
      final cached = SessionManager.instance.storage.read('inbox_$userId');
      if (cached != null && cached is List && cached.isNotEmpty && userList.isEmpty) {
        final List<Conversation> list = [];
        for (var item in cached) {
          list.add(Conversation.fromJson(item));
        }
        if (list.isNotEmpty) {
          userList = list;
          _listenToUsersPresence(list);
          notifyListeners();
        }
      }
    } catch (e) {
      Get.log('Error reading cached inbox: $e');
    }
  }

  void _saveCachedUserList(int userId, List<Conversation> list) {
    try {
      if (userId <= 0) return;
      if (list.isNotEmpty) {
        final toSave = list.take(50).map((e) => e.toJson()).toList();
        SessionManager.instance.storage.write('inbox_$userId', toSave);
      }
    } catch (e) {
      Get.log('Error saving cached inbox: $e');
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    for (var sub in _presenceSubs.values) {
      sub.cancel();
    }
    _presenceSubs.clear();
    super.dispose();
  }

  void onLongPress(Conversation? conversation) {
    Get.dialog(ConfirmationDialog(
      onTap: () {
        Get.back();
        db
            .collection(FirebaseRes.userChatList)
            .doc(userData?.id.toString())
            .collection(FirebaseRes.userList)
            .doc(conversation?.user?.userid.toString())
            .update({
          FirebaseRes.isDeleted: true,
          FirebaseRes.deletedId: '${DateTime.now().millisecondsSinceEpoch}',
          FirebaseRes.block: false,
          FirebaseRes.blockFromOther: false,
        });
      },
      description: S.current.messageWillOnlyBeRemoved,
      dialogSize: 1.9,
      padding: const EdgeInsets.symmetric(horizontal: 40),
    ));
    notifyListeners();
  }

  void getSettingData() {
    settingAppData = SessionManager.instance.getSettings()?.appdata;
    notifyListeners();
  }
}
