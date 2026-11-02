import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/button/custom_text_button.dart';
import 'package:orange_ui/common/login_setup_view.dart';
import 'package:orange_ui/common/privacy_policy_text.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/screen/auth_screen/auth_screen_view_model.dart';
import 'package:orange_ui/screen/auth_screen/widget/login_view.dart';
import 'package:orange_ui/screen/auth_screen/registration/register_view.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';

class LoginScreen extends StatelessWidget {
  final int index;
  final AuthScreenViewModel viewModel;

  const LoginScreen({super.key, required this.index, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AuthScreenViewModel>.reactive(
      onViewModelReady: (viewModel) {
        viewModel.init(index);
      },
      viewModelBuilder: () => viewModel,
      disposeViewModel: false,
      builder: (context, viewModel, child) {
        final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
        return LoginSetupView(
          title: S.of(context).goAheadAndSetUpYourAccount,
          description: S.of(context).welcomeToYourNewJourneyOfConnections,
          child: Column(
            children: [
              LoginTopTabBar(viewModel: viewModel, isCompact: isKeyboardOpen),
              Expanded(
                child: PageView(
                  controller: viewModel.pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    LoginView(viewModel: viewModel),
                    RegisterView(viewModel: viewModel),
                  ],
                ),
              ),
              SizedBox(height: isKeyboardOpen ? 4 : 10),
              CustomTextButton(
                onTap: viewModel.onContinueTap,
                height: isKeyboardOpen ? 48 : 55,
                margin: const EdgeInsets.symmetric(horizontal: 15),
                bottomSafeArea: false,
              ),
              if (!isKeyboardOpen) ...[
                const SizedBox(height: 10),
                const SafeArea(top: false, child: PrivacyPolicyText()),
              ],
            ],
          ),
        );
      },
    );
  }
}

class LoginTopTabBar extends StatelessWidget {
  final AuthScreenViewModel viewModel;
  final bool isCompact;

  const LoginTopTabBar({super.key, required this.viewModel, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isCompact ? 44 : 55,
      decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
              borderRadius:
                  SmoothBorderRadius(cornerRadius: 30, cornerSmoothing: 1)),
          color: ColorRes.borderColor),
      margin: EdgeInsets.only(bottom: isCompact ? 10 : 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedAlign(
            alignment: viewModel.pageIndex == 0
                ? AlignmentDirectional.centerStart
                : AlignmentDirectional.centerEnd,
            duration: const Duration(milliseconds: 250),
            child: Container(
              height: 48,
              width: (Get.width / 2) - 30,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: ShapeDecoration(
                  color: ColorRes.white,
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                        cornerRadius: 30, cornerSmoothing: 1),
                  ),
                  shadows: [
                    BoxShadow(
                        color: ColorRes.dimGrey2.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 4))
                  ]),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onTap(0),
                  child: Text(
                    S.of(context).login,
                    style: const TextStyle(
                        color: ColorRes.davyGrey,
                        fontFamily: FontRes.medium,
                        fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => onTap(1),
                  child: Text(
                    S.current.register.capitalize ?? '',
                    style: const TextStyle(
                        color: ColorRes.davyGrey,
                        fontFamily: FontRes.medium,
                        fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void onTap(int index) {
    viewModel.pageIndex = index;
    viewModel.notifyListeners();
    viewModel.pageController.animateToPage(index,
        duration: const Duration(milliseconds: 250), curve: Curves.linear);
  }
}
