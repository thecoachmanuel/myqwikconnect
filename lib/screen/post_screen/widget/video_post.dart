import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/model/social/post/add_comment.dart';
import 'package:orange_ui/screen/video_preview_screen/video_preview_screen.dart';
import 'package:orange_ui/screen/video_preview_screen/video_preview_screen_view_model.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class VideoPost extends StatelessWidget {
  final Post? post;

  const VideoPost({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final content = (post?.content ?? []).isNotEmpty ? post!.content!.first : null;
    final rawThumb = content?.thumbnail;
    final videoUrl = content?.content ?? '';

    // If thumbnail looks like a video url, don't use it as image thumbnail
    final isVideoThumb = rawThumb != null &&
        (rawThumb.toLowerCase().endsWith('.mp4') ||
            rawThumb.toLowerCase().endsWith('.mov') ||
            rawThumb.toLowerCase().endsWith('.webm') ||
            rawThumb.toLowerCase().endsWith('.avi') ||
            rawThumb.toLowerCase().endsWith('.m4v'));
    final thumbnail = isVideoThumb ? null : rawThumb;

    // Determine what preview to show: thumbnail image, or the video URL as image fallback
    final previewUrl = (thumbnail != null && thumbnail.isNotEmpty)
        ? thumbnail
        : null;

    return InkWell(
      onTap: () {
        if (videoUrl.isEmpty) return;
        Get.to(() => VideoPreviewScreen(
              videoUrl: videoUrl,
              type: VideoType.post,
              post: post,
            ));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: Get.height / 1.7),
              height: 240,
              width: double.infinity,
              color: const Color(0xFF1E293B),
              child: previewUrl != null
                  ? CustomImage(
                      image: previewUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        // Dark gradient background that looks like a video frame
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1A)],
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: ColorRes.themeColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: ColorRes.themeColor.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 36,
                                color: ColorRes.themeColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap to watch video',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                                fontFamily: FontRes.medium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            // Play button overlay
            if (previewUrl != null)
              Container(
                height: 53,
                width: 53,
                decoration: BoxDecoration(
                    color: ColorRes.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle),
                padding: const EdgeInsets.all(15),
                child: Image.asset(AssetRes.icPlay,
                    alignment: Alignment.centerRight),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              child: FittedBox(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  margin: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: ColorRes.white),
                  child: Row(
                    children: [
                      Image.asset(AssetRes.icEye, width: 15, height: 15),
                      const SizedBox(width: 10),
                      Text(
                        NumberFormat.compact()
                            .format(content?.viewCount ?? 0),
                        style: const TextStyle(
                            fontFamily: FontRes.medium,
                            color: ColorRes.davyGrey,
                            fontSize: 12),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
