import 'dart:io';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/edit_profile_screen/edit_profile_screen_view_model.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/const_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/style_res.dart';

class MainProfileAvatarArea extends StatelessWidget {
  final EditProfileScreenViewModel model;

  const MainProfileAvatarArea({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    Images? firstImage = model.imageList.isNotEmpty ? model.imageList.first : null;
    final fullName = model.fullNameController.text.trim().isNotEmpty
        ? model.fullNameController.text.trim()
        : model.userData?.fullname;

    Widget avatarWidget;
    if (firstImage == null || (firstImage.image ?? '').trim().isEmpty) {
      avatarWidget = CommonUI.profileImagePlaceHolder(
        name: CommonUI.fullName(fullName),
        heightWidth: 104,
        borderRadius: 24,
      );
    } else if (firstImage.id != -1) {
      avatarWidget = CustomImage(
        image: '${ConstRes.aImageBaseUrl}${firstImage.image}',
        height: 104,
        width: 104,
        radius: 24,
      );
    } else if (kIsWeb) {
      avatarWidget = Image.network(
        firstImage.image ?? '',
        fit: BoxFit.cover,
        height: 104,
        width: 104,
        errorBuilder: (context, error, stackTrace) =>
            CommonUI.profileImagePlaceHolder(
          name: CommonUI.fullName(fullName),
          heightWidth: 104,
          borderRadius: 24,
        ),
      );
    } else {
      avatarWidget = Image.file(
        File(firstImage.image ?? ''),
        fit: BoxFit.cover,
        height: 104,
        width: 104,
        errorBuilder: (context, error, stackTrace) =>
            CommonUI.profileImagePlaceHolder(
          name: CommonUI.fullName(fullName),
          heightWidth: 104,
          borderRadius: 24,
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
        child: Column(
          children: [
            InkWell(
              onTap: model.pickProfilePicture,
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: ShapeDecoration(
                      gradient: StyleRes.linearGradient,
                      shape: const SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius.all(
                          SmoothRadius(cornerRadius: 28, cornerSmoothing: 1),
                        ),
                      ),
                    ),
                    child: ClipSmoothRect(
                      radius: const SmoothBorderRadius.all(
                        SmoothRadius(cornerRadius: 24, cornerSmoothing: 1),
                      ),
                      child: Container(
                        width: 104,
                        height: 104,
                        color: ColorRes.white,
                        child: avatarWidget,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        gradient: StyleRes.linearGradient,
                        shape: BoxShape.circle,
                        border: Border.all(color: ColorRes.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 18,
                          color: ColorRes.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: model.pickProfilePicture,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ColorRes.lightOrange.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 15,
                      color: ColorRes.themeColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Change Profile Photo',
                      style: TextStyle(
                        fontFamily: FontRes.bold,
                        fontSize: 12.5,
                        color: ColorRes.themeColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

