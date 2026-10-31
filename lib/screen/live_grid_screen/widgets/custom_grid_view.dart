import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/chat_and_live_stream/live_stream.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class CustomGridView extends StatelessWidget {
  final List<LiveStreamUser> userData;
  final Function(LiveStreamUser? data) onImageTap;

  const CustomGridView({
    super.key,
    required this.userData,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: userData.isEmpty
          ? noLiveUser()
          : SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: userData.map<Widget>((e) {
                      int index = userData.indexOf(e);
                      return index % 2 == 0
                          ? gridTile(
                              data: e,
                              width: (Get.width / 2) - 18,
                              height: index % 4 == 0 ? (Get.width * 0.65) : (Get.width * 0.49),
                              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            )
                          : const SizedBox();
                    }).toList(),
                  ),
                  Column(
                    children: userData.map<Widget>((e) {
                      int index = userData.indexOf(e);
                      return index % 2 == 1
                          ? gridTile(
                              data: e,
                              width: (Get.width / 2) - 18,
                              height: (index + 1) % 4 == 0 ? (Get.width * 0.65) : (Get.width * 0.49),
                              margin: const EdgeInsets.fromLTRB(0, 0, 12, 12),
                            )
                          : const SizedBox();
                    }).toList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget gridTile({
    required LiveStreamUser data,
    required double height,
    required double width,
    required EdgeInsetsGeometry margin,
  }) {
    return GestureDetector(
      onTap: () {
        onImageTap(data);
      },
      child: Container(
          width: width,
          height: height,
          margin: margin,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomImage(
                    image: data.userImage,
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    fullname: data.fullName,
                    radius: 20,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaY: 15, sigmaX: 15),
                    child: Container(
                      width: width,
                      color: ColorRes.grey29.withValues(alpha: 0.20),
                      padding: EdgeInsets.fromLTRB(Get.width / 40, 12, 0, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  data.fullName ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ColorRes.white,
                                    fontSize: 15,
                                    fontFamily: FontRes.bold,
                                  ),
                                ),
                              ),
                              Text(
                                ' ${data.age ?? ''}',
                                style: const TextStyle(
                                  color: ColorRes.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Image.asset(
                                AssetRes.tickMark,
                                height: 16,
                                width: 16,
                              ),
                            ],
                          ),
                          Text(
                            data.address ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ColorRes.white,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Image.asset(
                                AssetRes.eye,
                                width: 15,
                                height: 12,
                                color: ColorRes.white,
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                '${data.watchingCount ?? 0}',
                                style: const TextStyle(
                                  color: ColorRes.white,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )),
    );
  }

  Widget noLiveUser() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          S.current.noUsersAreLive,
          style: const TextStyle(fontFamily: FontRes.medium, fontSize: 20, color: ColorRes.grey, letterSpacing: 1),
        ),
      ],
    );
  }
}
