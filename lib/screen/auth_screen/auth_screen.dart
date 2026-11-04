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
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Layer 1: Folake Adeleke full-screen portrait ──────────────
              Positioned.fill(
                child: Image.asset(
                  AssetRes.icLoginBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),

              // ── Layer 2: Subtle warm brand tint (matches commit 40e627a feel) ──
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: ColorRes.themeColor.withValues(alpha: 0.12),
                  ),
                ),
              ),

              // ── Layer 3: Pure white logo header block at the top ──────────
              // Dedicated white zone so logo is 100% legible with clean margins
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      // Soft bottom shadow so the logo block lifts cleanly
                      // above the background image
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x18000000),
                          offset: Offset(0, 6),
                          blurRadius: 18,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // QwikConnect logo — Qwik orange gradient, Connect black
                        const QwikConnectLogo(
                          fontSize: 42,
                          connectColor: ColorRes.black,
                        ),
                        const SizedBox(height: 6),
                        // Slogan
                        Text(
                          'Where young professionals meet real connections.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: FontRes.semiBold,
                            fontSize: 13.5,
                            color: ColorRes.davyGrey,
                            letterSpacing: 0.1,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Layer 4: Bottom login card anchored to the bottom ─────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(
                      left: 15, right: 15, bottom: 48, top: 25),
                  decoration: const ShapeDecoration(
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius.vertical(
                        top: SmoothRadius(
                          cornerRadius: 40,
                          cornerSmoothing: 1,
                        ),
                      ),
                    ),
                    color: ColorRes.white,
                    shadows: [
                      BoxShadow(
                        color: Color(0x14000000),
                        offset: Offset(0, -6),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  // Respect system bottom insets (home bar on iOS/Android,
                  // address bar on mobile browsers)
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 4),
                        SocialLoginCard(
                          image: AssetRes.googleLogo,
                          text: S.current.continueWithGoogle,
                          onTap: viewModel.onGoogleTap,
                        ),
                        const SizedBox(height: 10),
                        SocialLoginCard(
                          image: AssetRes.icEmail,
                          text: S.of(context).continueWithEmail,
                          onTap: () => viewModel.onLoginTap(1),
                        ),
                        if (AppPlatform.isIOS) ...[
                          const SizedBox(height: 10),
                          SocialLoginCard(
                            image: AssetRes.appleLogo,
                            text: S.current.continueWithApple,
                            bgColor: ColorRes.black,
                            iconColor: ColorRes.white,
                            textColor: ColorRes.white,
                            onTap: viewModel.onAppleTap,
                          ),
                        ],
                        const SizedBox(height: 20),
                        RichText(
                          text: TextSpan(
                            text: S.of(context).alreadyHaveAnAccount,
                            style: const TextStyle(
                              color: ColorRes.dimGrey3,
                              fontFamily: FontRes.regular,
                              fontSize: 15,
                            ),
                            children: [
                              TextSpan(
                                text: '  ${S.current.logIn.capitalize}',
                                style: const TextStyle(
                                  color: ColorRes.themeColor,
                                  fontFamily: FontRes.bold,
                                  fontSize: 18,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    viewModel.onLoginTap(0);
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

  const SocialLoginCard({
    super.key,
    required this.image,
    required this.text,
    this.bgColor,
    this.textColor,
    this.iconColor,
    required this.onTap,
  });

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
              blurRadius: 10,
            ),
          ],
        ),
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
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
