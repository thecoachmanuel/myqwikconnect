import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/const_res.dart';
import 'package:orange_ui/utils/firebase_res.dart';
import 'package:orange_ui/utils/font_res.dart';

import '../../../model/chat_and_live_stream/live_stream.dart';

class CommentListArea extends StatelessWidget {
  final BuildContext pageContext;
  final List<LiveStreamComment> commentList;

  const CommentListArea({
    super.key,
    required this.commentList,
    required this.pageContext,
  });

  @override
  Widget build(BuildContext context) {
    double tempSize =
        MediaQuery.of(pageContext).viewInsets.bottom == 0 ? 0 : MediaQuery.of(pageContext).viewInsets.bottom;
    return SizedBox(
      height: (tempSize == 0) ? (Get.height - 270) / 2 : (Get.height - 270) - tempSize - 50,
      width: Get.width,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorRes.black,
              ColorRes.transparent,
              ColorRes.transparent,
            ],
            stops: [0.0, 0.3, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstOut,
        child: ListView.builder(
          itemCount: commentList.length,
          reverse: true,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: CachedNetworkImage(
                      imageUrl: '${commentList[index].userImage}',
                      cacheKey: '${commentList[index].userImage}',
                      errorWidget: (context, url, error) {
                        return Image.asset(
                          AssetRes.themeLabel,
                          width: 32,
                          height: 32,
                        );
                      },
                      fit: BoxFit.cover,
                      height: 32,
                      width: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: Get.width / 1.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commentList[index].userName ?? '',
                          style: const TextStyle(
                            color: ColorRes.white,
                            fontSize: 12,
                            fontFamily: FontRes.semiBold,
                          ),
                        ),
                        commentList[index].commentType == FirebaseRes.msg
                            ? Text(
                                commentList[index].comment ?? '',
                                style: TextStyle(
                                  color: ColorRes.white.withValues(alpha: 0.90),
                                  fontSize: 13,
                                  fontFamily: FontRes.semiBold,
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.only(top: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      ColorRes.themeColor.withValues(alpha: 0.45),
                                      ColorRes.lightOrange.withValues(alpha: 0.35),
                                    ],
                                  ),
                                  border: Border.all(color: ColorRes.themeColor.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(AssetRes.diamond, width: 14, height: 14),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Sent a gift',
                                      style: TextStyle(
                                        color: ColorRes.white,
                                        fontSize: 12,
                                        fontFamily: FontRes.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: commentList[index].comment?.startsWith('http') == true
                                            ? commentList[index].comment!
                                            : '${ConstRes.aImageBaseUrl}${commentList[index].comment}',
                                        cacheKey: '${ConstRes.aImageBaseUrl}${commentList[index].comment}',
                                        errorWidget: (context, url, error) {
                                          return Image.asset(AssetRes.gift, width: 28, height: 28);
                                        },
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
