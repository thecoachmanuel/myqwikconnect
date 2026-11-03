import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/common/gradient_border.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/screen/subscription_sheet/subscription_sheet.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/style_res.dart';

class YourAreProMember extends StatelessWidget {
  const YourAreProMember({super.key});

  String _formatExpiry(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final months = [
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
    final expired = _isExpired(me?.proExpireDate);

    return SubscriptionBG(
      widget: SafeArea(
        top: true,
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ColorRes.themeColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: ColorRes.themeColor, size: 20),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'VIP Membership',
                    style: const TextStyle(
                      fontFamily: FontRes.bold,
                      fontSize: 17,
                      color: ColorRes.darkGrey,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Column(
                  children: [
                    // ── Hero gradient card ────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 28),
                      decoration: ShapeDecoration(
                        gradient: StyleRes.linearGradient,
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                              cornerRadius: 28, cornerSmoothing: 1),
                        ),
                        shadows: [
                          BoxShadow(
                            color: ColorRes.themeColor.withValues(alpha: 0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          // Crown icon
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text('👑',
                                  style: TextStyle(fontSize: 28)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Avatar with gradient ring
                          GradientBorder(
                            strokeWidth: 3,
                            radius: 300,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.9),
                                Colors.white.withValues(alpha: 0.4),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: ClipOval(
                                child: CustomImage(
                                  image: me?.profileImage ?? '',
                                  height: 90,
                                  width: 90,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Name
                          Text(
                            me?.fullname ?? me?.username ?? 'Premium Member',
                            style: const TextStyle(
                              fontFamily: FontRes.bold,
                              fontSize: 20,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          // Premium pill badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 5),
                                Text(
                                  S.of(context).premium.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: FontRes.bold,
                                    color: Colors.white,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Expiry date
                          if (expiryStr.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: expired
                                    ? Colors.red.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    expired
                                        ? Icons.warning_amber_rounded
                                        : Icons.calendar_today_rounded,
                                    color:
                                        Colors.white.withValues(alpha: 0.9),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    expired
                                        ? 'Subscription expired · $expiryStr'
                                        : 'Active until $expiryStr',
                                    style: TextStyle(
                                      fontFamily: FontRes.medium,
                                      color:
                                          Colors.white.withValues(alpha: 0.95),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Benefits section ─────────────────────────
                    _SectionLabel(label: 'Your Premium Benefits'),
                    const SizedBox(height: 12),
                    _BenefitRow(
                      icon: Icons.verified_rounded,
                      title: 'Verified Badge',
                      subtitle: 'Orange check on your profile',
                    ),
                    _BenefitRow(
                      icon: Icons.swap_horiz_rounded,
                      title: 'Unlimited Reverse Swipes',
                      subtitle: 'Undo any missed connection',
                    ),
                    _BenefitRow(
                      icon: Icons.chat_bubble_rounded,
                      title: 'Free Chat Access',
                      subtitle: 'Message anyone without diamonds',
                    ),
                    _BenefitRow(
                      icon: Icons.block_rounded,
                      title: 'Ad-Free Experience',
                      subtitle: 'No interruptions while you browse',
                    ),
                    _BenefitRow(
                      icon: Icons.star_rounded,
                      title: 'Priority in Discover',
                      subtitle: 'Show up first in match lists',
                    ),

                    const SizedBox(height: 28),

                    // ── Renew CTA if expired, else close ─────────
                    if (expired)
                      _PrimaryButton(
                        label: '🔄 Renew VIP Subscription',
                        onTap: () {
                          Get.back();
                          // Parent will re-open the subscription sheet
                        },
                        gradient: StyleRes.linearGradient,
                      )
                    else
                      _PrimaryButton(
                        label: '✓ All Good — Continue',
                        onTap: Get.back,
                        gradient: StyleRes.linearGradient,
                      ),

                    const SizedBox(height: 16),

                    // Secondary: dimmed text note
                    Text(
                      'Your subscription renews automatically.\nCancel anytime from your store.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: FontRes.regular,
                        fontSize: 12,
                        color: ColorRes.dimGrey3.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
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

// ────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: FontRes.bold,
          fontSize: 15,
          color: ColorRes.darkGrey,
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius:
              SmoothBorderRadius(cornerRadius: 16, cornerSmoothing: 1),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              gradient: StyleRes.linearGradient,
              shape: SmoothRectangleBorder(
                borderRadius:
                    SmoothBorderRadius(cornerRadius: 12, cornerSmoothing: 1),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: FontRes.semiBold,
                    fontSize: 14,
                    color: ColorRes.darkGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: FontRes.regular,
                    fontSize: 12,
                    color: ColorRes.dimGrey3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: ColorRes.themeColor, size: 20),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Gradient gradient;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: ShapeDecoration(
          gradient: gradient,
          shape: SmoothRectangleBorder(
            borderRadius:
                SmoothBorderRadius(cornerRadius: 18, cornerSmoothing: 1),
          ),
          shadows: [
            BoxShadow(
              color: ColorRes.themeColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            )
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: FontRes.bold,
            fontSize: 16,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
