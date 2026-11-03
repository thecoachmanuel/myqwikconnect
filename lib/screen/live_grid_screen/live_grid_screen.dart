import 'package:flutter/material.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/screen/dashboard/widget/custom_banner_ads.dart';
import 'package:orange_ui/screen/live_grid_screen/live_grid_screen_view_model.dart';
import 'package:orange_ui/screen/live_grid_screen/widgets/custom_grid_view.dart';
import 'package:orange_ui/screen/live_grid_screen/widgets/live_grid_top_area.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:stacked/stacked.dart';

class LiveGridScreen extends StatelessWidget {
  const LiveGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LiveGridScreenViewModel>.reactive(
      onViewModelReady: (model) {
        model.init();
      },
      viewModelBuilder: () => LiveGridScreenViewModel(),
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: ColorRes.white,
          body: LayoutBuilder(
            builder: (context, constraints) {
              // On wider screens centre content in a max-width container
              final bool isWide = constraints.maxWidth >= 900;
              final Widget content = Column(
                children: [
                  LiveGridTopArea(
                    onBackBtnTap: model.onBackBtnTap,
                    onGoLiveTap: model.goLiveBtnClick,
                    userData: model.userData,
                  ),
                  if (!model.isLoading)
                    CustomGridView(
                      userData: model.liveStreamUsers,
                      onImageTap: model.onLiveStreamProfileTap,
                    )
                  else
                    Expanded(
                      child: CommonUI.lottieWidget(),
                    ),
                  const CustomBannerAds(),
                ],
              );

              if (isWide) {
                return Center(
                  child: SizedBox(
                    width: 900,
                    child: content,
                  ),
                );
              }
              return content;
            },
          ),
        );
      },
    );
  }
}
