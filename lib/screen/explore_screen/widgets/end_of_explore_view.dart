import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/screen/explore_screen/explore_screen_view_model.dart';
import 'package:orange_ui/screen/map_screen/map_screen.dart';
import 'package:orange_ui/screen/preference_screen/preference_screen.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/style_res.dart';

class EndOfExploreView extends StatelessWidget {
  final ExploreScreenViewModel model;

  const EndOfExploreView({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        width: double.infinity,
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
              color: ColorRes.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: StyleRes.linearGradient,
                boxShadow: [
                  BoxShadow(
                    color: ColorRes.themeColor.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.explore_rounded,
                size: 46,
                color: ColorRes.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "You're All Caught Up!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontRes.bold,
                fontSize: 22,
                color: ColorRes.davyGrey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You've reviewed all available profiles matching your preferences. Try refreshing, widening your distance or age filters, or exploring users live on the map.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: FontRes.regular,
                fontSize: 14,
                color: ColorRes.grey.withValues(alpha: 0.9),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            // Primary Button: Refresh Profiles
            InkWell(
              onTap: model.refreshProfiles,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: StyleRes.linearGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: ColorRes.themeColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh_rounded, color: ColorRes.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Refresh Profiles",
                      style: TextStyle(
                        fontFamily: FontRes.semiBold,
                        fontSize: 15,
                        color: ColorRes.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Secondary Button: Adjust Preferences
            InkWell(
              onTap: () {
                Get.to(() => const PreferenceScreen())?.then((_) {
                  model.refreshProfiles();
                });
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: ColorRes.themeColor, width: 1.5),
                  color: ColorRes.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.tune_rounded, color: ColorRes.themeColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      S.current.matchPreference,
                      style: const TextStyle(
                        fontFamily: FontRes.semiBold,
                        fontSize: 15,
                        color: ColorRes.themeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Tertiary Button: Explore on Map
            TextButton.icon(
              onPressed: () {
                Get.to(() => const MapScreen());
              },
              icon: const Icon(Icons.location_on_rounded, color: ColorRes.dimGrey6, size: 18),
              label: const Text(
                "Explore Profiles on Map",
                style: TextStyle(
                  fontFamily: FontRes.medium,
                  fontSize: 14,
                  color: ColorRes.dimGrey6,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
