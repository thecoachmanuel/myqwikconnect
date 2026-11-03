import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/common/gradient_border.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/subscription_sheet/subscription_sheet.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/style_res.dart';

class PremiumMemberDialog extends StatelessWidget {
  const PremiumMemberDialog({super.key});

  String _formatExpiry(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return rawDate;
    }
  }

  bool _isExpired(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return false;
    try {
      return DateTime.parse(rawDate).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    UserData? me = SessionManager.instance.getUser();
    final expiryStr = _formatExpiry(me?.proExpireDate);
    final bool expired = _isExpired(me?.proExpireDate);

    return Dialog(
      backgroundColor: ColorRes.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: ShapeDecoration(
              color: ColorRes.white,
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 24,
                  cornerSmoothing: 1,
                ),
              ),
              shadows: [
                BoxShadow(
                  color: ColorRes.themeColor.withValues(alpha: 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Gradient Header Banner ────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                      decoration: const BoxDecoration(
                        gradient: StyleRes.linearGradient,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                AssetRes.icPremiumCrown,
                                height: 26,
                                width: 26,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                S.current.youArePremiumMember.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: FontRes.bold,
                                  fontSize: 15,
                                  color: ColorRes.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 0,
                            child: GestureDetector(
                              onTap: Get.back,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: ColorRes.white.withValues(alpha: 0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: ColorRes.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        children: [
                          // ── Avatar & Name ─────────────────────────────
                          GradientBorder(
                            strokeWidth: 3,
                            radius: 300,
                            gradient: StyleRes.linearGradient,
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: CustomImage(
                                  image: me?.profileImage ?? '',
                                  height: 74,
                                  width: 74,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                me?.fullname ?? me?.username ?? 'VIP Member',
                                style: const TextStyle(
                                  fontFamily: FontRes.bold,
                                  fontSize: 18,
                                  color: ColorRes.darkGrey,
                                ),
                              ),
                              if (me?.isVerify == true) ...[
                                const SizedBox(width: 5),
                                Image.asset(AssetRes.tickMark, width: 18, height: 18),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ── Active Status & Expiry Badge ──────────────
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: expired
                                  ? ColorRes.themeColor.withValues(alpha: 0.1)
                                  : const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: expired
                                    ? ColorRes.themeColor.withValues(alpha: 0.3)
                                    : const Color(0xFF10B981).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: expired ? ColorRes.themeColor : const Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  expired
                                      ? 'Subscription Expired · $expiryStr'
                                      : (expiryStr.isNotEmpty
                                          ? 'VIP Active · Until $expiryStr'
                                          : 'VIP Member Active · Lifetime'),
                                  style: TextStyle(
                                    fontFamily: FontRes.semiBold,
                                    fontSize: 12,
                                    color: expired ? ColorRes.themeColor : const Color(0xFF065F46),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Benefits Card ─────────────────────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: ShapeDecoration(
                              color: ColorRes.dimGrey7.withValues(alpha: 0.3),
                              shape: SmoothRectangleBorder(
                                borderRadius: SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 1),
                                side: const BorderSide(color: ColorRes.borderColor, width: 0.8),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Active VIP Privileges',
                                  style: TextStyle(
                                    fontFamily: FontRes.bold,
                                    fontSize: 13,
                                    color: ColorRes.darkGrey,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _privilegeRow(
                                  icon: Icons.verified_rounded,
                                  title: 'Verified VIP Badge',
                                  subtitle: 'Crown & tick mark on your profile',
                                ),
                                _privilegeRow(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  title: 'Free Direct Messaging',
                                  subtitle: 'Send messages without diamond deduction',
                                ),
                                _privilegeRow(
                                  icon: Icons.swap_horiz_rounded,
                                  title: 'Unlimited Rewinds',
                                  subtitle: 'Reverse and reconnect with past profiles',
                                ),
                                _privilegeRow(
                                  icon: Icons.block_flipped,
                                  title: '100% Ad-Free Browsing',
                                  subtitle: 'Zero ads across feed, chat, & explore',
                                ),
                                _privilegeRow(
                                  icon: Icons.star_outline_rounded,
                                  title: 'Priority Discovery Placement',
                                  subtitle: 'Highlighted first to nearby users',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Action Buttons ────────────────────────────
                          if (expired)
                            InkWell(
                              onTap: () {
                                Get.back();
                                Get.bottomSheet(
                                  const SubscriptionSheet(),
                                  isScrollControlled: true,
                                );
                              },
                              child: Container(
                                height: 48,
                                width: double.infinity,
                                decoration: ShapeDecoration(
                                  gradient: StyleRes.linearGradient,
                                  shape: SmoothRectangleBorder(
                                    borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 1),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  '🔄 Renew VIP Subscription',
                                  style: TextStyle(
                                    fontFamily: FontRes.bold,
                                    fontSize: 15,
                                    color: ColorRes.white,
                                  ),
                                ),
                              ),
                            )
                          else
                            InkWell(
                              onTap: Get.back,
                              child: Container(
                                height: 48,
                                width: double.infinity,
                                decoration: ShapeDecoration(
                                  gradient: StyleRes.linearGradient,
                                  shape: SmoothRectangleBorder(
                                    borderRadius: SmoothBorderRadius(cornerRadius: 14, cornerSmoothing: 1),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Enjoy VIP Privileges',
                                  style: TextStyle(
                                    fontFamily: FontRes.bold,
                                    fontSize: 15,
                                    color: ColorRes.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),

                          Text(
                            'Orange VIP · Powered by Paystack Secure Payments',
                            style: TextStyle(
                              fontFamily: FontRes.regular,
                              fontSize: 11,
                              color: ColorRes.dimGrey3.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _privilegeRow({required IconData icon, required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: ShapeDecoration(
              gradient: StyleRes.linearGradient,
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(cornerRadius: 8, cornerSmoothing: 1),
              ),
            ),
            child: Icon(icon, color: ColorRes.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: FontRes.semiBold,
                    fontSize: 12.5,
                    color: ColorRes.darkGrey,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: FontRes.regular,
                    fontSize: 11,
                    color: ColorRes.dimGrey3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: ColorRes.themeColor, size: 16),
        ],
      ),
    );
  }
}

