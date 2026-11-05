import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_ui/common/qwik_connect_logo.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/chat_and_live_stream/live_stream.dart';
import 'package:orange_ui/service/extention/int_extention.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class RandomStreamTopBarArea extends StatelessWidget {
  final VoidCallback onEndBtnTap;
  final VoidCallback onDiamondTap;
  final VoidCallback onCameraTap;
  final VoidCallback onSpeakerTap;
  final VoidCallback? onVideoToggle;
  final bool isVideoHidden;
  final bool mute;
  final LiveStreamUser? user;

  const RandomStreamTopBarArea({
    super.key,
    required this.onEndBtnTap,
    required this.onDiamondTap,
    required this.onCameraTap,
    required this.onSpeakerTap,
    this.onVideoToggle,
    this.isVideoHidden = false,
    required this.mute,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            height: 45,
            width: Get.width,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: ColorRes.black.withValues(alpha: 0.33),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    const QwikConnectLogo(
                        fontSize: 16, connectColor: ColorRes.white),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ColorRes.themeColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        S.current.live.toUpperCase(),
                        style: const TextStyle(
                          color: ColorRes.white,
                          fontSize: 10,
                          fontFamily: FontRes.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onEndBtnTap,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 88,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              ColorRes.themeColor,
                              ColorRes.lightOrange,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            S.current.end,
                            style: const TextStyle(
                              color: ColorRes.white,
                              fontSize: 12,
                              fontFamily: FontRes.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    "${NumberFormat.compact(locale: 'en').format(double.parse('${user?.watchingCount ?? '0'}'))} ${S.current.viewers}",
                    style: const TextStyle(
                      color: ColorRes.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 45,
            width: Get.width,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: ShapeDecoration(
              color: ColorRes.black.withValues(alpha: 0.33),
              shape: SmoothRectangleBorder(
                  borderRadius:
                      SmoothBorderRadius(cornerRadius: 30, cornerSmoothing: 1)),
            ),
            child: Row(
              spacing: 5,
              children: [
                const SizedBox(width: 5),
                Expanded(
                  child: InkWell(
                    onTap: onDiamondTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(AssetRes.diamond, width: 15, height: 15),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            "${user?.collectedDiamond?.numberFormat} ${S.current.collected}",
                            style: const TextStyle(
                                color: ColorRes.white, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Flip camera button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onCameraTap,
                  child: Container(
                    height: 37,
                    width: 37,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorRes.black.withValues(alpha: 0.33),
                    ),
                    child: Center(
                      child: Image.asset(
                        AssetRes.icCameraFlip,
                        height: 18,
                        width: 18,
                        color: ColorRes.white,
                      ),
                    ),
                  ),
                ),
                // Video Hide / Unhide button
                if (onVideoToggle != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onVideoToggle,
                    child: Container(
                      height: 37,
                      width: 37,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isVideoHidden
                            ? const Color(0xFFEF4444).withValues(alpha: 0.8)
                            : ColorRes.black.withValues(alpha: 0.33),
                      ),
                      child: Center(
                        child: Icon(
                          isVideoHidden
                              ? Icons.videocam_off_rounded
                              : Icons.videocam_rounded,
                          color: ColorRes.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                // Mute / Unmute microphone button
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSpeakerTap,
                  child: Container(
                    height: 37,
                    width: 37,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: mute
                          ? const Color(0xFFEF4444).withValues(alpha: 0.8)
                          : ColorRes.black.withValues(alpha: 0.33),
                    ),
                    child: Center(
                      child: Image.asset(
                        !mute ? AssetRes.speaker : AssetRes.speakerOff,
                        color: ColorRes.white,
                        height: 15,
                        width: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
