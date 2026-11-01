import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_fun.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/confirmation_dialog.dart';
import 'package:orange_ui/common/video_upload_dialog.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/chat_and_live_stream/chat.dart';
import 'package:orange_ui/model/setting_model.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/bottom_diamond_shop/bottom_diamond_shop.dart';
import 'package:orange_ui/screen/chat_screen/widgets/image_video_send_sheet.dart';
import 'package:orange_ui/screen/chat_screen/widgets/image_view_page.dart';
import 'package:orange_ui/screen/chat_screen/widgets/item_selection_dialog_android.dart';
import 'package:orange_ui/screen/explore_screen/widgets/reverse_swipe_dialog.dart';
import 'package:orange_ui/screen/user_detail_screen/user_detail_screen.dart';
import 'package:orange_ui/screen/user_report_screen/report_sheet.dart';
import 'package:orange_ui/screen/video_preview_screen/video_preview_screen.dart';
import 'package:orange_ui/screen/video_preview_screen/video_preview_screen_view_model.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/service/subscription/subscription_manager.dart';
import 'package:orange_ui/utils/app_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/firebase_res.dart';
import 'package:stacked/stacked.dart';

class ChatScreenViewModel extends BaseViewModel {
  var db = FirebaseFirestore.instance;
  late DocumentReference documentSender;
  late DocumentReference documentReceiver;
  late CollectionReference drChatMessages;
  ImagePicker picker = ImagePicker();

  TextEditingController textMsgController = TextEditingController();

  ScrollController scrollController = ScrollController();

  File? chatImage;

  String imagePath = '';
  String selectedItem = S.current.image;
  String blockUnblock = S.current.block;
  List<ChatMessage> chatData = [];
  String deletedId = '';

  StreamSubscription<QuerySnapshot<ChatMessage>>? chatStream;
  StreamSubscription<DocumentSnapshot<Conversation>>? conUserStream;

  Conversation conversation;
  UserData? registrationUserData;
  UserData? receiverUserData;

  Map<String, List<ChatMessage>>? grouped;
  int startingNumber = 30;
  List<String> notDeletedIdentity = [];
  List<String> timeStamp = [];
  bool isLongPress = false;
  int walletCoin = 0;
  bool isAutoPayEnable = false;
  bool isBlock = false;
  bool isBlockOther = false;
  static String conversationID = '';
  int messagePrice = 0;

  Appdata? settingAppData;

  ChatScreenViewModel(this.conversation);

  void init() {
    conversationID = conversation.conversationId ?? '';
    _loadCachedChat();
    getPrefData();
    scrollToGetChat();
  }

  String _getChatStorageKey() {
    final int myId = registrationUserData?.id ?? SessionManager.instance.getUserID();
    final convId = conversation.conversationId ?? conversationID;
    return 'chat_${myId}_$convId';
  }

  void _loadCachedChat() {
    try {
      final convId = conversation.conversationId ?? conversationID;
      if (convId.isEmpty) return;
      final key = _getChatStorageKey();
      var cached = SessionManager.instance.storage.read(key);
      if (cached == null || (cached is List && cached.isEmpty)) {
        // Fallback to legacy key
        cached = SessionManager.instance.storage.read('chat_$convId');
      }
      if (cached != null && cached is List && cached.isNotEmpty && chatData.isEmpty) {
        final List<ChatMessage> cachedList = [];
        for (var item in cached) {
          cachedList.add(ChatMessage.fromJson(item));
        }
        if (cachedList.isNotEmpty) {
          chatData = cachedList;
          _groupMessages(chatData);
          notifyListeners();
        }
      }
    } catch (e) {
      Get.log('Error loading cached chat: $e');
    }
  }

  void _saveCachedChat() {
    try {
      final convId = conversation.conversationId ?? conversationID;
      if (convId.isEmpty) return;
      if (chatData.isNotEmpty) {
        final toSave = chatData.take(100).map((e) => e.toJson()).toList();
        final key = _getChatStorageKey();
        SessionManager.instance.storage.write(key, toSave);
        SessionManager.instance.storage.write('chat_$convId', toSave);
        SessionManager.instance.storage.save();
      }
    } catch (e) {
      Get.log('Error saving cached chat: $e');
    }
  }

  void _groupMessages(List<ChatMessage> messages) {
    final now = DateTime.now();
    Map<String, List<ChatMessage>> customGrouped = {};

    for (var message in messages) {
      if (message.time != null) {
        final time =
            DateTime.fromMillisecondsSinceEpoch(message.time!.toInt());
        final formattedDate = DateFormat(AppRes.dMY).format(time);

        String groupKey;
        if (formattedDate == DateFormat(AppRes.dMY).format(now)) {
          groupKey = S.current.today;
        } else if (formattedDate ==
            DateFormat(AppRes.dMY)
                .format(now.subtract(const Duration(days: 1)))) {
          groupKey = S.current.yesterday;
        } else {
          groupKey = formattedDate;
        }

        customGrouped.putIfAbsent(groupKey, () => []).add(message);
      }
    }

    grouped = customGrouped;
  }

  Future<void> getPrefData() async {
    registrationUserData = SessionManager.instance.getUser();

    blockUnblock =
        conversation.block == true ? S.current.unBlock : S.current.block;
    isAutoPayEnable =
        SessionManager.instance.getBool(key: SessionKeys.isMessageDialog);
    isBlock = conversation.block == true ? true : false;
    isBlockOther = conversation.blockFromOther == true ? true : false;

    settingAppData = SessionManager.instance.getSettings()?.appdata;
    messagePrice = settingAppData?.messagePrice ?? 0;
    notifyListeners();

    getProfileAPi();
    initFireBaseData();
  }

  Future<void> getProfileAPi() async {
    ApiProvider().getProfile(userID: conversation.user?.userid).then((value) {
      receiverUserData = value.data;
      notifyListeners();
    });

    ApiProvider()
        .getProfile(userID: registrationUserData?.id)
        .then((value) async {
      registrationUserData = value.data;
      walletCoin = value.data?.wallet ?? 0;
      blockUnblock =
          value.data?.blockedUsers?.contains('${conversation.user?.userid}') ==
                  true
              ? S.current.unBlock
              : S.current.block;
      isBlock =
          value.data?.blockedUsers?.contains('${conversation.user?.userid}') ==
                  true
              ? true
              : false;
      notifyListeners();
      SessionManager.instance.setUser(value.data);
    });
  }

  void initFireBaseData() {
    int myId = registrationUserData?.id ?? SessionManager.instance.getUserID();
    int otherId = conversation.user?.userid ?? -1;

    documentReceiver = db
        .collection(FirebaseRes.userChatList)
        .doc('$otherId')
        .collection(FirebaseRes.userList)
        .doc('$myId');
    documentSender = db
        .collection(FirebaseRes.userChatList)
        .doc('$myId')
        .collection(FirebaseRes.userList)
        .doc('$otherId');

    if (conversation.conversationId == null ||
        conversation.conversationId!.isEmpty) {
      conversation.setConversationId(
        CommonFun.getConversationID(myId: myId, otherUserId: otherId),
      );
    }
    conversationID = conversation.conversationId ?? '';

    drChatMessages = db
        .collection(FirebaseRes.chat)
        .doc(conversation.conversationId)
        .collection(FirebaseRes.chat);

    _loadCachedChat();
    getChat();
  }

  Future<void> minusCoinApi(Function onCompletion) async {
    onCompletion.call();
    ApiProvider()
        .minusCoinFromWallet(settingAppData?.messagePrice)
        .then((minusCoinFromWallet) {
      if (minusCoinFromWallet.status == true && minusCoinFromWallet.wallet != null) {
        int wallet = minusCoinFromWallet.wallet!.toInt();
        registrationUserData?.wallet = wallet;
        walletCoin = wallet;
        updateDataLocalUser(registrationUserData);
        notifyListeners();
      }
    });
  }

  void scrollToGetChat() {
    scrollController.addListener(() {
      if (scrollController.offset ==
          scrollController.position.maxScrollExtent) {
        getChat();
      }
    });
  }

  void onUserTap() {
    Get.to(() => UserDetailScreen(userId: conversation.user?.userid));
  }

  void onCancelBtnClick() {
    timeStamp = [];
    notifyListeners();
  }

  // chat item delete method
  void chatDeleteDialog() {
    Get.dialog(ConfirmationDialog(
      onTap: onDeleteBtnClick,
      description: S.current.afterDeletingTheChatYouCanNotRestoreOurMessage,
      dialogSize: 1.6,
      padding: const EdgeInsets.symmetric(horizontal: 40),
    ));
  }

  void onDeleteBtnClick() {
    for (int i = 0; i < timeStamp.length; i++) {
      drChatMessages.doc(timeStamp[i]).update({
        FirebaseRes.noDeleteIdentity: FieldValue.arrayRemove(
          ['${registrationUserData?.id}'],
        )
      });
      chatData
          .removeWhere((element) => element.time.toString() == timeStamp[i]);
    }
    timeStamp = [];
    Get.back();
    notifyListeners();
  }

  // long press to select chat method
  void onLongPress(ChatMessage? data) {
    if (!timeStamp.contains('${data?.time?.round()}')) {
      timeStamp.add('${data?.time?.round()}');
    } else {
      timeStamp.remove('${data?.time?.round()}');
    }
    isLongPress = true;
    notifyListeners();
  }

  void unblockDialog() {
    Get.dialog(ConfirmationDialog(
      onTap: () {
        Get.back();
        unBlockUser();
      },
      description: S.current.areYouSureYouWantToUnblockThisUser,
      textButton: S.current.unBlock,
      heading: "${S.current.unBlock} ${conversation.user?.username} ?",
      dialogSize: 1.6,
    ));
  }

  // more btn event
  Future<void> onMoreBtnTap(String value) async {
    if (value == S.current.block) {
      blockUser();
    }
    if (value == S.current.unBlock) {
      unBlockUser();
    }

    if (value == AppRes.report) {
      Get.bottomSheet(
        ReportSheet(
          reportId: conversation.user?.userid,
          userData: receiverUserData,
          fullName: conversation.user?.username,
          profileImage: conversation.user?.image,
          age: int.parse(conversation.user?.age ?? '0'),
          address: conversation.user?.city,
          reportType: 1,
        ),
        isScrollControlled: true,
      );
    }
  }

  Future<void> blockUser() async {
    ApiProvider().updateBlockList(conversation.user?.userid);
    await documentSender
        .withConverter(
            fromFirestore: Conversation.fromFirestore,
            toFirestore: (Conversation value, options) {
              return value.toFirestore();
            })
        .update({
      FirebaseRes.block: true,
    });
    await documentReceiver
        .withConverter(
            fromFirestore: Conversation.fromFirestore,
            toFirestore: (Conversation value, options) {
              return value.toFirestore();
            })
        .update({
      FirebaseRes.blockFromOther: true,
    });
    blockUnblock = S.current.unBlock;
    isBlock = true;
    isBlockOther = true;
    notifyListeners();
  }

  Future<void> unBlockUser() async {
    ApiProvider().updateBlockList(conversation.user?.userid);
    await documentSender
        .withConverter(
            fromFirestore: Conversation.fromFirestore,
            toFirestore: (Conversation value, options) {
              return value.toFirestore();
            })
        .update({
      FirebaseRes.block: false,
    });
    await documentReceiver
        .withConverter(
            fromFirestore: Conversation.fromFirestore,
            toFirestore: (Conversation value, options) {
              return value.toFirestore();
            })
        .update({
      FirebaseRes.blockFromOther: false,
    });
    blockUnblock = S.current.block;
    isBlock = false;
    isBlockOther = false;
    notifyListeners();
  }

  // navigate to imageviewScreen
  void onImageTap(ChatMessage? imageData) {
    Get.to(() => ImageViewPage(userData: imageData, onBack: Get.back));
  }

  void _addOptimisticMessage(ChatMessage msg) {
    if (!chatData.any((m) => m.time == msg.time)) {
      chatData.insert(0, msg);
      _groupMessages(chatData);
      _saveCachedChat();
      notifyListeners();
    }
  }

  // send a text message
  void onSendBtnTap() async {
    if (textMsgController.text.trim().isEmpty) {
      return;
    }
    final textMessage = textMsgController.text.trim();
    textMsgController.clear();

    if (conversation.blockFromOther == true) {
      CommonUI.snackBarWidget(S.current.thisUserBlockYou);
      return;
    }

    if (textMessage.isEmpty) return;

    final int time = DateTime.now().millisecondsSinceEpoch;
    final optimisticMsg = ChatMessage(
      notDeletedIdentities: [
        '${registrationUserData?.id}',
        '${conversation.user?.userid}'
      ],
      senderUser: ChatUser(
        username: registrationUserData?.fullname,
        date: time.toDouble(),
        isHost: registrationUserData?.isVerified == 2,
        isNewMsg: true,
        userid: registrationUserData?.id,
        userIdentity: registrationUserData?.identity,
        image: registrationUserData?.profileImage,
        city: registrationUserData?.address,
        age: registrationUserData?.age.toString(),
      ),
      msgType: FirebaseRes.msg,
      msg: textMessage,
      id: conversation.user?.userid?.toString(),
      time: time.toDouble(),
    );
    _addOptimisticMessage(optimisticMsg);

    // Always send free for fake users or subscribed users or free message
    if (registrationUserData?.isFake == 1 ||
        isSubscribe.value ||
        messagePrice <= 0) {
      firebaseMsgUpdate(
          msgType: FirebaseRes.msg, textMessage: textMessage, customTime: time);
      return;
    }

    // Check wallet balance
    final currentWallet = registrationUserData?.wallet ?? walletCoin;
    if (currentWallet >= messagePrice) {
      if (isAutoPayEnable) {
        minusCoinApi(() {
          firebaseMsgUpdate(
              msgType: FirebaseRes.msg,
              textMessage: textMessage,
              customTime: time);
        });
      } else {
        getChatMsgDialog(onContinueTap: (isSelected) {
          isAutoPayEnable = isSelected;
          SessionManager.instance
              .setBool(key: SessionKeys.isMessageDialog, value: isSelected);
          minusCoinApi(() {
            Get.back();
            firebaseMsgUpdate(
                msgType: FirebaseRes.msg,
                textMessage: textMessage,
                customTime: time);
          });
        }, onCancelTap: () {
          chatData.removeWhere((m) => m.time == time.toDouble());
          notifyListeners();
        });
      }
    } else {
      chatData.removeWhere((m) => m.time == time.toDouble());
      notifyListeners();
      emptyDialog();
    }
  }

  void onTextMsgContinueClick(bool isSelected) {
    isAutoPayEnable = isSelected;
    SessionManager.instance.setBool(
      key: SessionKeys.isMessageDialog,
      value: isSelected,
    );

    final textMessage = textMsgController.text.trim();
    textMsgController.clear();

    minusCoinApi(() {
      Get.back();
      firebaseMsgUpdate(msgType: FirebaseRes.msg, textMessage: textMessage);
      // Clear text field early to avoid duplication
      textMsgController.clear();
    });
  }

  void onPlusButtonClick(int type) {
    if (registrationUserData?.isFake == 1 || isSubscribe.value) {
      openMediaPicker(type);
      return;
    }

    final currentWallet = registrationUserData?.wallet ?? walletCoin;
    if (messagePrice == 0 || currentWallet >= messagePrice) {
      openMediaPicker(type);
    } else {
      emptyDialog();
    }
  }

  void payAndOpenMediaPicker(int type) {
    minusCoinApi(() => openMediaPicker(type));
  }

  void onAutoPaySelected(bool isSelected, int type, Function onCompletion) {
    isAutoPayEnable = isSelected;
    SessionManager.instance.setBool(
      key: SessionKeys.isMessageDialog,
      value: isSelected,
    );

    minusCoinApi(() {
      Get.back(); // close dialog
      onCompletion.call();
      // openMediaPicker(type);
    });
  }

  void openMediaPicker(int type) {
    if (conversation.blockFromOther == true) {
      CommonUI.snackBarWidget(S.current.thisUserBlockYou);
      return;
    }

    Get.bottomSheet(
      ItemSelectionDialogAndroid(
        onImageBtnClick: () {
          Get.back();
          pickImage(type);
        },
        onVideoBtnClick: () {
          Get.back();
          pickVideo(type);
        },
      ),
      backgroundColor: ColorRes.transparent,
      isScrollControlled: true,
    );
  }

  Future<void> pickImage(int type) async {
    selectedItem = S.current.image;

    final XFile? picked = await picker.pickImage(
      source: type == 0 ? ImageSource.gallery : ImageSource.camera,
      imageQuality: AppRes.quality,
      maxHeight: AppRes.maxHeight,
      maxWidth: AppRes.maxWidth,
    );

    if (picked == null || picked.path.isEmpty) return;

    final imageBytes = await picked.readAsBytes();
    final imageFile = File(picked.path);

    Get.bottomSheet(
      ImageVideoSendSheet(
        image: imageFile,
        selectedItem: selectedItem,
        onSendBtnClick: (msg, _) async {
          CommonUI.lottieLoader();
          isAutoPayEnable
              ? minusCoinApi(() async {
                  final response = await ApiProvider().getStoreFileGivePath(
                    image: picked,
                    bytes: imageBytes,
                    filename: picked.name,
                  );
                  Get.back(); // close loader
                  if (response.status == true) {
                    Get.back(); // close sheet
                    firebaseMsgUpdate(
                      image: response.path,
                      msgType: FirebaseRes.image,
                      textMessage: msg,
                    );
                  } else {
                    CommonUI.snackBarWidget(response.message);
                  }
                })
              : getChatMsgDialog(
                  onContinueTap: (isSelected) => onAutoPaySelected(
                    isSelected,
                    type,
                    () async {
                      final response = await ApiProvider().getStoreFileGivePath(
                        image: picked,
                        bytes: imageBytes,
                        filename: picked.name,
                      );
                      Get.back(); // close loader
                      if (response.status == true) {
                        Get.back(); // close sheet
                        firebaseMsgUpdate(
                          image: response.path,
                          msgType: FirebaseRes.image,
                          textMessage: msg,
                        );
                      } else {
                        CommonUI.snackBarWidget(response.message);
                      }
                    },
                  ),
                  onCancelTap: () {
                    Get.back();
                    Get.back();
                  },
                );
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> pickVideo(int type) async {
    selectedItem = S.current.videoCap;

    final XFile? picked = await picker.pickVideo(
      source: type == 0 ? ImageSource.gallery : ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );

    if (picked == null || picked.path.isEmpty) return;

    final videoBytes = await picked.readAsBytes();
    final sizeInMb = videoBytes.length / (1024 * 1024);

    if (sizeInMb > AppRes.maxVideoUploadSize) {
      Get.dialog(VideoUploadDialog(
        selectAnother: () {
          Get.back();
          pickVideo(type);
        },
      ));
      return;
    }

    final thumbnail = await CommonFun.getFileThumbnail(picked.path);

    Get.bottomSheet(
      ImageVideoSendSheet(
        image: thumbnail,
        selectedItem: selectedItem,
        onSendBtnClick: (msg, _) async {
          CommonUI.lottieLoader();
          isAutoPayEnable
              ? minusCoinApi(() async {
                  // Run both uploads concurrently
                  final [thumbRes, videoRes] = await Future.wait([
                    ApiProvider().getStoreFileGivePath(
                      image: thumbnail,
                      filename: 'thumb_${picked.name}.jpg',
                    ),
                    ApiProvider().getStoreFileGivePath(
                      image: picked,
                      bytes: videoBytes,
                      filename: picked.name,
                    ),
                  ]);

                  Get.back(); // close loader

                  if (thumbRes.status == true && videoRes.status == true) {
                    Get.back(); // close sheet
                    firebaseMsgUpdate(
                      textMessage: msg,
                      video: videoRes.path,
                      msgType: FirebaseRes.video,
                      image: thumbRes.path,
                    );
                  } else {
                    CommonUI.snackBarWidget(
                      thumbRes.message ?? videoRes.message,
                    );
                  }
                })
              : getChatMsgDialog(
                  onContinueTap: (isSelected) => onAutoPaySelected(
                    isSelected,
                    type,
                    () async {
                      // Run both uploads concurrently
                      final [thumbRes, videoRes] = await Future.wait([
                        ApiProvider().getStoreFileGivePath(
                          image: thumbnail,
                          filename: 'thumb_${picked.name}.jpg',
                        ),
                        ApiProvider().getStoreFileGivePath(
                          image: picked,
                          bytes: videoBytes,
                          filename: picked.name,
                        ),
                      ]);

                      Get.back(); // close loader

                      if (thumbRes.status == true && videoRes.status == true) {
                        Get.back(); // close sheet
                        firebaseMsgUpdate(
                          textMessage: msg,
                          video: videoRes.path,
                          msgType: FirebaseRes.video,
                          image: thumbRes.path,
                        );
                      } else {
                        CommonUI.snackBarWidget(
                          thumbRes.message ?? videoRes.message,
                        );
                      }
                    },
                  ),
                  onCancelTap: () {
                    Get.back();
                    Get.back();
                  },
                );
        },
      ),
      isScrollControlled: true,
    );
  }

  //  video preview screen navigate
  void onVideoItemClick(ChatMessage? data) {
    Get.to(() => VideoPreviewScreen(
          videoUrl: data?.video,
          type: VideoType.other,
        ));
  }

  Future<void> getChat() async {
    try {
      Get.log('[getChat] 🔄 Starting getChat()');

      // Fetch deletedId asynchronously without blocking the stream
      documentSender
          .withConverter(
            fromFirestore: Conversation.fromFirestore,
            toFirestore: (Conversation value, options) => value.toFirestore(),
          )
          .get()
          .then((docSnapshot) {
        deletedId = docSnapshot.data()?.deletedId?.toString() ?? '';
        Get.log('[getChat] 🗑️ deletedId: $deletedId');
      }).catchError((_) {});

      // Stream chat messages with reliable single-field index query
      Get.log('[getChat] 📡 Setting up chat stream...');
      chatStream?.cancel();
      chatStream = drChatMessages
          .orderBy(FirebaseRes.time, descending: true)
          .limit(startingNumber)
          .withConverter(
            fromFirestore: ChatMessage.fromFirestore,
            toFirestore: (ChatMessage value, options) => value.toFirestore(),
          )
          .snapshots()
          .listen((snapshot) {
        final myIdNum =
            registrationUserData?.id ?? SessionManager.instance.getUserID();
        final myIdStr = myIdNum.toString();

        final incoming = snapshot.docs
            .map((doc) => doc.data())
            .where((msg) {
              // Only filter out if the message was explicitly deleted by this specific user
              if (myIdNum > 0 &&
                  msg.notDeletedIdentities != null &&
                  msg.notDeletedIdentities!.isNotEmpty &&
                  !msg.notDeletedIdentities!.contains(myIdStr) &&
                  !msg.notDeletedIdentities!.contains(myIdNum)) {
                return false;
              }
              return true;
            })
            .toList();

        if (incoming.isNotEmpty) {
          chatData = incoming;
          _saveCachedChat();
          _groupMessages(chatData);
        } else if (chatData.isEmpty) {
          _loadCachedChat();
        }
        startingNumber += 30;
        Get.log('[getChat] 💬 Messages fetched and cached: ${chatData.length}');
        notifyListeners();
      }, onError: (err) {
        Get.log('[getChat] ❌ Stream error: $err');
      });
    } catch (e) {
      Get.log('[getChat] ❌ Error fetching chat: $e');
    }
  }

  //Firebase message update method
  Future<void> firebaseMsgUpdate({
    required String msgType,
    String? textMessage,
    String? image,
    String? video,
    int? customTime,
  }) async {
    final int time = customTime ?? DateTime.now().millisecondsSinceEpoch;
    final int myId =
        registrationUserData?.id ?? SessionManager.instance.getUserID();
    notDeletedIdentity = [
      '$myId',
      '${conversation.user?.userid}'
    ];

    final isHost = registrationUserData?.isVerified == 2;
    final messageData = ChatMessage(
      notDeletedIdentities: notDeletedIdentity,
      senderUser: ChatUser(
        username: registrationUserData?.fullname,
        date: time.toDouble(),
        isHost: isHost,
        isNewMsg: true,
        userid: registrationUserData?.id,
        userIdentity: registrationUserData?.identity,
        image: registrationUserData?.profileImage,
        city: registrationUserData?.address,
        age: registrationUserData?.age.toString(),
      ),
      msgType: msgType,
      msg: textMessage,
      image: image,
      video: video,
      id: conversation.user?.userid?.toString(),
      time: time.toDouble(),
    ).toJson();

    final String lastMessage =
        CommonFun.getLastMsg(msgType: msgType, msg: textMessage ?? '');

    // Optimistic UI update: show message immediately in chat
    final newMsgObj = ChatMessage.fromJson(messageData);
    chatData.insert(0, newMsgObj);
    _groupMessages(chatData);
    _saveCachedChat();
    notifyListeners();

    // 1. Store message in Firestore (non-blocking)
    final msgSetFuture = drChatMessages.doc(time.toString()).set(messageData);

    // 2. Sender conversation update (upsert with merge)
    final senderCon = conversation.toJson();
    senderCon[FirebaseRes.lastMsg] = lastMessage;
    senderCon[FirebaseRes.time] = time.toDouble();
    senderCon[FirebaseRes.isDeleted] = false;
    senderCon[FirebaseRes.deletedId] = '';
    final senderFuture = documentSender.set(senderCon, SetOptions(merge: true));

    // 3. Receiver conversation update (upsert with merge)
    final receiverUser = ChatUser(
      username: registrationUserData?.fullname,
      date: time.toDouble(),
      isHost: isHost,
      isNewMsg: true,
      userid: registrationUserData?.id,
      userIdentity: registrationUserData?.identity,
      image: registrationUserData?.profileImage,
      city: registrationUserData?.address,
      age: registrationUserData?.age.toString(),
    );

    final receiverCon = Conversation(
      block: false,
      blockFromOther: false,
      conversationId: conversation.conversationId,
      deletedId: '',
      isDeleted: false,
      isMute: false,
      lastMsg: lastMessage,
      newMsg: lastMessage,
      time: time.toDouble(),
      user: receiverUser,
    ).toJson();
    final receiverFuture =
        documentReceiver.set(receiverCon, SetOptions(merge: true));

    // Run all Firestore updates concurrently
    await Future.wait([msgSetFuture, senderFuture, receiverFuture])
        .then((_) {
      _saveCachedChat();
    }).catchError((err) {
      Get.log('Error writing chat to firestore: $err');
    });

    if (receiverUserData?.isNotification == 1) {
      _sendPushNotification(lastMessage);
    }
  }

  void _sendPushNotification(String lastMessage) {
    ApiProvider().pushNotification(
      title: registrationUserData?.fullname ?? '',
      body: lastMessage,
      conversationId: conversation.conversationId ?? '',
      deviceType: receiverUserData?.deviceType,
      token: '${receiverUserData?.deviceToken}',
    );
  }

  void emptyDialog() {
    Get.dialog(
      EmptyWalletDialog(
          onCancelTap: () {
            Get.back();
          },
          onContinueTap: () {
            Get.back();
            Get.bottomSheet(const BottomDiamondShop());
          },
          walletCoin: registrationUserData?.wallet ?? walletCoin),
    );
  }

  void getChatMsgDialog(
      {required Function(bool isSelected) onContinueTap,
      required Function onCancelTap}) {
    Get.dialog(
      ReverseSwipeDialog(
          onContinueTap: onContinueTap,
          isCheckBoxVisible: true,
          walletCoin: walletCoin,
          title1: S.current.message.toUpperCase(),
          title2: S.current.priceCap,
          dialogDisc: AppRes.messageDisc(settingAppData?.messagePrice),
          coinPrice: '${settingAppData?.messagePrice ?? 0}',
          onCancelTap: () {
            Get.back();
            onCancelTap.call();
          }),
    ).then((value) {
      getProfileAPi();
    });
  }

  void updateDataLocalUser(UserData? data) {
    SessionManager.instance.setUser(data);
  }

  // Dispose Method
  @override
  void dispose() {
    _updateSenderUser(); // Offload Firestore update to a separate method
    _disposeControllers(); // Clean up resources
    super.dispose();
  }

  void _updateSenderUser() async {
    try {
      var docSnapshot = await documentSender
          .withConverter(
            fromFirestore: Conversation.fromFirestore,
            toFirestore: (Conversation value, options) => value.toFirestore(),
          )
          .get();

      var senderUser = docSnapshot.data()?.user;
      if (senderUser != null) {
        senderUser.isNewMsg = false;
        await documentSender.update({FirebaseRes.user: senderUser.toJson()});
      }
    } catch (e) {
      debugPrint("Error updating sender user: $e");
    }
  }

  void _disposeControllers() {
    chatStream?.cancel();
    conUserStream?.cancel();
    scrollController.dispose();
    textMsgController.dispose();
    conversationID = '';
  }
}
