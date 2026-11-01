import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/screen/webview_screen/webview_screen_view_model.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';

class WebViewScreen extends StatelessWidget {
  final String appBarTitle;
  final String url;

  const WebViewScreen(
      {super.key, required this.appBarTitle, required this.url});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<WebViewScreenViewModel>.reactive(
      onViewModelReady: (model) => model.init(url, appBarTitle),
      viewModelBuilder: () => WebViewScreenViewModel(),
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: ColorRes.white,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Get.back(),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorRes.themeColor.withValues(alpha: 0.08),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: ColorRes.themeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          appBarTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: FontRes.bold,
                            color: ColorRes.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: ColorRes.grey5),
                Expanded(
                  child: model.buildNativeReaderContent(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
