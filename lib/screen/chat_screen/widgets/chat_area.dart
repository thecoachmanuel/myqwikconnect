import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/model/chat_and_live_stream/chat.dart';
import 'package:orange_ui/screen/chat_screen/chat_screen_view_model.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/utils/app_platform.dart';
import 'package:orange_ui/utils/app_res.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/firebase_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/style_res.dart';

class ChatArea extends StatelessWidget {
  final Map<String, List<ChatMessage>>? chatData;
  final Function(ChatMessage? data) onImageTap;
  final ScrollController scrollController;
  final Function(ChatMessage? data) onVideoItemClick;
  final Function(ChatMessage? data) onLongPress;
  final List<String> timeStamp;
  final ChatScreenViewModel model;

  const ChatArea({
    super.key,
    required this.chatData,
    required this.onImageTap,
    required this.scrollController,
    required this.onVideoItemClick,
    required this.onLongPress,
    required this.timeStamp,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (overscroll) {
          overscroll.disallowIndicator();
          return true;
        },
        child: ListView.builder(
          controller: scrollController,
          reverse: true,
          padding: const EdgeInsets.only(bottom: 10),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: chatData != null ? chatData?.keys.length : 0,
          physics: AppPlatform.isAndroid
              ? const ClampingScrollPhysics()
              : const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            String? date = chatData?.keys.elementAt(index) ?? '';
            List<ChatMessage>? messages = chatData?[date];
            return Column(
              children: [
                alertView(date),
                ListView.builder(
                  itemCount: messages?.length,
                  reverse: true,
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    ChatMessage? data = messages?[index];
                    return userMessageWidget(data, model: model);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget userMessageWidget(ChatMessage? data,
      {required ChatScreenViewModel model}) {
    bool isMsgSelected = timeStamp.contains('${data?.time?.round()}');
    bool isMe = data?.senderUser?.userid == SessionManager.instance.getUserID();
    return InkWell(
      onLongPress: () => onLongPress(data),
      onTap: () {
        timeStamp.isNotEmpty ? onLongPress(data) : () {};
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: ColorRes.white,
          borderRadius: BorderRadius.circular(10),
        ),
        foregroundDecoration: BoxDecoration(
          color: isMsgSelected
              ? ColorRes.themeColor.withValues(alpha: 0.3)
              : ColorRes.transparent,
          borderRadius: isMsgSelected
              ? BorderRadius.circular(0)
              : BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (isMe) ...[
              _dateFormater(data?.time),
              if (data?.isSending == true)
                const Padding(
                  padding: EdgeInsets.only(right: 5.0),
                  child: SizedBox(
                    width: 11,
                    height: 11,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: ColorRes.grey2),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 5.0),
                  child: Icon(Icons.done_all_rounded, size: 14, color: ColorRes.themeColor),
                ),
            ],
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isMe ? null : ColorRes.grey10,
                  gradient: !isMe ? null : StyleRes.linearGradient),
              child: data?.msgType == FirebaseRes.msg
                  ? _textMessage(data)
                  : data?.msgType == FirebaseRes.image
                      ? imageMessage(data, model: model)
                      : videoMessage(data, model: model),
            ),
            if (!isMe) _dateFormater(data?.time),
          ],
        ),
      ),
    );
  }

  Widget _textMessage(ChatMessage? data, {EdgeInsets? padding}) {
    bool isMe = data?.senderUser?.userid == SessionManager.instance.getUserID();
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxWidth: data?.msgType == FirebaseRes.msg
              ? Get.width / 1.4
              : Get.width / 1.7),
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(vertical: 13.0, horizontal: 11),
        child: Text(
          data?.msg ?? '',
          style: TextStyle(
              color: isMe ? ColorRes.white : ColorRes.darkGrey,
              fontFamily: FontRes.regular),
        ),
      ),
    );
  }

  Widget imageMessage(ChatMessage? data, {required ChatScreenViewModel model}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        imageVideoPosterWidget(
            data: data,
            onTap: model.timeStamp.isEmpty ? (data) => onImageTap(data) : null),
        if ((data?.msg ?? '').isNotEmpty)
          _textMessage(data,
              padding: const EdgeInsets.only(bottom: 8.0, left: 10, right: 10)),
      ],
    );
  }

  Widget videoMessage(ChatMessage? data, {required ChatScreenViewModel model}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            imageVideoPosterWidget(
                data: data,
                onTap: model.timeStamp.isEmpty ? onVideoItemClick : null),
            if ((data?.msg ?? '').isNotEmpty)
              _textMessage(data,
                  padding:
                      const EdgeInsets.only(bottom: 8.0, left: 10, right: 10)),
          ],
        ),
      ],
    );
  }

  Widget _dateFormater(double? time) {
    if (time == null) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Text(
          DateFormat(AppRes.hmmA)
              .format(DateTime.fromMillisecondsSinceEpoch(time.toInt())),
          style: const TextStyle(color: ColorRes.grey2, fontSize: 12)),
    );
  }

  Widget alertView(String? time) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: ColorRes.grey13,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text('$time',
            style: const TextStyle(color: ColorRes.darkGrey9, fontSize: 11)),
      ),
    );
  }

  Widget imageVideoPosterWidget(
      {ChatMessage? data, Function(ChatMessage? data)? onTap}) {
    final bool isSending = data?.isSending == true;
    final double mediaWidth = (Get.width * 0.65).clamp(200.0, 260.0);
    final double mediaHeight = (mediaWidth * 0.85).clamp(170.0, 220.0);

    return InkWell(
      onTap: (!isSending && onTap != null) ? () => onTap(data) : null,
      child: Container(
        padding: const EdgeInsets.all(4.0),
        height: mediaHeight,
        width: mediaWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomImage(
                image: data?.image,
                height: mediaHeight,
                width: mediaWidth,
                fit: BoxFit.cover,
                radius: 8,
              ),
              if (data?.msgType == FirebaseRes.video && !isSending)
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: ColorRes.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(AssetRes.playButton,
                        height: 18, width: 17, color: ColorRes.white),
                  ),
                ),
              if (isSending)
                Container(
                  color: ColorRes.black.withValues(alpha: 0.45),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: ColorRes.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sending...',
                        style: TextStyle(
                          color: ColorRes.white.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontFamily: FontRes.medium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
