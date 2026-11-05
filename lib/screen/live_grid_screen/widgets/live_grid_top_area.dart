import 'package:flutter/material.dart';
import 'package:orange_ui/common/button/round_icon_button.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/qwik_connect_logo.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class LiveGridTopArea extends StatelessWidget {
  final VoidCallback onBackBtnTap;
  final VoidCallback onGoLiveTap;
  final UserData? userData;

  const LiveGridTopArea(
      {super.key,
      required this.onBackBtnTap,
      required this.onGoLiveTap,
      this.userData});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 19),
        child: Row(
          children: [
            RoundIconButton(onTap: onBackBtnTap),
            const SizedBox(width: 13),
            const QwikConnectLogo(fontSize: 18),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: ColorRes.themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                S.current.live.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: FontRes.bold,
                  color: ColorRes.themeColor,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () {
                if (userData?.isFake != 1) {
                  userData?.canGoLive == 0
                      ? CommonUI.snackBarWidget(
                          S.of(context).pleaseApplyForLiveStreamFromLivestreamDashboardFromProfile)
                      : userData?.canGoLive == 1
                          ? CommonUI.snackBarWidget(S.of(context).yourApplicationIsPendingPleaseWait)
                          : onGoLiveTap();
                } else {
                  onGoLiveTap();
                }
              },
              child: Container(
                height: 45,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ColorRes.lightOrange,
                      ColorRes.themeColor,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      AssetRes.sun,
                      height: 21,
                      width: 21,
                      color: ColorRes.white,
                    ),
                    const SizedBox(width: 7.62),
                    Text(
                      S.current.goLive,
                      style: const TextStyle(
                        color: ColorRes.white,
                        fontSize: 14,
                        fontFamily: FontRes.extraBold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
