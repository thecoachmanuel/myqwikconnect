import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/random_streming_screen/random_streaming_screen_view_model.dart';
import 'package:orange_ui/screen/random_streming_screen/widgets/bottom_text_field.dart';
import 'package:orange_ui/screen/random_streming_screen/widgets/comment_list_area.dart';
import 'package:orange_ui/screen/random_streming_screen/widgets/randon_stream_top_bar_area.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';

import '../../model/chat_and_live_stream/live_stream.dart';
import '../../model/setting_model.dart';

class RandomStreamingScreen extends StatelessWidget {
  final UserData? userData;
  final LiveStreamUser liveStreamUser;
  final Appdata? settingData;

  const RandomStreamingScreen(
      {super.key,
      this.userData,
      required this.liveStreamUser,
      this.settingData});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      // Status bar color
      statusBarColor: ColorRes.transparent,

      // Status bar brightness (optional)
      statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
      statusBarBrightness: Brightness.light, // For iOS (dark icons)
    ));
    return ViewModelBuilder<RandomStreamingScreenViewModel>.reactive(
      onViewModelReady: (model) {
        model.init();
      },
      viewModelBuilder: () => RandomStreamingScreenViewModel(
          liveStreamUser: liveStreamUser, registrationUserData: userData, settingAppData: settingData),
      builder: (context, model, child) {
        return PopScope(
          onPopInvokedWithResult: (didPop, _) => model.onEndVideoTap(),
          canPop: false,
          child: Scaffold(
            backgroundColor: ColorRes.black,
            body: Stack(
              children: [
                model.isLoading
                    ? CommonUI.lottieWidget()
                    : model.localUserJoined
                        ? (model.isVideoHidden
                            ? _buildAudioOnlyView(model)
                            : AgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: model.engine,
                                  canvas: const VideoCanvas(uid: 0),
                                ),
                              ))
                        : CommonUI.lottieWidget(),
                Column(
                  children: [
                    RandomStreamTopBarArea(
                      onEndBtnTap: model.onEndBtnTap,
                      onDiamondTap: model.onDiamondTap,
                      onSpeakerTap: model.onSpeakerTap,
                      onCameraTap: model.onCameraTap,
                      onVideoToggle: model.onVideoToggle,
                      isVideoHidden: model.isVideoHidden,
                      mute: model.muted,
                      user: model.liveStreamUser,
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () {
                          model.commentFocus.unfocus();
                        },
                        child: Column(
                          children: [
                            const Spacer(),
                            CommentListArea(
                              commentList: model.commentList,
                              pageContext: context,
                            ),
                            BottomTextField(
                              commentController: model.commentController,
                              onMsgSend: model.onCommentSend,
                              commentFocus: model.commentFocus,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioOnlyView(RandomStreamingScreenViewModel model) {
    final avatar = model.registrationUserData?.profileImage ?? model.liveStreamUser.userImage;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF141419), Color(0xFF1F1B2E), Color(0xFF0F0E17)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorRes.themeColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  height: 130,
                  width: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ColorRes.themeColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: CachedNetworkImage(
                    imageUrl: avatar ?? '',
                    height: 110,
                    width: 110,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 110,
                      width: 110,
                      color: ColorRes.dimGrey3,
                      child: const Icon(Icons.person, color: ColorRes.white, size: 55),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              model.liveStreamUser.fullName ?? 'Host',
              style: const TextStyle(
                color: ColorRes.white,
                fontFamily: FontRes.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ColorRes.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ColorRes.white.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: ColorRes.themeColor, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Camera Off (Audio Only)',
                    style: TextStyle(
                      color: ColorRes.white,
                      fontFamily: FontRes.semiBold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
