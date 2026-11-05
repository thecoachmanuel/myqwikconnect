import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
import 'package:orange_ui/service/presence_service.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/service/subscription/subscription_manager.dart';
import 'package:orange_ui/utils/app_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/firebase_res.dart';
import 'package:stacked/stacked.dart';
import 'package:video_compress/video_compress.dart';

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
  bool isUserOnline = false;
  String userLastSeen = '';
  StreamSubscription? presenceSubscription;

  Appdata? settingAppData;

  ChatScreenViewModel(this.conversation);

  void init() {
    conversationID = conversation.conversationId ?? '';
    _loadCachedChat();
    getPrefData();
    scrollToGetChat();
  }

  String _getChatStorageKey() {
    final int myId =
        registrationUserData?.id ?? SessionManager.instance.getUserID();
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
      if (cached != null &&
          cached is List &&
          cached.isNotEmpty &&
          chatData.isEmpty) {
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
        final time = DateTime.fromMillisecondsSinceEpoch(message.time!.toInt());
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

    final targetId = conversation.user?.userid;
    if (targetId != null && targetId > 0) {
      presenceSubscription?.cancel();
      presenceSubscription = FirebaseFirestore.instance
          .collection('user_presence')
          .doc('$targetId')
          .snapshots()
          .listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          isUserOnline = data['isOnline'] == true;
          userLastSeen = PresenceService.formatLastSeen(data['lastSeen']);
        } else {
          isUserOnline = false;
          userLastSeen = 'Offline';
        }
        notifyListeners();
      }, onError: (_) {});
    }

    ApiProvider().getSettingData().then((value) {
      if (value.status == true && value.data != null) {
        SessionManager.instance.setSettings(value.data);
        settingAppData = value.data?.appdata;
        messagePrice = settingAppData?.messagePrice ?? 0;
        notifyListeners();
      }
    }).catchError((_) {});

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
      if (minusCoinFromWallet.status == true &&
          minusCoinFromWallet.wallet != null) {
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
        isHost: (registrationUserData?.isVerified ?? 0) >= 2,
        isNewMsg: true,
        userid: registrationUserData?.id,
        userIdentity: registrationUserData?.identity,
        image: registrationUserData?.profileImage,
        city: registrationUserData?.address,
        age: registrationUserData?.age.toString(),
        isVerified: registrationUserData?.isVerified,
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
        registrationUserData?.isPro == 1 ||
        registrationUserData?.isVerified == 3 ||
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
    if (registrationUserData?.isFake == 1 ||
        isSubscribe.value ||
        registrationUserData?.isPro == 1 ||
        registrationUserData?.isVerified == 3) {
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

    final isChatVideoEnabled = settingAppData?.chatVideoEnabled == 1;

    if (!isChatVideoEnabled) {
      // Admin has video disabled by default for chat: directly open image picker
      pickImage(type);
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

  void _sendOptimisticMedia({
    required String msgType,
    required String localPath,
    String? localVideoPath,
    String? caption,
    required Future<Map<String, String?>> Function() uploadCallback,
  }) {
    final int time = DateTime.now().millisecondsSinceEpoch;
    final int myId =
        registrationUserData?.id ?? SessionManager.instance.getUserID();

    final optimisticMsg = ChatMessage(
      id: conversation.user?.userid?.toString(),
      msgType: msgType,
      msg: caption,
      image: localPath,
      video: localVideoPath,
      time: time.toDouble(),
      isSending: true,
      notDeletedIdentities: ['$myId', '${conversation.user?.userid}'],
      senderUser: ChatUser(
        username: registrationUserData?.fullname,
        date: time.toDouble(),
        isHost: (registrationUserData?.isVerified ?? 0) >= 2,
        isNewMsg: true,
        userid: myId,
        userIdentity: registrationUserData?.identity,
        image: registrationUserData?.profileImage,
        city: registrationUserData?.address,
        age: registrationUserData?.age.toString(),
        isVerified: registrationUserData?.isVerified,
      ),
    );

    _addOptimisticMessage(optimisticMsg);

    void executeUpload() async {
      try {
        final result = await uploadCallback();
        final remoteImage = result['image'];
        final remoteVideo = result['video'];

        if (remoteImage != null || remoteVideo != null) {
          optimisticMsg.image = remoteImage ?? localPath;
          optimisticMsg.video = remoteVideo ?? localVideoPath;
          optimisticMsg.isSending = false;

          await firebaseMsgUpdate(
            msgType: msgType,
            textMessage: caption,
            image: remoteImage,
            video: remoteVideo,
            customTime: time,
          );
        } else {
          chatData.removeWhere((m) => m.time == time.toDouble());
          _groupMessages(chatData);
          notifyListeners();
          CommonUI.snackBar(
              message: 'Failed to upload media. Please try again.');
        }
      } catch (e) {
        chatData.removeWhere((m) => m.time == time.toDouble());
        _groupMessages(chatData);
        notifyListeners();
        CommonUI.snackBar(message: 'Failed to upload media. Please try again.');
      }
    }

    if (registrationUserData?.isFake == 1 ||
        isSubscribe.value ||
        registrationUserData?.isPro == 1 ||
        registrationUserData?.isVerified == 3 ||
        messagePrice <= 0) {
      executeUpload();
    } else {
      final currentWallet = registrationUserData?.wallet ?? walletCoin;
      if (currentWallet >= messagePrice) {
        if (isAutoPayEnable) {
          minusCoinApi(executeUpload);
        } else {
          getChatMsgDialog(
            onContinueTap: (isSelected) {
              isAutoPayEnable = isSelected;
              SessionManager.instance
                  .setBool(key: SessionKeys.isMessageDialog, value: isSelected);
              Get.back();
              minusCoinApi(executeUpload);
            },
            onCancelTap: () {
              Get.back();
              chatData.removeWhere((m) => m.time == time.toDouble());
              _groupMessages(chatData);
              notifyListeners();
            },
          );
        }
      } else {
        chatData.removeWhere((m) => m.time == time.toDouble());
        _groupMessages(chatData);
        notifyListeners();
        emptyDialog();
      }
    }
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
        onSendBtnClick: (msg, _) {
          Get.back(); // Close sheet immediately
          _sendOptimisticMedia(
            msgType: FirebaseRes.image,
            localPath: picked.path,
            caption: msg,
            uploadCallback: () async {
              final response = await ApiProvider().getStoreFileGivePath(
                image: picked,
                bytes: imageBytes,
                filename: picked.name,
              );
              if (response.status == true && response.path != null) {
                return {'image': response.path};
              }
              return {};
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
      maxDuration: const Duration(seconds: 120),
    );

    if (picked == null || picked.path.isEmpty) return;

    File effectiveVideoFile = File(picked.path);
    Uint8List effectiveVideoBytes = await picked.readAsBytes();
    String videoFileName = picked.name;

    // WhatsApp-standard compression for video uploads on mobile
    if (!kIsWeb) {
      try {
        CommonUI.lottieLoader();
        final MediaInfo? info = await VideoCompress.compressVideo(
          picked.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );
        Get.back();
        if (info != null && info.file != null && info.file!.existsSync()) {
          effectiveVideoFile = info.file!;
          effectiveVideoBytes = await info.file!.readAsBytes();
          videoFileName = info.file!.path.split(Platform.pathSeparator).last;
        }
      } catch (e) {
        Get.back();
        debugPrint('VideoCompress error: $e');
      }
    }

    final sizeInMb = effectiveVideoBytes.length / (1024 * 1024);

    if (sizeInMb > AppRes.maxVideoUploadSize) {
      Get.dialog(VideoUploadDialog(
        selectAnother: () {
          Get.back();
          pickVideo(type);
        },
      ));
      return;
    }

    File? thumbnail;
    try {
      thumbnail = await CommonFun.getFileThumbnail(effectiveVideoFile.path);
    } catch (_) {}

    Get.bottomSheet(
      ImageVideoSendSheet(
        image: thumbnail ?? effectiveVideoFile,
        videoPath: effectiveVideoFile.path,
        isVideo: true,
        selectedItem: selectedItem,
        onSendBtnClick: (msg, _) {
          Get.back(); // Close sheet immediately
          _sendOptimisticMedia(
            msgType: FirebaseRes.video,
            localPath: thumbnail?.path ?? effectiveVideoFile.path,
            localVideoPath: effectiveVideoFile.path,
            caption: msg,
            uploadCallback: () async {
              // 1. Upload video file first
              final videoRes = await ApiProvider().getStoreFileGivePath(
                image: XFile(effectiveVideoFile.path),
                bytes: effectiveVideoBytes,
                filename: videoFileName,
              );

              if (videoRes.status != true || (videoRes.path ?? '').isEmpty) {
                return {};
              }

              // 2. Try uploading thumbnail gracefully (optional)
              String thumbUrl = videoRes.path!;
              try {
                if (!kIsWeb && thumbnail != null && thumbnail.existsSync()) {
                  final thumbRes = await ApiProvider().getStoreFileGivePath(
                    image: XFile(thumbnail.path),
                    filename: 'thumb_$videoFileName.jpg',
                  );
                  if (thumbRes.status == true &&
                      (thumbRes.path ?? '').isNotEmpty) {
                    thumbUrl = thumbRes.path!;
                  }
                }
              } catch (_) {}

              return {'image': thumbUrl, 'video': videoRes.path!};
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

        final incoming = snapshot.docs.map((doc) => doc.data()).where((msg) {
          // Only filter out if the message was explicitly deleted by this specific user
          if (myIdNum > 0 &&
              msg.notDeletedIdentities != null &&
              msg.notDeletedIdentities!.isNotEmpty &&
              !msg.notDeletedIdentities!.contains(myIdStr)) {
            return false;
          }
          return true;
        }).toList();

        if (incoming.isNotEmpty) {
          chatData = incoming;
          _saveCachedChat();
          _groupMessages(chatData);
          // Mark any unread messages from the other user as read
          _markMessagesAsRead(incoming);
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
  /// Marks messages from the other user as read in Firestore (batch write).
  void _markMessagesAsRead(List<ChatMessage> messages) {
    try {
      final int myId =
          registrationUserData?.id ?? SessionManager.instance.getUserID();
      // Find messages sent by the other user that aren't yet marked as read
      final unread = messages.where((m) =>
          m.senderUser?.userid != myId && m.isRead == false && m.time != null);
      if (unread.isEmpty) return;
      final batch = db.batch();
      for (final msg in unread) {
        batch.update(
          drChatMessages.doc(msg.time!.toInt().toString()),
          {'isRead': true},
        );
      }
      batch.commit().catchError((e) {
        Get.log('[markRead] ❌ Error: $e');
      });
    } catch (e) {
      Get.log('[markRead] ❌ Exception: $e');
    }
  }  Future<void> firebaseMsgUpdate({
    required String msgType,
    String? textMessage,
    String? image,
    String? video,
    int? customTime,
  }) async {
    final int time = customTime ?? DateTime.now().millisecondsSinceEpoch;
    final int myId =
        registrationUserData?.id ?? SessionManager.instance.getUserID();
    notDeletedIdentity = ['$myId', '${conversation.user?.userid}'];

    final isHost = (registrationUserData?.isVerified ?? 0) >= 2;
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
        isVerified: registrationUserData?.isVerified,
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

    // Optimistic UI update: update existing optimistic message or insert new one
    final existingIdx = chatData.indexWhere((m) => m.time == time.toDouble());
    if (existingIdx >= 0) {
      chatData[existingIdx] = ChatMessage.fromJson(messageData)
        ..isSending = false;
    } else {
      chatData.insert(0, ChatMessage.fromJson(messageData));
    }
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
      isVerified: registrationUserData?.isVerified,
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
    await Future.wait([msgSetFuture, senderFuture, receiverFuture]).then((_) {
      _saveCachedChat();
    }).catchError((err) {
      Get.log('Error writing chat to firestore: $err');
    });

    if (receiverUserData?.isNotification != 0) {
      _sendPushNotification(lastMessage);
    }
  }

  void _sendPushNotification(String lastMessage) {
    final myId =
        registrationUserData?.id ?? SessionManager.instance.getUserID();
    final receiverId = conversation.user?.userid;
    ApiProvider().pushNotification(
      title: registrationUserData?.fullname ?? '',
      body: lastMessage,
      conversationId: conversation.conversationId ?? '',
      deviceType: receiverUserData?.deviceType,
      token: receiverUserData?.deviceToken ?? '',
      myUserId: myId > 0 ? myId : null,
      targetUserId: receiverId != null && receiverId > 0 ? receiverId : null,
    );
  }

  void emptyDialog() {
    Get.dialog(
      EmptyWalletDialog(
          onCancelTap: () {
            Get.back();
          },
          onContinueTap: () async {
            Get.back();
            await Get.bottomSheet(const BottomDiamondShop());
            final myUser = SessionManager.instance.getUser();
            if (myUser != null) {
              registrationUserData = myUser;
              walletCoin = myUser.wallet ?? 0;
              notifyListeners();
            }
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
