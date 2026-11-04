import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/button/round_icon_button.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/model/chat_and_live_stream/chat.dart';
import 'package:orange_ui/utils/app_res.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class ChatTopBarArea extends StatelessWidget {
  final Conversation? conversation;
  final Function(String value) onMoreBtnTap;
  final String blockUnblock;
  final VoidCallback onUserTap;
  final bool isOnline;
  final String lastSeen;

  const ChatTopBarArea({
    super.key,
    required this.conversation,
    required this.onMoreBtnTap,
    required this.blockUnblock,
    required this.onUserTap,
    this.isOnline = false,
    this.lastSeen = '',
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                const RoundIconButton(bgColor: ColorRes.transparent),
                const SizedBox(width: 15),
                Stack(
                  children: [
                    GestureDetector(
                      onTap: onUserTap,
                      child: CustomImage(
                        image: conversation?.user?.image,
                        fullname: conversation?.user?.username,
                        height: 38,
                        width: 38,
                        radius: 19,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: ColorRes.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: onUserTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                conversation?.user?.username != null
                                    ? '${conversation?.user?.username} '
                                            .capitalize ??
                                        ''
                                    : ' ',
                                style: const TextStyle(
                                  color: ColorRes.darkGrey,
                                  fontSize: 16,
                                  fontFamily: FontRes.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (conversation?.user?.isHost == true ||
                                conversation?.user?.isVerify == true) ...[
                              const SizedBox(width: 4),
                              Image.asset(AssetRes.tickMark,
                                  height: 16, width: 16),
                            ],
                            if (conversation?.user?.age != null &&
                                conversation!.user!.age!.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                conversation!.user!.age!,
                                style: const TextStyle(
                                  color: ColorRes.darkGrey,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            if (isOnline) ...[
                              const Text(
                                'Online',
                                style: TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontFamily: FontRes.medium,
                                  fontSize: 12.5,
                                ),
                              ),
                            ] else ...[
                              Text(
                                lastSeen.isNotEmpty
                                    ? lastSeen
                                    : (conversation?.user?.city != null
                                        ? "${conversation?.user?.city}"
                                        : 'Offline'),
                                style: const TextStyle(
                                  color: ColorRes.darkGrey9,
                                  fontFamily: FontRes.regular,
                                  fontSize: 12.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    onMoreBtnTap(value);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                  itemBuilder: (BuildContext context) {
                    return {blockUnblock, AppRes.report}.map(
                      (String choice) {
                        return PopupMenuItem<String>(
                          value: choice,
                          child: Text(choice),
                        );
                      },
                    ).toList();
                  },
                  child: Image.asset(
                    AssetRes.moreHorizontal,
                    height: 27,
                    width: 27,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 0.5,
            width: Get.width,
            margin: const EdgeInsets.only(right: 10, left: 10, bottom: 5.5),
            color: ColorRes.grey2,
          ),
        ],
      ),
    );
  }
}
