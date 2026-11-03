import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/screen/feed_screen/feed_screen_view_model.dart';
import 'package:orange_ui/screen/feed_screen/widget/feed_story_bar.dart';
import 'package:orange_ui/screen/post_screen/widget/post_card.dart';
import 'package:orange_ui/service/post_upload_service.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/style_res.dart';
import 'package:stacked/stacked.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<FeedScreenViewModel>.reactive(
      onViewModelReady: (viewModel) => viewModel.init(),
      viewModelBuilder: () => FeedScreenViewModel(),
      builder: (context, model, child) {
        return Stack(
          children: [
            model.isLoading
                ? CommonUI.lottieWidget()
                : RefreshIndicator(
                    color: ColorRes.themeColor,
                    backgroundColor: ColorRes.white,
                    onRefresh: model.onRefresh,
                    child: Stack(
                      children: [
                        CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: model.scrollController,
                          slivers: [
                            SliverToBoxAdapter(child: FeedStoryBar(model: model)),
                            SliverToBoxAdapter(child: _buildUploadProgressCard()),
                            model.postList.isEmpty
                                ? const SliverToBoxAdapter(child: SizedBox.shrink())
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        return PostCard(
                                          post: model.postList[index],
                                          model: model,
                                          postIndex: index,
                                        );
                                      },
                                      childCount: model.postList.length,
                                    ),
                                  ),
                            // Load-more indicator / end-of-feed indicator
                            SliverToBoxAdapter(
                              child: model.isFetchingMore
                                  ? _buildLoadMoreIndicator()
                                  : !model.hasMore && model.postList.isNotEmpty
                                      ? _buildEndOfFeedIndicator()
                                      : const SizedBox(height: 100),
                            ),
                          ],
                        ),
                        if (model.postList.isEmpty) CommonUI.noData(),
                      ],
                    ),
                  ),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: InkWell(
                onTap: model.onCreatePost,
                child: Container(
                  width: 50,
                  height: 50,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      gradient: StyleRes.linearGradient),
                  child: const Icon(Icons.add_rounded, color: ColorRes.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(ColorRes.themeColor),
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Loading more posts...',
            style: TextStyle(
              fontFamily: FontRes.regular,
              fontSize: 13,
              color: ColorRes.dimGrey3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOfFeedIndicator() {
    return const SizedBox.shrink();
  }

  Widget _buildUploadProgressCard() {
    return Obx(() {
      final uploadService = PostUploadService.instance;
      if (!uploadService.isUploading.value &&
          uploadService.statusText.value.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ColorRes.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ColorRes.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ColorRes.lightOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.cloud_upload_rounded,
                    color: ColorRes.themeColor, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        uploadService.statusText.value,
                        style: const TextStyle(
                          fontFamily: FontRes.semiBold,
                          fontSize: 13,
                          color: ColorRes.davyGrey,
                        ),
                      ),
                      Text(
                        '${(uploadService.progress.value * 100).toInt()}%',
                        style: const TextStyle(
                          fontFamily: FontRes.medium,
                          fontSize: 12,
                          color: ColorRes.dimGrey3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: uploadService.progress.value,
                      minHeight: 5,
                      backgroundColor:
                          ColorRes.lightGrey.withValues(alpha: 0.5),
                      valueColor:
                          const AlwaysStoppedAnimation(ColorRes.themeColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
