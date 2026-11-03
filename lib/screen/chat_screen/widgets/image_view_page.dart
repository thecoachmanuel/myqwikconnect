import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:orange_ui/common/button/round_icon_button.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/chat_and_live_stream/chat.dart';
import 'package:orange_ui/service/extention/string_extention.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/utils/app_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class ImageViewPage extends StatefulWidget {
  final ChatMessage? userData;
  final VoidCallback onBack;

  const ImageViewPage({super.key, this.userData, required this.onBack});

  @override
  State<ImageViewPage> createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageViewPage> {
  TapDownDetails _doubleTapDetails = TapDownDetails();
  final _transformationController = TransformationController();
  bool _hasError = false;

  String get _imageUrl {
    String raw = (widget.userData?.image ?? '').trim();
    if (raw.isEmpty) return '';
    return raw.addBaseURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorRes.black,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onDoubleTapDown: handleDoubleTapDown,
              onDoubleTap: handleDoubleTap,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: _buildImage(),
                ),
              ),
            ),
            topBarArea()
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    final url = _imageUrl;
    if (url.isEmpty || _hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_rounded, color: ColorRes.dimGrey3, size: 54),
            const SizedBox(height: 12),
            const Text(
              'Unable to load image',
              style: TextStyle(
                color: ColorRes.dimGrey3,
                fontFamily: FontRes.semiBold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                });
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorRes.themeColor,
                foregroundColor: ColorRes.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      );
    }

    return Image.network(
      url,
      height: Get.height,
      width: double.infinity,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ColorRes.themeColor,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_rounded, color: ColorRes.dimGrey3, size: 54),
              const SizedBox(height: 12),
              const Text(
                'Unable to load image',
                style: TextStyle(
                  color: ColorRes.dimGrey3,
                  fontFamily: FontRes.semiBold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorRes.themeColor,
                  foregroundColor: ColorRes.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(-position.dx * 2, -position.dy * 2, 0.0, 1.0)
        ..scaleByDouble(3.0, 3.0, 1, 1);
    }
  }

  Widget topBarArea() {
    return Container(
      color: ColorRes.black.withValues(alpha: 0.3),
      padding: const EdgeInsets.fromLTRB(21, 18, 23, 18),
      child: Row(
        children: [
          RoundIconButton(
            onTap: widget.onBack,
            bgColor: ColorRes.white.withValues(alpha: 0.2),
            color: ColorRes.white,
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.userData?.senderUser?.userid ==
                            SessionManager.instance.getUserID()
                        ? S.current.you
                        : '${widget.userData?.senderUser?.username} ',
                    style: const TextStyle(
                      color: ColorRes.white,
                      fontSize: 16,
                      fontFamily: FontRes.bold,
                    ),
                  ),
                ],
              ),
              if (widget.userData?.time != null)
                Text(
                  DateFormat('${AppRes.dMY}, ${AppRes.hhMmA}')
                      .format(DateTime.fromMillisecondsSinceEpoch(widget.userData!.time!.toInt())),
                  style: const TextStyle(
                    color: ColorRes.white,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.value = Matrix4.identity();
    _transformationController.dispose();
    super.dispose();
  }
}
