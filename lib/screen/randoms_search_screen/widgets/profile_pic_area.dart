import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/animation/ripple_animation.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/common/profile_detail_card.dart';
import 'package:orange_ui/common/social_icon.dart';
import 'package:orange_ui/common/top_story_line.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/randoms_search_screen/randoms_search_screen_view_model.dart';
import 'package:orange_ui/service/extention/string_extention.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';

class ProfilePicArea extends StatelessWidget {
  final String profileImage;
  final RandomsSearchScreenViewModel model;

  const ProfilePicArea(
      {super.key, required this.profileImage, required this.model});

  @override
  Widget build(BuildContext context) {
    final double cardWidth = (Get.width * 0.85).clamp(280.0, 420.0);
    final double avatarSize = (Get.width / 3).clamp(100.0, 140.0);
    final double cardHeight = (Get.height * 0.58).clamp(380.0, 520.0);

    return Expanded(
      child: model.isLoading
          ? Container(
              width: cardWidth,
              height: cardHeight,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage(AssetRes.worldMap),
                ),
              ),
              child: RipplesAnimation(
                child: CustomImage(
                    image: profileImage,
                    height: avatarSize,
                    width: avatarSize,
                    fit: BoxFit.cover,
                    radius: 360),
              ))
          : model.userData == null
              ? CommonUI.noData()
              : Container(
                  width: cardWidth,
                  height: cardHeight,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(20)),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: (model.userData?.images ?? []).isEmpty
                            ? Stack(
                                children: [
                                  // Show profileImage if available, else fallback to theme placeholder
                                  Builder(builder: (_) {
                                    final img = model.userData?.profileImage;
                                    final hasImage =
                                        img != null && img.isNotEmpty;
                                    if (hasImage) {
                                      return CustomImage(
                                        image: img.addBaseURL(),
                                        width: cardWidth,
                                        height: cardHeight,
                                        fit: BoxFit.cover,
                                        radius: 0,
                                      );
                                    }
                                    return Container(
                                      decoration: BoxDecoration(
                                          color: ColorRes.themeColor
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                    );
                                  }),
                                  if ((model.userData?.profileImage ?? '')
                                      .isEmpty)
                                    Center(
                                      child: Container(
                                          width: cardWidth,
                                          height: cardHeight,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: ColorRes.themeColor
                                                .withValues(alpha: 0.2),
                                          ),
                                          child:
                                              Image.asset(AssetRes.themeLabel)),
                                    ),
                                ],
                              )
                            : PageView.builder(
                                controller: model.pageController,
                                itemCount:
                                    (model.userData?.images ?? []).length,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  Images image =
                                      (model.userData?.images ?? [])[index];
                                  return FractionallySizedBox(
                                    widthFactor: 1 /
                                        model.pageController.viewportFraction,
                                    child: Stack(
                                      children: [
                                        CustomImage(
                                            image: image.image?.addBaseURL(),
                                            width: cardWidth,
                                            height: cardHeight,
                                            radius: 0),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap: model.onLeftBtnClick,
                                                child: Container(
                                                    height: cardHeight,
                                                    color:
                                                        ColorRes.transparent),
                                              ),
                                            ),
                                            Expanded(
                                              child: InkWell(
                                                onTap: model.onRightBtnClick,
                                                child: Container(
                                                    height: cardHeight,
                                                    color:
                                                        ColorRes.transparent),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      SizedBox(
                        height: cardHeight,
                        width: cardWidth,
                        child: Column(
                          children: [
                            const SizedBox(height: 14),
                            TopStoryLine(
                                pageController: model.pageController,
                                imageLength:
                                    (model.userData?.images ?? []).length),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(left: 9),
                              child: Row(
                                children: [
                                  SocialIcon(
                                      icon: AssetRes.instagramLogo,
                                      onSocialIconTap: model.onInstagramTap,
                                      isVisible: model.isSocialBtnVisible(
                                          model.userData?.instagram)),
                                  SocialIcon(
                                      icon: AssetRes.facebookLogo,
                                      onSocialIconTap: model.onFBTap,
                                      isVisible: model.isSocialBtnVisible(
                                          model.userData?.facebook)),
                                  SocialIcon(
                                      icon: AssetRes.youtubeLogo,
                                      onSocialIconTap: model.onYoutubeTap,
                                      isVisible: model.isSocialBtnVisible(
                                          model.userData?.youtube)),
                                ],
                              ),
                            ),
                            ProfileDetailCard(
                                onImageTap: model.onImageTap,
                                userData: model.userData)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
