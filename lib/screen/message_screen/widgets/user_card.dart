import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/common_fun.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class UserCard extends StatelessWidget {
  final String? name;
  final String? age;
  final String? msg;
  final String? time;
  final String? image;
  final bool newMsg;
  final bool? tickMark;
  final bool isOnline;

  const UserCard({
    super.key,
    required this.name,
    required this.age,
    required this.msg,
    required this.time,
    required this.image,
    required this.newMsg,
    required this.tickMark,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding:
              const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: 11),
          height: 74,
          width: Get.width,
          decoration: BoxDecoration(
            color: ColorRes.lightGrey2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomImage(
                    image: image,
                    fullname: name,
                    height: 53,
                    width: 53,
                    radius: 30,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF9CA3AF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Flexible(
                                  flex: 5,
                                  child: Text(
                                    (name ?? '').capitalize ?? '',
                                    softWrap: false,
                                    style: const TextStyle(
                                        color: ColorRes.darkGrey5,
                                        fontFamily: FontRes.bold,
                                        overflow: TextOverflow.ellipsis,
                                        fontSize: 16),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    ' ${age ?? ''}',
                                    style: const TextStyle(fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: tickMark == true
                                      ? Image.asset(
                                          AssetRes.tickMark,
                                          height: 17.5,
                                          width: 18.33,
                                        )
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            (time != null && time!.isNotEmpty && time != 'null')
                                ? CommonFun.readTimestamp(
                                    double.tryParse(time!) ?? 0.0,
                                  )
                                : '',
                            style: const TextStyle(
                                fontSize: 12, color: ColorRes.grey),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 20,
                            child: Text(
                              '$msg',
                              style: const TextStyle(
                                fontSize: 14,
                                color: ColorRes.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const Spacer(),
                          Visibility(
                            visible: newMsg,
                            child: Container(
                              height: 12,
                              width: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: newMsg
                                    ? const LinearGradient(
                                        colors: [
                                          ColorRes.themeColor,
                                          ColorRes.themeColor,
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
