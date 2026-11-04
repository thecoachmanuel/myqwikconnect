import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/qwik_connect_logo.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/screen/auth_screen/auth_screen_view_model.dart';
import 'package:orange_ui/utils/app_platform.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AuthScreenViewModel>.reactive(
      onViewModelReady: (viewModel) {
        viewModel.init(0);
      },
      viewModelBuilder: () => AuthScreenViewModel(),
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: ColorRes.white,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // ── Logo + Slogan (Pure white background, clean & separated, ZERO overlap) ──
                const QwikConnectLogo(
                  fontSize: 44,
                  connectColor: ColorRes.black,
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Where young professionals meet real connections.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: FontRes.semiBold,
                      fontSize: 14,
                      color: ColorRes.davyGrey,
                      letterSpacing: 0.1,
                      height: 1.3,
                    ),
                  ),
                ),

                // ── Middle: Lady image pushed down below logo/slogan on pure white ──
                Expanded(
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.topCenter,
                    color: ColorRes.white,
                    child: Image.asset(
                      AssetRes.icLoginBackground,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),

                // ── Bottom: Social Login Card ──
                Container(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, bottom: 40, top: 20),
                  decoration: const ShapeDecoration(
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius.vertical(
                            top: SmoothRadius(
                                cornerRadius: 36, cornerSmoothing: 1)),
                      ),
                      color: ColorRes.white,
                      shadows: [
                        BoxShadow(
                            color: Color(0x0A000000),
                            offset: Offset(0, -4),
                            blurRadius: 16)
                      ]),
                  child: Column(
                    spacing: 10,
                    children: [
                      SocialLoginCard(
                          image: AssetRes.googleLogo,
                          text: S.current.continueWithGoogle,
                          onTap: viewModel.onGoogleTap),
                      SocialLoginCard(
                          image: AssetRes.icEmail,
                          text: S.of(context).continueWithEmail,
                          onTap: () => viewModel.onLoginTap(1)),
                      if (AppPlatform.isIOS)
                        SocialLoginCard(
                          image: AssetRes.appleLogo,
                          text: S.current.continueWithApple,
                          bgColor: ColorRes.black,
                          iconColor: ColorRes.white,
                          textColor: ColorRes.white,
                          onTap: viewModel.onAppleTap,
                        ),
                      const SizedBox(height: 15),
                      RichText(
                        text: TextSpan(
                          text: S.of(context).alreadyHaveAnAccount,
                          style: const TextStyle(
                              color: ColorRes.dimGrey3,
                              fontFamily: FontRes.regular,
                              fontSize: 15),
                          children: [
                            TextSpan(
                              text: '  ${S.current.logIn.capitalize}',
                              style: const TextStyle(
                                  color: ColorRes.themeColor,
                                  fontFamily: FontRes.bold,
                                  fontSize: 18),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  viewModel.onLoginTap(0);
                                },
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
        );
      },
    );
  }
}

class SocialLoginCard extends StatelessWidget {
  final String image;
  final String text;
  final Color? bgColor;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const SocialLoginCard(
      {super.key,
      required this.image,
      required this.text,
      this.bgColor,
      this.textColor,
      this.iconColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: ShapeDecoration(
            color: bgColor ?? ColorRes.white,
            shape: SmoothRectangleBorder(
              borderRadius:
                  SmoothBorderRadius(cornerRadius: 15, cornerSmoothing: 1),
              side: BorderSide(color: bgColor ?? ColorRes.borderColor),
            ),
            shadows: [
              BoxShadow(
                  color: ColorRes.black.withValues(alpha: 0.06),
                  offset: const Offset(0, 4),
                  blurRadius: 10)
            ]),
        child: Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: 20, width: 20, color: iconColor),
            Text(
              text,
              style: TextStyle(
                  color: textColor ?? ColorRes.darkGrey,
                  fontFamily: FontRes.semiBold,
                  fontSize: 17),
            )
          ],
        ),
      ),
    );
  }
}
