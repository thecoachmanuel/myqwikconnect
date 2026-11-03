import 'dart:io';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/app_image_file.dart';
import 'package:orange_ui/common/button/border_icon_button.dart';
import 'package:orange_ui/common/button/custom_text_button.dart';
import 'package:orange_ui/common/confirmation_dialog.dart';
import 'package:orange_ui/common/custom_border.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:video_player/video_player.dart';

class ImageVideoSendSheet extends StatefulWidget {
  final File? image;
  final String? videoPath;
  final bool isVideo;
  final String selectedItem;
  final Function(String msg, File? image) onSendBtnClick;

  const ImageVideoSendSheet({
    super.key,
    this.image,
    this.videoPath,
    this.isVideo = false,
    required this.onSendBtnClick,
    required this.selectedItem,
  });

  @override
  State<ImageVideoSendSheet> createState() => _ImageVideoSendSheetState();
}

class _ImageVideoSendSheetState extends State<ImageVideoSendSheet> {
  final TextEditingController _msgController = TextEditingController();
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initVideoIfApplicable();
  }

  void _initVideoIfApplicable() {
    final path = widget.videoPath ?? (widget.isVideo ? widget.image?.path : null);
    if ((widget.isVideo || widget.videoPath != null) && path != null && path.isNotEmpty) {
      try {
        if (kIsWeb) {
          _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(path));
        } else {
          _videoPlayerController = VideoPlayerController.file(File(path));
        }

        _videoPlayerController?.initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoPlayerController?.setLooping(true);
            _videoPlayerController?.play();
            _isPlaying = true;
          }
        }).catchError((err) {
          debugPrint('Error initializing video preview: $err');
        });

        _videoPlayerController?.addListener(() {
          if (mounted) {
            final playing = _videoPlayerController?.value.isPlaying ?? false;
            if (playing != _isPlaying) {
              setState(() {
                _isPlaying = playing;
              });
            }
          }
        });
      } catch (e) {
        debugPrint('Failed to create VideoPlayerController: $e');
      }
    }
  }

  void _togglePlayPause() {
    if (_videoPlayerController == null || !_isVideoInitialized) return;
    setState(() {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        _isPlaying = false;
      } else {
        _videoPlayerController!.play();
        _isPlaying = true;
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isVideoMedia = widget.isVideo || widget.videoPath != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          margin: const EdgeInsets.only(top: 40),
          decoration: const ShapeDecoration(
            color: Colors.white,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius.vertical(
                top: SmoothRadius(cornerRadius: 28, cornerSmoothing: 1),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag Indicator
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: ColorRes.grey2.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 37),
                        Flexible(
                          child: Text(
                            isVideoMedia ? 'Send Video' : S.current.send,
                            style: const TextStyle(
                              color: ColorRes.black,
                              fontSize: 18,
                              fontFamily: FontRes.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        BorderIconButton(
                          onTap: () {
                            if (_msgController.text.trim().isNotEmpty) {
                              Get.dialog(ConfirmationDialog(
                                onTap: () {
                                  Get.back();
                                  Get.back();
                                },
                                description: S.of(context).ifYouCloseTheSheetYourMessageCoinWillBe,
                              ));
                            } else {
                              Get.back();
                            }
                          },
                          icon: AssetRes.icClose,
                        ),
                      ],
                    ),
                  ),
                  const CustomBorder(),
                  const SizedBox(height: 14),

                  // Preview Area
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isVideoMedia ? _buildVideoPreview() : _buildImagePreview(),
                  ),

                  const SizedBox(height: 16),

                  // Caption Input Area (WhatsApp style)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF6F7F9),
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                            cornerRadius: 16,
                            cornerSmoothing: 1,
                          ),
                          side: BorderSide(
                            color: ColorRes.borderColor.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: ColorRes.dimGrey3,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _msgController,
                              style: const TextStyle(
                                fontFamily: FontRes.medium,
                                fontSize: 14,
                                color: ColorRes.black,
                              ),
                              maxLines: 3,
                              minLines: 1,
                              decoration: InputDecoration(
                                hintText: isVideoMedia
                                    ? 'Add a caption for this video...'
                                    : S.current.writeSomethingHere,
                                hintStyle: const TextStyle(
                                  fontFamily: FontRes.regular,
                                  fontSize: 14,
                                  color: ColorRes.dimGrey3,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Send Button
                  CustomTextButton(
                    onTap: () {
                      widget.onSendBtnClick(
                        _msgController.text.trim(),
                        widget.image,
                      );
                    },
                    title: isVideoMedia ? 'Send Video' : S.current.send,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_isVideoInitialized && _videoPlayerController != null) {
      final duration = _videoPlayerController!.value.duration;

      return GestureDetector(
        onTap: _togglePlayPause,
        child: ClipSmoothRect(
          radius: const SmoothBorderRadius.all(
            SmoothRadius(cornerRadius: 18, cornerSmoothing: 1),
          ),
          child: Container(
            color: Colors.black,
            constraints: const BoxConstraints(maxHeight: 260),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoPlayerController!.value.aspectRatio > 0
                        ? _videoPlayerController!.value.aspectRatio.clamp(0.65, 1.8)
                        : 16 / 9,
                    child: VideoPlayer(_videoPlayerController!),
                  ),
                ),
                // Play / Pause Overlay Icon
                AnimatedOpacity(
                  opacity: _isPlaying ? 0.0 : 0.85,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    height: 54,
                    width: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.55),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                // Video duration badge
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: FontRes.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Loading / Fallback Video placeholder
    return ClipSmoothRect(
      radius: const SmoothBorderRadius.all(
        SmoothRadius(cornerRadius: 18, cornerSmoothing: 1),
      ),
      child: Container(
        height: 200,
        width: double.infinity,
        color: const Color(0xFF1E1E24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: ColorRes.lightOrange,
            ),
            SizedBox(height: 12),
            Text(
              'Preparing video preview...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: FontRes.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final path = widget.image?.path ?? '';
    return ClipSmoothRect(
      radius: const SmoothBorderRadius.all(
        SmoothRadius(cornerRadius: 18, cornerSmoothing: 1),
      ),
      child: Container(
        height: 220,
        width: double.infinity,
        color: const Color(0xFFF5F5F7),
        child: appImageFile(
          path: path,
          height: 220,
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
