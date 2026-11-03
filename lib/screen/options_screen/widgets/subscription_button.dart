import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/subscription_sheet/subscription_sheet.dart';
import 'package:orange_ui/screen/subscription_sheet/widget/premium_member_dialog.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/service/subscription/subscription_manager.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/style_res.dart';

class SubscriptionButton extends StatefulWidget {
  const SubscriptionButton({super.key});

  @override
  State<SubscriptionButton> createState() => _SubscriptionButtonState();
}

class _SubscriptionButtonState extends State<SubscriptionButton> {
  String _text1 = S.current.go;
  String _text2 = ' ${S.current.premium}';
  bool _isVip = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() {
    UserData? userData = SessionManager.instance.getUser();
    bool expired = false;
    if (userData?.proExpireDate != null && userData!.proExpireDate!.trim().isNotEmpty) {
      try {
        expired = DateTime.parse(userData.proExpireDate!).isBefore(DateTime.now());
      } catch (_) {}
    }

    _isVip = ((userData?.isPro == 1 || userData?.isVerified == 3) && !expired) || isSubscribe.value;

    if (_isVip) {
      _text1 = '';
      _text2 = S.current.youArePremiumMember;
    } else {
      _text1 = S.current.go;
      _text2 = ' ${S.current.premium}';
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      UserData? userData = SessionManager.instance.getUser();
      bool expired = false;
      if (userData?.proExpireDate != null && userData!.proExpireDate!.trim().isNotEmpty) {
        try {
          expired = DateTime.parse(userData.proExpireDate!).isBefore(DateTime.now());
        } catch (_) {}
      }

      final isVip = ((userData?.isPro == 1 || userData?.isVerified == 3) && !expired) || isSubscribe.value;
      final text1 = isVip ? '' : S.current.go;
      final text2 = isVip ? S.current.youArePremiumMember : ' ${S.current.premium}';

      return InkWell(
        onTap: () {
          if (isVip) {
            // Display the dedicated VIP Premium Member modal
            Get.dialog(
              const PremiumMemberDialog(),
              barrierDismissible: true,
            );
          } else {
            // Open SubscriptionSheet to buy/upgrade
            Get.bottomSheet(const SubscriptionSheet(), isScrollControlled: true)
                .then((value) {
              _checkStatus();
            });
          }
        },
        child: Container(
          height: 49,
          margin: const EdgeInsets.symmetric(vertical: 3),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: StyleRes.linearGradient),
          child: Row(
            children: [
              Container(
                height: 28,
                width: 28,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                    color: ColorRes.themeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Image.asset(
                  AssetRes.icPremiumCrown,
                  height: 28,
                  width: 28,
                ),
              ),
              RichText(
                text: TextSpan(
                  text: text1,
                  style: const TextStyle(
                      color: ColorRes.white,
                      fontFamily: FontRes.regular,
                      fontSize: 15),
                  children: [
                    TextSpan(
                      text: text2.toUpperCase(),
                      style: const TextStyle(
                          color: ColorRes.white,
                          fontFamily: FontRes.bold,
                          fontSize: 15),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      );
    });
  }
}
