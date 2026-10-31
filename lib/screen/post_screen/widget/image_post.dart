import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/model/social/post/add_comment.dart';
import 'package:orange_ui/screen/feed_screen/feed_screen_view_model.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ImagePost extends StatefulWidget {
  final List<Content> content;
  final FeedScreenViewModel model;

  const ImagePost({super.key, required this.content, required this.model});

  @override
  State<ImagePost> createState() => _ImagePostState();
}

class _ImagePostState extends State<ImagePost> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: widget.content.length == 1
          ? Container(
              constraints: BoxConstraints(maxHeight: Get.height / 1.7),
              width: double.infinity,
              child: CustomImage(
                image: widget.content.first.content,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            )
          : Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: 390,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.content.length,
                    itemBuilder: (context, index) {
                      return CustomImage(
                        image: widget.content[index].content,
                        fit: BoxFit.cover,
                        height: 390,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      effect: CustomizableEffect(
                        dotDecoration: DotDecoration(
                          width: 31,
                          height: 2,
                          color: ColorRes.white.withValues(alpha: 0.3),
                        ),
                        activeDotDecoration: const DotDecoration(
                          width: 31,
                          height: 2,
                          color: ColorRes.white,
                        ),
                      ),
                      onDotClicked: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      count: widget.content.length,
                    ),
                  ),
                )
              ],
            ),
    );
  }
}
